local _, ns = ...

-- Base locale. Every key used in the addon must be defined here.
-- Other locales only override the keys they translate; missing keys fall back to enUS.
local L = setmetatable({}, {
    __index = function(_, key)
        return key
    end,
})
ns.L = L

L["ADDON_LOADED"] = "Version %s loaded. Type /gryphonchat for help."
L["DEBUG_ON"] = "Debug output enabled."
L["DEBUG_OFF"] = "Debug output disabled."
L["HELP_HEADER"] = "Commands:"
L["HELP_VERSION"] = "/gryphonchat version - show the addon version"
L["HELP_DEBUG"] = "/gryphonchat debug - toggle debug output"
L["HELP_NOTIFY"] = "/gryphonchat notify on||off - automatic messages of the addon (e.g. on login)"
L["NOTIFY_ON"] = "Automatic messages are on for this character."
L["NOTIFY_OFF"] = "Automatic messages are off for this character. Answers to commands are still shown."
L["COPY_URL_TITLE"] = "Copy Link"
L["COPY_CHAT_TITLE"] = "Copy Chat: %s"
L["COPY_CHAT_TOOLTIP"] = "Copy chat"
L["COPY_CHAT_EMPTY"] = "This chat window has no messages to copy."
L["COPY_HINT_LINE"] = "Ctrl+C copies, Esc closes."
L["COPY_HINT_TEXT"] = "Everything is selected: Ctrl+C copies, Esc closes."
L["HELP_LINES"] = "/gryphonchat lines <50-5000> - lines every chat window of this character keeps (default 128)"
L["LINES_INFO"] = "Chat windows keep %d lines for this character."
L["LINES_SET"] = "Chat windows now keep %d lines for this character."
L["LINES_INVALID"] = "Please enter a whole number of lines between %d and %d."
-- Blizzard's channel names as the game client of this language shows them, and their short names.
L["CHANNEL_GENERAL"] = "General"
L["CHANNEL_GENERAL_SHORT"] = "G"
L["CHANNEL_TRADE"] = "Trade"
L["CHANNEL_TRADE_SHORT"] = "T"
L["CHANNEL_LOCAL_DEFENSE"] = "LocalDefense"
L["CHANNEL_LOCAL_DEFENSE_SHORT"] = "LD"
L["CHANNEL_WORLD_DEFENSE"] = "WorldDefense"
L["CHANNEL_WORLD_DEFENSE_SHORT"] = "WD"
L["CHANNEL_LOOKING_FOR_GROUP"] = "LookingForGroup"
L["CHANNEL_LOOKING_FOR_GROUP_SHORT"] = "LfG"
L["CHANNEL_GUILD_RECRUITMENT"] = "GuildRecruitment"
L["CHANNEL_GUILD_RECRUITMENT_SHORT"] = "GR"
L["HELP_CHANNELS"] = "/gryphonchat channels - show the short channel names"
L["HELP_CHANNELS_TOGGLE"] = "/gryphonchat channels on||off - short channel names for this character (default off)"
L["HELP_CHANNELS_SET"] = "/gryphonchat channels set <channel||number> <short name> - own short name for a channel"
L["HELP_CHANNELS_RESET"] = "/gryphonchat channels reset <channel||number> - remove the own short name"
L["CHANNELS_ON"] = "Short channel names are on for this character."
L["CHANNELS_OFF"] = "Short channel names are off for this character."
L["CHANNELS_NONE"] = "You have not joined any channel."
L["CHANNELS_ENTRY"] = "%s: %s"
L["CHANNELS_ENTRY_CUSTOM"] = "%s: %s (own)"
L["CHANNELS_ENTRY_NONE"] = "%s: unchanged"
L["CHANNELS_SET"] = "%s is now shown as %s."
L["CHANNELS_RESET"] = "Own short name of %s removed."
L["CHANNELS_NOT_CUSTOM"] = "%s has no own short name."
L["CHANNELS_UNKNOWN"] = "You have not joined a channel with the number %s."
L["CHANNELS_INVALID"] = "Short names need 1 to %d characters, without ||, [ or ]."
