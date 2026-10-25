local _, ns = ...
local L = ns.L
local ChannelNames = ns:RegisterModule("ChannelNames")

-- Shortens the channel name in front of channel messages, e.g. "[1. General - Elwynn Forest]" to
-- "[1. G]". Blizzard's channels have default short names (localized, in Locales/), every channel can
-- get an own one. Off by default, settings per character. The functions on ChannelNames are also
-- used by the editor on the options page and in the chat settings (Modules/ChannelNamesEditor.lua).
--
-- The channel number stays: Blizzard splits the name with "(%d+. )(.*)" when it builds the line
-- (ChatFrameUtil.ResolvePrefixedChannelName) and fails without it.

-- Blizzard's channels: Locales/ has their name as L["CHANNEL_<KEY>"] and the default short name as
-- L["CHANNEL_<KEY>_SHORT"].
local DEFAULT_CHANNELS = {
    "GENERAL",
    "TRADE",
    "LOCAL_DEFENSE",
    "WORLD_DEFENSE",
    "LOOKING_FOR_GROUP",
    "GUILD_RECRUITMENT",
}

ChannelNames.MAX_SHORT_NAME_LENGTH = 16

-- Blizzard only shows a channel message if the channel name is longer than the name the chat frame
-- registered for the channel (ChatFrameOverrides.lua: "channelLength > strlen(value)"). Short names
-- are padded to the original length with "|r", which shows nothing.
local PADDING = "|r"

-- Lowercase channel name -> default short name, built on first use.
local defaultShortNames

local function GetDefaultShortNames()
    if not defaultShortNames then
        defaultShortNames = {}
        for _, key in ipairs(DEFAULT_CHANNELS) do
            defaultShortNames[L["CHANNEL_" .. key]:lower()] = L["CHANNEL_" .. key .. "_SHORT"]
        end
    end
    return defaultShortNames
end

-- "General - Elwynn Forest" -> "General", like ChatFrameUtil.GetChannelShortcutName.
local function GetBaseName(channelName)
    return strtrim(channelName:match("^[^%-]+") or channelName)
end

function ChannelNames.IsEnabled()
    return ns.charDb.channelNames.enabled
end

function ChannelNames.SetEnabled(enabled)
    ns.charDb.channelNames.enabled = enabled
end

-- Default short name of one of Blizzard's channels, or nil.
function ChannelNames.GetDefaultShortName(baseName)
    return GetDefaultShortNames()[baseName:lower()]
end

-- Own short name of a channel, or nil.
function ChannelNames.GetCustomShortName(baseName)
    local entry = ns.charDb.channelNames.custom[baseName:lower()]
    return entry and entry.shortName
end

-- Short name to show for a channel, or nil to keep its name.
function ChannelNames.GetShortName(baseName)
    return ChannelNames.GetCustomShortName(baseName) or ChannelNames.GetDefaultShortName(baseName)
end

function ChannelNames.IsValidShortName(shortName)
    return shortName ~= "" and #shortName <= ChannelNames.MAX_SHORT_NAME_LENGTH
        and not shortName:find("[|%[%]]")
end

-- Sets the own short name of a channel. Check it with IsValidShortName first.
function ChannelNames.SetCustomShortName(baseName, shortName)
    ns.charDb.channelNames.custom[baseName:lower()] = { name = baseName, shortName = shortName }
end

function ChannelNames.ResetCustomShortName(baseName)
    ns.charDb.channelNames.custom[baseName:lower()] = nil
end

