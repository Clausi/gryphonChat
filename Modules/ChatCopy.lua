local _, ns = ...
local L = ns.L
local ChatCopy = ns:RegisterModule("ChatCopy")

-- Button in the button bar of every chat window that opens the whole window content to copy.
-- Classic: above the Blizzard buttons, which use the layout indices -2 to 3. Mainline: at the bottom
-- (see Compat.CreateChatFrameButton).
local BUTTON_LAYOUT_INDEX = -10
local BUTTON_ICON = "Interface\\Buttons\\UI-GuildButton-PublicNote-Up"
local BUTTON_HIGHLIGHT = "Interface\\Buttons\\UI-Common-MouseHilight"

-- Chat frame -> its copy button, so every window gets only one.
local buttons = {}

-- Text of a chat line as shown, without escape sequences: colors and textures are dropped, links
-- keep their visible text. Battle.net names (|K...|k) are encoded and cannot be shown, they become
-- "?". An escaped "||" stays a single "|".
local function ToPlainText(text)
    return (text:gsub("||", "\001")
        :gsub("|c%x%x%x%x%x%x%x%x", "")
        :gsub("|cn[^:]*:", "")
        :gsub("|r", "")
        :gsub("|H.-|h(.-)|h", "%1")
        :gsub("|T.-|t", "")
        :gsub("|A.-|a", "")
        :gsub("|K.-|k", "?")
        :gsub("|n", " ")
        :gsub("\001", "|"))
end

-- All lines of a chat window, oldest first, as plain text.
local function GetChatText(chatFrame)
    local lines = {}
    for i = 1, chatFrame:GetNumMessages() do
        local text = chatFrame:GetMessageInfo(i)
        if type(text) == "string" and not (issecretvalue and issecretvalue(text)) then
            lines[#lines + 1] = ToPlainText(text)
        end
    end
    return table.concat(lines, "\n"), #lines
end

local function ShowChat(chatFrame)
    local text, count = GetChatText(chatFrame)
    if count == 0 then
        ns:Print(L["COPY_CHAT_EMPTY"])
        return
    end
    ns.CopyFrame.ShowText(format(L["COPY_CHAT_TITLE"], ns.Compat.GetChatFrameName(chatFrame)), text)
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

    button:SetScript("OnMouseDown", function()
        icon:SetPoint("CENTER", 1, -1)
    end)
    button:SetScript("OnMouseUp", function()
        icon:SetPoint("CENTER")
    end)
    button:SetScript("OnClick", function()
        ShowChat(chatFrame)
    end)
    button:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetText(L["COPY_CHAT_TOOLTIP"])
        GameTooltip:Show()
    end)
    button:SetScript("OnLeave", GameTooltip_Hide)

    buttons[chatFrame] = button
end

function ChatCopy:OnEnable()
    ns.Compat.HookChatFrames(AddButton)
end
