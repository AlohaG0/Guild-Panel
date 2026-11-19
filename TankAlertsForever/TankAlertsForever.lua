local spells = {
    [12975] = "Ни шагу назад",
    [871] = "Глухая оборона",
    [20230] = "Возмездие",
}
local kicks = {
    [6552] = "Зуботычина", [6554] = "Зуботычина",
    [72] = "Удар щитом", [1671] = "Удар щитом",
    [1672] = "Удар щитом", [29704] = "Удар щитом",
}
local alert = CreateFrame("Frame", "TankAlertsForeverAlert", UIParent, "BackdropTemplate")
alert:SetBackdrop({bgFile = "Interface\\Buttons\\WHITE8X8", edgeFile = "Interface\\Buttons\\WHITE8X8", edgeSize = 1})
alert:SetBackdropColor(0.055, 0.055, 0.065, 0.95)
alert:SetBackdropBorderColor(0.86, 0.65, 0.50, 0.8)
alert:SetSize(420, 42)
alert:SetPoint("CENTER", UIParent, "CENTER", 0, 155)
alert:SetFrameStrata("HIGH")
local alertText = alert:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
alertText:SetPoint("CENTER")
alert:Hide()

local hideTimer
local function showScreenAlert(message)
    if hideTimer then
        hideTimer:Cancel()
    end
    alertText:SetText(message)
    alert:Show()
    hideTimer = C_Timer.NewTimer(2.5, function()
        alert:Hide()
        hideTimer = nil
    end)
end

local lastSent = {}
local blockedByClient = false
local testStatus
local function sendGroupAlert(groupMessage)
    if TankAlertsForeverDB.groupChat == false then
        return "Включи сообщения в чат в настройках."
    end
    local sendChat = C_ChatInfo and C_ChatInfo.SendChatMessage
    if not sendChat then
        return "API чата недоступен."
    end
    if blockedByClient then
        return "Автоанонс заблокирован клиентом до /reload."
    end
    local channel = "PARTY"
    if IsInGroup(LE_PARTY_CATEGORY_INSTANCE) then
        channel = "INSTANCE_CHAT"
    elseif IsInRaid() then
        channel = "RAID"
    elseif not IsInGroup() then
        return "Для теста чата вступи в группу или рейд."
    end
    local now = GetTime()
    local previous = lastSent[groupMessage]
    if previous and now - previous < 3 then
        return "Повтори тест через несколько секунд."
    end
    if C_ChatInfo.AreOutgoingAddonChatMessagesRestricted and C_ChatInfo.AreOutgoingAddonChatMessagesRestricted() then

        return "Клиент ограничил сообщения аддонов."
    end
    if C_ChatInfo.InChatMessagingLockdown and C_ChatInfo.InChatMessagingLockdown() then
        return "Автоанонс недоступен в текущем боевом режиме."
    end

    local ok = pcall(sendChat, groupMessage, channel)
    if not ok then
        blockedByClient = true
        return "API чата отклонил отправку."
    end
    if blockedByClient then return "Игра заблокировала автоанонс." end
    lastSent[groupMessage] = now
    return "Вызван API отправки в групповой чат."
end

local function showAlert(message, groupMessage)
    showScreenAlert(message)
    local result = sendGroupAlert(groupMessage)
    if testStatus then testStatus:SetText(result) end
end

local panel = CreateFrame("Frame", "TankAlertsForeverPanel", UIParent, "BackdropTemplate")
ForeverAlertsStyle.Panel(panel)
panel:SetSize(440, 425)
panel:SetPoint("CENTER")
panel:SetFrameStrata("DIALOG")
panel:EnableMouse(true)
local title = panel:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
title:SetPoint("TOPLEFT", 20, -18)
title:SetTextColor(0.86, 0.65, 0.50)
title:SetText("Tank Tools Forever")
panel:Hide()
table.insert(UISpecialFrames, panel:GetName())

local function option(label, offset, key)
    local checkbox = CreateFrame("CheckButton", nil, panel, "UICheckButtonTemplate")
    checkbox:SetPoint("TOPLEFT", 14, offset - 20)
    ForeverAlertsStyle.Check(checkbox)
    local caption = checkbox:CreateFontString(nil, "OVERLAY", key and "GameFontHighlight" or "GameFontDisable")
    caption:SetPoint("LEFT", checkbox, "RIGHT", 2, 0)
    caption:SetText(label)
    if key then
        checkbox:SetScript("OnClick", function(self)
            TankAlertsForeverDB[key] = self:GetChecked() == true
        end)
    else
        checkbox:Disable()
    end
    return checkbox
end

local defensives = option("Защитные способности и Возмездие", -31, "defensives")
local interrupts = option("Успешное прерывание цели", -58, "interrupts")
local groupChat = option("Сообщать в чат группы или рейда", -85, "groupChat")
option("Мои промахи", -112)
option("Провал Провокации", -139)
local abilityUsed = option("Сообщать применение вместо результата", -170, "abilityUsed")
local help = panel:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
help:SetPoint("TOPLEFT", 18, -230)
help:SetText("Для промахов нет подтверждённого источника данных.")

