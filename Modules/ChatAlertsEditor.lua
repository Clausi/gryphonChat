local _, ns = ...
local L = ns.L

-- Editor for the chat alerts (Modules/ChatAlerts.lua): a table with one row per chat type and the
-- keywords, a checkbox per alert and a sound dropdown, the sound pause, then the keyword settings with an edit box
-- for the own keywords. The options page (Modules/Options.lua) creates it.
local ChatAlertsEditor = {}
ns.ChatAlertsEditor = ChatAlertsEditor

local LABEL_WIDTH = 130
local COLUMN_WIDTH = 66
local SOUND_WIDTH = 150
local HEADER_HEIGHT = 30
local ROW_HEIGHT = 28
local KEYWORDS_WIDTH = 420
-- The sound menu scrolls beyond this height: LibSharedMedia can bring many sounds.
local MENU_HEIGHT = 400

-- Column header and tooltip per alert.
local COLUMNS = {
    tabFlash = { "ALERTS_COLUMN_TAB_FLASH", "OPTIONS_ALERTS_TAB_FLASH_TOOLTIP" },
    tabCount = { "ALERTS_COLUMN_TAB_COUNT", "OPTIONS_ALERTS_TAB_COUNT_TOOLTIP" },
    newMessagesLine = { "ALERTS_COLUMN_NEW_LINE", "OPTIONS_ALERTS_NEW_LINE_TOOLTIP" },
    markLines = { "ALERTS_COLUMN_MARK_LINES", "OPTIONS_ALERTS_MARK_LINES_TOOLTIP" },
    centerText = { "ALERTS_COLUMN_CENTER", "OPTIONS_ALERTS_CENTER_TOOLTIP" },
}

-- Extra tooltips for the row labels.
local ROW_TOOLTIPS = {
    whisper = "OPTIONS_ALERTS_WHISPER_NOTE",
    keyword = "OPTIONS_ALERTS_KEYWORD_ROW_TOOLTIP",
}

local function GetTypeConfig(chatType)
    return ns.charDb.chatAlerts.types[chatType]
end

local function SetTooltip(frame, title, text)
    frame:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetText(title)
        if text then
            GameTooltip:AddLine(text, 1, 1, 1, true)
        end
        GameTooltip:Show()
    end)
    frame:SetScript("OnLeave", GameTooltip_Hide)
end

local function CreateCheckbox(parent, text, tooltip, onClick)
    local checkbox = CreateFrame("CheckButton", nil, parent, "UICheckButtonTemplate")
    checkbox.Text:SetFontObject("GameFontHighlight")
    checkbox.Text:SetText(text)
    checkbox:SetScript("OnClick", function(self)
        onClick(self:GetChecked() and true or false)
    end)
    SetTooltip(checkbox, text, tooltip)
    return checkbox
end

local function CreateHeader(editor, anchor)
    local x = LABEL_WIDTH
    for _, alert in ipairs(ns.modules.ChatAlerts.ALERTS) do
        local column = COLUMNS[alert]
        local header = CreateFrame("Frame", nil, editor)
        header:SetSize(COLUMN_WIDTH, HEADER_HEIGHT)
        header:SetPoint("TOPLEFT", anchor, "BOTTOMLEFT", x, -12)
        local text = header:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
        text:SetAllPoints()
        text:SetJustifyV("BOTTOM")
        text:SetText(L[column[1]])
        SetTooltip(header, L[column[1]], L[column[2]])
        x = x + COLUMN_WIDTH
    end

    local soundHeader = CreateFrame("Frame", nil, editor)
    soundHeader:SetSize(SOUND_WIDTH, HEADER_HEIGHT)
    soundHeader:SetPoint("TOPLEFT", anchor, "BOTTOMLEFT", x + 8, -12)
    local text = soundHeader:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
    text:SetAllPoints()
    text:SetJustifyH("LEFT")
    text:SetJustifyV("BOTTOM")
    text:SetText(L["ALERTS_COLUMN_SOUND"])
    SetTooltip(soundHeader, L["ALERTS_COLUMN_SOUND"], L["OPTIONS_ALERTS_SOUND_TOOLTIP"])
end

