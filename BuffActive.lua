-- BuffActive 0.0.1
-- Checks for missing buffs when out of combat
-- unable to check when in combat due to midnight changes
-- if you are missing a buff, enter combat and enable that buff, the missing buff message stays until you exit combat :(
-- based on BuffReminder

local frame = CreateFrame("Frame")
frame:RegisterEvent("UNIT_AURA")
frame:RegisterEvent("PLAYER_REGEN_ENABLED")  -- leaving combat

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
    end
end)
