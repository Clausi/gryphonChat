local _, ns = ...

-- Differences between the supported clients (Forever, Classic Era, Anniversary, MoP Classic,
-- Retail), in one place. Detects the APIs and methods a client has instead of comparing version
-- numbers. Blizzard UI reference: the forever, classic_era, classic_anniversary, classic (MoP
-- Classic) and live branches of Gethe/wow-ui-source.
local Compat = {}
ns.Compat = Compat

-- Registers a filter for a chat message event: filter(chatFrame, event, message, ...) returns
-- true to hide the message, or false followed by the changed event arguments. Anniversary has
-- ChatFrameUtil.AddMessageEventFilter; the global ChatFrame_AddMessageEventFilter only exists as
-- a deprecation fallback there.
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

-- Creates an own button in the button bar next to a chat window. The bar (chatFrame.buttonFrame in
-- FloatingChatFrame.xml) is a VerticalLayoutFrame that stacks its children by layoutIndex from top
-- to bottom: ChatFrame1 uses -2 to 3, the other windows 1 to 3. Duplicate indices raise an error.
function Compat.CreateChatFrameButton(chatFrame, layoutIndex)
    local buttonFrame = chatFrame.buttonFrame
    local button = CreateFrame("Button", nil, buttonFrame)
    button.layoutIndex = layoutIndex
    button.align = "center"
    button:SetSize(32, 32)
    buttonFrame:MarkDirty()
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
