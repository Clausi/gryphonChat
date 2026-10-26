local _, ns = ...

-- Differences between the supported clients (Forever, Classic Era, Anniversary, MoP Classic,
-- Retail), in one place. Detects the APIs and methods a client has instead of comparing version
-- numbers. Blizzard UI reference: the forever, classic_era, classic_anniversary, classic (MoP
-- Classic) and live branches of Gethe/wow-ui-source.
local Compat = {}
ns.Compat = Compat

-- Registers a filter for a chat message event: filter(chatFrame, event, message, ...) returns
-- true to hide the message, or false followed by the changed event arguments. All supported clients
-- have ChatFrameUtil.AddMessageEventFilter; the global ChatFrame_AddMessageEventFilter only exists as
-- a deprecation fallback there. Blizzard skips the filter when an event argument is a secret value
-- (ChatFrameFilters.lua, canaccessvalue).
function Compat.AddMessageEventFilter(event, filter)
    ChatFrameUtil.AddMessageEventFilter(event, filter)
end

-- Calls handler(link, text, button, chatFrame) when a "|Haddon:...|h" link is clicked. SetItemRef
-- passes links of type "addon" to the EventRegistry event "SetItemRef" (ItemRefHandlersShared.lua),
-- for every addon: the handler has to check that the link is its own.
function Compat.RegisterAddonLinkHandler(owner, handler)
    EventRegistry:RegisterCallback("SetItemRef", function(_, link, text, button, chatFrame)
        handler(link, text, button, chatFrame)
    end, owner)
end

-- Calls callback(chatFrame) for every chat window, including temporary whisper windows.
function Compat.ForEachChatFrame(callback)
    for _, frameName in ipairs(CHAT_FRAMES) do
        local chatFrame = _G[frameName]
        if chatFrame then
            callback(chatFrame)
        end
    end
end

-- Calls callback(chatFrame) for every chat window now and whenever a temporary whisper window is
-- opened (FCF_OpenTemporaryWindow creates or reuses one). The callback may see the same frame
-- several times.
function Compat.HookChatFrames(callback)
    Compat.ForEachChatFrame(callback)
    hooksecurefunc("FCF_OpenTemporaryWindow", function()
        Compat.ForEachChatFrame(callback)
    end)
end

-- Name of a chat window as shown on its tab ("General", "Combat Log", the whisper target, ...).
function Compat.GetChatFrameName(chatFrame)
    return chatFrame.name or chatFrame:GetName()
end

-- Creates an own button in the button bar next to a chat window (chatFrame.buttonFrame in
-- FloatingChatFrame.xml).
-- Classic: the bar is a VerticalLayoutFrame that stacks its children by layoutIndex from top to
-- bottom: ChatFrame1 uses -2 to 3, the other windows 1 to 3. Duplicate indices raise an error.
-- Mainline: the bar has no layout. Blizzard anchors the channel button (ChatFrame1) and the minimize
-- button (undocked windows) to the top and ChatFrameMenuButton to the bottom of ChatFrame1's bar.
-- The own button goes to the bottom, above the menu button; there is room for one.
function Compat.CreateChatFrameButton(chatFrame, layoutIndex)
    local buttonFrame = chatFrame.buttonFrame
    local button = CreateFrame("Button", nil, buttonFrame)
    button:SetSize(32, 32)
    if buttonFrame.MarkDirty then
        button.layoutIndex = layoutIndex
        button.align = "center"
        buttonFrame:MarkDirty()
    elseif ChatFrameMenuButton and ChatFrameMenuButton:GetParent() == buttonFrame then
        button:SetPoint("BOTTOM", ChatFrameMenuButton, "TOP")
    else
        button:SetPoint("BOTTOM")
    end
    return button
end

-- Channels the character has joined, in channel number order: { { number = 1, name = "General" },
-- ... }. GetChannelList() returns number, name (without zone) and disabled flag per channel.
function Compat.GetJoinedChannels()
    local channels = {}
    local list = { GetChannelList() }
    for i = 1, #list, 3 do
        channels[#channels + 1] = { number = list[i], name = list[i + 1] }
    end
    return channels
end

-- Adds an own category below "Other" in the chat settings (right click on a chat tab > Settings)
-- that shows panel. Blizzard shows its panels by the button ID as index into CHAT_CONFIG_CATEGORIES
-- (ChatConfigFrame_Shared.lua). That table is not touched, to keep taint out: the own button calls
-- ChatConfigCategory_OnClick with an ID that is not in it, which hides all of Blizzard's panels, and
-- a hook hides the own panel again when one of Blizzard's buttons is clicked. Returns false if the
-- chat settings are not there.
function Compat.AddChatConfigCategory(text, panel)
    local categoryFrame = ChatConfigCategoryFrame
    -- "Other", the last category of a normal chat window.
    local lastButton = ChatConfigCategoryFrameButton4
    if not categoryFrame or not lastButton or not ChatConfigCategory_OnClick then
        return false
    end

    -- Built like ConfigCategoryButtonTemplate, which needs a global frame name for its highlight.
    local button = CreateFrame("Button", nil, categoryFrame)
    button:SetID(#CHAT_CONFIG_CATEGORIES + 1)
    button:SetHeight(16)
    button:SetPoint("TOPLEFT", lastButton, "BOTTOMLEFT", 0, -1)
    button:SetPoint("TOPRIGHT", lastButton, "BOTTOMRIGHT", 0, -1)
    button:SetNormalFontObject("GameFontNormalLeft")
    button:SetHighlightFontObject("GameFontHighlightLeft")
    button:SetText(text)
    button:GetFontString():ClearAllPoints()
    button:GetFontString():SetPoint("LEFT", 2, 1)
    button:SetHighlightTexture("Interface\\Buttons\\UI-Listbox-Highlight2", "ADD")
    button:GetHighlightTexture():SetVertexColor(0.11, 0.325, 0.48)
    -- Looked up on click: the hook below replaces the global function.
    button:SetScript("OnClick", function(self)
        ChatConfigCategory_OnClick(self)
    end)

    -- Same place as Blizzard's panels.
    panel:SetParent(ChatConfigFrame)
    panel:ClearAllPoints()
    panel:SetPoint("TOPLEFT", ChatConfigBackgroundFrame, "TOPLEFT")
    panel:SetPoint("BOTTOMRIGHT", ChatConfigBackgroundFrame, "BOTTOMRIGHT")
    panel:Hide()

    hooksecurefunc("ChatConfigCategory_OnClick", function(clicked)
        panel:SetShown(clicked == button)
        if clicked == button then
            button:LockHighlight()
        else
            button:UnlockHighlight()
        end
    end)
    -- The text to speech window hides the chat categories; the own one follows "Other".
    hooksecurefunc("ChatConfigCategoryFrame_Refresh", function()
        button:SetShown(lastButton:IsShown())
    end)
    return true
end
