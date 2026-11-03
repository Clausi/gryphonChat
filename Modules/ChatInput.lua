local _, ns = ...
local ChatInput = ns:RegisterModule("ChatInput")

-- Input line of the chat windows: the up and down arrow keys go through the lines entered before,
-- without Alt, and the history is kept across logouts and reloads.
-- Blizzard's input lines keep a history of their own, but leave the arrow keys without Alt to the
-- key bindings (ignoreArrows in ChatFrameEditBox.xml). With the Alt mode off, the arrow keys reach
-- OnArrowPressed; the own history is shared by all input lines and goes in there. The entered line
-- is set as text: OnTextChanged parses its slash command (e.g. "/g") like a typed one.

-- Lines kept (historyLines in ChatFrameEditBox.xml).
local HISTORY_LINES = 32

-- Input line -> position in the history while going through it, nil before the first arrow key.
local positions = {}

-- Input lines already hooked.
local hooked = {}

local function GetHistory()
    return ns.charDb.chatInput.history
end

-- Blizzard adds every sent line (with its slash command) through AddHistoryLine.
local function AddLine(_, text)
    if type(text) ~= "string" or (issecretvalue and issecretvalue(text)) or text == "" then
        return
    end
    local history = GetHistory()
    if history[#history] ~= text then
        history[#history + 1] = text
    end
    while #history > HISTORY_LINES do
        table.remove(history, 1)
    end
    wipe(positions)
end

local function OnArrowPressed(editBox, key)
    if not ns.charDb.chatInput.arrowKeys or (key ~= "UP" and key ~= "DOWN") then
        return
    end
    -- The arrow keys choose a name there.
    if ns.Compat.IsAutoCompleteShownFor(editBox) then
        return
    end
    local history = GetHistory()
    local position = positions[editBox]
    if key == "UP" then
        if #history == 0 then
            return
        end
        position = position and math.max(position - 1, 1) or #history
    else
        if not position then
            return
        end
        position = position + 1
        -- Below the newest line comes an empty input line.
        if position > #history then
            positions[editBox] = nil
            editBox:SetText("")
            return
        end
    end
    positions[editBox] = position
    editBox:SetText(history[position])
end

local function OnFocusGained(editBox)
    positions[editBox] = nil
end

local function ApplyArrowKeys(chatFrame)
    local editBox = ns.Compat.GetChatEditBox(chatFrame)
    if editBox then
        editBox:SetAltArrowKeyMode(not ns.charDb.chatInput.arrowKeys)
    end
end

local function HookEditBox(chatFrame)
    ApplyArrowKeys(chatFrame)
    local editBox = ns.Compat.GetChatEditBox(chatFrame)
    if editBox and not hooked[editBox] then
        hooksecurefunc(editBox, "AddHistoryLine", AddLine)
        editBox:HookScript("OnArrowPressed", OnArrowPressed)
        editBox:HookScript("OnEditFocusGained", OnFocusGained)
        hooked[editBox] = true
    end
end

function ChatInput.SetArrowKeys(enabled)
    ns.charDb.chatInput.arrowKeys = enabled
    ns.Compat.ForEachChatFrame(ApplyArrowKeys)
end

-- Off: the history only lasts for the session and is deleted on logout.
function ChatInput.SetKeepHistory(enabled)
    ns.charDb.chatInput.keepHistory = enabled
end

function ChatInput:OnEnable()
    -- Left over if the game ended without a logout.
    if not ns.charDb.chatInput.keepHistory then
        wipe(GetHistory())
    end
    ns:RegisterEvent("PLAYER_LOGOUT", function()
        if not ns.charDb.chatInput.keepHistory then
            wipe(GetHistory())
        end
    end)
    ns.Compat.HookChatFrames(HookEditBox)
end
