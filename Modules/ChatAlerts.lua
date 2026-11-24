local _, ns = ...
local L = ns.L
local ChatAlerts = ns:RegisterModule("ChatAlerts")

-- Alerts for messages in chats the player does not want to miss (guild, party, raid, ...) and for
-- keywords such as the own name. Every chat type, and the keywords, has its own choice of alerts:
--   - in the chat windows: a glowing tab and an unread count while a window is in the background,
--     a "New messages" line where its unread messages start and a marker in front of the lines,
--   - outside of them: a sound and the message in the upper middle of the screen.
-- Keywords are also shown in color. A message of a chat type that contains a keyword gets the alerts
-- of both, and the sound of the keywords if they have one. Own messages never alert.
--
-- The tab glow and count are own frames on the tab: calling FCF_StartAlertFlash would taint the tab
-- state that Blizzard's whisper handling reads (see WhisperList.lua). They ignore the tab's alpha,
-- so they stay visible while the tabs are faded out. A docked tab in the dock's overflow lights up
-- the overflow button instead.
--
-- New messages are seen after a window showed them (Compat.HookChatMessages), so the counts follow
-- Blizzard's rules which window shows what. Marker, keyword colors and the "New messages" line
-- change the message before it is shown, in a message filter. Blizzard skips the filters for secret
-- event arguments (e.g. in encounters): then there are no keywords, markers and line, but
-- tab, sound and screen alerts still work. Secret text is only passed on to font strings.

-- Chat types with own alert settings, in the order of the options: the chats, then the keywords.
ChatAlerts.TYPES = { "guild", "officer", "party", "raid", "instance", "whisper", "keyword" }
-- Alerts of a chat type, in the order of the options. The sound is set apart.
ChatAlerts.ALERTS = { "tabFlash", "tabCount", "newMessagesLine", "markLines", "centerText" }

-- Chat events of the chats.

local GROUP_EVENTS = {
    guild = { "CHAT_MSG_GUILD" },
    officer = { "CHAT_MSG_OFFICER" },
    party = { "CHAT_MSG_PARTY", "CHAT_MSG_PARTY_LEADER" },
    raid = { "CHAT_MSG_RAID", "CHAT_MSG_RAID_LEADER", "CHAT_MSG_RAID_WARNING" },
    instance = { "CHAT_MSG_INSTANCE_CHAT", "CHAT_MSG_INSTANCE_CHAT_LEADER" },
    whisper = { "CHAT_MSG_WHISPER", "CHAT_MSG_BN_WHISPER" },
}

-- Own whispers. Whisper chats are told apart by the other player, so the own whispers keep the chat
-- with them active (see the sound pause).
local OWN_WHISPER_EVENTS = { "CHAT_MSG_WHISPER_INFORM", "CHAT_MSG_BN_WHISPER_INFORM" }

-- Further chat events whose messages are searched for keywords.
local KEYWORD_EVENTS = {
    "CHAT_MSG_SAY",
    "CHAT_MSG_YELL",
    "CHAT_MSG_EMOTE",
    "CHAT_MSG_CHANNEL",
    "CHAT_MSG_COMMUNITIES_CHANNEL",
}

-- Chats that get the "New messages" line. The filter runs for every window that registered the
-- event, but whispers can go to own windows and channels to some windows only, so the line could
-- land in a window that does not show the message.
local LINE_GROUPS = { guild = true, officer = true, party = true, raid = true, instance = true }

-- Sounds to choose from (keys of SOUNDKIT, on all supported clients), labels "ALERTS_SOUND_<key>".
-- An empty key is no sound.
ChatAlerts.SOUNDS = {
    "READY_CHECK",
    "RAID_WARNING",
    "IG_PLAYER_INVITE",
    "MAP_PING",
    "UI_BNET_TOAST",
    "ALARM_CLOCK_WARNING_3",
    "TELL_MESSAGE",
}
-- Sounds that other addons register with LibSharedMedia-3.0 (embedded, Libs/) are saved with this
-- prefix before their name. LibSharedMedia lists them with a "None" entry, which is left out.
local SHARED_PREFIX = "lsm:"
local LSM = LibStub("LibSharedMedia-3.0")
local LSM_NONE = "None"
-- At most one sound in this many seconds, across all chats.
local SOUND_COOLDOWN = 2
-- Choices for the sound pause in seconds (config.soundPause): a chat's sound plays only after the
-- chat was quiet this long, so a running conversation alerts once. 0 is every message.
ChatAlerts.SOUND_PAUSES = { 0, 15, 30, 60, 120, 300 }

