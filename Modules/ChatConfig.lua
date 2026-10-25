local _, ns = ...
local L = ns.L
local ChatConfig = ns:RegisterModule("ChatConfig")

-- Own category in the chat settings (right click on a chat tab > Settings) with the channel names
-- editor, next to Blizzard's own channel settings.

function ChatConfig:OnEnable()
    local panel = CreateFrame("Frame")

    local title = panel:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", 16, -14)
    title:SetText(L["OPTIONS_CHANNEL_NAMES"])

    local editor = ns.ChannelNamesEditor.Create(panel)
    editor:SetPoint("TOPLEFT", 16, -40)
    editor:SetPoint("BOTTOMRIGHT", -12, 10)

    if not ns.Compat.AddChatConfigCategory(ns.name, panel) then
        ns:Debug("Chat settings not found, no GryphonChat category there.")
    end
end
