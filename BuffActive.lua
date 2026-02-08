-- BuffActive 0.0.3
-- Checks and alerts for missing buffs
-- based on BuffReminder, this version by ArcNineOhNine (Midnight compatible)

local frame = CreateFrame("Frame")
frame:RegisterEvent("UNIT_AURA")
frame:RegisterEvent("PLAYER_REGEN_ENABLED")  -- leaving combat
frame:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED") -- used to see if we are in combat
frame:RegisterEvent("PLAYER_ENTERING_WORLD")

-- Use spell IDs instead of names (Midnight-safe)
local buffsByClass = {
    WARRIOR = { 6673 },      -- Battle Shout
    MAGE    = { 1459 },      -- Arcane Intellect
    DRUID   = { 1126 },      -- Mark of the Wild
    PRIEST  = { 21562 },     -- Power Word: Fortitude
}

local messageFrame = CreateFrame("Frame", nil, UIParent)
messageFrame:SetSize(600, 250)
messageFrame:SetPoint("CENTER")
messageFrame.text = messageFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
messageFrame.text:SetPoint("CENTER")
messageFrame:Hide()

local function ShowMessage(msg)
    messageFrame.text:SetText(msg)
    messageFrame:Show()
end

local function HideMessage()
    messageFrame:Hide()
end

local function CheckBuffs()
    if InCombatLockdown() or UnitIsDeadOrGhost("player") then
        return
    end
    SetClassBuff()
    if not classBuffID then
        hasBuff = true
        UpdateMessage()
        return
    end
    local info = C_Spell.GetSpellInfo(classBuffID)
    local name = info and info.name
    hasBuff = name and AuraUtil.FindAuraByName(name, "player") ~= nil
    UpdateMessage()
end

local applyEvents = {
    ["SPELL_AURA_APPLIED"] = true,
    ["SPELL_AURA_REFRESH"] = true
}
local removalEvents = {
    ["SPELL_AURA_REMOVED"] = true,
    ["SPELL_AURA_BROKEN"] = true,
    ["SPELL_AURA_BROKEN_SPELL"] = true
}

local classBuffID = nil
local hasBuff = false
local function SetClassBuff()
    local _, class = UnitClass("player")
    local buffs = buffsByClass[class]
    classBuffID = buffs and buffs[1] or nil
end

local function UpdateMessage()
    if UnitIsDeadOrGhost("player") then
        HideMessage()
        return
    end
    if not classBuffID then
        HideMessage()
        return
    end
    local info = C_Spell.GetSpellInfo(classBuffID)
    local name = info and info.name
    if hasBuff then
        HideMessage()
    else
        ShowMessage("Missing buff: " .. (name or "Unknown"))
    end
end

frame:SetScript("OnEvent", function(_, event, unit)
    if event == "PLAYER_ENTERING_WORLD" then
        SetClassBuff()
        CheckBuffs()
    elseif event == "UNIT_AURA" and unit == "player" then
        CheckBuffs()
    elseif event == "PLAYER_REGEN_ENABLED" then
        CheckBuffs()
    elseif event == "COMBAT_LOG_EVENT_UNFILTERED" then
        local timestamp, subevent, hideCaster,
              sourceGUID, sourceName, sourceFlags, sourceRaidFlags,
              destGUID, destName, destFlags, destRaidFlags,
              spellID, spellName = CombatLogGetCurrentEventInfo()
        local playerGUID = UnitGUID("player")
        if destGUID == playerGUID and classBuffID == spellID then
            if applyEvents[subevent] then
                hasBuff = true
            elseif removalEvents[subevent] then
                hasBuff = false
            end
            UpdateMessage()
        end
    end
end)
