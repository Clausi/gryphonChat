local _, ns = ...
local ChatScroll = ns:RegisterModule("ChatScroll")

-- Mouse wheel in the chat windows: with Shift to the first or last line, with Ctrl a page at a time.
-- Optionally the chat scrolls back to the last line some time after the last wheel scroll.

ChatScroll.MAX_BOTTOM_DELAY = 300
ChatScroll.BOTTOM_DELAY_STEP = 5

-- Chat frame -> timer that scrolls it back to the last line.
local bottomTimers = {}

local function CancelBottomTimer(chatFrame)
    if bottomTimers[chatFrame] then
        bottomTimers[chatFrame]:Cancel()
        bottomTimers[chatFrame] = nil
    end
end

local function StartBottomTimer(chatFrame)
    CancelBottomTimer(chatFrame)
    local delay = ns.charDb.chatScroll.bottomDelay
    if delay <= 0 or chatFrame:GetScrollOffset() == 0 then
        return
    end
    bottomTimers[chatFrame] = C_Timer.NewTimer(delay, function()
        bottomTimers[chatFrame] = nil
        chatFrame:ScrollToBottom()
    end)
end

-- Blizzard's handler has already scrolled by scrolled lines (up is positive).
local function OnMouseWheel(chatFrame, delta, scrolled)
    if ns.charDb.chatScroll.modifiers then
        if IsShiftKeyDown() then
            if delta > 0 then
                chatFrame:ScrollToTop()
            else
                chatFrame:ScrollToBottom()
            end
        elseif IsControlKeyDown() then
            local page = chatFrame:GetPagingScrollAmount()
            chatFrame:ScrollByAmount((delta > 0 and page or -page) - scrolled)
        end
    end
    StartBottomTimer(chatFrame)
end

-- Seconds after the last wheel scroll until the chat scrolls back to the last line, 0 for never.
function ChatScroll.SetBottomDelay(seconds)
    ns.charDb.chatScroll.bottomDelay = seconds
    if seconds == 0 then
        for chatFrame in pairs(bottomTimers) do
            CancelBottomTimer(chatFrame)
        end
    end
end

function ChatScroll:OnEnable()
    ns.Compat.HookChatMouseWheel(OnMouseWheel)
end