local function CreateRow(editor, chatType, index, top)
    local ChatAlerts = ns.modules.ChatAlerts
    local row = CreateFrame("Frame", nil, editor)
    row:SetHeight(ROW_HEIGHT)
    row:SetPoint("TOPLEFT", top, "BOTTOMLEFT", 0, -(index - 1) * ROW_HEIGHT - 4)
    row:SetPoint("RIGHT")
    row.checkboxes = {}

    local label = CreateFrame("Frame", nil, row)
    label:SetSize(LABEL_WIDTH, ROW_HEIGHT)
    label:SetPoint("LEFT")
    local labelText = label:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    labelText:SetPoint("LEFT", 4, 0)
    labelText:SetPoint("RIGHT", -4, 0)
    labelText:SetJustifyH("LEFT")
    labelText:SetWordWrap(false)
    labelText:SetText(L["ALERTS_GROUP_" .. chatType:upper()])
    if ROW_TOOLTIPS[chatType] then
        SetTooltip(label, labelText:GetText(), L[ROW_TOOLTIPS[chatType]])
    end

    local x = LABEL_WIDTH
    for _, alert in ipairs(ChatAlerts.ALERTS) do
        if ChatAlerts.HasAlert(chatType, alert) then
            local checkbox = CreateFrame("CheckButton", nil, row, "UICheckButtonTemplate")
            checkbox:SetPoint("CENTER", row, "LEFT", x + COLUMN_WIDTH / 2, 0)
            checkbox:SetScript("OnClick", function(self)
                GetTypeConfig(chatType)[alert] = self:GetChecked() and true or false
            end)
            local column = COLUMNS[alert]
            SetTooltip(checkbox, L[column[1]], L[column[2]])
            row.checkboxes[alert] = checkbox
        end
        x = x + COLUMN_WIDTH
    end

    local function IsSound(key)
        return GetTypeConfig(chatType).sound == key
    end
    local function SetSound(key)
        GetTypeConfig(chatType).sound = key
        if key ~= "" then
            ChatAlerts.PlaySound(key)
        end
    end
    local dropdown = CreateFrame("DropdownButton", nil, row, "WowStyle1DropdownTemplate")
    dropdown:SetWidth(SOUND_WIDTH)
    dropdown:SetPoint("LEFT", x + 8, 0)
    -- Built from scratch on every open, so it lists the LibSharedMedia sounds registered by then.
    dropdown:SetupMenu(function(_, rootDescription)
        rootDescription:SetScrollMode(MENU_HEIGHT)
        rootDescription:CreateRadio(L["ALERTS_SOUND_NONE"], IsSound, SetSound, "")
        for _, key in ipairs(ChatAlerts.SOUNDS) do
            rootDescription:CreateRadio(L["ALERTS_SOUND_" .. key], IsSound, SetSound, key)
        end

        local shared = ChatAlerts.GetSharedSounds()
        -- A saved sound whose addon is no longer loaded stays visible as chosen.
        local savedName = ChatAlerts.GetSharedSoundName(GetTypeConfig(chatType).sound)
        local missing = savedName and not ChatAlerts.IsSharedSoundAvailable(savedName)
        if #shared > 0 or missing then
            rootDescription:CreateDivider()
            rootDescription:CreateTitle(L["ALERTS_SOUND_SHARED"])
        end
        if missing then
            rootDescription:CreateRadio(format(L["ALERTS_SOUND_MISSING"], savedName), IsSound, SetSound,
                ChatAlerts.GetSharedSoundKey(savedName))
        end
        for _, name in ipairs(shared) do
            rootDescription:CreateRadio(name, IsSound, SetSound, ChatAlerts.GetSharedSoundKey(name))
        end
    end)
    row.dropdown = dropdown

    row.chatType = chatType
    return row
end

local function FormatPause(seconds)
    if seconds == 0 then
        return L["ALERTS_PAUSE_NONE"]
    elseif seconds % 60 == 0 then
        return format(L["OPTIONS_MINUTES"], seconds / 60)
    end
    return format(L["OPTIONS_SECONDS"], seconds)
end

-- Label and dropdown for the sound pause, below the table.
local function CreatePauseRow(editor, anchor)
    local config = ns.charDb.chatAlerts
    local label = CreateFrame("Frame", nil, editor)
    label:SetSize(LABEL_WIDTH + 4 * COLUMN_WIDTH, ROW_HEIGHT)
    label:SetPoint("TOPLEFT", anchor, "BOTTOMLEFT", 0, -12)
    local labelText = label:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    labelText:SetPoint("LEFT", 4, 0)
    labelText:SetPoint("RIGHT", -4, 0)
    labelText:SetJustifyH("LEFT")
    labelText:SetText(L["ALERTS_EDITOR_SOUND_PAUSE"])
    SetTooltip(label, L["ALERTS_EDITOR_SOUND_PAUSE"], L["ALERTS_EDITOR_SOUND_PAUSE_TOOLTIP"])

    local function IsPause(seconds)
        return config.soundPause == seconds
    end
    local function SetPause(seconds)
        config.soundPause = seconds
    end
    local dropdown = CreateFrame("DropdownButton", nil, editor, "WowStyle1DropdownTemplate")
    dropdown:SetWidth(SOUND_WIDTH)
    dropdown:SetPoint("LEFT", label, "RIGHT", COLUMN_WIDTH + 8, 0)
    dropdown:SetupMenu(function(_, rootDescription)
        for _, seconds in ipairs(ns.modules.ChatAlerts.SOUND_PAUSES) do
            rootDescription:CreateRadio(FormatPause(seconds), IsPause, SetPause, seconds)
        end
    end)
    editor.pauseDropdown = dropdown
    return label
end

-- Shows the saved keywords. Like the channel names editor: the cursor goes to the start, so the text
-- is in view.
local function ShowKeywords(editor)
    editor.keywordBox:SetText(ns.modules.ChatAlerts.GetKeywordText())
    editor.keywordBox:SetCursorPosition(0)
end

