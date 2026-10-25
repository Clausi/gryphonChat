local addonName, ns = ...
local L = ns.L
local ChatLinks = ns:RegisterModule("ChatLinks")

-- Makes web addresses in chat messages clickable. A click opens a small dialog to copy the address.
-- The address is stored in an own link "|Haddon:GryphonChat:url:<address>|h<address>|h".
local LINK_PREFIX = "addon:" .. addonName .. ":url:"
local LINK_COLOR = "ff66bbff"

-- Web addresses: with a scheme ("https://...") or starting with "www.". Both end at whitespace or
-- at "|", which starts the next escape sequence (color, link) or is an escaped "||".
local URL_PATTERNS = {
    "%a[%w+.-]*://[^%s|]+",
    "[Ww][Ww][Ww]%.[^%s|]+",
}

-- Characters that usually end the sentence rather than the address, e.g. "see www.example.com."
local TRAILING_PUNCTUATION = "[%.,;:!%?%)%]}'\"]+$"

-- Chat events whose messages are checked for web addresses.
local EVENTS = {
    "CHAT_MSG_SAY",
    "CHAT_MSG_YELL",
    "CHAT_MSG_GUILD",
    "CHAT_MSG_OFFICER",
    "CHAT_MSG_PARTY",
    "CHAT_MSG_PARTY_LEADER",
    "CHAT_MSG_RAID",
    "CHAT_MSG_RAID_LEADER",
    "CHAT_MSG_RAID_WARNING",
    "CHAT_MSG_INSTANCE_CHAT",
    "CHAT_MSG_INSTANCE_CHAT_LEADER",
    -- Whispers: received and sent ("_INFORM" is the own message as shown in the chat).
    "CHAT_MSG_WHISPER",
    "CHAT_MSG_WHISPER_INFORM",
    "CHAT_MSG_BN_WHISPER",
    "CHAT_MSG_BN_WHISPER_INFORM",
    "CHAT_MSG_CHANNEL",
    "CHAT_MSG_COMMUNITIES_CHANNEL",
    "CHAT_MSG_AFK",
    "CHAT_MSG_DND",
}

-- Start and end of the first web address in text from position init on.
local function FindUrl(text, init)
    local first, last
    for _, pattern in ipairs(URL_PATTERNS) do
        local urlStart, urlEnd = text:find(pattern, init)
        if urlStart and (not first or urlStart < first) then
            first, last = urlStart, urlEnd
        end
    end
    return first, last
end

local function FormatUrlLink(url)
    return format("|c%s|H%s%s|h%s|h|r", LINK_COLOR, LINK_PREFIX, url, url)
end

-- Replaces the web addresses in text without hyperlinks by links. Returns nil if there are none.
local function LinkifyText(text)
    local parts = {}
    local init = 1
    while true do
        local first, last = FindUrl(text, init)
        if not first then
            break
        end
        local url = (text:sub(first, last):gsub(TRAILING_PUNCTUATION, ""))
        parts[#parts + 1] = text:sub(init, first - 1)
        parts[#parts + 1] = FormatUrlLink(url)
        init = first + #url
    end
    if #parts == 0 then
        return nil
    end
    parts[#parts + 1] = text:sub(init)
    return table.concat(parts)
end

-- Replaces the web addresses in a chat message by links. Existing hyperlinks (items, players, ...)
-- are left untouched. Returns nil if the message has no web address.
local function Linkify(message)
    if not (message:find("://", 1, true) or message:find("[Ww][Ww][Ww]%.")) then
        return nil
    end

    local parts = {}
    local found = false
    local init = 1
    while init <= #message do
        local linkStart, linkEnd = message:find("|H.-|h.-|h", init)
        -- Without a further hyperlink, the rest of the message is plain text.
        local text = message:sub(init, (linkStart or 0) - 1)
        local linked = LinkifyText(text)
        found = found or linked ~= nil
        parts[#parts + 1] = linked or text
        if not linkStart then
            break
        end
        parts[#parts + 1] = message:sub(linkStart, linkEnd)
        init = linkEnd + 1
    end

    return found and table.concat(parts) or nil
end

local function UrlFilter(_, _, message, ...)
    if type(message) ~= "string" or (issecretvalue and issecretvalue(message)) then
        return false
    end
    local linked = Linkify(message)
    if linked then
        return false, linked, ...
    end
    return false
end

local function OnLinkClicked(link)
    if type(link) ~= "string" or link:sub(1, #LINK_PREFIX) ~= LINK_PREFIX then
        return
    end
    ns.CopyFrame.ShowLine(L["COPY_URL_TITLE"], link:sub(#LINK_PREFIX + 1))
end

function ChatLinks:OnEnable()
    for _, event in ipairs(EVENTS) do
        ns.Compat.AddMessageEventFilter(event, UrlFilter)
    end
    ns.Compat.RegisterAddonLinkHandler(self, OnLinkClicked)
end