ChatAlerts.MAX_KEYWORD_LENGTH = 32
local MIN_KEYWORD_LENGTH = 2

local GLOW_TEXTURE = "Interface\\ChatFrame\\ChatFrameTab-NewMessage"
local MARKER = "|TInterface\\ChatFrame\\ChatFrameExpandArrow:0|t "
local KEYWORD_COLOR = "ffff7f00"
local NEW_MESSAGES_COLOR = { 1, 0.82, 0 }
local MAX_COUNT = 99

-- Screen alerts: the newest line on top, each shown for a while and then faded out.
local CENTER_LINES = 3
local CENTER_LINE_HEIGHT = 22
local CENTER_WIDTH = 800
local CENTER_HOLD = 5
local CENTER_FADE = 1.5

-- Escape sequences in a chat message that keywords are not searched in: an escaped "||",
-- hyperlinks, colors, textures, atlases, Battle.net names and line breaks.
local ESCAPES = {
    "^||",
    "^|H.-|h.-|h",
    "^|c%x%x%x%x%x%x%x%x",
    "^|cn[^:]*:",
    "^|r",
    "^|T.-|t",
    "^|A.-|a",
    "^|K.-|k",
    "^|n",
}

local eventGroups = {}
for group, events in pairs(GROUP_EVENTS) do
    for _, event in ipairs(events) do
        eventGroups[event] = group
    end
end
local ownWhisperEvents = {}
for _, event in ipairs(OWN_WHISPER_EVENTS) do
    ownWhisperEvents[event] = true
end
local keywordEvents = {}
for _, event in ipairs(KEYWORD_EVENTS) do
    keywordEvents[event] = true
end

-- Chat frame -> { unread = counted messages while in the background, flash = the tab glows,
-- lastMessage = GetTime() of the last counted or glowing message, linePending = the next message gets
-- the "New messages" line, overlay = glow and count on the tab }.
local states = {}
-- Functions called with the chat frame after its unread messages or glow changed (see the whisper list).
local unreadCallbacks = {}
local overflowOverlay
local playerGUID
-- Lowercase keywords including the own name, nil while keywords are off.
local keywords
local lastSoundTime = 0
local lastLineID, lastAlertTime, lastAlertEvent
-- Chat (group, or "whisper:" with the other player) -> GetTime() of its last message, own included.
local lastActivity = {}
local center
local centerEntries = {}

local function GetConfig()
    return ns.charDb.chatAlerts
end

local function IsSecret(value)
    return issecretvalue ~= nil and issecretvalue(value)
end

local function IsOwnMessage(senderGUID)
    return type(senderGUID) == "string" and not IsSecret(senderGUID) and senderGUID == playerGUID
end

-- True if the chat type can have the alert: the "New messages" line only goes to the chats that
-- every window registered for them shows (LINE_GROUPS).
function ChatAlerts.HasAlert(chatType, alert)
    return alert ~= "newMessagesLine" or LINE_GROUPS[chatType] == true
end

-- Settings of a chat type, or nil if it has no alert at all.
local function GetTypeConfig(chatType)
    local typeConfig = chatType and GetConfig().types[chatType]
    if not typeConfig then
        return nil
    end
    if typeConfig.sound ~= "" then
        return typeConfig
    end
    for _, alert in ipairs(ChatAlerts.ALERTS) do
        if typeConfig[alert] and ChatAlerts.HasAlert(chatType, alert) then
            return typeConfig
        end
    end
    return nil
end

-- True if the chat or the keyword settings of a message have the alert.
local function HasAnyAlert(alert, groupConfig, keywordConfig)
    return (groupConfig ~= nil and groupConfig[alert]) or (keywordConfig ~= nil and keywordConfig[alert]) or false
end

-- Keywords -------------------------------------------------------------------------------------

