-- BuffActive
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

local function CheckBuffs(isForced)
    local currentTime = GetTime()
    
    -- Allow forced checks (from UNIT_AURA events) to bypass debounce if needed
    if not isForced and (currentTime - lastCheckTime < BuffActiveDB.checkInterval) then
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

            -- First, try the direct lookup by spell ID
            local auraData = C_UnitAuras.GetPlayerAuraBySpellID(spellID)
            if auraData and auraData.name then
                -- Aura exists and has a name, so it's active
                -- Note: expirationTime=0 means permanent/indefinite aura (like Devotion Aura)
                found = true
            end

            -- If direct lookup failed or aura wasn't active, we'll rely on the UNIT_AURA event
            -- The direct lookup should be sufficient for most cases
            -- The aura data fields might be protected, so we'll skip the manual loop

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
        CheckBuffs(true)  -- force check on aura change
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