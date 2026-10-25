local _, ns = ...
local L = ns.L
local Options = ns:RegisterModule("Options")

-- Options page in Blizzard's settings (Esc > Options > AddOns > GryphonChat): the general settings
-- as a vertical list, the short channel names as a subcategory with the channel names editor. The
-- settings are per character and stay in ns.charDb; proxy settings read and write them there.

local category

-- Proxy setting variables must be unique among all settings of the game and addons.
local function RegisterProxySetting(variable, varType, name, defaultValue, getValue, setValue)
    return Settings.RegisterProxySetting(category, "GRYPHONCHAT_" .. variable, varType, name, defaultValue,
        getValue, setValue)
end

local function RegisterGeneralSettings()
    local notifications = RegisterProxySetting("NOTIFICATIONS", Settings.VarType.Boolean,
        L["OPTIONS_NOTIFICATIONS"], ns.charDefaults.notifications,
        function()
            return ns.charDb.notifications
        end,
        function(value)
            ns.charDb.notifications = value
        end)
    Settings.CreateCheckbox(category, notifications, L["OPTIONS_NOTIFICATIONS_TOOLTIP"])

    local ChatHistory = ns.modules.ChatHistory
    local chatLines = RegisterProxySetting("CHAT_LINES", Settings.VarType.Number, L["OPTIONS_CHAT_LINES"],
        ns.charDefaults.chatLines,
        function()
            return ns.charDb.chatLines
        end,
        function(value)
            -- The slider moves in whole steps, but its values may carry rounding errors.
            ChatHistory.SetLines(floor(value + 0.5))
        end)
    local sliderOptions = Settings.CreateSliderOptions(ChatHistory.MIN_LINES, ChatHistory.MAX_LINES, 1)
    sliderOptions:SetLabelFormatter(MinimalSliderWithSteppersMixin.Label.Right)
    Settings.CreateSlider(category, chatLines, sliderOptions, L["OPTIONS_CHAT_LINES_TOOLTIP"])
end

local function RegisterChannelNamesPage()
    local frame = CreateFrame("Frame")

    local title = frame:CreateFontString(nil, "ARTWORK", "GameFontHighlightHuge")
    title:SetPoint("TOPLEFT", 10, -15)
    title:SetText(L["OPTIONS_CHANNEL_NAMES"])

    local editor = ns.ChannelNamesEditor.Create(frame)
    editor:SetPoint("TOPLEFT", 10, -50)
    editor:SetPoint("BOTTOMRIGHT", -10, 10)

    Settings.RegisterCanvasLayoutSubcategory(category, frame, L["OPTIONS_CHANNEL_NAMES"])
end

function Options:OnInitialize()
    category = Settings.RegisterVerticalLayoutCategory(ns.name)
    RegisterGeneralSettings()
    RegisterChannelNamesPage()
    Settings.RegisterAddOnCategory(category)
end

-- "/gryphonchat options" opens the options page.
ns:RegisterCommand("options", function()
    Settings.OpenToCategory(category:GetID())
end, { L["HELP_OPTIONS"] })
