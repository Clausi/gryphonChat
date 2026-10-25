local _, ns = ...
local L = ns.L

-- Editor for the short channel names (Modules/ChannelNames.lua): a checkbox to turn them on and one
-- row per channel with an edit box for its short name. The options page (Modules/Options.lua) and
-- the chat settings (Modules/ChatConfig.lua) each create one.
local ChannelNamesEditor = {}
ns.ChannelNamesEditor = ChannelNamesEditor

local ROW_HEIGHT = 26
local NAME_WIDTH = 220
local EDIT_WIDTH = 110
local RESET_WIDTH = 110
-- Room for the scroll bar of ScrollFrameTemplate on the right.
local SCROLL_BAR_WIDTH = 30

local editors = {}

-- Channels to list: the joined ones with their number, then the ones with an own short name that
-- are not joined right now.
local function GetEntries()
    local entries, listed = {}, {}
    for _, channel in ipairs(ns.Compat.GetJoinedChannels()) do
        entries[#entries + 1] = { name = channel.name, label = format("%d. %s", channel.number, channel.name) }
        listed[channel.name:lower()] = true
    end
    for _, name in ipairs(ns.modules.ChannelNames.GetCustomChannels()) do
        if not listed[name:lower()] then
            entries[#entries + 1] = { name = name, label = name }
        end
    end
    return entries
end

local function UpdateRow(row)
    local ChannelNames = ns.modules.ChannelNames
    row.label:SetText(row.entry.label)
    -- A focused edit box keeps what the user is typing.
    if not row.editBox:HasFocus() then
        row.editBox:SetText(ChannelNames.GetShortName(row.entry.name) or "")
    end
    row.resetButton:SetEnabled(ChannelNames.GetCustomShortName(row.entry.name) ~= nil)
end

-- Saves the short name in the edit box. Empty or the default short name removes the own short name.
-- Rows are only updated, not rebuilt, so a removed channel keeps its row until the editor is shown
-- again and the focus cannot jump to another channel.
local function Commit(editor, row)
    local ChannelNames = ns.modules.ChannelNames
    local name = row.entry.name
    local shortName = strtrim(row.editBox:GetText())
    editor.errorText:SetText("")

    if shortName ~= (ChannelNames.GetShortName(name) or "") then
        if shortName == "" or shortName == ChannelNames.GetDefaultShortName(name) then
            ChannelNames.ResetCustomShortName(name)
        elseif ChannelNames.IsValidShortName(shortName) then
            ChannelNames.SetCustomShortName(name, shortName)
        else
            editor.errorText:SetFormattedText(L["CHANNELS_INVALID"], ChannelNames.MAX_SHORT_NAME_LENGTH)
        end
    end
    row.editBox:SetText(ChannelNames.GetShortName(name) or "")
    UpdateRow(row)
end

local function CreateRow(editor, index)
    local row = CreateFrame("Frame", nil, editor.content)
    row:SetHeight(ROW_HEIGHT)
    row:SetPoint("TOPLEFT", 0, -(index - 1) * ROW_HEIGHT)
    row:SetPoint("RIGHT")

    row.label = row:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    row.label:SetPoint("LEFT", 4, 0)
    row.label:SetWidth(NAME_WIDTH - 8)
    row.label:SetJustifyH("LEFT")
    row.label:SetWordWrap(false)

    -- InputBoxTemplate draws its left border outside the box.
    local editBox = CreateFrame("EditBox", nil, row, "InputBoxTemplate")
    editBox:SetSize(EDIT_WIDTH, 20)
    editBox:SetPoint("LEFT", NAME_WIDTH + 6, 0)
    editBox:SetAutoFocus(false)
    editBox:SetMaxLetters(ns.modules.ChannelNames.MAX_SHORT_NAME_LENGTH)
    editBox:SetScript("OnEnterPressed", editBox.ClearFocus)
    editBox:SetScript("OnEscapePressed", function(self)
        self:SetText(ns.modules.ChannelNames.GetShortName(row.entry.name) or "")
        self:ClearFocus()
    end)
    editBox:SetScript("OnEditFocusLost", function()
        Commit(editor, row)
    end)
    row.editBox = editBox

    local resetButton = CreateFrame("Button", nil, row, "UIPanelButtonTemplate")
    resetButton:SetSize(RESET_WIDTH, 22)
    resetButton:SetPoint("LEFT", editBox, "RIGHT", 12, 0)
    resetButton:SetText(L["CHANNELS_EDITOR_RESET"])
    resetButton:SetScript("OnClick", function()
        -- Saves what was typed first, then removes it.
        editBox:ClearFocus()
        ns.modules.ChannelNames.ResetCustomShortName(row.entry.name)
        editor.errorText:SetText("")
        UpdateRow(row)
    end)
    row.resetButton = resetButton

    editor.rows[index] = row
    return row
end

local function Refresh(editor)
    editor.checkbox:SetChecked(ns.modules.ChannelNames.IsEnabled())
    editor.errorText:SetText("")

    local entries = GetEntries()
    for index, entry in ipairs(entries) do
        local row = editor.rows[index] or CreateRow(editor, index)
        row.entry = entry
        row:Show()
        UpdateRow(row)
    end
    for index = #entries + 1, #editor.rows do
        editor.rows[index]:Hide()
    end
    editor.content:SetHeight(math.max(#entries, 1) * ROW_HEIGHT)
    editor.emptyText:SetShown(#entries == 0)
end

-- Creates an editor in parent. Anchor it with SetPoint or SetAllPoints; it fills the space it gets
-- and refreshes whenever it is shown.
function ChannelNamesEditor.Create(parent)
    local editor = CreateFrame("Frame", nil, parent)
    editor.rows = {}

    local checkbox = CreateFrame("CheckButton", nil, editor, "UICheckButtonTemplate")
    checkbox:SetPoint("TOPLEFT", -4, 0)
    checkbox.Text:SetFontObject("GameFontHighlight")
    checkbox.Text:SetText(L["CHANNELS_EDITOR_ENABLE"])
    checkbox:SetScript("OnClick", function(self)
        ns.modules.ChannelNames.SetEnabled(self:GetChecked() and true or false)
    end)
    editor.checkbox = checkbox

    local description = editor:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    description:SetPoint("TOPLEFT", checkbox, "BOTTOMLEFT", 4, -4)
    description:SetPoint("RIGHT")
    description:SetJustifyH("LEFT")
    description:SetText(L["CHANNELS_EDITOR_DESCRIPTION"])

    local nameHeader = editor:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    nameHeader:SetPoint("TOPLEFT", description, "BOTTOMLEFT", 4, -16)
    nameHeader:SetText(L["CHANNELS_EDITOR_CHANNEL"])
    local shortNameHeader = editor:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    shortNameHeader:SetPoint("LEFT", nameHeader, "LEFT", NAME_WIDTH, 0)
    shortNameHeader:SetText(L["CHANNELS_EDITOR_SHORT_NAME"])

    editor.errorText = editor:CreateFontString(nil, "ARTWORK", "GameFontRedSmall")
    editor.errorText:SetPoint("BOTTOMLEFT", 0, 0)
    editor.errorText:SetPoint("RIGHT")
    editor.errorText:SetJustifyH("LEFT")

    local scrollFrame = CreateFrame("ScrollFrame", nil, editor, "ScrollFrameTemplate")
    scrollFrame:SetPoint("TOPLEFT", nameHeader, "BOTTOMLEFT", -4, -6)
    scrollFrame:SetPoint("BOTTOMRIGHT", -SCROLL_BAR_WIDTH, 20)
    local content = CreateFrame("Frame", nil, scrollFrame)
    content:SetSize(1, ROW_HEIGHT)
    scrollFrame:SetScrollChild(content)
    scrollFrame:SetScript("OnSizeChanged", function(_, width)
        content:SetWidth(width)
    end)
    editor.content = content

    editor.emptyText = content:CreateFontString(nil, "ARTWORK", "GameFontDisable")
    editor.emptyText:SetPoint("LEFT", 4, 0)
    editor.emptyText:SetText(L["CHANNELS_NONE"])

    editor:SetScript("OnShow", Refresh)
    editors[#editors + 1] = editor
    return editor
end

local function IsEditing(editor)
    for _, row in ipairs(editor.rows) do
        if row.editBox:HasFocus() then
            return true
        end
    end
    return false
end

-- Channels joined or left while an editor is shown. Not while the user types: the rows could move
-- and the edit box would save to another channel.
ns:RegisterEvent("CHANNEL_UI_UPDATE", function()
    for _, editor in ipairs(editors) do
        if editor:IsVisible() and not IsEditing(editor) then
            Refresh(editor)
        end
    end
end)