local function Refresh(editor)
    local config = ns.charDb.chatAlerts
    for _, row in ipairs(editor.rows) do
        local typeConfig = GetTypeConfig(row.chatType)
        for alert, checkbox in pairs(row.checkboxes) do
            checkbox:SetChecked(typeConfig[alert])
        end
        row.dropdown:GenerateMenu()
    end
    editor.pauseDropdown:GenerateMenu()
    editor.keywordsCheckbox:SetChecked(config.keywords)
    editor.ownNameCheckbox:SetChecked(config.ownName)
    if not editor.keywordBox:HasFocus() then
        ShowKeywords(editor)
    end
end

local function CommitKeywords(editor)
    local ChatAlerts = ns.modules.ChatAlerts
    local invalid = ChatAlerts.SetKeywordText(editor.keywordBox:GetText())
    editor.errorText:SetText(invalid and ChatAlerts.GetInvalidKeywordText() or "")
    ShowKeywords(editor)
end

-- Creates an editor in parent. Anchor it with SetPoint or SetAllPoints; it refreshes whenever it is
-- shown.
function ChatAlertsEditor.Create(parent)
    local ChatAlerts = ns.modules.ChatAlerts
    local config = ns.charDb.chatAlerts
    local editor = CreateFrame("Frame", nil, parent)
    editor.rows = {}

    local description = editor:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    description:SetPoint("TOPLEFT")
    description:SetPoint("RIGHT")
    description:SetJustifyH("LEFT")
    description:SetText(L["ALERTS_EDITOR_DESCRIPTION"])

    CreateHeader(editor, description)
    local top = CreateFrame("Frame", nil, editor)
    top:SetSize(1, 1)
    top:SetPoint("TOPLEFT", description, "BOTTOMLEFT", 0, -12 - HEADER_HEIGHT)
    for index, chatType in ipairs(ChatAlerts.TYPES) do
        editor.rows[index] = CreateRow(editor, chatType, index, top)
    end
    local pauseRow = CreatePauseRow(editor, editor.rows[#editor.rows])

    local keywordsCheckbox = CreateCheckbox(editor, L["OPTIONS_ALERTS_KEYWORDS_ENABLE"],
        L["OPTIONS_ALERTS_KEYWORDS_TOOLTIP"], function(checked)
            config.keywords = checked
            ChatAlerts.Refresh()
        end)
    keywordsCheckbox:SetPoint("TOPLEFT", pauseRow, "BOTTOMLEFT", -4, -12)
    editor.keywordsCheckbox = keywordsCheckbox

    local ownNameCheckbox = CreateCheckbox(editor, L["OPTIONS_ALERTS_OWN_NAME"], L["OPTIONS_ALERTS_OWN_NAME_TOOLTIP"],
        function(checked)
            config.ownName = checked
            ChatAlerts.Refresh()
        end)
    ownNameCheckbox:SetPoint("TOPLEFT", keywordsCheckbox, "BOTTOMLEFT")
    editor.ownNameCheckbox = ownNameCheckbox

    local keywordLabel = editor:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    keywordLabel:SetPoint("TOPLEFT", ownNameCheckbox, "BOTTOMLEFT", 4, -10)
    keywordLabel:SetText(L["ALERTS_EDITOR_KEYWORDS"])

    -- InputBoxTemplate draws its left border outside the box.
    local keywordBox = CreateFrame("EditBox", nil, editor, "InputBoxTemplate")
    keywordBox:SetSize(KEYWORDS_WIDTH, 20)
    keywordBox:SetPoint("TOPLEFT", keywordLabel, "BOTTOMLEFT", 6, -6)
    keywordBox:SetAutoFocus(false)
    keywordBox:SetMaxLetters(255)
    keywordBox:SetScript("OnEnterPressed", keywordBox.ClearFocus)
    keywordBox:SetScript("OnEscapePressed", function(self)
        ShowKeywords(editor)
        self:ClearFocus()
    end)
    keywordBox:SetScript("OnEditFocusLost", function()
        CommitKeywords(editor)
    end)
    editor.keywordBox = keywordBox

    local keywordHint = editor:CreateFontString(nil, "ARTWORK", "GameFontDisableSmall")
    keywordHint:SetPoint("TOPLEFT", keywordBox, "BOTTOMLEFT", -6, -4)
    keywordHint:SetPoint("RIGHT")
    keywordHint:SetJustifyH("LEFT")
    keywordHint:SetText(L["ALERTS_EDITOR_KEYWORDS_HINT"])

    editor.errorText = editor:CreateFontString(nil, "ARTWORK", "GameFontRedSmall")
    editor.errorText:SetPoint("TOPLEFT", keywordHint, "BOTTOMLEFT", 0, -4)
    editor.errorText:SetPoint("RIGHT")
    editor.errorText:SetJustifyH("LEFT")

    -- The options window lays out its pages only after showing them: refresh again once the edit box
    -- has its size.
    editor:SetScript("OnShow", function()
        editor.errorText:SetText("")
        Refresh(editor)
        C_Timer.After(0, function()
            if editor:IsVisible() then
                Refresh(editor)
            end
        end)
    end)
    return editor
end
