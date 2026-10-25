-- luacheck configuration for GryphonChat (WoW Forever, Classic Era, Anniversary, MoP Classic and
-- Retail, Lua 5.1)
std = "lua51"
max_line_length = 120
exclude_files = { ".tools/" }

-- Methods defined with ":" do not have to use the implicit self.
self = false

-- Globals the addon defines.
globals = {
    "GryphonChatDB",
    "GryphonChatCharDB",
    "SLASH_GRYPHONCHAT1",
    "SlashCmdList",
}

-- WoW API and Blizzard UI globals the addon reads. Add new ones here when used.
read_globals = {
    -- WoW Lua extensions
    "format",
    "floor",
    "strtrim",
    "issecretvalue",
    "hooksecurefunc",
    "wipe",

    -- API
    "C_AddOns",
    "C_Timer",
    "CreateFrame",
    "GetAddOnMemoryUsage",
    "UpdateAddOnMemoryUsage",
    "GetChannelList",
    "GetLocale",
    "IsControlKeyDown",

    -- UI helpers
    "ChatFrameUtil",
    "EventRegistry",
    "FCF_OpenTemporaryWindow",
    "GameTooltip_Hide",

    -- Frames
    "CHAT_FRAMES",
    "DEFAULT_CHAT_FRAME",
    "GameTooltip",
    "UIParent",
}
