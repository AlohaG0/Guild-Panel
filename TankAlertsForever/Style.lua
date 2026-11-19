-- Original styling inspired by dark, bronze-accented EllesmereUI Forever.
-- Uses only stock game textures and fonts.
if ForeverAlertsStyle then return end
ForeverAlertsStyle = {}
local Style = ForeverAlertsStyle
local r, g, b = 0.86, 0.65, 0.50
local backdrop = {bgFile = "Interface\\Buttons\\WHITE8X8", edgeFile = "Interface\\Buttons\\WHITE8X8", edgeSize = 1}

function Style.Button(frame)
    for _, key in ipairs({"Left", "Middle", "Right"}) do
        if frame[key] then frame[key]:Hide() end
    end
    frame:SetNormalTexture(nil)
    frame:SetPushedTexture(nil)
    local background = frame:CreateTexture(nil, "BACKGROUND")
    background:SetAllPoints()
    background:SetColorTexture(0.12, 0.12, 0.14, 1)
    local accent = frame:CreateTexture(nil, "BORDER")
    accent:SetPoint("BOTTOMLEFT")
    accent:SetPoint("BOTTOMRIGHT")
    accent:SetHeight(1)
    accent:SetColorTexture(r, g, b, 0.6)
    frame:SetScript("OnEnter", function()
        background:SetColorTexture(0.22, 0.18, 0.16, 1)
    end)
    frame:SetScript("OnLeave", function()
        background:SetColorTexture(0.12, 0.12, 0.14, 1)
    end)
end

function Style.Panel(frame)
    frame:SetBackdrop(backdrop)
    frame:SetBackdropColor(0.055, 0.055, 0.065, 0.98)
    frame:SetBackdropBorderColor(0.25, 0.23, 0.21, 1)
    local stripe = frame:CreateTexture(nil, "ARTWORK")
    stripe:SetPoint("TOPLEFT", 1, -1)
    stripe:SetPoint("TOPRIGHT", -1, -1)
    stripe:SetHeight(2)
    stripe:SetColorTexture(r, g, b, 1)
    local close = CreateFrame("Button", nil, frame)
    close:SetSize(24, 24)
    close:SetPoint("TOPRIGHT", -8, -8)
    local text = close:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    text:SetPoint("CENTER")
    text:SetText("×")
    Style.Button(close)
    close:SetScript("OnClick", function() frame:Hide() end)
    frame:SetMovable(true)
    frame:SetClampedToScreen(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", function(self) self:StartMoving() end)
    frame:SetScript("OnDragStop", function(self) self:StopMovingOrSizing() end)
end

function Style.Check(frame)
    local background = frame:CreateTexture(nil, "BACKGROUND")
    background:SetPoint("TOPLEFT", 5, -5)
    background:SetPoint("BOTTOMRIGHT", -5, 5)
    background:SetColorTexture(0.16, 0.15, 0.15, 1)
    frame:SetNormalTexture(nil)
    frame:SetPushedTexture(nil)
    frame:SetCheckedTexture("Interface\\Buttons\\UI-CheckBox-Check")
end

