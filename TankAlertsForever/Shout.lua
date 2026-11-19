local ranks = {6673, 5242, 6192, 11549, 11550, 11551, 25289}
local defaults = {volume = 100, size = 64, x = 0, y = -140, sound = true, soundChoice = 1, locked = false}
local settings
local nativeContainer
local legacyActive = false
local soundNames = {"Svetlana Neural: Крик", "Рейдовое предупреждение", "Готовность", "Сообщение"}
local function playAlertSound()
    local choice = settings.soundChoice
    local volume = settings.volume / 100
    if volume <= 0 then return end
    if choice == 1 then
        PlaySoundFile(string.format("Interface\\AddOns\\TankAlertsForever\\Sounds\\krik_%03d.wav", settings.volume), "Master")
    else
        local sounds = {8959, 8960, 3081}
        PlaySound(sounds[choice - 1], "Master", false, false, nil, volume)
    end
end
local button = CreateFrame("Button", "TankAlertsForeverShoutIcon", UIParent, "BackdropTemplate")
button:SetBackdrop({edgeFile = "Interface\\Buttons\\WHITE8X8", edgeSize = 3})
button:SetClampedToScreen(true)
button:SetMovable(true)
button:RegisterForDrag("LeftButton")
button:RegisterForClicks("RightButtonUp")
local icon = button:CreateTexture(nil, "ARTWORK")
icon:SetPoint("TOPLEFT", 4, -4)
icon:SetPoint("BOTTOMRIGHT", -4, 4)
icon:SetTexture("Interface\\Icons\\Ability_Warrior_BattleShout")
icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)
local timeText = button:CreateFontString("TankAlertsForeverShoutTime", "OVERLAY", "GameFontHighlightLarge")
timeText:SetPoint("CENTER")
timeText:SetShadowColor(0, 0, 0, 1)
timeText:SetShadowOffset(1, -1)
local panel = CreateFrame("Frame", "TankAlertsForeverShoutOptions", UIParent, "BackdropTemplate")
ForeverAlertsStyle.Panel(panel)
panel:SetSize(360, 395)
panel:SetPoint("CENTER")
panel:SetFrameStrata("DIALOG")
panel:EnableMouse(true)
panel:Hide()
table.insert(UISpecialFrames, "TankAlertsForeverShoutOptions")
local title = panel:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
title:SetPoint("TOPLEFT", 20, -18)
title:SetTextColor(0.86, 0.65, 0.50)
title:SetText("Боевой крик")

local function applyLayout()
    button:SetSize(settings.size, settings.size)
    button:ClearAllPoints()
    button:SetPoint("CENTER", UIParent, "CENTER", settings.x, settings.y)
end

local function initializeNative()
    if nativeContainer or InCombatLockdown() then return end
    if not C_XMLUtil or not C_XMLUtil.GetTemplateInfo("CustomAuraContainerTemplate") then return end
    local included = {}
    for _, id in ipairs(ranks) do included[id] = true end
    local container = CreateFrame("AuraContainer", nil, button, "CustomAuraContainerTemplate")
    container:SetAllPoints(button)
    container:AddAuraSlot("battleShout", "HELPFUL", {
        candidateFilters = {includeSpellIDs = included},
        initializeFrame = function(frame)
            frame:SetAllPoints(container)
            frame:EnableMouse(false)
            local border = frame:CreateTexture(nil, "BACKGROUND")
            border:SetAllPoints(frame)
            border:SetColorTexture(0.2, 1, 0.35, 1)
            local image = frame:CreateTexture(nil, "ARTWORK")
            image:SetPoint("TOPLEFT", 4, -4)
            image:SetPoint("BOTTOMRIGHT", -4, 4)
            image:SetTexCoord(0.07, 0.93, 0.07, 0.93)
            frame:SetIcon(image)
            local countdown = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightLarge")
            countdown:SetPoint("CENTER")
            countdown:SetShadowColor(0, 0, 0, 1)
            countdown:SetShadowOffset(1, -1)
            frame:SetDurationText(countdown)
        end,
    })
    container:SetUnit("player")
    nativeContainer = container
end

local function findAura()
    if not issecretvalue or not C_UnitAuras or not C_Secrets
        or not C_Secrets.ShouldSpellAuraBeSecret then
        return nil, true
    end
    local restricted = false
    for _, id in ipairs(ranks) do
        if C_Spell.DoesSpellExist(id) then
            if C_Secrets.ShouldSpellAuraBeSecret(id) then
                restricted = true
            else
                local aura = C_UnitAuras.GetPlayerAuraBySpellID(id)
                if issecretvalue(aura) then
                    restricted = true
                elseif aura then
                    return aura, false
                end
            end
        end
    end
    return nil, restricted