testStatus = panel:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
testStatus:SetPoint("BOTTOMLEFT", 18, 13)
testStatus:SetWidth(400)
testStatus:SetJustifyH("LEFT")

local screenTest = CreateFrame("Button", "TankAlertsForeverScreenTest", panel, "UIPanelButtonTemplate")
screenTest:SetSize(130, 24)
screenTest:SetPoint("TOPLEFT", 16, -255)
ForeverAlertsStyle.Button(screenTest)
screenTest:SetText("Тест на экране")
screenTest:SetScript("OnClick", function()
    showScreenAlert("[Тест] Ни шагу назад — применено")
    testStatus:SetText("Показано тестовое уведомление.")
end)

local chatTest = CreateFrame("Button", "TankAlertsForeverChatTest", panel, "UIPanelButtonTemplate")
chatTest:SetSize(130, 24)
chatTest:SetPoint("LEFT", screenTest, "RIGHT", 8, 0)
ForeverAlertsStyle.Button(chatTest)
chatTest:SetText("Тест в чат")
chatTest:SetScript("OnClick", function()
    testStatus:SetText(sendGroupAlert("[Тест] Tank Alerts Forever"))
end)

local macroPanel = CreateFrame("Frame", "TankAlertsForeverMacros", UIParent, "BackdropTemplate")
ForeverAlertsStyle.Panel(macroPanel)
macroPanel:SetSize(440, 280)
macroPanel:SetPoint("CENTER")
macroPanel:SetFrameStrata("DIALOG")
macroPanel:EnableMouse(true)
macroPanel:Hide()
table.insert(UISpecialFrames, "TankAlertsForeverMacros")
local macroTitle = macroPanel:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
macroTitle:SetPoint("TOPLEFT", 20, -18)
macroTitle:SetText("Анонс по нажатию способности")
macroTitle:SetTextColor(0.86, 0.65, 0.50)
local macroText = CreateFrame("EditBox", "TankAlertsForeverMacroText", macroPanel)
macroText:SetPoint("TOPLEFT", 22, -115)
macroText:SetSize(390, 95)
macroText:SetMultiLine(true)
macroText:SetAutoFocus(false)
macroText:SetFontObject("ChatFontNormal")
macroText:SetMaxLetters(255)
macroText:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
local macroSpell, macroRaid = "Ни шагу назад", false
local function refreshMacro()
    macroText:SetText("#showtooltip " .. macroSpell .. "\n/cast " .. macroSpell
        .. "\n/stopmacro [nogroup]\n/" .. (macroRaid and "ra" or "p") .. " Использую: " .. macroSpell)
    macroText:HighlightText()
end
for i, name in ipairs({"Ни шагу назад", "Глухая оборона", "Возмездие"}) do
    local choose = CreateFrame("Button", nil, macroPanel, "UIPanelButtonTemplate")
    choose:SetSize(126, 24)
    choose:SetPoint("TOPLEFT", 20 + (i - 1) * 132, -55)
    ForeverAlertsStyle.Button(choose)
    choose:SetText(name)
    choose:SetScript("OnClick", function() macroSpell = name; refreshMacro() end)
end
local channelButton = CreateFrame("Button", nil, macroPanel, "UIPanelButtonTemplate")
channelButton:SetSize(126, 24)
channelButton:SetPoint("TOPLEFT", 20, -85)
ForeverAlertsStyle.Button(channelButton)
channelButton:SetText("Канал: группа")
channelButton:SetScript("OnClick", function(self)
    macroRaid = not macroRaid
    self:SetText(macroRaid and "Канал: рейд" or "Канал: группа")
    refreshMacro()
end)
local macroHint = macroPanel:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
macroHint:SetPoint("BOTTOMLEFT", 20, 20)
macroHint:SetText("Скопируй в /macro и вынеси на панель. Отключи автоанонс.\nСообщение означает нажатие, успех применения не проверяется.")
local macros = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
macros:SetSize(268, 24)
macros:SetPoint("TOPLEFT", 16, -286)
ForeverAlertsStyle.Button(macros)
macros:SetText("Макросы для анонса по нажатию")
macros:SetScript("OnClick", function()
    macroPanel:Show()
    refreshMacro()
end)
local shoutSettings = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
shoutSettings:SetSize(268, 24)
shoutSettings:SetPoint("TOPLEFT", 16, -320)
ForeverAlertsStyle.Button(shoutSettings)
shoutSettings:SetText("Боевой крик · звук и громкость")
shoutSettings:SetScript("OnClick", function()
    if TankAlertsForeverOpenShout then TankAlertsForeverOpenShout() end
end)

local function togglePanel()
    if panel:IsShown() then
        panel:Hide()
        return
    end
    defensives:SetChecked(TankAlertsForeverDB.defensives ~= false)
    interrupts:SetChecked(TankAlertsForeverDB.interrupts ~= false)
    groupChat:SetChecked(TankAlertsForeverDB.groupChat ~= false)
    abilityUsed:SetChecked(TankAlertsForeverDB.abilityUsed == true)

    if not blockedByClient then testStatus:SetText("") end
    panel:Show()
