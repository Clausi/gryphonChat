local _, ns = ...
local L = ns.L
local ChatHistory = ns:RegisterModule("ChatHistory")

-- Number of lines every chat window keeps (Blizzard: 128). This is also what "Copy chat" can show.
ChatHistory.MIN_LINES = 50
ChatHistory.MAX_LINES = 5000

local function ApplyMaxLines(chatFrame)
    chatFrame:SetMaxLines(ns.charDb.chatLines)
end

function ChatHistory.IsValidLines(lines)
    return lines == floor(lines) and lines >= ChatHistory.MIN_LINES and lines <= ChatHistory.MAX_LINES
end

-- Sets the number of lines and applies it to every chat window. Check it with IsValidLines first.
function ChatHistory.SetLines(lines)
    ns.charDb.chatLines = lines
    ns.Compat.ForEachChatFrame(ApplyMaxLines)
end

function ChatHistory:OnEnable()
    ns.Compat.HookChatFrames(ApplyMaxLines)
end

-- "/gryphonchat lines <n>" sets the number of lines, without argument shows it.
ns:RegisterCommand("lines", function(args)
    if args ~= "" then
        local lines = tonumber(args)
        if not lines or not ChatHistory.IsValidLines(lines) then
            ns:Print(L["LINES_INVALID"], ChatHistory.MIN_LINES, ChatHistory.MAX_LINES)
            return
        end
        ChatHistory.SetLines(lines)
        ns:Print(L["LINES_SET"], lines)
        return
    end
    ns:Print(L["LINES_INFO"], ns.charDb.chatLines)
end, { L["HELP_LINES"] })