local function RebuildKeywords()
    local config = GetConfig()
    if not config.keywords then
        keywords = nil
        return
    end
    local list = {}
    if config.ownName then
        for _, name in ipairs(ns.Compat.GetOwnMentionNames()) do
            list[#list + 1] = name:lower()
        end
    end
    for _, word in ipairs(config.keywordList) do
        list[#list + 1] = word:lower()
    end
    keywords = #list > 0 and list or nil
end

-- Calls fn(part, isPlain) for the parts of a chat message in order: plain text and escape sequences.
local function ForEachPart(message, fn)
    local init = 1
    local plainStart = 1
    while true do
        local bar = message:find("|", init, true)
        if not bar then
            break
        end
        local escapeEnd
        for _, pattern in ipairs(ESCAPES) do
            local _, last = message:find(pattern, bar)
            if last then
                escapeEnd = last
                break
            end
        end
        if escapeEnd then
            if bar > plainStart then
                fn(message:sub(plainStart, bar - 1), true)
            end
            fn(message:sub(bar, escapeEnd), false)
            plainStart = escapeEnd + 1
            init = escapeEnd + 1
        else
            init = bar + 1
        end
    end
    if plainStart <= #message then
        fn(message:sub(plainStart), true)
    end
end

-- Letters, digits and the bytes of multibyte (UTF-8) characters belong to a word.
local function IsWordByte(text, position)
    local char = text:sub(position, position)
    return char ~= "" and char:find("[%w\128-\255]") ~= nil
end

-- Start and end of the first keyword in text (lowercase) from position init on, as a whole word.
local function FindKeyword(lowerText, init)
    local bestStart, bestEnd
    for _, keyword in ipairs(keywords) do
        local position = init
        while true do
            local first, last = lowerText:find(keyword, position, true)
            if not first or (bestStart and first > bestStart) then
                break
            end
            if not IsWordByte(lowerText, first - 1) and not IsWordByte(lowerText, last + 1) then
                if not bestStart or first < bestStart or last > bestEnd then
                    bestStart, bestEnd = first, last
                end
                break
            end
            position = first + 1
        end
    end
    return bestStart, bestEnd
end

local function HasKeyword(message)
    if not keywords or type(message) ~= "string" or IsSecret(message) then
        return false
    end
    local found = false
    ForEachPart(message, function(part, isPlain)
        if isPlain and not found and FindKeyword(part:lower(), 1) then
            found = true
        end
    end)
    return found
end

-- The message with the keywords in color. string.lower keeps the length, so the positions found in
-- the lowercase text are valid in the original.
local function HighlightKeywords(message)
    local result = {}
    ForEachPart(message, function(part, isPlain)
        if not isPlain then
            result[#result + 1] = part
            return
        end
        local lowerPart = part:lower()
        local position = 1
        while true do
            local first, last = FindKeyword(lowerPart, position)
            if not first then
                break
            end
            result[#result + 1] = part:sub(position, first - 1)
            result[#result + 1] = "|c" .. KEYWORD_COLOR .. part:sub(first, last) .. "|r"
            position = last + 1
        end
        result[#result + 1] = part:sub(position)
    end)
    return table.concat(result)
end

-- Tab glow and count ---------------------------------------------------------------------------

-- isTab: the glow goes into the tab's BORDER layer like Blizzard's own tab glow (FloatingChatFrame.xml),
-- below the tab name, so the name stays readable. Adding a texture to the tab writes no Blizzard field.
-- The overflow button has no text; its glow lies on top.
local function CreateOverlay(parent, isTab)
    local overlay = CreateFrame("Frame", nil, parent)
    overlay:SetAllPoints(parent)
    overlay:SetFrameLevel(parent:GetFrameLevel() + 5)
    -- The tabs fade out while the mouse is away from the chat.
    overlay:SetIgnoreParentAlpha(true)
    overlay:EnableMouse(false)

    local glow
    if isTab then
        glow = parent:CreateTexture(nil, "BORDER", nil, 1)
        glow:SetIgnoreParentAlpha(true)
        glow:SetPoint("BOTTOMLEFT", 8, 0)
        glow:SetPoint("BOTTOMRIGHT", -8, 0)
    else
        glow = overlay:CreateTexture(nil, "OVERLAY")
        glow:SetPoint("TOPLEFT", 6, 0)
        glow:SetPoint("BOTTOMRIGHT", -6, -2)
    end
    glow:SetTexture(GLOW_TEXTURE)
    glow:SetBlendMode("ADD")
    glow:Hide()
    overlay.glow = glow

    local pulse = glow:CreateAnimationGroup()
    pulse:SetLooping("BOUNCE")
    local alpha = pulse:CreateAnimation("Alpha")
    alpha:SetFromAlpha(1)
    alpha:SetToAlpha(0.25)
    alpha:SetDuration(0.8)
    overlay.pulse = pulse

    local count = overlay:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    -- A chat tab is 32 high, but its art and name fill only the lower half (ChatTabTemplate): the count
    -- sits in the upper right corner of the art.
    if isTab then
        count:SetPoint("TOPRIGHT", -4, -9)
    else
        count:SetPoint("TOPRIGHT", -2, 4)
    end
    count:SetShadowOffset(1, -1)
    overlay.count = count

    overlay:Hide()
    return overlay
end

local function ShowOverlay(overlay, unread, flash)
    overlay:SetShown(unread > 0 or flash)
    overlay.glow:SetShown(flash)
    if flash then
        if not overlay.pulse:IsPlaying() then
            overlay.pulse:Play()
        end
    else
        overlay.pulse:Stop()
    end
    overlay.count:SetText(unread > 0 and (unread > MAX_COUNT and MAX_COUNT .. "+" or unread) or "")
end

-- The overflow button stands for the docked tabs that do not fit into the dock.
local function UpdateOverflow()
    local button = ns.Compat.GetChatDockOverflowButton()
    if not button then
        return
    end
    local unread, flash = 0, false
    for chatFrame, state in pairs(states) do
        if (state.unread > 0 or state.flash) and ns.Compat.IsChatTabInOverflow(chatFrame) then
            unread = unread + state.unread
            flash = flash or state.flash
        end
    end
    if unread == 0 and not flash and not overflowOverlay then
        return
    end
    overflowOverlay = overflowOverlay or CreateOverlay(button)
    ShowOverlay(overflowOverlay, unread, flash)
end

local function UpdateTab(chatFrame)
    local state = states[chatFrame]
    if state.overlay then
        ShowOverlay(state.overlay, state.unread, state.flash)
    end
    UpdateOverflow()
    for _, callback in ipairs(unreadCallbacks) do
        callback(chatFrame)
    end
end

local function OnChatFrameShown(chatFrame)
    local state = states[chatFrame]
    state.unread = 0
    state.flash = false
    state.linePending = false
    UpdateTab(chatFrame)
end

local function OnChatFrameHidden(chatFrame)
    states[chatFrame].linePending = true
end

-- Called for every chat window, and again whenever a whisper window opens.
local function OnChatFrame(chatFrame)
    if states[chatFrame] then
        return
    end
    local tab = ns.Compat.GetChatTab(chatFrame)
    states[chatFrame] = {
        unread = 0,
        flash = false,
        lastMessage = 0,
        linePending = not chatFrame:IsShown(),
        overlay = tab and CreateOverlay(tab, true),
    }
    chatFrame:HookScript("OnShow", OnChatFrameShown)
    chatFrame:HookScript("OnHide", OnChatFrameHidden)
end

-- "New messages" line, marker and keyword colors -----------------------------------------------

local function IsNewMessagesLine(text)
    return type(text) == "string" and not IsSecret(text) and text == L["ALERTS_NEW_MESSAGES"]
end

-- Before the first message a window in the background gets; an older line of the window goes away.
local function AddNewMessagesLine(chatFrame)
    local state = states[chatFrame]
    if not state or not state.linePending or chatFrame:IsShown() then
        return
    end
    state.linePending = false
    chatFrame:RemoveMessagesByPredicate(IsNewMessagesLine)
    chatFrame:AddMessage(L["ALERTS_NEW_MESSAGES"], NEW_MESSAGES_COLOR[1], NEW_MESSAGES_COLOR[2],
        NEW_MESSAGES_COLOR[3])
end

-- Message filter, called for every chat window that registered the event. Argument 12 of the event
-- is the sender's GUID.
local function MessageFilter(chatFrame, event, message, ...)
    if type(message) ~= "string" or IsSecret(message) then
        return false
    end
    local group = eventGroups[event]
    local groupConfig = GetTypeConfig(group)
    local own = IsOwnMessage(select(11, ...))
    local hit = not own and HasKeyword(message)
    local keywordConfig = hit and GetTypeConfig("keyword") or nil

    if not own and groupConfig and groupConfig.newMessagesLine and LINE_GROUPS[group] then
        AddNewMessagesLine(chatFrame)
    end

    local changed = message
    if hit then
        changed = HighlightKeywords(changed)
    end
    -- Own messages keep the marker of their chat, so all its lines look the same.
    if HasAnyAlert("markLines", groupConfig, keywordConfig) then
        changed = MARKER .. changed
    end
    if changed ~= message then
        return false, changed, ...
    end
    return false
end

-- Sound and screen -----------------------------------------------------------------------------

local function PlayAlertSound(key)
    local now = GetTime()
    if now - lastSoundTime < SOUND_COOLDOWN then
        return
    end
    lastSoundTime = now
    ChatAlerts.PlaySound(key)
end

local function RenderCenter()
    for i = 1, CENTER_LINES do
        local line = center.lines[i]
        local entry = centerEntries[i]
        if entry then
            -- The text can be a secret value: font strings take it as it is.
            line:SetText(entry.text)
            line:SetTextColor(entry.r, entry.g, entry.b)
            line:Show()
        else
            line:Hide()
        end
    end
end

local function UpdateCenter()
    local now = GetTime()
    local removed = false
    for i = #centerEntries, 1, -1 do
        local age = now - centerEntries[i].time
        if age >= CENTER_HOLD + CENTER_FADE then
            table.remove(centerEntries, i)
            removed = true
        end
    end
    if removed then
        RenderCenter()
    end
    if #centerEntries == 0 then
        center:Hide()
        return
    end
    for i, entry in ipairs(centerEntries) do
        local age = now - entry.time
        center.lines[i]:SetAlpha(age <= CENTER_HOLD and 1 or 1 - (age - CENTER_HOLD) / CENTER_FADE)
    end
end

local function CreateCenter()
    center = CreateFrame("Frame", nil, UIParent)
    center:SetSize(CENTER_WIDTH, CENTER_LINES * CENTER_LINE_HEIGHT)
    -- Below the error messages (UIErrorsFrame), above the raid warnings (RaidWarningFrame).
    center:SetPoint("TOP", UIParent, "TOP", 0, -186)
    center:SetFrameStrata("HIGH")
    center:EnableMouse(false)
    center.lines = {}
    for i = 1, CENTER_LINES do
        local line = center:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
        line:SetPoint("TOP", 0, -(i - 1) * CENTER_LINE_HEIGHT)
        line:SetWidth(CENTER_WIDTH)
        line:SetWordWrap(false)
        line:SetShadowOffset(1, -1)
        center.lines[i] = line
    end
    center:SetScript("OnUpdate", UpdateCenter)
    center:Hide()
end

-- The message as the chat window shows it, in its color.
local function ShowCenterText(message, r, g, b)
    if not center then
        CreateCenter()
    end
    table.insert(centerEntries, 1, { text = message, r = r or 1, g = g or 1, b = b or 1, time = GetTime() })
    centerEntries[CENTER_LINES + 1] = nil
    RenderCenter()
    center:Show()
end

-- Several windows can show the same message: sound and screen alert only once. The line ID tells
-- messages apart; without it (secret), the event in the same frame counts as the same message.
local function IsNewMessage(event, lineID)
    if lineID ~= nil and not IsSecret(lineID) then
        if lineID == lastLineID then
            return false
        end
        lastLineID = lineID
        return true
    end
    local now = GetTime()
    if now == lastAlertTime and event == lastAlertEvent then
        return false
    end
    lastAlertTime, lastAlertEvent = now, event
    return true
end

-- The chat of a message for the sound pause: the group, for whispers per other player (name, or the
-- Battle.net name escape). nil for messages outside of the groups.
local function GetActivityKey(group, name)
    if group ~= "whisper" then
        return group
    end
    if type(name) == "string" and not IsSecret(name) and name ~= "" then
        return "whisper:" .. name
    end
    return "whisper"
end

-- True if the chat had no message during the sound pause, then counts the message. Called by every
-- window that shows the message: only the first call can be true, and only it counts for the sound.
local function TakeQuiet(key)
    if not key then
        return false
    end
    local now = GetTime()
    local last = lastActivity[key]
    lastActivity[key] = now
    return last == nil or now - last >= GetConfig().soundPause
end

-- After a window showed a chat message.
local function OnChatMessage(chatFrame, event, eventArgs, message, r, g, b)
    local group = eventGroups[event]
    local ownWhisper = ownWhisperEvents[event]
    if not group and not ownWhisper and not (keywords and keywordEvents[event]) then
        return
    end
    local text, senderGUID, lineID, name = ns.Compat.GetChatEventInfo(eventArgs)
    -- Own messages never alert, but keep their chat active.
    if ownWhisper then
        TakeQuiet(GetActivityKey("whisper", name))
        return
    end
    local quiet = TakeQuiet(group and GetActivityKey(group, name))
    if IsOwnMessage(senderGUID) then
        return
    end
    local groupConfig = GetTypeConfig(group)
    local keywordConfig = HasKeyword(text) and GetTypeConfig("keyword") or nil
    if not groupConfig and not keywordConfig then
        return
    end

    local state = states[chatFrame]
    local count = HasAnyAlert("tabCount", groupConfig, keywordConfig)
    local flash = HasAnyAlert("tabFlash", groupConfig, keywordConfig)
    if state and not chatFrame:IsShown() and (count or flash) then
        if count then
            state.unread = state.unread + 1
        end
        state.flash = state.flash or flash
        state.lastMessage = GetTime()
        UpdateTab(chatFrame)
    end

    if IsNewMessage(event, lineID) then
        -- The keyword sound has no pause: a keyword is rare and meant for you.
        local sound = (keywordConfig and keywordConfig.sound ~= "" and keywordConfig.sound)
            or (quiet and groupConfig and groupConfig.sound ~= "" and groupConfig.sound)
        if sound then
            PlayAlertSound(sound)
        end
        if HasAnyAlert("centerText", groupConfig, keywordConfig) then
            ShowCenterText(message, r, g, b)
        end
    end
end

-- Unread messages for other modules -----------------------------------------------------------

-- The counted messages of a chat window in the background, whether its tab glows and the GetTime() of
-- the last of them. Only chat types and keywords with "tabCount" or "tabFlash" count.
function ChatAlerts.GetUnread(chatFrame)
    local state = states[chatFrame]
    if not state then
        return 0, false, 0
    end
    return state.unread, state.flash, state.lastMessage
end

-- Calls callback(chatFrame) whenever GetUnread of a chat window changed.
function ChatAlerts.RegisterUnreadCallback(callback)
    unreadCallbacks[#unreadCallbacks + 1] = callback
end

-- Settings -------------------------------------------------------------------------------------

-- After a change of the keyword settings in the options.
function ChatAlerts.Refresh()
    RebuildKeywords()
end

-- Plays a saved sound: a key of ChatAlerts.SOUNDS or a LibSharedMedia sound (GetSharedSoundKey).
-- A LibSharedMedia sound whose addon is no longer loaded plays nothing.
function ChatAlerts.PlaySound(key)
    local name = ChatAlerts.GetSharedSoundName(key)
    if not name then
        ns.Compat.PlaySoundKit(key)
        return
    end
    local file = LSM:Fetch(LSM.MediaType.SOUND, name, true)
    if file then
        ns.Compat.PlaySoundFile(file)
    end
end

-- The saved key of a LibSharedMedia sound.
function ChatAlerts.GetSharedSoundKey(name)
    return SHARED_PREFIX .. name
end

-- The LibSharedMedia name of a saved key, or nil for a built-in sound.
function ChatAlerts.GetSharedSoundName(key)
    if key:sub(1, #SHARED_PREFIX) == SHARED_PREFIX then
        return key:sub(#SHARED_PREFIX + 1)
    end
    return nil
end

-- Whether a LibSharedMedia sound is registered right now (its addon is loaded).
function ChatAlerts.IsSharedSoundAvailable(name)
    return LSM:IsValid(LSM.MediaType.SOUND, name)
end

-- Names of the sounds other addons registered with LibSharedMedia, sorted, without "None".
function ChatAlerts.GetSharedSounds()
    local names = {}
    for _, name in ipairs(LSM:List(LSM.MediaType.SOUND)) do
        if name ~= LSM_NONE then
            names[#names + 1] = name
        end
    end
    return names
end

local function IsValidKeyword(word)
    return #word >= MIN_KEYWORD_LENGTH and #word <= ChatAlerts.MAX_KEYWORD_LENGTH and not word:find("[|,]")
end

local function FindKeywordIndex(word, list)
    local lowerWord = word:lower()
    for i, existing in ipairs(list or GetConfig().keywordList) do
        if existing:lower() == lowerWord then
            return i
        end
    end
    return nil
end

-- The own keywords as one text, separated by commas, for the options.
function ChatAlerts.GetKeywordText()
    return table.concat(GetConfig().keywordList, ", ")
end

-- Sets the own keywords from a text separated by commas. Invalid words are left out; returns the
-- first of them, or nil.
function ChatAlerts.SetKeywordText(text)
    local list, invalid = {}, nil
    for word in text:gmatch("[^,]+") do
        word = strtrim(word)
        if word ~= "" then
            if not IsValidKeyword(word) then
                invalid = invalid or word
            elseif not FindKeywordIndex(word, list) then
                list[#list + 1] = word
            end
        end
    end
    GetConfig().keywordList = list
    RebuildKeywords()
    return invalid
end

-- Error text for an invalid keyword.
function ChatAlerts.GetInvalidKeywordText()
    return format(L["KEYWORDS_INVALID"], MIN_KEYWORD_LENGTH, ChatAlerts.MAX_KEYWORD_LENGTH)
end

local function PrintKeywords()
    local config = GetConfig()
    if #config.keywordList == 0 then
        ns:Print(L["KEYWORDS_NONE"])
    else
        ns:Print(L["KEYWORDS_LIST"], table.concat(config.keywordList, ", "))
    end
    if config.ownName then
        ns:Print(L["KEYWORDS_OWN_NAME"], table.concat(ns.Compat.GetOwnMentionNames(), ", "))
    end
    if not config.keywords then
        ns:Print(L["KEYWORDS_OFF"])
    end
end

-- "/gryphonchat keywords [add|remove <word>]"
local function KeywordsCommand(args)
    local action, word = args:match("^(%S*)%s*(.-)%s*$")
    action = action:lower()
    local list = GetConfig().keywordList

    if action == "" then
        PrintKeywords()
    elseif action == "add" then
        if not IsValidKeyword(word) then
            ns:Print(ChatAlerts.GetInvalidKeywordText())
        elseif FindKeywordIndex(word) then
            ns:Print(L["KEYWORDS_EXISTS"], word)
        else
            list[#list + 1] = word
            RebuildKeywords()
            ns:Print(L["KEYWORDS_ADDED"], word)
        end
    elseif action == "remove" then
        local index = FindKeywordIndex(word)
        if index then
            ns:Print(L["KEYWORDS_REMOVED"], table.remove(list, index))
            RebuildKeywords()
        else
            ns:Print(L["KEYWORDS_NOT_FOUND"], word)
        end
    else
        ns:Print(L["HELP_KEYWORDS_ADD"])
        ns:Print(L["HELP_KEYWORDS_REMOVE"])
    end
end

ns:RegisterCommand("keywords", KeywordsCommand,
    { L["HELP_KEYWORDS"], L["HELP_KEYWORDS_ADD"], L["HELP_KEYWORDS_REMOVE"] })

function ChatAlerts:OnEnable()
    playerGUID = UnitGUID("player")
    RebuildKeywords()

    ns.Compat.HookChatFrames(OnChatFrame)
    ns.Compat.HookChatMessages(OnChatMessage)

    for _, events in pairs(GROUP_EVENTS) do
        for _, event in ipairs(events) do
            ns.Compat.AddMessageEventFilter(event, MessageFilter)
        end
    end
    for _, event in ipairs(KEYWORD_EVENTS) do
        ns.Compat.AddMessageEventFilter(event, MessageFilter)
    end

    local button = ns.Compat.GetChatDockOverflowButton()
    if button then
        button:HookScript("OnShow", UpdateOverflow)
        button:HookScript("OnHide", UpdateOverflow)
    end
end
