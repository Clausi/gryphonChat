local _, ns = ...

-- Options page in Blizzard's settings (Esc > Options > AddOns) built from own controls on a canvas
-- category, instead of Blizzard's vertical settings list.
--
-- Blizzard's settings list reuses its control frames for every page. A control that showed a
-- setting registered by addon code keeps tainted callback handles, and the Blizzard setting it
-- shows next runs tainted. A changed action bar toggle then taints the Edit Mode layout, and Edit
-- Mode fails on secret values (TargetUnit blocked, party frames compare secret health colors).
-- The controls here are own frames and are never shown for Blizzard's settings. The canvas has no
-- OnShow script: Blizzard shows it from its own code and calls OnRefresh through
-- securecallfunction.
--
--   local panel = ns.OptionsPanel.Create(title)
--   panel:AddHeader(text)
--   panel:AddCheckbox(label, tooltip, getValue, setValue)
--   panel:AddSlider(label, tooltip, minValue, maxValue, step, formatValue, getValue, setValue)
--   panel:AddButton(label, buttonText, tooltip, onClick)
--   local category = panel:Register()  -- after all rows; Settings.OpenToCategory(category:GetID())
local OptionsPanel = {}
ns.OptionsPanel = OptionsPanel

local ROW_HEIGHT = 30
local HEADER_HEIGHT = 34
local SIDE_PADDING = 16
local LABEL_WIDTH = 220
local SCROLL_BAR_SPACE = 24

local Panel = {}
Panel.__index = Panel

local function ShowTooltip(owner, title, text)
    GameTooltip:SetOwner(owner, "ANCHOR_RIGHT")
    GameTooltip:SetText(title, HIGHLIGHT_FONT_COLOR.r, HIGHLIGHT_FONT_COLOR.g, HIGHLIGHT_FONT_COLOR.b)
    GameTooltip:AddLine(text, nil, nil, nil, true)
    GameTooltip:Show()
end

local function HideTooltip()
    GameTooltip:Hide()
end

local function SetTooltip(frame, title, text)
    frame:SetScript("OnEnter", function(self)
        ShowTooltip(self, title, text)
    end)
    frame:SetScript("OnLeave", HideTooltip)
end

-- The canvas is sized by Blizzard's settings panel; the rows scroll if they do not fit.
function OptionsPanel.Create(title)
    local panel = setmetatable({ controls = {}, height = 0, refreshing = false }, Panel)

    local canvas = CreateFrame("Frame")
    canvas:Hide()
    panel.canvas = canvas

    local titleText = canvas:CreateFontString(nil, "ARTWORK", "GameFontHighlightHuge")
    titleText:SetPoint("TOPLEFT", 7, -22)
    titleText:SetText(title)
    panel.title = title

    local scrollFrame = CreateFrame("ScrollFrame", nil, canvas, "ScrollFrameTemplate")
    scrollFrame:SetPoint("TOPLEFT", 0, -56)
    scrollFrame:SetPoint("BOTTOMRIGHT", -SCROLL_BAR_SPACE, 8)
    scrollFrame.ScrollBar:SetHideIfUnscrollable(true)
    local content = CreateFrame("Frame", nil, scrollFrame)
    content:SetSize(1, 1)
    scrollFrame:SetScrollChild(content)
    scrollFrame:SetScript("OnSizeChanged", function(_, width)
        content:SetWidth(width)
    end)
    panel.content = content

    canvas.OnRefresh = function()
        panel:Refresh()
    end
    return panel
end

-- Shows the current values, e.g. after a change by slash command. Blizzard calls it each time the
-- page is shown.
function Panel:Refresh()
    self.refreshing = true
    for _, refresh in ipairs(self.controls) do
        refresh()
    end
    self.refreshing = false
end

-- Registers the page under Esc > Options > AddOns and returns its category.
function Panel:Register()
    self:Refresh()
    local category = Settings.RegisterCanvasLayoutCategory(self.canvas, self.title)
    Settings.RegisterAddOnCategory(category)
    return category
end

-- Returns the y offset of a new row of the given height.
function Panel:AddRow(height)
    local y = -self.height
    self.height = self.height + height
    self.content:SetHeight(self.height)
    return y
end

function Panel:AddHeader(text)
    local y = self:AddRow(HEADER_HEIGHT)
    local header = self.content:CreateFontString(nil, "ARTWORK", "GameFontHighlightLarge")
    header:SetPoint("BOTTOMLEFT", self.content, "TOPLEFT", 0, y - HEADER_HEIGHT + 6)
    header:SetText(text)
end

-- Label on the left and the control in the second column, like Blizzard's settings list. Returns
-- the point for the control.
function Panel:AddLabeledRow(label)
    local y = self:AddRow(ROW_HEIGHT)
    local text = self.content:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    text:SetPoint("LEFT", self.content, "TOPLEFT", SIDE_PADDING, y - ROW_HEIGHT / 2)
    text:SetWidth(LABEL_WIDTH)
    text:SetJustifyH("LEFT")
    text:SetWordWrap(false)
    text:SetText(label)
    return "LEFT", self.content, "TOPLEFT", SIDE_PADDING + LABEL_WIDTH, y - ROW_HEIGHT / 2
end

function Panel:AddCheckbox(label, tooltip, getValue, setValue)
    local checkbox = CreateFrame("CheckButton", nil, self.content, "UICheckButtonTemplate")
    checkbox:SetSize(26, 26)
    checkbox:SetPoint(self:AddLabeledRow(label))
    checkbox:SetScript("OnClick", function(button)
        setValue(button:GetChecked())
    end)
    SetTooltip(checkbox, label, tooltip)
    self.controls[#self.controls + 1] = function()
        checkbox:SetChecked(getValue() and true or false)
    end
end

-- formatValue(value) returns the text right of the slider.
function Panel:AddSlider(label, tooltip, minValue, maxValue, step, formatValue, getValue, setValue)
    local slider = CreateFrame("Frame", nil, self.content, "MinimalSliderWithSteppersTemplate")
    slider:SetPoint(self:AddLabeledRow(label))
    local formatters = { [MinimalSliderWithSteppersMixin.Label.Right] = formatValue }
    slider:Init(getValue(), minValue, maxValue, (maxValue - minValue) / step, formatters)
    slider:RegisterCallback(MinimalSliderWithSteppersMixin.Event.OnValueChanged, function(_, value)
        if not self.refreshing then
            setValue(value)
        end
    end, slider)
    slider.Slider:HookScript("OnEnter", function(frame)
        ShowTooltip(frame, label, tooltip)
    end)
    slider.Slider:HookScript("OnLeave", HideTooltip)
    self.controls[#self.controls + 1] = function()
        slider:SetValue(getValue())
    end
end

function Panel:AddButton(label, buttonText, tooltip, onClick)
    local button = CreateFrame("Button", nil, self.content, "UIPanelButtonTemplate")
    button:SetSize(120, 22)
    button:SetPoint(self:AddLabeledRow(label))
    button:SetText(buttonText)
    button:SetScript("OnClick", onClick)
    SetTooltip(button, label, tooltip)
end