end

local previousState
local function update()
    if not settings or legacyActive then return end
    local aura, restricted = findAura()
    local state = restricted and "unknown" or (aura and "present" or "missing")
    if state == "missing" and previousState == "present" and settings.sound then
        playAlertSound()
    end
    previousState = state
    timeText:SetText("")
    if aura then
        local expires = aura.expirationTime
        if not issecretvalue(expires) and type(expires) == "number" and expires > 0 then
            timeText:SetText(tostring(math.max(0, math.ceil(expires - GetTime()))))
        end
    end
    icon:SetDesaturated(nativeContainer ~= nil or state ~= "present")
    if nativeContainer then
        timeText:SetText("")
        button:SetBackdropBorderColor(1, 0.22, 0.15, 1)
    elseif state == "present" then
        button:SetBackdropBorderColor(0.2, 1, 0.35, 1)
    elseif state == "unknown" then
        button:SetBackdropBorderColor(1, 0.75, 0.2, 1)
    else
        button:SetBackdropBorderColor(1, 0.22, 0.15, 1)
    end
    button:Show()
end

local function checkbox(label, y, key)
    local check = CreateFrame("CheckButton", nil, panel, "UICheckButtonTemplate")
    check:SetPoint("TOPLEFT", 15, y - 20)
    ForeverAlertsStyle.Check(check)
    check.Text:SetText(label)
    check:SetScript("OnClick", function(self)
        settings[key] = self:GetChecked() == true
        update()
    end)
    return check
end
local sound = checkbox("Звук, когда крик спал", -35, "sound")
local locked = checkbox("Закрепить положение", -65, "locked")
local soundPicker = CreateFrame("Button", "TankAlertsForeverShoutSoundPicker", panel, "UIPanelButtonTemplate")
soundPicker:SetSize(230, 24)
soundPicker:SetPoint("TOPLEFT", 20, -215)
ForeverAlertsStyle.Button(soundPicker)
soundPicker:SetScript("OnClick", function(self)
    settings.soundChoice = settings.soundChoice % #soundNames + 1
    self:SetText(soundNames[settings.soundChoice])
    playAlertSound()
end)
local soundTest = CreateFrame("Button", "TankAlertsForeverShoutSoundTest", panel, "UIPanelButtonTemplate")
soundTest:SetSize(70, 22)
soundTest:SetPoint("TOPLEFT", 20, -303)
ForeverAlertsStyle.Button(soundTest)
soundTest:SetText("Тест")
soundTest:SetScript("OnClick", playAlertSound)

local volumeSlider = CreateFrame("Slider", "TankAlertsForeverShoutVolume", panel, "OptionsSliderTemplate")
volumeSlider:SetPoint("TOPLEFT", 23, -270)
volumeSlider:SetWidth(265)
volumeSlider:SetMinMaxValues(0, 100)
volumeSlider:SetValueStep(10)
volumeSlider:SetObeyStepOnDrag(true)
volumeSlider.Low:SetText("0%")
volumeSlider.High:SetText("100%")
volumeSlider:SetScript("OnValueChanged", function(self, value)
    if not settings then return end
    settings.volume = math.floor(math.min(100, math.max(0, value)) / 10 + 0.5) * 10
    self.Text:SetText("Громкость крика: " .. settings.volume .. "%")
end)

local size = CreateFrame("Slider", "TankAlertsForeverShoutSize", panel, "OptionsSliderTemplate")
size:SetPoint("TOPLEFT", 23, -140)
size:SetWidth(265)
size:SetMinMaxValues(36, 120)
size:SetValueStep(1)
size:SetObeyStepOnDrag(true)
size.Low:SetText("36")
size.High:SetText("120")
size:SetScript("OnValueChanged", function(self, value)
    if not settings then return end
    settings.size = math.floor(value + 0.5)
    self.Text:SetText("Размер иконки: " .. settings.size)
    button:SetSize(settings.size, settings.size)
end)

local reset = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
reset:SetSize(160, 24)
reset:SetPoint("TOPLEFT", 20, -180)
reset:SetText("Вернуть в центр")
ForeverAlertsStyle.Button(reset)
reset:SetScript("OnClick", function()
    settings.x, settings.y = defaults.x, defaults.y
    applyLayout()
end)
local hint = panel:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
hint:SetPoint("BOTTOMLEFT", 20, 20)
hint:SetText("ЛКМ + перетаскивание — переместить\nПКМ — открыть настройки")

