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
L["HELP_LINES"] = "/gryphonchat lines <50-5000> - lines every chat window keeps (default 128)"
L["LINES_INFO"] = "Chat windows keep %d lines for this character."
L["LINES_SET"] = "Chat windows now keep %d lines for this character."
L["LINES_INVALID"] = "Please enter a whole number of lines between %d and %d."
