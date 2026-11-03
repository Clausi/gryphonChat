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

    local ChatInput = ns.modules.ChatInput
    local arrowKeys = RegisterProxySetting("ARROW_KEYS", Settings.VarType.Boolean, L["OPTIONS_ARROW_KEYS"],
        ns.charDefaults.chatInput.arrowKeys,
        function()
            return ns.charDb.chatInput.arrowKeys
        end,
        ChatInput.SetArrowKeys)
    Settings.CreateCheckbox(category, arrowKeys, L["OPTIONS_ARROW_KEYS_TOOLTIP"])

    local keepHistory = RegisterProxySetting("KEEP_HISTORY", Settings.VarType.Boolean, L["OPTIONS_KEEP_HISTORY"],
        ns.charDefaults.chatInput.keepHistory,
        function()
            return ns.charDb.chatInput.keepHistory
        end,
        ChatInput.SetKeepHistory)
    Settings.CreateCheckbox(category, keepHistory, L["OPTIONS_KEEP_HISTORY_TOOLTIP"])

    local linkTooltips = RegisterProxySetting("LINK_TOOLTIPS", Settings.VarType.Boolean, L["OPTIONS_LINK_TOOLTIPS"],
        ns.charDefaults.linkTooltips,
        function()
            return ns.charDb.linkTooltips
        end,
        function(value)
            ns.charDb.linkTooltips = value
        end)
    Settings.CreateCheckbox(category, linkTooltips, L["OPTIONS_LINK_TOOLTIPS_TOOLTIP"])

    local ChatScroll = ns.modules.ChatScroll
    local scrollModifiers = RegisterProxySetting("SCROLL_MODIFIERS", Settings.VarType.Boolean,
        L["OPTIONS_SCROLL_MODIFIERS"], ns.charDefaults.chatScroll.modifiers,
        function()
            return ns.charDb.chatScroll.modifiers
        end,
        function(value)
            ns.charDb.chatScroll.modifiers = value
        end)
    Settings.CreateCheckbox(category, scrollModifiers, L["OPTIONS_SCROLL_MODIFIERS_TOOLTIP"])

    local bottomDelay = RegisterProxySetting("SCROLL_BOTTOM_DELAY", Settings.VarType.Number,
        L["OPTIONS_SCROLL_BOTTOM_DELAY"], ns.charDefaults.chatScroll.bottomDelay,
        function()
            return ns.charDb.chatScroll.bottomDelay
        end,
        function(value)
            ChatScroll.SetBottomDelay(floor(value + 0.5))
        end)
    local delayOptions = Settings.CreateSliderOptions(0, ChatScroll.MAX_BOTTOM_DELAY, ChatScroll.BOTTOM_DELAY_STEP)
    delayOptions:SetLabelFormatter(MinimalSliderWithSteppersMixin.Label.Right, function(value)
        local seconds = floor(value + 0.5)
        return seconds == 0 and L["OPTIONS_OFF"] or format(L["OPTIONS_SECONDS"], seconds)
    end)
    Settings.CreateSlider(category, bottomDelay, delayOptions, L["OPTIONS_SCROLL_BOTTOM_DELAY_TOOLTIP"])
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

-- "/gryphonchat options" opens the options page. Opening it from addon code is blocked in combat
-- (ADDON_ACTION_BLOCKED for OpenSettingsPanel); Esc > Options still works there.
ns:RegisterCommand("options", function()
    if InCombatLockdown() then
        ns:Print(L["OPTIONS_IN_COMBAT"])
        return
    end
    Settings.OpenToCategory(category:GetID())
end, { L["HELP_OPTIONS"] })