local function toggleOptions()
    if not settings then return end
    if legacyActive then
        print("TankAlertsForever: настройки крика перенесены. Отключи отдельный ShoutStatusForever и выполни /reload.")
        return
    end
    if panel:IsShown() then panel:Hide(); return end
    sound:SetChecked(settings.sound)
    locked:SetChecked(settings.locked)
    soundPicker:SetText(soundNames[settings.soundChoice])
    size:SetValue(settings.size)
    volumeSlider:SetValue(settings.volume)
    panel:Show()
    update()
end
panel:SetScript("OnHide", update)
button:SetScript("OnClick", toggleOptions)
button:SetScript("OnDragStart", function(self)
    if settings and not settings.locked then self:StartMoving() end
end)
local function stopMoving(self)
    self:StopMovingOrSizing()
    if not settings then return end
    local x, y = self:GetCenter()
    local parentX, parentY = UIParent:GetCenter()
    if x and y and parentX and parentY then
        settings.x, settings.y = x - parentX, y - parentY
        applyLayout()
    end
end
button:SetScript("OnDragStop", stopMoving)
button:SetScript("OnHide", function(self) self:StopMovingOrSizing() end)
button:SetScript("OnEnter", function(self)
    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
    GameTooltip:SetText("Боевой крик")
    GameTooltip:AddLine("ЛКМ + перетаскивание — переместить", 1, 1, 1)
    GameTooltip:AddLine("ПКМ — настройки", 1, 1, 1)
    GameTooltip:Show()
end)
button:SetScript("OnLeave", function() GameTooltip:Hide() end)
button:Hide()
SLASH_SHOUTSTATUSFOREVER1 = "/shoutstatus"
SlashCmdList.SHOUTSTATUSFOREVER = toggleOptions
TankAlertsForeverOpenShout = toggleOptions

local events = CreateFrame("Frame")
events:RegisterEvent("PLAYER_LOGIN")
events:RegisterEvent("PLAYER_ENTERING_WORLD")
events:RegisterEvent("PLAYER_REGEN_ENABLED")
events:RegisterEvent("PLAYER_REGEN_DISABLED")
events:RegisterUnitEvent("UNIT_AURA", "player")
local ticker
events:SetScript("OnEvent", function(self, event, name)
    if event == "PLAYER_LOGIN" then
        if type(TankAlertsForeverDB) ~= "table" then TankAlertsForeverDB = {} end
        if type(TankAlertsForeverDB.shout) ~= "table" then
            TankAlertsForeverDB.shout = {}
            if type(ShoutStatusForeverDB) == "table" then
                for key in pairs(defaults) do
                    TankAlertsForeverDB.shout[key] = ShoutStatusForeverDB[key]
                end
            end
        end
        settings = TankAlertsForeverDB.shout
        legacyActive = C_AddOns and C_AddOns.IsAddOnLoaded and C_AddOns.IsAddOnLoaded("ShoutStatusForever") or false
        for key, value in pairs(defaults) do
            if type(settings[key]) ~= type(value) then settings[key] = value end
        end
        if settings.size ~= settings.size then settings.size = defaults.size end
        settings.size = math.min(120, math.max(36, settings.size))
        if settings.volume ~= settings.volume then settings.volume = 100 end
        settings.volume = math.floor(math.min(100, math.max(0, settings.volume)) / 10 + 0.5) * 10
        if settings.soundChoice ~= math.floor(settings.soundChoice)
            or settings.soundChoice < 1 or settings.soundChoice > #soundNames then
            settings.soundChoice = 1
        end
        for _, key in ipairs({"x", "y"}) do
            if settings[key] ~= settings[key] or math.abs(settings[key]) > 10000 then
                settings[key] = defaults[key]
            end
        end
        applyLayout()
        if legacyActive then
            print("TankAlertsForever: настройки крика перенесены. Отключи отдельный ShoutStatusForever и выполни /reload.")
        else
            initializeNative()
            button:Show()
            ticker = C_Timer.NewTicker(0.5, update)
        end
        self:UnregisterEvent("PLAYER_LOGIN")
    end
    if event == "PLAYER_REGEN_ENABLED" and settings and not legacyActive then initializeNative() end
    update()
end)