end

SLASH_TANKALERTSFOREVER1 = "/tankalerts"
SLASH_TANKALERTSFOREVER2 = "/tanktools"
SlashCmdList.TANKALERTSFOREVER = togglePanel

local launcher = CreateFrame("Button", "TankAlertsForeverLauncher", Minimap)
launcher:SetSize(28, 28)
launcher:SetPoint("BOTTOMLEFT", Minimap, "BOTTOMLEFT", 7, 7)
launcher:SetFrameStrata("MEDIUM")
launcher:RegisterForClicks("LeftButtonUp")
launcher:RegisterForDrag("RightButton")
launcher:SetNormalTexture("Interface\\Icons\\Ability_Warrior_ShieldWall")
launcher:SetHighlightTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight", "ADD")
launcher:SetScript("OnClick", togglePanel)

local function positionLauncher(angle)
    launcher:ClearAllPoints()
    launcher:SetPoint("CENTER", Minimap, "CENTER",
        math.cos(angle) * Minimap:GetWidth() / 2,
        math.sin(angle) * Minimap:GetHeight() / 2)
end

local function dragLauncher()
    local centerX, centerY = Minimap:GetCenter()
    if not centerX or not centerY then
        return
    end
    local cursorX, cursorY = GetCursorPosition()
    local scale = Minimap:GetEffectiveScale()
    local x, y = cursorX / scale - centerX, cursorY / scale - centerY
    if x == 0 and y == 0 then
        return
    end
    local angle = math.atan2(y, x)
    TankAlertsForeverDB.launcherAngle = angle
    positionLauncher(angle)
end

launcher:SetScript("OnDragStart", function(self)
    self:SetScript("OnUpdate", dragLauncher)
end)
launcher:SetScript("OnDragStop", function(self)
    self:SetScript("OnUpdate", nil)
    dragLauncher()
end)
launcher:SetScript("OnHide", function(self)
    self:SetScript("OnUpdate", nil)
end)
launcher:SetScript("OnEnter", function(self)
    GameTooltip:SetOwner(self, "ANCHOR_LEFT")
    GameTooltip:SetText("Tank Tools Forever")
    GameTooltip:AddLine("ЛКМ — настройки", 1, 1, 1)
    GameTooltip:AddLine("Зажми ПКМ, чтобы переместить кнопку", 1, 1, 1)
    GameTooltip:Show()
end)
launcher:SetScript("OnLeave", function()
    GameTooltip:Hide()
end)

local events = CreateFrame("Frame", "TankAlertsForeverEvents")
events:RegisterEvent("ADDON_LOADED")
events:RegisterEvent("ADDON_ACTION_BLOCKED")
events:RegisterEvent("ADDON_ACTION_FORBIDDEN")
events:RegisterUnitEvent("UNIT_SPELLCAST_SUCCEEDED", "player")
events:RegisterUnitEvent("UNIT_SPELLCAST_INTERRUPTED", "target", "focus")
events:RegisterUnitEvent("UNIT_SPELLCAST_CHANNEL_STOP", "target", "focus")
events:SetScript("OnEvent", function(self, event, unit, _, spellID, interruptedBy)
    if event == "ADDON_ACTION_BLOCKED" or event == "ADDON_ACTION_FORBIDDEN" then
        if unit == "TankAlertsForever" then
            blockedByClient = true
            testStatus:SetText("Игра запретила автоматическую отправку. См. README.")
        end
        return
    end
    if event == "ADDON_LOADED" then
        if unit == "TankAlertsForever" then
            if type(TankAlertsForeverDB) ~= "table" then
                TankAlertsForeverDB = {}
            end
            local angle = TankAlertsForeverDB.launcherAngle
            if type(angle) == "number" and math.abs(angle) <= math.pi then
                positionLauncher(angle)
            end
            self:UnregisterEvent("ADDON_LOADED")
        end
        return
    end

    local settings = TankAlertsForeverDB
    if not settings or not issecretvalue or issecretvalue(unit) then
        return
    end
    if event == "UNIT_SPELLCAST_SUCCEEDED" and unit == "player" then
        if issecretvalue(spellID) then
            return
        end
        local kick = kicks[spellID]
        if kick then
            if settings.interrupts ~= false and settings.abilityUsed then
                showAlert("Применено: " .. kick, "Применил: " .. kick)
            end
        end
        if settings.defensives ~= false and not issecretvalue(spellID) then
            local name = spells[spellID]
            if name then
                showAlert(name .. " — применено", "Применил: " .. name)
            end
        end
    elseif (event == "UNIT_SPELLCAST_INTERRUPTED" or event == "UNIT_SPELLCAST_CHANNEL_STOP")
        and (unit == "target" or unit == "focus") then
        if issecretvalue(interruptedBy) then
            return
        end
        if type(interruptedBy) ~= "string" then
            return
        end
        local playerGUID = UnitGUID("player")
        if not issecretvalue(playerGUID) and interruptedBy == playerGUID then
            if settings.interrupts ~= false and not settings.abilityUsed then
                showAlert("Каст прерван", "Прервал каст!")
            end
        end
    end
end)