-- Names of the channels with an own short name, sorted.
function ChannelNames.GetCustomChannels()
    local names = {}
    for _, entry in pairs(ns.charDb.channelNames.custom) do
        names[#names + 1] = entry.name
    end
    table.sort(names, function(a, b)
        return a:lower() < b:lower()
    end)
    return names
end

-- Event arguments of CHAT_MSG_CHANNEL: arg4 is the channel name with number, e.g.
-- "1. General - Elwynn Forest".
local function ChannelFilter(_, _, message, sender, language, channelName, ...)
    if not ChannelNames.IsEnabled() or type(channelName) ~= "string"
        or (issecretvalue and issecretvalue(channelName)) then
        return false
    end
    local prefix = channelName:match("^%d+%. ")
    if not prefix then
        return false
    end
    local shortName = ChannelNames.GetShortName(GetBaseName(channelName:sub(#prefix + 1)))
    if not shortName then
        return false
    end

    local newName = prefix .. shortName
    local missing = #channelName - #newName
    if missing > 0 then
        newName = newName .. PADDING:rep(floor((missing + 1) / #PADDING))
    end
    return false, message, sender, language, newName, ...
end

-- Channel name from a command argument: a channel number is resolved to the joined channel.
local function ResolveChannel(arg)
    local number = tonumber(arg)
    if not number then
        return GetBaseName(arg)
    end
    for _, channel in ipairs(ns.Compat.GetJoinedChannels()) do
        if channel.number == number then
            return channel.name
        end
    end
    return nil
end

local function PrintChannels()
    ns:Print(ChannelNames.IsEnabled() and L["CHANNELS_ON"] or L["CHANNELS_OFF"])

    local joined = ns.Compat.GetJoinedChannels()
    if #joined == 0 then
        ns:Print(L["CHANNELS_NONE"])
    end
    local listed = {}
    for _, channel in ipairs(joined) do
        local customShortName = ChannelNames.GetCustomShortName(channel.name)
        local shortName = ChannelNames.GetShortName(channel.name)
        local name = format("%d. %s", channel.number, channel.name)
        if customShortName then
            ns:Print(L["CHANNELS_ENTRY_CUSTOM"], name, customShortName)
        elseif shortName then
            ns:Print(L["CHANNELS_ENTRY"], name, shortName)
        else
            ns:Print(L["CHANNELS_ENTRY_NONE"], name)
        end
        listed[channel.name:lower()] = true
    end
    -- Own short names of channels that are not joined right now.
    for _, name in ipairs(ChannelNames.GetCustomChannels()) do
        if not listed[name:lower()] then
            ns:Print(L["CHANNELS_ENTRY_CUSTOM"], name, ChannelNames.GetCustomShortName(name))
        end
    end
end

function ChannelNames:OnEnable()
    ns.Compat.AddMessageEventFilter("CHAT_MSG_CHANNEL", ChannelFilter)
end

-- "/gryphonchat channels [on|off|set <channel> <short name>|reset <channel>]"
ns:RegisterCommand("channels", function(args)
    local action, rest = args:match("^(%S*)%s*(.-)$")
    action = action:lower()

    if action == "" then
        PrintChannels()
    elseif action == "on" or action == "off" then
        ChannelNames.SetEnabled(action == "on")
        ns:Print(ChannelNames.IsEnabled() and L["CHANNELS_ON"] or L["CHANNELS_OFF"])
    elseif action == "set" then
        local channelArg, shortName = rest:match("^(%S+)%s+(.-)%s*$")
        if not channelArg then
            ns:Print(L["HELP_CHANNELS_SET"])
            return
        end
        local name = ResolveChannel(channelArg)
        if not name then
            ns:Print(L["CHANNELS_UNKNOWN"], channelArg)
        elseif not ChannelNames.IsValidShortName(shortName) then
            ns:Print(L["CHANNELS_INVALID"], ChannelNames.MAX_SHORT_NAME_LENGTH)
        else
            ChannelNames.SetCustomShortName(name, shortName)
            ns:Print(L["CHANNELS_SET"], name, shortName)
        end
    elseif action == "reset" and rest ~= "" then
        local name = ResolveChannel(rest)
        if not name then
            ns:Print(L["CHANNELS_UNKNOWN"], rest)
        elseif not ChannelNames.GetCustomShortName(name) then
            ns:Print(L["CHANNELS_NOT_CUSTOM"], name)
        else
            ChannelNames.ResetCustomShortName(name)
            ns:Print(L["CHANNELS_RESET"], name)
        end
    else
        ns:Print(L["HELP_CHANNELS"])
        ns:Print(L["HELP_CHANNELS_TOGGLE"])
        ns:Print(L["HELP_CHANNELS_SET"])
        ns:Print(L["HELP_CHANNELS_RESET"])
    end
end, { L["HELP_CHANNELS"], L["HELP_CHANNELS_TOGGLE"], L["HELP_CHANNELS_SET"], L["HELP_CHANNELS_RESET"] })
