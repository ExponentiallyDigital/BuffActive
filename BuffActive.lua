-- BuffActive 0.0.4
-- Midnight-compatible: Out-of-combat buff reminder only
-- Hides on enter combat, re-checks on exit
-- based on BuffReminder, this version by ArcNineOhNine

local frame = CreateFrame("Frame")
frame:RegisterEvent("UNIT_AURA")
frame:RegisterEvent("PLAYER_REGEN_ENABLED")   -- exit combat
frame:RegisterEvent("PLAYER_REGEN_DISABLED")  -- enter combat
frame:RegisterEvent("PLAYER_ENTERING_WORLD")

-- Use spell IDs (Midnight-safe)
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
        CheckBuffs()  -- full check on exit
    elseif event == "PLAYER_REGEN_DISABLED" then
        HideMessage()  -- hide on enter combat
    elseif event == "PLAYER_ENTERING_WORLD" then
        CheckBuffs()
    end
end)