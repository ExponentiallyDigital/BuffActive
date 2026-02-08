-- BuffActive 0.0.2
-- Checks and alerts for missing buffs
-- based on BuffReminder, this version by ArcNineOhNine

local frame = CreateFrame("Frame")
frame:RegisterEvent("UNIT_AURA")
frame:RegisterEvent("PLAYER_REGEN_ENABLED")  -- leaving combat
frame:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED") -- used to see if we are in combat

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
    -- Never check buffs in combat (API returns null)
    if InCombatLockdown() then
        return
    end
    if UnitIsDeadOrGhost("player") then
        HideMessage()
        return
    end
    local _, class = UnitClass("player")
    local buffs = buffsByClass[class]
    if not buffs then
        HideMessage()
        return
    end
    for _, spellID in ipairs(buffs) do
        local info = C_Spell.GetSpellInfo(spellID)
        local name = info and info.name
        if name then
            local aura = AuraUtil.FindAuraByName(name, "player")
            if not aura then
                ShowMessage("Missing buff: " .. name)
                return
            end
        end
    end
    HideMessage()
end

frame:SetScript("OnEvent", function(_, event, unit)
    if event == "UNIT_AURA" and unit == "player" then
        CheckBuffs()
    elseif event == "PLAYER_REGEN_ENABLED" then
        -- Leaving combat: aura API is stable again
        CheckBuffs()
    elseif event == "COMBAT_LOG_EVENT_UNFILTERED" then
        local timestamp, subevent, hideCaster, sourceGUID, sourceName, sourceFlags, sourceRaidFlags,
              destGUID, destName, destFlags, destRaidFlags, spellID = CombatLogGetCurrentEventInfo()
        
        if (subevent == "SPELL_AURA_APPLIED" or subevent == "SPELL_AURA_REFRESH") and
           destGUID == UnitGUID("player") then
            local _, class = UnitClass("player")
            local buffs = buffsByClass[class]
            if buffs then
                for _, buffID in ipairs(buffs) do
                    if spellID == buffID then
                        HideMessage()
                        return
                    end
                end
            end
        end
    end
end)
