local _, ns = ...

-- Differences between the supported clients (Forever, Classic Era, Anniversary, MoP Classic,
-- Retail), in one place. Detects the APIs and methods a client has instead of comparing version
-- numbers. Blizzard UI reference: the forever, classic_era, classic_anniversary, classic (MoP
-- Classic) and live branches of Gethe/wow-ui-source.
local Compat = {}
ns.Compat = Compat

-- Registers a filter for a chat message event: filter(chatFrame, event, message, ...) returns
-- true to hide the message, or false followed by the changed event arguments. All supported clients
-- have ChatFrameUtil.AddMessageEventFilter; the global ChatFrame_AddMessageEventFilter only exists as
-- a deprecation fallback there. Blizzard skips the filter when an event argument is a secret value
-- (ChatFrameFilters.lua, canaccessvalue).
function Compat.AddMessageEventFilter(event, filter)
    ChatFrameUtil.AddMessageEventFilter(event, filter)
end

-- Calls handler(link, text, button, chatFrame) when a "|Haddon:...|h" link is clicked. SetItemRef
-- passes links of type "addon" to the EventRegistry event "SetItemRef" (ItemRefHandlersShared.lua),
-- for every addon: the handler has to check that the link is its own.
function Compat.RegisterAddonLinkHandler(owner, handler)
    EventRegistry:RegisterCallback("SetItemRef", function(_, link, text, button, chatFrame)
        handler(link, text, button, chatFrame)
    end, owner)
end

-- Calls callback(chatFrame) for every chat window, including temporary whisper windows.
function Compat.ForEachChatFrame(callback)
    for _, frameName in ipairs(CHAT_FRAMES) do
        local chatFrame = _G[frameName]
        if chatFrame then
            callback(chatFrame)
        end
    end
end

-- Calls callback(chatFrame) for every chat window now and whenever a temporary whisper window is
-- opened (FCF_OpenTemporaryWindow creates or reuses one). The callback may see the same frame
-- several times.
function Compat.HookChatFrames(callback)
    Compat.ForEachChatFrame(callback)
    hooksecurefunc("FCF_OpenTemporaryWindow", function()
        Compat.ForEachChatFrame(callback)
    end)
end

-- True for an open whisper window (FCF_OpenTemporaryWindow). A closed one keeps isTemporary and its
-- chat type until Blizzard reuses the frame, only inUse is cleared (FCF_Close).
function Compat.IsWhisperWindow(chatFrame)
    return chatFrame.isTemporary and chatFrame.inUse
        and (chatFrame.chatType == "WHISPER" or chatFrame.chatType == "BN_WHISPER") or false
end

-- Name of a whisper window. Can be a secret value on Mainline (FCF_HasSecretName in
-- FloatingChatFrame.lua), so it is returned as it is, without a test: pass it to a font string only.
function Compat.GetWhisperWindowName(chatFrame)
    return chatFrame.name
end

-- Prepares a button with the template SecureActionButtonTemplate for SetChatTabClicks. Whether the
-- action runs on the press or the release depends on the CVar ActionButtonUseKeyDown, so both are
-- registered (SecureActionButton_OnClick).
function Compat.InitChatTabClickButton(button)
    button:RegisterForClicks("LeftButtonDown", "LeftButtonUp")
    button:SetAttribute("type", "macro")
end

-- A click on the button clicks the chat tabs of chatFrames with mouseButton, like the player would:
-- "LeftButton" selects a window, "MiddleButton" closes a whisper window. The tab runs Blizzard's own
-- code from a secure button, so nothing of it is tainted (see WhisperList.lua). Not in combat. The
-- macro text holds 1023 characters: more tabs are left for the next click.
local MAX_TAB_CLICKS = 25

