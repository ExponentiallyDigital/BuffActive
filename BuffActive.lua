-- BuffActive 0.0.6
-- Midnight-compatible: Out-of-combat buff reminder only
-- Hides on enter combat, re-checks on exit
-- based on BuffReminder, this version by ArcNineOhNine

-- Initialize saved variables
if type(BuffActiveDB) ~= "table" then BuffActiveDB = {} end
if BuffActiveDB.checkInterval == nil then BuffActiveDB.checkInterval = 2 end
if BuffActiveDB.customSpells == nil then BuffActiveDB.customSpells = {} end

local frame = CreateFrame("Frame")
frame:RegisterEvent("UNIT_AURA")
frame:RegisterEvent("PLAYER_REGEN_ENABLED")   -- exit combat
frame:RegisterEvent("PLAYER_REGEN_DISABLED")  -- enter combat
frame:RegisterEvent("PLAYER_ENTERING_WORLD")

-- Cache spell names at startup to avoid repeated API calls
local cachedSpellNames = {}

-- Initialize with default buffs by class, but allow overrides from saved variables
local buffsByClass = {
    WARRIOR = { 6673 },      -- Battle Shout
    MAGE    = { 1459 },      -- Arcane Intellect
    DRUID   = { 1126 },      -- Mark of the Wild
    PRIEST  = { 21562 },     -- Power Word: Fortitude
}

-- Add custom spells from saved variables to the appropriate class
local function AddCustomSpells()
    -- Clear any previously added custom spells to avoid duplicates
    for class, spellIDs in pairs(buffsByClass) do
        local defaultSpellIDs = {
            WARRIOR = { 6673 },      -- Battle Shout
            MAGE    = { 1459 },      -- Arcane Intellect
            DRUID   = { 1126 },      -- Mark of the Wild
            PRIEST  = { 21562 },     -- Power Word: Fortitude
        }
        buffsByClass[class] = defaultSpellIDs[class] or {}
    end
    
    -- Add custom spells from saved variables to the appropriate class
    for class, customSpellIDs in pairs(BuffActiveDB.customSpells) do
        if buffsByClass[class] then
            for _, spellID in ipairs(customSpellIDs) do
                table.insert(buffsByClass[class], spellID)
            end
        else
            buffsByClass[class] = customSpellIDs
        end
    end
end

-- Pre-cache spell names
local function InitializeSpellCache()
    for class, spellIDs in pairs(buffsByClass) do
        for i, spellID in ipairs(spellIDs) do
            local info = C_Spell.GetSpellInfo(spellID)
            if info then
                cachedSpellNames[spellID] = info.name
            end
        end
    end
end

-- Create message frame
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

-- Debounce mechanism to prevent frequent checks
local lastCheckTime = 0

local function CheckBuffs()
    local currentTime = GetTime()
    if currentTime - lastCheckTime < BuffActiveDB.checkInterval then
        return
    end
    lastCheckTime = currentTime

    if InCombatLockdown() or UnitIsDeadOrGhost("player") then
        return
    end

    local _, class = UnitClass("player")
    local spellIDs = buffsByClass[class]

    if not spellIDs then
        HideMessage()
        return
    end

    for _, spellID in ipairs(spellIDs) do
        local spellName = cachedSpellNames[spellID]
        if spellName then
            -- More robust aura checking using C_UnitAuras (modern WoW API)
            local found = false

            -- Using GetPlayerAuraBySpellID which is more efficient for checking specific spells
            local auraData = C_UnitAuras.GetPlayerAuraBySpellID(spellID)
            if auraData then
                -- Additional check: make sure the aura is active (not expired)
                if not auraData.expires then
                    -- If no expiration time, assume it's active
                    found = true
                elseif auraData.expirationTime and auraData.expirationTime > GetTime() then
                    -- If expiration time is in the future, it's active
                    found = true
                end
            else
                -- Fallback: check all auras if the direct lookup failed
                local i = 1
                local name, icon, count, debuffType, duration, expirationTime, source, isStealable, 
                      nameplateShowPersonal, spellId, canApplyAura, isBossDebuff, castByPlayer, 
                      nameplateShowAll, timeMod = UnitAura("player", i, "HELPFUL")

                while name do
                    if spellId == spellID then
                        -- Check if the aura is still active
                        if not expirationTime or expirationTime > GetTime() then
                            found = true
                            break
                        end
                    end
                    i = i + 1
                    name, icon, count, debuffType, duration, expirationTime, source, isStealable, 
                          nameplateShowPersonal, spellId, canApplyAura, isBossDebuff, castByPlayer, 
                          nameplateShowAll, timeMod = UnitAura("player", i, "HELPFUL")
                end
            end

            if not found then
                ShowMessage("Missing buff: " .. spellName)
                return
            end
        end
    end
    HideMessage()
end

-- Initialize spell cache when addon loads
InitializeSpellCache()
AddCustomSpells()

frame:SetScript("OnEvent", function(self, event, unit)
    if event == "UNIT_AURA" and unit == "player" then
        CheckBuffs()
    elseif event == "PLAYER_REGEN_ENABLED" then
        CheckBuffs()  -- full check on exit
    elseif event == "PLAYER_REGEN_DISABLED" then
        HideMessage()  -- hide on enter combat
    elseif event == "PLAYER_ENTERING_WORLD" then
        InitializeSpellCache() -- Re-initialize cache on world load
        AddCustomSpells()      -- Add custom spells after world load
        CheckBuffs()
    end
end)