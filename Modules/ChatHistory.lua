local _, ns = ...
local L = ns.L
local ChatHistory = ns:RegisterModule("ChatHistory")

-- Number of lines every chat window keeps (Blizzard: 128). This is also what "Copy chat" can show.
local MIN_LINES = 50
local MAX_LINES = 5000

local function ApplyMaxLines(chatFrame)
    chatFrame:SetMaxLines(ns.charDb.chatLines)
end

function ChatHistory:OnEnable()
    ns.Compat.HookChatFrames(ApplyMaxLines)
end

-- "/gryphonchat lines <n>" sets the number of lines, without argument shows it.
ns:RegisterCommand("lines", function(args)
    if args ~= "" then
        local lines = tonumber(args)
        if not lines or lines ~= floor(lines) or lines < MIN_LINES or lines > MAX_LINES then
            ns:Print(L["LINES_INVALID"], MIN_LINES, MAX_LINES)
            return
        end
        ns.charDb.chatLines = lines
        ns.Compat.ForEachChatFrame(ApplyMaxLines)
        ns:Print(L["LINES_SET"], lines)
        return
    end
    ns:Print(L["LINES_INFO"], ns.charDb.chatLines)
end, { L["HELP_LINES"] })
