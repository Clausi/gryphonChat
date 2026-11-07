local _, ns = ...
local L = ns.L
local WhisperList = ns:RegisterModule("WhisperList")

-- Overview of the open whisper windows, for when Blizzard's dock is full ("New Tab" and "Both" of the
-- whisper mode): newest first, with the unread messages per window, to open and close them. Blizzard's
-- overflow list shows neither. The button sits in the button bar of every chat window and is shown
-- while a whisper window is open.
--
-- Whisper names can be secret values on Mainline, so they are only passed on to font strings: they
-- are not compared, sorted or tested. Windows are told apart by their frame, and new messages are
-- seen through Blizzard's tab alert instead of the whisper events and their sender.
--
-- Opening and closing go through secure buttons that click Blizzard's tabs (see
-- Compat.SetChatTabClicks). Calling FCF_SelectDockFrame or FCF_PopInWindow from here would taint the
-- dock and the window state: Blizzard then handles later whispers in tainted code, and its
-- FCFManager_GetToken fails on a secret name ("attempt to perform string conversion on a secret string
-- value"). Secure buttons cannot be changed in combat, so the list closes when combat starts and
-- cannot be opened until it ends. For the same reason windows can only be closed by a click in the
-- list, not by a slash command.
--
-- A closed whisper window keeps no text. "New Tab" shows the messages nowhere else, so they are gone
-- like when Blizzard's own tab menu closes the window.

-- Classic: above the copy button (layout index -10). Mainline: stacked on top of it, see
-- Compat.CreateChatFrameButton.
local BUTTON_LAYOUT_INDEX = -11
local BUTTON_ICON = "Interface\\ChatFrame\\UI-ChatWhisperIcon"
local BUTTON_HIGHLIGHT = "Interface\\Buttons\\UI-Common-MouseHilight"

local LIST_BACKDROP = {
    -- A plain white texture: the tooltip background is partly transparent, chat text would show
    -- through. SetBackdropColor sets the actual color.
    bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    tile = true,
    tileSize = 16,
    edgeSize = 16,
    insets = { left = 4, right = 4, top = 4, bottom = 4 },
}
local LIST_WIDTH = 260
local LIST_PADDING = 10
local LIST_HEADER_HEIGHT = 32
local LIST_FOOTER_HEIGHT = 38
local ROW_HEIGHT = 20
-- Windows beyond this are not listed until others are closed; the title shows the full count.
local MAX_ROWS = 20

local UNREAD_COLOR = { 1, 0.82, 0 }
local READ_COLOR = { 1, 1, 1 }

-- Whisper window -> { unread = messages not seen yet, lastActivity = GetTime() of the last change }.
local states = {}
-- Chat frame -> its list button.
local buttons = {}
-- Whisper windows with the OnShow hook.
local hooked = {}

local list
local closeReadButton, closeAllButton
local rows = {}
local CreateRow

local function IsEnabled()
    return ns.charDb.whisperList
end

-- The open whisper windows, newest first. Frame IDs keep the order stable for equal times.
local function GetWindows()
    local windows = {}
    for chatFrame in pairs(states) do
        windows[#windows + 1] = chatFrame
    end
    table.sort(windows, function(a, b)
        local timeA, timeB = states[a].lastActivity, states[b].lastActivity
        if timeA ~= timeB then
            return timeA > timeB
        end
        return a:GetID() > b:GetID()
    end)
    return windows
end

local function GetTotalUnread()
    local total = 0
    for _, state in pairs(states) do
        total = total + state.unread
    end
    return total
end

-- Windows without unread messages, except the conversation on screen.
local function GetReadWindows()
    local windows = {}
    for chatFrame, state in pairs(states) do
        if state.unread == 0 and not chatFrame:IsShown() then
            windows[#windows + 1] = chatFrame
        end
    end
    return windows
end

-- Only out of combat: it changes secure buttons. The list closes when combat starts.
local function UpdateList(windows)
    list.title:SetFormattedText(L["WHISPER_LIST_TITLE"], #windows)

    local shownRows = min(#windows, MAX_ROWS)
    for i = 1, shownRows do
        local row = rows[i] or CreateRow(i)
        local chatFrame = windows[i]
        local unread = states[chatFrame].unread
        local color = unread > 0 and UNREAD_COLOR or READ_COLOR
        ns.Compat.SetChatTabClicks(row, { chatFrame }, "LeftButton")
        ns.Compat.SetChatTabClicks(row.closeButton, { chatFrame }, "MiddleButton")
        row.name:SetText(ns.Compat.GetWhisperWindowName(chatFrame))
        row.name:SetTextColor(color[1], color[2], color[3])
        row.unread:SetText(unread > 0 and unread or "")
        row:Show()
    end
    for i = shownRows + 1, #rows do
        rows[i]:Hide()
    end

    local readWindows = GetReadWindows()
    ns.Compat.SetChatTabClicks(closeReadButton, readWindows, "MiddleButton")
    closeReadButton:SetEnabled(#readWindows > 0)
    ns.Compat.SetChatTabClicks(closeAllButton, windows, "MiddleButton")

    list:SetHeight(LIST_HEADER_HEIGHT + shownRows * ROW_HEIGHT + LIST_FOOTER_HEIGHT)
end

-- Brings the buttons and an open list up to date.
local function Refresh()
    local windows = GetWindows()
    local total = GetTotalUnread()
    local shown = IsEnabled() and #windows > 0

    for _, button in pairs(buttons) do
        ns.Compat.SetChatFrameButtonShown(button, shown)
        button.unread:SetText(total > 0 and total or "")
    end

    if list and list:IsShown() then
        if shown then
            UpdateList(windows)
        else
            list:Hide()
        end
    end
end

local function CreateFooterButton(text, tooltip)
    local button = CreateFrame("Button", nil, list, "UIPanelButtonTemplate, SecureActionButtonTemplate")
    ns.Compat.InitChatTabClickButton(button)
    button:SetSize((LIST_WIDTH - 2 * LIST_PADDING - 4) / 2, 22)
    button:SetNormalFontObject("GameFontNormalSmall")
    button:SetHighlightFontObject("GameFontHighlightSmall")
    button:SetText(text)
    button:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_TOP")
        GameTooltip:SetText(tooltip, nil, nil, nil, nil, true)
        GameTooltip:Show()
    end)
    button:SetScript("OnLeave", GameTooltip_Hide)
    return button
end

function CreateRow(index)
    local row = CreateFrame("Button", nil, list, "SecureActionButtonTemplate")
    ns.Compat.InitChatTabClickButton(row)
    row:SetHeight(ROW_HEIGHT)
    row:SetPoint("TOPLEFT", LIST_PADDING, -LIST_HEADER_HEIGHT - (index - 1) * ROW_HEIGHT)
    row:SetPoint("TOPRIGHT", -LIST_PADDING, -LIST_HEADER_HEIGHT - (index - 1) * ROW_HEIGHT)
    row:SetHighlightTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight", "ADD")

    local closeButton = CreateFrame("Button", nil, row, "UIPanelCloseButtonNoScripts, SecureActionButtonTemplate")
    ns.Compat.InitChatTabClickButton(closeButton)
    closeButton:SetSize(20, 20)
    closeButton:SetPoint("RIGHT")
    row.closeButton = closeButton

    row.unread = row:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
    row.unread:SetPoint("RIGHT", closeButton, "LEFT", -4, 0)
    row.unread:SetWidth(24)
    row.unread:SetJustifyH("RIGHT")

    -- A fixed width: the name can be secret, so the addon must not measure it.
    row.name = row:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    row.name:SetPoint("LEFT", 2, 0)
    row.name:SetPoint("RIGHT", row.unread, "LEFT", -4, 0)
    row.name:SetJustifyH("LEFT")
    row.name:SetWordWrap(false)

    row:SetScript("PostClick", function()
        list:Hide()
    end)

    rows[index] = row
    return row
end

local function CreateList()
    list = CreateFrame("Frame", nil, UIParent, "BackdropTemplate")
    list:SetBackdrop(LIST_BACKDROP)
    list:SetBackdropColor(0, 0, 0, 0.9)
    list:SetWidth(LIST_WIDTH)
    list:SetFrameStrata("DIALOG")
    list:SetToplevel(true)
    list:SetClampedToScreen(true)
    list:EnableMouse(true)
    list:Hide()

    list.title = list:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    list.title:SetPoint("TOPLEFT", LIST_PADDING + 2, -LIST_PADDING)

    -- UIPanelCloseButton goes through HideUIPanel, see CopyFrame.lua.
    local closeButton = CreateFrame("Button", nil, list, "UIPanelCloseButtonNoScripts")
    closeButton:SetPoint("TOPRIGHT", -2, -2)
    closeButton:SetScript("OnClick", function()
        list:Hide()
    end)

    closeReadButton = CreateFooterButton(L["WHISPER_LIST_CLOSE_READ"], L["WHISPER_LIST_CLOSE_READ_TOOLTIP"])
    closeReadButton:SetPoint("BOTTOMLEFT", LIST_PADDING, LIST_PADDING)
    closeAllButton = CreateFooterButton(L["WHISPER_LIST_CLOSE_ALL"], L["WHISPER_LIST_CLOSE_ALL_TOOLTIP"])
    closeAllButton:SetPoint("BOTTOMRIGHT", -LIST_PADDING, LIST_PADDING)
end

local function ToggleList(button)
    if InCombatLockdown() then
        ns:Print(L["WHISPER_LIST_IN_COMBAT"])
        return
    end
    if not list then
        CreateList()
    end
    if list:IsShown() then
        list:Hide()
        return
    end
    UpdateList(GetWindows())
    -- The rows are protected, so the game refuses to anchor the list to the button ("Cannot anchor
    -- protected frames to regions"). The list goes to the button's position on UIParent instead.
    local scale = button:GetEffectiveScale() / UIParent:GetEffectiveScale()
    list:ClearAllPoints()
    list:SetPoint("BOTTOMLEFT", UIParent, "BOTTOMLEFT", button:GetRight() * scale + 4, button:GetTop() * scale)
    list:Show()
end

local function AddButton(chatFrame)
    if buttons[chatFrame] then
        return
    end

    local button = ns.Compat.CreateChatFrameButton(chatFrame, BUTTON_LAYOUT_INDEX)
    local icon = button:CreateTexture(nil, "ARTWORK")
    icon:SetTexture(BUTTON_ICON)
    icon:SetSize(18, 18)
    icon:SetPoint("CENTER")
    button:SetHighlightTexture(BUTTON_HIGHLIGHT, "ADD")

    button.unread = button:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    button.unread:SetPoint("BOTTOMRIGHT", -2, 2)

    button:SetScript("OnClick", ToggleList)
    button:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetText(L["WHISPER_LIST_TOOLTIP"])
        GameTooltip:Show()
    end)
    button:SetScript("OnLeave", GameTooltip_Hide)
    button:Hide()

    buttons[chatFrame] = button
end

local function OnWindowShown(chatFrame)
    local state = states[chatFrame]
    if state then
        state.unread = 0
        state.lastActivity = GetTime()
        Refresh()
    end
end

-- Called for every chat window, and again whenever a whisper window opens. New windows have no state
-- yet; closed ones lost theirs in OnWindowClosed, also when Blizzard reuses the frame.
local function OnChatFrame(chatFrame)
    AddButton(chatFrame)
    if not ns.Compat.IsWhisperWindow(chatFrame) or states[chatFrame] then
        return
    end

    if not hooked[chatFrame] then
        chatFrame:HookScript("OnShow", OnWindowShown)
        hooked[chatFrame] = true
    end
    states[chatFrame] = { unread = 0, lastActivity = GetTime() }
    Refresh()
end

-- FCF_StartAlertFlash runs per message for a window that is not on screen, also for later messages.
local function OnNewMessage(chatFrame)
    local state = states[chatFrame]
    if state then
        state.unread = state.unread + 1
        state.lastActivity = GetTime()
        Refresh()
    end
end

-- Blizzard stops the alert when the player answers from another window ("Both" whisper mode).
local function OnAlertStopped(chatFrame)
    local state = states[chatFrame]
    if state and state.unread > 0 then
        state.unread = 0
        Refresh()
    end
end

local function OnWindowClosed()
    for chatFrame in pairs(states) do
        if not ns.Compat.IsWhisperWindow(chatFrame) then
            states[chatFrame] = nil
        end
    end
    Refresh()
end

-- Turns the list button on or off, for the options.
function WhisperList.SetEnabled(enabled)
    ns.charDb.whisperList = enabled
    Refresh()
end

function WhisperList:OnEnable()
    ns.Compat.HookChatFrames(OnChatFrame)
    ns.Compat.HookChatAlerts(OnNewMessage, OnAlertStopped)
    ns.Compat.HookChatWindowClosed(OnWindowClosed)
    -- Fires before the combat lockdown starts, so the secure buttons can still be hidden.
    ns:RegisterEvent("PLAYER_REGEN_DISABLED", function()
        if list then
            list:Hide()
        end
    end)
end

-- "/gryphonchat whispers" shows how many whisper windows are open.
ns:RegisterCommand("whispers", function()
    ns:Print(L["WHISPER_LIST_INFO"], #GetWindows(), GetTotalUnread())
end, { L["HELP_WHISPERS"] })