function Compat.SetChatTabClicks(button, chatFrames, mouseButton)
    local lines = {}
    for i = 1, min(#chatFrames, MAX_TAB_CLICKS) do
        lines[i] = format("/click %sTab %s", chatFrames[i]:GetName(), mouseButton)
    end
    button:SetAttribute("macrotext", table.concat(lines, "\n"))
end

-- Calls onStart(chatFrame) when the tab of a chat window starts alerting and onStop(chatFrame) when
-- it stops. FCF_StartAlertFlash runs for every message while the window is not on screen.
function Compat.HookChatAlerts(onStart, onStop)
    hooksecurefunc("FCF_StartAlertFlash", onStart)
    hooksecurefunc("FCF_StopAlertFlash", onStop)
end

-- Calls callback() after a chat window was closed. FCF_Close(frame, fallback) can also close the
-- current window when called without arguments, so it does not name the window.
function Compat.HookChatWindowClosed(callback)
    hooksecurefunc("FCF_Close", function()
        callback()
    end)
end

-- Name of a chat window as shown on its tab ("General", "Combat Log", the whisper target, ...).
function Compat.GetChatFrameName(chatFrame)
    return chatFrame.name or chatFrame:GetName()
end

-- Creates an own button in the button bar next to a chat window (chatFrame.buttonFrame in
-- FloatingChatFrame.xml).
-- Classic: the bar is a VerticalLayoutFrame that stacks its children by layoutIndex from top to
-- bottom: ChatFrame1 uses -2 to 3, the other windows 1 to 3. Duplicate indices raise an error.
-- Mainline: the bar has no layout. Blizzard anchors the channel button (ChatFrame1) and the minimize
-- button (undocked windows) to the top and ChatFrameMenuButton to the bottom of ChatFrame1's bar.
-- The own buttons go to the bottom, above the menu button, one above the other. There is room for
-- one on a short window: create buttons that are only shown at times (SetChatFrameButtonShown) last.
local lastChatFrameButtons = {}

function Compat.CreateChatFrameButton(chatFrame, layoutIndex)
    local buttonFrame = chatFrame.buttonFrame
    local button = CreateFrame("Button", nil, buttonFrame)
    button:SetSize(32, 32)
    if buttonFrame.MarkDirty then
        button.layoutIndex = layoutIndex
        button.align = "center"
        buttonFrame:MarkDirty()
    elseif lastChatFrameButtons[buttonFrame] then
        button:SetPoint("BOTTOM", lastChatFrameButtons[buttonFrame], "TOP")
    elseif ChatFrameMenuButton and ChatFrameMenuButton:GetParent() == buttonFrame then
        button:SetPoint("BOTTOM", ChatFrameMenuButton, "TOP")
    else
        button:SetPoint("BOTTOM")
    end
    lastChatFrameButtons[buttonFrame] = button
    return button
end

-- Shows or hides a button from CreateChatFrameButton. The layout of the Classic bar skips hidden
-- children, but has to be told about the change.
function Compat.SetChatFrameButtonShown(button, shown)
    if button:IsShown() == shown then
        return
    end
    button:SetShown(shown)
    local buttonFrame = button:GetParent()
    if buttonFrame.MarkDirty then
        buttonFrame:MarkDirty()
    end
end

-- Channels the character has joined, in channel number order: { { number = 1, name = "General" },
-- ... }. GetChannelList() returns number, name (without zone) and disabled flag per channel.
function Compat.GetJoinedChannels()
    local channels = {}
    local list = { GetChannelList() }
    for i = 1, #list, 3 do
        channels[#channels + 1] = { number = list[i], name = list[i + 1] }
    end
    return channels
end

-- Name of a joined channel without zone, as GetChannelList returns it: "General" for "General -
-- Elwynn Forest", or nil. ChatFrameUtil.GetChannelShortcutName splits the full name at "-" on the
-- Classic clients and asks C_ChatInfo.GetChannelShortcut on Mainline, which also covers names like
-- "Trade (Services) - Stormwind City" -> "Services".
function Compat.GetChannelBaseName(channelNumber)
    if type(channelNumber) ~= "number" or not select(2, GetChannelName(channelNumber)) then
        return nil
    end
    local name = ChatFrameUtil.GetChannelShortcutName(channelNumber)
    if name == "" then
        return nil
    end
    return name
end

-- Adds an own category below "Other" in the chat settings (right click on a chat tab > Settings)
-- that shows panel. Blizzard shows its panels by the button ID as index into CHAT_CONFIG_CATEGORIES
-- (ChatConfigFrame_Shared.lua). That table is not touched, to keep taint out: the own button calls
-- ChatConfigCategory_OnClick with an ID that is not in it, which hides all of Blizzard's panels, and
-- a hook hides the own panel again when one of Blizzard's buttons is clicked. Returns false if the
-- chat settings are not there.
function Compat.AddChatConfigCategory(text, panel)
    local categoryFrame = ChatConfigCategoryFrame
    -- "Other", the last category of a normal chat window.
    local lastButton = ChatConfigCategoryFrameButton4
    if not categoryFrame or not lastButton or not ChatConfigCategory_OnClick then
        return false
    end

    -- Built like ConfigCategoryButtonTemplate, which needs a global frame name for its highlight.
    local button = CreateFrame("Button", nil, categoryFrame)
    button:SetID(#CHAT_CONFIG_CATEGORIES + 1)
    button:SetHeight(16)
    button:SetPoint("TOPLEFT", lastButton, "BOTTOMLEFT", 0, -1)
    button:SetPoint("TOPRIGHT", lastButton, "BOTTOMRIGHT", 0, -1)
    button:SetNormalFontObject("GameFontNormalLeft")
    button:SetHighlightFontObject("GameFontHighlightLeft")
    button:SetText(text)
    button:GetFontString():ClearAllPoints()
    button:GetFontString():SetPoint("LEFT", 2, 1)
    button:SetHighlightTexture("Interface\\Buttons\\UI-Listbox-Highlight2", "ADD")
    button:GetHighlightTexture():SetVertexColor(0.11, 0.325, 0.48)
    -- Looked up on click: the hook below replaces the global function.
    button:SetScript("OnClick", function(self)
        ChatConfigCategory_OnClick(self)
    end)

    -- Same place as Blizzard's panels.
    panel:SetParent(ChatConfigFrame)
    panel:ClearAllPoints()
    panel:SetPoint("TOPLEFT", ChatConfigBackgroundFrame, "TOPLEFT")
    panel:SetPoint("BOTTOMRIGHT", ChatConfigBackgroundFrame, "BOTTOMRIGHT")
    panel:Hide()

    hooksecurefunc("ChatConfigCategory_OnClick", function(clicked)
        panel:SetShown(clicked == button)
        if clicked == button then
            button:LockHighlight()
        else
            button:UnlockHighlight()
        end
    end)
    -- The text to speech window hides the chat categories; the own one follows "Other".
    hooksecurefunc("ChatConfigCategoryFrame_Refresh", function()
        button:SetShown(lastButton:IsShown())
    end)
    return true
end

-- Input line (edit box) of a chat window (parentKey "editBox" in FloatingChatFrame.xml).
function Compat.GetChatEditBox(chatFrame)
    return chatFrame.editBox
end

-- True if the name suggestions (AutoCompleteBox, e.g. for "/w Na") are shown for editBox. While
-- they are, AutoCompleteEditBox_OnArrowPressed uses the arrow keys to choose a name.
function Compat.IsAutoCompleteShownFor(editBox)
    local box = AutoCompleteBox
    return box ~= nil and box:IsShown() and box.parent == editBox
end

-- Calls onEnter(chatFrame, link) and onLeave(chatFrame) when the mouse enters or leaves a link in a
-- chat window. ChatFrameMixin:OnHyperlinkEnter and OnHyperlinkLeave (ChatFrame.lua) pass both to
-- the EventRegistry, so no chat frame script is touched. The link may be a secret value.
function Compat.RegisterChatHyperlinkHover(owner, onEnter, onLeave)
    EventRegistry:RegisterCallback("ChatFrame.OnHyperlinkEnter", function(_, chatFrame, link)
        onEnter(chatFrame, link)
    end, owner)
    EventRegistry:RegisterCallback("ChatFrame.OnHyperlinkLeave", function(_, chatFrame)
        onLeave(chatFrame)
    end, owner)
end

-- Calls callback(chatFrame, delta, scrolled) after a chat window scrolled by mouse wheel; scrolled
-- is the signed amount of lines Blizzard's handler scrolled it (positive is up, to older lines).
-- Classic: OnMouseWheel is FloatingChatFrame_OnMouseScroll, set on VARIABLES_LOADED (ChatFrame
-- OnEvent) and for new whisper windows, and calls ScrollUp/ScrollDown, i.e. ScrollByAmount(+-1).
-- Mainline: ScrollUtil.InitScrollingMessageFrameWithScrollBar sets it in OnLoad and calls
-- ScrollByAmount(+-3). Both only when the CVar chatMouseScroll is on. The script is hooked, not
-- replaced; a hook on ScrollByAmount records the amount (all scrolling ends there, see
-- ScrollingMessageFrame.lua). AddMessage also scrolls through it, so it is not the hook for the wheel.
local wheelHooks = {}
local scrolledAmounts = {}

local function RecordScrolledAmount(chatFrame, amount)
    scrolledAmounts[chatFrame] = amount
end

function Compat.HookChatMouseWheel(callback)
    local function HookFrame(chatFrame)
        -- A later SetScript replaces the hooked script, so it is hooked again then.
        local script = chatFrame:GetScript("OnMouseWheel")
        if not script or wheelHooks[chatFrame] == script then
            return
        end
        if wheelHooks[chatFrame] == nil then
            hooksecurefunc(chatFrame, "ScrollByAmount", RecordScrolledAmount)
        end
        chatFrame:HookScript("OnMouseWheel", function(self, delta)
            local scrolled = scrolledAmounts[self] or 0
            scrolledAmounts[self] = nil
            callback(self, delta, scrolled)
        end)
        wheelHooks[chatFrame] = chatFrame:GetScript("OnMouseWheel")
    end

    Compat.HookChatFrames(HookFrame)
    -- Classic sets the script on VARIABLES_LOADED, which may come after PLAYER_LOGIN. The chat
    -- frames handle the event after this handler, so the check waits a frame.
    ns:RegisterEvent("VARIABLES_LOADED", function()
        C_Timer.After(0, function()
            Compat.ForEachChatFrame(HookFrame)
        end)
    end)
end
