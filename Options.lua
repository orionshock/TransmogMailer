local addonName, addon = ...

-- Static popup for character deletion confirmation
StaticPopupDialogs["TRANSMOGMAILER_CONFIRM_DELETE_CHARACTER"] = {
    text = "Are you sure you want to delete %s from TransmogMailer? This will reset all mappings for this character to None.",
    button1 = "Yes",
    button2 = "No",
    OnAccept = function(self, data)
        local characterName = data.characterName
        local currentRealm = GetNormalizedRealmName()
        local currentFaction = UnitFactionGroup("player")
        
        -- Remove character from addon.db.characters
        if addon.db.characters and addon.db.characters[currentRealm] and addon.db.characters[currentRealm][currentFaction] then
            addon.db.characters[currentRealm][currentFaction][characterName] = nil
        end
        
        -- Reset mappings that reference the deleted character to "_none"
        for key, value in pairs(addon.db.mappings) do
            if value == characterName then
                addon.db.mappings[key] = "_none"
            end
        end
        
        -- Update dropdowns that reference the deleted character
        for _, initializer in ipairs(addon.dependentInitializers) do
            local setting = initializer:GetSetting()
            if setting and setting:GetValue() == characterName then
                setting:SetValue("_none")
            end
        end
        
        -- Reset the cleanup dropdown to default
        addon.cleanupSetting:SetValue("")
    end,
    timeout = 0,
    whileDead = true,
    hideOnEscape = true
}

