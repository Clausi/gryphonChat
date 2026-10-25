local _, ns = ...
local L = ns.L

-- Dialogs that show text to copy with Ctrl+C: a small one for a single line (e.g. a link) and a
-- large one for many lines (e.g. a whole chat window). Both are read-only and close with Escape.
local CopyFrame = {}
ns.CopyFrame = CopyFrame

local BACKDROP = {
    bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
    edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
    tile = true,
    tileSize = 32,
    edgeSize = 32,
    insets = { left = 11, right = 12, top = 12, bottom = 11 },
}

-- Time after Ctrl+C before the line dialog closes, so the copy goes through first.
local CLOSE_AFTER_COPY_DELAY = 0.1

local lineDialog, textDialog

local function CreateDialog(width, height)
    local dialog = CreateFrame("Frame", nil, UIParent, "BackdropTemplate")
    dialog:SetBackdrop(BACKDROP)
    dialog:SetSize(width, height)
    dialog:SetPoint("CENTER")
    dialog:SetFrameStrata("DIALOG")
    dialog:SetToplevel(true)
    dialog:SetClampedToScreen(true)
    dialog:EnableMouse(true)
    dialog:SetMovable(true)
    dialog:RegisterForDrag("LeftButton")
    dialog:SetScript("OnDragStart", dialog.StartMoving)
    dialog:SetScript("OnDragStop", dialog.StopMovingOrSizing)
    dialog:Hide()

    dialog.title = dialog:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    dialog.title:SetPoint("TOP", 0, -18)

    dialog.hint = dialog:CreateFontString(nil, "ARTWORK", "GameFontDisableSmall")
    dialog.hint:SetPoint("BOTTOM", 0, 18)

    -- UIPanelCloseButton closes with HideUIPanel(), which is blocked in combat for addon frames
    -- ("Interface action failed because of an AddOn"). The dialog is no UI panel, so it just hides.
    local closeButton = CreateFrame("Button", nil, dialog, "UIPanelCloseButtonNoScripts")
    closeButton:SetPoint("TOPRIGHT", -6, -6)
    closeButton:SetScript("OnClick", function()
        dialog:Hide()
    end)

    return dialog
end

-- Keeps the edit box read-only (typing restores the text) and closes the dialog on Escape.
local function SetupEditBox(editBox, dialog)
    editBox:SetAutoFocus(false)
    editBox:SetScript("OnTextChanged", function(self, userInput)
        if userInput then
            self:SetText(self.copyText)
            self:HighlightText()
        end
    end)
    editBox:SetScript("OnEscapePressed", function()
        dialog:Hide()
    end)
end

local function GetLineDialog()
    if lineDialog then
        return lineDialog
    end
    lineDialog = CreateDialog(460, 110)
    lineDialog.hint:SetText(L["COPY_HINT_LINE"])

    local editBox = CreateFrame("EditBox", nil, lineDialog, "InputBoxTemplate")
    editBox:SetSize(400, 20)
    editBox:SetPoint("CENTER", 0, -2)
    SetupEditBox(editBox, lineDialog)
    -- Closes after copying, the link is all the dialog is for.
    editBox:SetScript("OnKeyDown", function(_, key)
        if key == "C" and IsControlKeyDown() then
            C_Timer.After(CLOSE_AFTER_COPY_DELAY, function()
                lineDialog:Hide()
            end)
        end
    end)
    lineDialog.editBox = editBox

    return lineDialog
end

local function GetTextDialog()
    if textDialog then
        return textDialog
    end
    textDialog = CreateDialog(640, 440)
    textDialog.hint:SetText(L["COPY_HINT_TEXT"])

    local scrollFrame = CreateFrame("ScrollFrame", nil, textDialog, "ScrollFrameTemplate")
    scrollFrame:SetPoint("TOPLEFT", 22, -42)
    scrollFrame:SetPoint("BOTTOMRIGHT", -42, 40)

    local editBox = CreateFrame("EditBox", nil, scrollFrame)
    editBox:SetMultiLine(true)
    editBox:SetFontObject("ChatFontNormal")
    editBox:SetWidth(640 - 22 - 42)
    SetupEditBox(editBox, textDialog)
    scrollFrame:SetScrollChild(editBox)

    -- Clicks below the last line focus the edit box as well.
    scrollFrame:SetScript("OnMouseDown", function()
        editBox:SetFocus()
    end)

    textDialog.scrollFrame = scrollFrame
    textDialog.editBox = editBox

    return textDialog
end

local function ShowDialog(dialog, title, text)
    dialog.title:SetText(title)
    dialog.editBox.copyText = text
    dialog.editBox:SetText(text)
    dialog:Show()
    dialog:Raise()
    dialog.editBox:SetFocus()
    dialog.editBox:HighlightText()
end

-- Shows a single line (e.g. a link) to copy.
function CopyFrame.ShowLine(title, text)
    ShowDialog(GetLineDialog(), title, text)
end

-- Shows a multi-line text to copy, scrolled to the end (the newest chat lines).
function CopyFrame.ShowText(title, text)
    local dialog = GetTextDialog()
    ShowDialog(dialog, title, text)
    -- The scroll range is only known after the edit box laid out the new text.
    C_Timer.After(0, function()
        dialog.scrollFrame:SetVerticalScroll(dialog.scrollFrame:GetVerticalScrollRange())
    end)
end
