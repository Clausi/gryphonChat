local _, ns = ...
local LinkTooltips = ns:RegisterModule("LinkTooltips")

-- Shows the tooltip of item, spell, quest, achievement and similar links in chat while the mouse is
-- over them, without a click.

-- Link types GameTooltip:SetHyperlink shows. Players, channels, battle pets and addon links are left
-- out: they have no such tooltip or their own one.
local LINK_TYPES = {
    item = true,
    spell = true,
    enchant = true,
    quest = true,
    talent = true,
    glyph = true,
    achievement = true,
    currency = true,
    instancelock = true,
    keystone = true,
    azessence = true,
    conduit = true,
    mawpower = true,
    transmogillusion = true,
}

-- Chat window that shows the tooltip, to hide only the own tooltip.
local tooltipOwner

local function OnLinkEnter(chatFrame, link)
    if not ns.charDb.linkTooltips then
        return
    end
    if type(link) ~= "string" or (issecretvalue and issecretvalue(link)) then
        return
    end
    if not LINK_TYPES[link:match("^(%a+):")] then
        return
    end
    GameTooltip:SetOwner(chatFrame, "ANCHOR_CURSOR")
    GameTooltip:SetHyperlink(link)
    GameTooltip:Show()
    tooltipOwner = chatFrame
end

local function OnLinkLeave(chatFrame)
    if tooltipOwner == chatFrame and GameTooltip:GetOwner() == chatFrame then
        GameTooltip:Hide()
    end
    tooltipOwner = nil
end

function LinkTooltips:OnEnable()
    ns.Compat.RegisterChatHyperlinkHover(self, OnLinkEnter, OnLinkLeave)
end
