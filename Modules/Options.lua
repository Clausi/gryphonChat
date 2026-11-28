local _, ns = ...
local L = ns.L
local Options = ns:RegisterModule("Options")

-- Options page in Blizzard's settings (Esc > Options > AddOns > GryphonChat): the general settings
-- built with own controls (Core/OptionsPanel.lua explains why), the chat alerts (with the alerts
-- editor) and the short channel names (with the channel names editor) as canvas subcategories. The
-- settings are per character and stay in ns.charDb; the controls read and write them there or
-- through the setters of the modules, so a change takes effect right away.

local category, panel

-- The sliders move in whole steps, but their values may carry rounding errors.
local function Round(value)
    return floor(value + 0.5)
end

local function FormatNumber(value)
    return tostring(Round(value))
end

local function FormatBottomDelay(value)
    local seconds = Round(value)
    return seconds == 0 and L["OPTIONS_OFF"] or format(L["OPTIONS_SECONDS"], seconds)
end

local function AddGeneralSettings()
    panel:AddCheckbox(L["OPTIONS_NOTIFICATIONS"], L["OPTIONS_NOTIFICATIONS_TOOLTIP"],
        function()
            return ns.charDb.notifications
        end,
        function(value)
            ns.charDb.notifications = value
        end)

    local ChatHistory = ns.modules.ChatHistory
    panel:AddSlider(L["OPTIONS_CHAT_LINES"], L["OPTIONS_CHAT_LINES_TOOLTIP"],
        ChatHistory.MIN_LINES, ChatHistory.MAX_LINES, 1, FormatNumber,
        function()
            return ns.charDb.chatLines
        end,
        function(value)
            ChatHistory.SetLines(Round(value))
        end)

    local ChatInput = ns.modules.ChatInput
    panel:AddCheckbox(L["OPTIONS_ARROW_KEYS"], L["OPTIONS_ARROW_KEYS_TOOLTIP"],
        function()
            return ns.charDb.chatInput.arrowKeys
        end,
        ChatInput.SetArrowKeys)

    panel:AddCheckbox(L["OPTIONS_KEEP_HISTORY"], L["OPTIONS_KEEP_HISTORY_TOOLTIP"],
        function()
            return ns.charDb.chatInput.keepHistory
        end,
        ChatInput.SetKeepHistory)

    panel:AddCheckbox(L["OPTIONS_LINK_TOOLTIPS"], L["OPTIONS_LINK_TOOLTIPS_TOOLTIP"],
        function()
            return ns.charDb.linkTooltips
        end,
        function(value)
            ns.charDb.linkTooltips = value
        end)

    panel:AddCheckbox(L["OPTIONS_WHISPER_LIST"], L["OPTIONS_WHISPER_LIST_TOOLTIP"],
        function()
            return ns.charDb.whisperList
        end,
        ns.modules.WhisperList.SetEnabled)

    local ChatScroll = ns.modules.ChatScroll
    panel:AddCheckbox(L["OPTIONS_SCROLL_MODIFIERS"], L["OPTIONS_SCROLL_MODIFIERS_TOOLTIP"],
        function()
            return ns.charDb.chatScroll.modifiers
        end,
        function(value)
            ns.charDb.chatScroll.modifiers = value
        end)

    panel:AddSlider(L["OPTIONS_SCROLL_BOTTOM_DELAY"], L["OPTIONS_SCROLL_BOTTOM_DELAY_TOOLTIP"],
        0, ChatScroll.MAX_BOTTOM_DELAY, ChatScroll.BOTTOM_DELAY_STEP, FormatBottomDelay,
        function()
            return ns.charDb.chatScroll.bottomDelay
        end,
        function(value)
            ChatScroll.SetBottomDelay(Round(value))
        end)
end

-- A subcategory with a title and an editor that fills the rest of the page. Canvas pages show own
-- frames only, so they do not share controls with Blizzard's settings.
local function RegisterEditorPage(name, createEditor)
    local frame = CreateFrame("Frame")

    local title = frame:CreateFontString(nil, "ARTWORK", "GameFontHighlightHuge")
    title:SetPoint("TOPLEFT", 10, -15)
    title:SetText(name)

    local editor = createEditor(frame)
    editor:SetPoint("TOPLEFT", 10, -50)
    editor:SetPoint("BOTTOMRIGHT", -10, 10)

    Settings.RegisterCanvasLayoutSubcategory(category, frame, name)
end

function Options:OnInitialize()
    panel = ns.OptionsPanel.Create(ns.name)
    AddGeneralSettings()
    category = panel:Register()
    -- Chat alerts: a table of the chat types and their alerts.
    RegisterEditorPage(L["OPTIONS_ALERTS"], ns.ChatAlertsEditor.Create)
    RegisterEditorPage(L["OPTIONS_CHANNEL_NAMES"], ns.ChannelNamesEditor.Create)
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