-- Initialize the settings panel
function addon.InitializeSettings()
    local category, layout = Settings.RegisterVerticalLayoutCategory(addonName)
    Settings.RegisterAddOnCategory(category)
    addon.categoryID = category:GetID()
    
    -- Store dependent initializers for armor and weapon dropdowns
    addon.dependentInitializers = {}

    -- Modifier key dropdown
    local function GetModifierOptions()
        local container = Settings.CreateControlTextContainer()
        container:Add("NONE", "None", "Disable mailing functionality")
        container:Add("SHIFT", "Shift", "Use Shift key as modifier")
        container:Add("CTRL", "Ctrl", "Use Ctrl key as modifier")
        container:Add("ALT", "Alt", "Use Alt key as modifier")
        return container:GetData()
    end
    
    local modifierSetting = Settings.RegisterProxySetting(category, "modifier", Settings.VarType.String, "Modifier Key", "NONE",
        function() return addon.db.modifier end,
        function(value) addon.db.modifier = value end
    )
    local modifierInitializer = Settings.CreateDropdown(category, modifierSetting, GetModifierOptions, "Select the modifier key for mailing transmog items")
    modifierInitializer.reinitializeOnValueChanged = true

    -- Armor mappings (including offhand and shield)
    layout:AddInitializer(CreateSettingsListSectionHeaderInitializer("Armor Recipients"))
    for _, armor in ipairs(addon.armorTypes) do
        local function GetArmorOptions()
            local container = Settings.CreateControlTextContainer()
            container:Add("_none", "None", "No recipient selected")
            local currentRealm = GetNormalizedRealmName()
            local currentFaction = UnitFactionGroup("player")
            if addon.db.characters and currentRealm and currentFaction and addon.db.characters[currentRealm] and addon.db.characters[currentRealm][currentFaction] then
                for name, class in pairs(addon.db.characters[currentRealm][currentFaction]) do
                    if armor.equipClasses and tContains(armor.equipClasses, class) then
                        local displayName = name
                        if RAID_CLASS_COLORS and RAID_CLASS_COLORS[class] and RAID_CLASS_COLORS[class].colorStr then
                            displayName = "|c" .. RAID_CLASS_COLORS[class].colorStr .. name .. "|r"
                        end
                        container:Add(name, displayName, "Send to " .. name)
                    end
                end
            end
            return container:GetData()
        end
        
        local setting = Settings.RegisterProxySetting(category, "armor_" .. armor.key, Settings.VarType.String, armor.label .. " Recipient", "_none",
            function() 
                local value = addon.db.mappings["armor_" .. armor.key]
                return (value == nil or value == "") and "_none" or value 
            end,
            function(value) addon.db.mappings["armor_" .. armor.key] = value end
        )
        local initializer = Settings.CreateDropdown(category, setting, GetArmorOptions, "Select the character to receive " .. armor.label .. " items")
        initializer.reinitializeOnValueChanged = true
        table.insert(addon.dependentInitializers, initializer)
    end

    -- Weapon mappings
    layout:AddInitializer(CreateSettingsListSectionHeaderInitializer("Weapon Recipients"))
    for _, weapon in ipairs(addon.weaponTypes) do
        local function GetWeaponOptions()
            local container = Settings.CreateControlTextContainer()
            container:Add("_none", "None", "No recipient selected")
            local currentRealm = GetNormalizedRealmName()
            local currentFaction = UnitFactionGroup("player")
            if addon.db.characters and currentRealm and currentFaction and addon.db.characters[currentRealm] and addon.db.characters[currentRealm][currentFaction] then
                for name, class in pairs(addon.db.characters[currentRealm][currentFaction]) do
                    if weapon.equipClasses and tContains(weapon.equipClasses, class) then
                        local displayName = name
                        if RAID_CLASS_COLORS and RAID_CLASS_COLORS[class] and RAID_CLASS_COLORS[class].colorStr then
                            displayName = "|c" .. RAID_CLASS_COLORS[class].colorStr .. name .. "|r"
                        end
                        container:Add(name, displayName, "Send to " .. name)
                    end
                end
            end
            return container:GetData()
        end
        
        local setting = Settings.RegisterProxySetting(category, "weapon_" .. weapon.key, Settings.VarType.String, weapon.label .. " Recipient", "_none",
            function() 
                local value = addon.db.mappings["weapon_" .. weapon.key]
                return (value == nil or value == "") and "_none" or value 
            end,
            function(value) addon.db.mappings["weapon_" .. weapon.key] = value end
        )
        local initializer = Settings.CreateDropdown(category, setting, GetWeaponOptions, "Select the character to receive " .. weapon.label .. " items")
        initializer.reinitializeOnValueChanged = true
        table.insert(addon.dependentInitializers, initializer)
    end

    -- Character cleanup section
    layout:AddInitializer(CreateSettingsListSectionHeaderInitializer("Character Cleanup"))
    
    local function GetCharacterOptions()
        local container = Settings.CreateControlTextContainer()
        container:Add("", "Select a character", "Choose a character to delete")
        local currentRealm = GetNormalizedRealmName()
        local currentFaction = UnitFactionGroup("player")
        if addon.db.characters and currentRealm and currentFaction and addon.db.characters[currentRealm] and addon.db.characters[currentRealm][currentFaction] then
            for name, class in pairs(addon.db.characters[currentRealm][currentFaction]) do
                if name ~= UnitName("player") then
                    local displayName = name
                    if RAID_CLASS_COLORS and RAID_CLASS_COLORS[class] and RAID_CLASS_COLORS[class].colorStr then
                        displayName = "|c" .. RAID_CLASS_COLORS[class].colorStr .. name .. "|r"
                    end
                    container:Add(name, displayName, "Delete " .. name)
                end
            end
        end
        return container:GetData()
    end
    
    local cleanupSetting = Settings.RegisterProxySetting(category, "cleanup_character", Settings.VarType.String, "Character to Delete", "",
        function() return addon.cleanupValue or "" end,
        function(value)
            addon.cleanupValue = value
            if value and value ~= "" and value ~= UnitName("player") then
                StaticPopup_Show("TRANSMOGMAILER_CONFIRM_DELETE_CHARACTER", value, nil, {characterName = value})
            end
        end
    )
    addon.cleanupSetting = cleanupSetting -- Store for access in StaticPopup OnAccept
    local cleanupInitializer = Settings.CreateDropdown(category, cleanupSetting, GetCharacterOptions, "Select a character to delete from TransmogMailer")
    cleanupInitializer.reinitializeOnValueChanged = true
end