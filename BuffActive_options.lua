-- Define default spells for each class (defined outside event handler to ensure accessibility)
local defaultSpellsByClass = {
    WARRIOR = { {id = 6673, name = "Battle Shout"} },      -- Battle Shout
    MAGE    = { {id = 1459, name = "Arcane Intellect"} },  -- Arcane Intellect
    DRUID   = { {id = 1126, name = "Mark of the Wild"} },  -- Mark of the Wild
    PRIEST  = { {id = 21562, name = "Power Word: Fortitude"} }, -- Power Word: Fortitude
}

local f = CreateFrame("Frame")
f:RegisterEvent("ADDON_LOADED")
f:SetScript("OnEvent", function(self, event, addon)
    if addon ~= "BuffActive" then return end
    
    ------------------------------------------------------------
    -- Helper functions defined first to ensure they're available
    ------------------------------------------------------------
    

    ------------------------------------------------------------
    -- Helper: Update spell list display
    ------------------------------------------------------------
    local function UpdateSpellListDisplay()
        if not panel.spellListFrame then return end
        
        -- Initialize spellButtons table if it doesn't exist
        if not panel.spellListFrame.spellButtons then
            panel.spellListFrame.spellButtons = {}
        end
        
        -- Clear existing content
        for i = 1, #panel.spellListFrame.spellButtons do
            if panel.spellListFrame.spellButtons[i] then
                panel.spellListFrame.spellButtons[i]:Hide()
            end
        end
        
        local class = GetPlayerClass()
        local defaultSpells = GetCurrentClassDefaultSpells()
        local customSpells = BuffActiveDB.customSpells[class] or {}
        
        -- Combine default and custom spells
        local allSpells = {}
        for _, spell in ipairs(defaultSpells) do
            table.insert(allSpells, {id = spell.id, name = spell.name, isDefault = true})
        end
        for _, spellID in ipairs(customSpells) do
            local spellName = GetSpellName(spellID)
            table.insert(allSpells, {id = spellID, name = spellName, isDefault = false})
        end
        
        -- Calculate dynamic height for scroll child based on number of spells
        local contentHeight = math.max(300, (#allSpells * 30) + 20)
        
        -- Create or reuse buttons for each spell
        if not panel.spellListFrame.spellButtons then
            panel.spellListFrame.spellButtons = {}
        end
        
        for i, spell in ipairs(allSpells) do
            local button = panel.spellListFrame.spellButtons[i]
            if not button then
                button = CreateFrame("Button", nil, panel.spellListFrame.scrollChild, "UIPanelButtonTemplate")
                button:SetSize(300, 25)
                button:SetPoint("TOPLEFT", 10, -(i-1)*30 - 10)
                
                local text = button:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
                text:SetPoint("LEFT", 5, 0)
                button.text = text
                
                local deleteBtn = CreateFrame("Button", nil, button, "UIPanelButtonTemplate")
                deleteBtn:SetSize(20, 20)
                deleteBtn:SetPoint("RIGHT", -5, 0)
                deleteBtn:SetText("X")
                deleteBtn:SetScript("OnClick", function()
                    -- Remove the spell from custom spells
                    local class = GetPlayerClass()
                    if BuffActiveDB.customSpells[class] then
                        for j, spellID in ipairs(BuffActiveDB.customSpells[class]) do
                            if spellID == spell.id then
                                table.remove(BuffActiveDB.customSpells[class], j)
                                break
                            end
                        end
                    end
                    UpdateSpellListDisplay()
                end)
                button.deleteBtn = deleteBtn
                
                panel.spellListFrame.spellButtons[i] = button
            end
            
            button.text:SetText(spell.id .. ": " .. spell.name .. (spell.isDefault and " (Default)" or ""))
            button.deleteBtn:SetShown(not spell.isDefault) -- Only show delete button for custom spells
            button:Show()
        end
        
        -- Update the scroll child size to accommodate all spells
        panel.spellListFrame.scrollChild:SetSize(330, contentHeight)
        
        -- Hide unused buttons
        for i = #allSpells + 1, #panel.spellListFrame.spellButtons do
            if panel.spellListFrame.spellButtons[i] then
                panel.spellListFrame.spellButtons[i]:Hide()
            end
        end
    end

    ------------------------------------------------------------
    -- Helper: Create Checkbox
    ------------------------------------------------------------
    local function CreateCheckbox(parent, label, tooltip, x, y, initial, onClick)
        local cb = CreateFrame("CheckButton", nil, parent, "InterfaceOptionsCheckButtonTemplate")
        cb:SetPoint("TOPLEFT", x, y)
        cb.Text:SetText(label)
        cb.tooltipText = tooltip
        cb:SetChecked(initial)
        cb:SetScript("OnClick", function(self)
            onClick(self:GetChecked())
        end)
        return cb
    end

    ------------------------------------------------------------
    -- Helper: Create Dropdown
    ------------------------------------------------------------
    local function CreateDropdown(parent, label, items, initialValue, onSelect, x, y)
        local dd = CreateFrame("Frame", nil, parent, "UIDropDownMenuTemplate")
        dd:SetPoint("TOPLEFT", x, y)
        local title = parent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        title:SetPoint("BOTTOMLEFT", dd, "TOPLEFT", 20, 0)
        title:SetText(label)
        UIDropDownMenu_SetWidth(dd, 160)
        UIDropDownMenu_Initialize(dd, function(self, level)
            for _, item in ipairs(items) do
                local info = UIDropDownMenu_CreateInfo()
                info.text = item.text
                info.value = item.value
                info.func = function()
                    UIDropDownMenu_SetSelectedValue(dd, item.value)
                    onSelect(item.value)
                end
                UIDropDownMenu_AddButton(info)
            end
        end)
        UIDropDownMenu_SetSelectedValue(dd, initialValue)
        return dd
    end

    ------------------------------------------------------------
    -- Helper: Create Input Box
    ------------------------------------------------------------
    local function CreateInputBox(parent, label, x, y, width, height, initialText, onEnterPressed)
        local labelFrame = parent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        labelFrame:SetPoint("TOPLEFT", x, y)
        labelFrame:SetText(label)

        local input = CreateFrame("EditBox", nil, parent, "InputBoxTemplate")
        input:SetPoint("TOPLEFT", labelFrame, "BOTTOMLEFT", 0, -5)
        input:SetSize(width, height)
        input:SetText(initialText or "")
        input:SetAutoFocus(false)
        input:SetMaxLetters(100)

        input:SetScript("OnEnterPressed", function(self)
            self:ClearFocus()
            if onEnterPressed then
                onEnterPressed(self:GetText())
            end
        end)

        return input
    end

    ------------------------------------------------------------
    -- Helper: Create Button
    ------------------------------------------------------------
    local function CreateButton(parent, text, x, y, width, height, onClick)
        local button = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
        button:SetPoint("TOPLEFT", x, y)
        button:SetSize(width, height)
        button:SetText(text)
        button:SetScript("OnClick", onClick)
        return button
    end

    ------------------------------------------------------------
    -- Interface Options Panel
    ------------------------------------------------------------
    local panel = CreateFrame("Frame", "BuffActiveOptionsPanel", UIParent)
    panel.name = "BuffActive"

    ------------------------------------------------------------
    -- Display addOn metadata heading
    ------------------------------------------------------------
    local meta = (C_AddOns and C_AddOns.GetAddOnMetadata) or GetAddOnMetadata
    local title = panel:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", 20, -10)
    title:SetText("BuffActive  " .. (meta("BuffActive", "Version") or ""))
    local subtitle = panel:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    subtitle:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -4)
    subtitle:SetText(meta("BuffActive", "Notes") or "")
    local author = panel:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    author:SetPoint("TOPLEFT", subtitle, "BOTTOMLEFT", 0, -2)
    author:SetText("Author: " .. (meta("BuffActive", "Author") or ""))

    -- When the panel is shown, refresh the status text
    panel:SetScript("OnShow", function()
        if ddCheckFrequency then
            UIDropDownMenu_SetSelectedValue(ddCheckFrequency, BuffActiveDB.checkInterval)
        end
        UpdateSpellListDisplay()
    end)

    local category = Settings.RegisterCanvasLayoutCategory(panel, panel.name)
    Settings.RegisterAddOnCategory(category)

    ------------------------------------------------------------
    -- Helper: Create Checkbox
    ------------------------------------------------------------
    local function CreateCheckbox(parent, label, tooltip, x, y, initial, onClick)
        local cb = CreateFrame("CheckButton", nil, parent, "InterfaceOptionsCheckButtonTemplate")
        cb:SetPoint("TOPLEFT", x, y)
        cb.Text:SetText(label)
        cb.tooltipText = tooltip
        cb:SetChecked(initial)
        cb:SetScript("OnClick", function(self)
            onClick(self:GetChecked())
        end)
        return cb
    end

    ------------------------------------------------------------
    -- Helper: Create Dropdown
    ------------------------------------------------------------
    local function CreateDropdown(parent, label, items, initialValue, onSelect, x, y)
        local dd = CreateFrame("Frame", nil, parent, "UIDropDownMenuTemplate")
        dd:SetPoint("TOPLEFT", x, y)
        local title = parent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        title:SetPoint("BOTTOMLEFT", dd, "TOPLEFT", 20, 0)
        title:SetText(label)
        UIDropDownMenu_SetWidth(dd, 160)
        UIDropDownMenu_Initialize(dd, function(self, level)
            for _, item in ipairs(items) do
                local info = UIDropDownMenu_CreateInfo()
                info.text = item.text
                info.value = item.value
                info.func = function()
                    UIDropDownMenu_SetSelectedValue(dd, item.value)
                    onSelect(item.value)
                end
                UIDropDownMenu_AddButton(info)
            end
        end)
        UIDropDownMenu_SetSelectedValue(dd, initialValue)
        return dd
    end

    ------------------------------------------------------------
    -- Helper: Create Input Box
    ------------------------------------------------------------
    local function CreateInputBox(parent, label, x, y, width, height, initialText, onEnterPressed)
        local labelFrame = parent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        labelFrame:SetPoint("TOPLEFT", x, y)
        labelFrame:SetText(label)

        local input = CreateFrame("EditBox", nil, parent, "InputBoxTemplate")
        input:SetPoint("TOPLEFT", labelFrame, "BOTTOMLEFT", 0, -5)
        input:SetSize(width, height)
        input:SetText(initialText or "")
        input:SetAutoFocus(false)
        input:SetMaxLetters(100)

        input:SetScript("OnEnterPressed", function(self)
            self:ClearFocus()
            if onEnterPressed then
                onEnterPressed(self:GetText())
            end
        end)

        return input
    end

    ------------------------------------------------------------
    -- Helper: Create Button
    ------------------------------------------------------------
    local function CreateButton(parent, text, x, y, width, height, onClick)
        local button = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
        button:SetPoint("TOPLEFT", x, y)
        button:SetSize(width, height)
        button:SetText(text)
        button:SetScript("OnClick", onClick)
        return button
    end

    ------------------------------------------------------------
    -- Helper: Get player's class
    ------------------------------------------------------------
    local function GetPlayerClass()
        local _, class = UnitClass("player")
        return class
    end

    ------------------------------------------------------------
    -- Spell cache to store spell names
    ------------------------------------------------------------
    local spellNameCache = {}

    ------------------------------------------------------------
    -- Helper: Get spell name from spell ID with caching
    ------------------------------------------------------------
    local function GetSpellName(spellID)
        if spellNameCache[spellID] then
            return spellNameCache[spellID]
        end
        
        local info = C_Spell.GetSpellInfo(spellID)
        local name = info and info.name or "Unknown Spell"
        spellNameCache[spellID] = name
        return name
    end



    ------------------------------------------------------------
    -- Helper: Pre-populate spell name cache for default spells
    ------------------------------------------------------------
    local function PopulateSpellNameCache()
        for class, spells in pairs(defaultSpellsByClass) do
            for _, spell in ipairs(spells) do
                GetSpellName(spell.id) -- This will cache the name
            end
        end
    end

    ------------------------------------------------------------
    -- 1. Dropdown: Check frequency
    ------------------------------------------------------------
    ddCheckFrequency = CreateDropdown(
        panel,
        "Check frequency:",
        {
            { text = "1 second", value = 1 },
            { text = "2 seconds (default)", value = 2 },
            { text = "3 seconds", value = 3 },
            { text = "5 seconds", value = 5 },
            { text = "10 seconds", value = 10 },
        },
        BuffActiveDB.checkInterval or 2,  -- Default to 2 if not set
        function(val)
            BuffActiveDB.checkInterval = val
        end,
        20, -72
    )
    local freqHelp = panel:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    freqHelp:SetPoint("TOPLEFT", ddCheckFrequency, "BOTTOMLEFT", 20, -2)
    freqHelp:SetText("How often the addon checks for missing buffs. Lower values update faster but use more resources.")

    ------------------------------------------------------------
    -- 2. Spell Override Section
    ------------------------------------------------------------
    local spellOverrideLabel = panel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    spellOverrideLabel:SetPoint("TOPLEFT", 20, -142)
    spellOverrideLabel:SetText("Spell Override - Current Class Spells:")

    -- Create scrollable frame for spell list
    local spellListFrame = CreateFrame("ScrollFrame", nil, panel, "UIPanelScrollFrameTemplate")
    spellListFrame:SetPoint("TOPLEFT", 20, -170)
    spellListFrame:SetSize(350, 150) -- Fixed height for scrolling
    panel.spellListFrame = spellListFrame

    local spellListScrollChild = CreateFrame("Frame", nil, spellListFrame)
    spellListScrollChild:SetSize(330, 300) -- Height will be adjusted based on content
    spellListFrame:SetScrollChild(spellListScrollChild)
    panel.spellListFrame.scrollChild = spellListScrollChild

    -- Add spell input section
    local addSpellLabel = panel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    addSpellLabel:SetPoint("TOPLEFT", 20, -330)
    addSpellLabel:SetText("Add Custom Spell ID:")

    local spellInput = CreateInputBox(
        panel,
        "Enter Spell ID:",
        20, -355,
        150, 25,
        "",
        function(text)
            local spellID = tonumber(text)
            if spellID then
                local class = GetPlayerClass()
                if not BuffActiveDB.customSpells[class] then
                    BuffActiveDB.customSpells[class] = {}
                end
                -- Check if spell ID is already added
                local alreadyAdded = false
                for _, existingID in ipairs(BuffActiveDB.customSpells[class]) do
                    if existingID == spellID then
                        alreadyAdded = true
                        break
                    end
                end
                if not alreadyAdded then
                    table.insert(BuffActiveDB.customSpells[class], spellID)
                    UpdateSpellListDisplay()
                end
            end
        end
    )

    local addButton = CreateButton(
        panel,
        "Add Spell",
        180, -355,
        80, 25,
        function()
            local spellID = tonumber(spellInput:GetText())
            if spellID then
                local class = GetPlayerClass()
                if not BuffActiveDB.customSpells[class] then
                    BuffActiveDB.customSpells[class] = {}
                end
                -- Check if spell ID is already added
                local alreadyAdded = false
                for _, existingID in ipairs(BuffActiveDB.customSpells[class]) do
                    if existingID == spellID then
                        alreadyAdded = true
                        break
                    end
                end
                if not alreadyAdded then
                    table.insert(BuffActiveDB.customSpells[class], spellID)
                    UpdateSpellListDisplay()
                end
            else
                -- If the spell ID is not valid (not a number), still allow removal via the X button
                -- Invalid spell IDs will appear in the list but won't function properly
                UpdateSpellListDisplay()
            end
        end
    )

    -- Initialize the spell list display
    PopulateSpellNameCache()
    UpdateSpellListDisplay()
end)