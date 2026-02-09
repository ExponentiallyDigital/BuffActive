-- BuffActive 0.0.5
-- Midnight-compatible: Out-of-combat buff reminder only
-- Hides on enter combat, re-checks on exit
-- based on BuffReminder, this version by ArcNineOhNine

local frame = CreateFrame("Frame")
frame:RegisterEvent("UNIT_AURA")
frame:RegisterEvent("PLAYER_REGEN_ENABLED")   -- exit combat
frame:RegisterEvent("PLAYER_REGEN_DISABLED")  -- enter combat
frame:RegisterEvent("PLAYER_ENTERING_WORLD")

-- Cache spell names at startup to avoid repeated API calls
local cachedSpellNames = {}
local buffsByClass = {
    WARRIOR = { 6673 },      -- Battle Shout
    MAGE    = { 1459 },      -- Arcane Intellect
    DRUID   = { 1126 },      -- Mark of the Wild
    PRIEST  = { 21562 },     -- Power Word: Fortitude
}

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
local CHECK_INTERVAL = 2 -- seconds

local function CheckBuffs()
    local currentTime = GetTime()
    if currentTime - lastCheckTime < CHECK_INTERVAL then
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
            -- More efficient aura checking using UnitAura
            local i = 1
            local auraName, _, _, _, _, _, _, _, _, _, spellId = UnitAura("player", i)
            local found = false
            
            while auraName do
                if spellId == spellID then
                    found = true
                    break
                end
                i = i + 1
                auraName, _, _, _, _, _, _, _, _, _, spellId = UnitAura("player", i)
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

frame:SetScript("OnEvent", function(self, event, unit)
    if event == "UNIT_AURA" and unit == "player" then
        CheckBuffs()
    elseif event == "PLAYER_REGEN_ENABLED" then
        CheckBuffs()  -- full check on exit
    elseif event == "PLAYER_REGEN_DISABLED" then
        HideMessage()  -- hide on enter combat
    elseif event == "PLAYER_ENTERING_WORLD" then
        InitializeSpellCache() -- Re-initialize cache on world load
        CheckBuffs()
    end
end)