-- luacheck configuration for GryphonChat (WoW Forever and Retail, Lua 5.1)
std = "lua51"
max_line_length = 120
exclude_files = { ".tools/", "Libs/" }

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
    "min",
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
    "GetChannelName",
    "GetLocale",
    "GetTime",
    "InCombatLockdown",
    "IsControlKeyDown",
    "IsShiftKeyDown",
    "PlaySound",
    "PlaySoundFile",
    "LibStub",
    "SOUNDKIT",
    "Constants",
    "UnitGUID",
    "UnitName",

    -- UI helpers
    "ChatFrameUtil",
    "EventRegistry",
    "FCF_OpenTemporaryWindow",
    "GameTooltip_Hide",
    "HIGHLIGHT_FONT_COLOR",
    "Settings",
    "MinimalSliderWithSteppersMixin",
    "ChatConfigCategory_OnClick",
    "ChatConfigCategoryFrame_Refresh",
    "CHAT_CONFIG_CATEGORIES",

    -- Frames
    "CHAT_FRAMES",
    "GENERAL_CHAT_DOCK",
    "DEFAULT_CHAT_FRAME",
    "GameTooltip",
    "UIParent",
    "ChatConfigFrame",
    "ChatConfigBackgroundFrame",
    "ChatConfigCategoryFrame",
    "ChatConfigCategoryFrameButton4",
    "ChatFrameMenuButton",
    "AutoCompleteBox",
}
