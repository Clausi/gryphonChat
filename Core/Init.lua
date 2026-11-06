local addonName, ns = ...

-- Shared addon namespace. All files receive the same `ns` table via `...`.
ns.name = addonName
ns.version = C_AddOns.GetAddOnMetadata(addonName, "Version")
ns.modules = {}

-- Default values for the saved variables. Missing keys are filled in on load.
-- Account-wide (GryphonChatDB, ns.db): settings and data shared by all characters.
ns.defaults = {
    debug = false,
}

-- Per character (GryphonChatCharDB, ns.charDb): data and settings only the logged-in character needs.
ns.charDefaults = {
    -- Automatic messages of the addon (e.g. on login). Change with "/gryphonchat notify on|off".
    notifications = true,
    -- Lines every chat window keeps (Blizzard default). Change with "/gryphonchat lines <n>".
    chatLines = 128,
    -- Short channel names in chat. Change with "/gryphonchat channels".
    channelNames = {
        enabled = false,
        -- Language code after the short name of a channel with a language, e.g. "T [EN]".
        showLanguage = true,
        -- Own short names, keyed by lowercase channel name: { name = "Global", shortName = "G" }.
        custom = {},
    },
    -- Input line of the chat windows. Change in the options.
    chatInput = {
        -- Arrow keys go through the input history without Alt.
        arrowKeys = true,
        -- The input history is kept across logouts and reloads.
        keepHistory = true,
        -- Saved input history, oldest line first.
        history = {},
    },
    -- Tooltips of item, spell, ... links in chat on mouseover. Change in the options.
    linkTooltips = true,
    -- Mouse wheel in the chat windows. Change in the options.
    chatScroll = {
        -- Shift: to the first or last line, Ctrl: a page at a time.
        modifiers = true,
        -- Seconds after the last wheel scroll until the chat scrolls back down, 0 for never.
        bottomDelay = 0,
    },
}

-- Registers a module. A module may implement:
--   module:OnInitialize()  -- called once after saved variables are loaded
--   module:OnEnable()      -- called on PLAYER_LOGIN
function ns:RegisterModule(name)
    local module = { name = name }
    self.modules[#self.modules + 1] = module
    self.modules[name] = module
    return module
end

-- Registers a "/gryphonchat <name> ..." subcommand.
--   handler(args)  -- args: the rest of the input after the command name, trimmed
--   helpLines      -- user-facing help lines (already localized), shown by "/gryphonchat"
ns.commands = {}

function ns:RegisterCommand(name, handler, helpLines)
    local command = { name = name, handler = handler, helpLines = helpLines or {} }
    self.commands[#self.commands + 1] = command
    self.commands[name] = command
end

-- Simple event dispatcher: ns:RegisterEvent("EVENT", function(event, ...) end)
local eventFrame = CreateFrame("Frame")
local eventHandlers = {}

eventFrame:SetScript("OnEvent", function(_, event, ...)
    local handlers = eventHandlers[event]
    if not handlers then
        return
    end
    for i = 1, #handlers do
        handlers[i](event, ...)
    end
end)

function ns:RegisterEvent(event, handler)
    if not eventHandlers[event] then
        eventHandlers[event] = {}
        eventFrame:RegisterEvent(event)
    end
    table.insert(eventHandlers[event], handler)
end
