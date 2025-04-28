local addonName, addon = ...

-- Initialize the settings panel
function addon.InitializeSettings()
    local category, layout = Settings.RegisterVerticalLayoutCategory(addonName)
    Settings.RegisterAddOnCategory(category)
    addon.categoryID = category:GetID()

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

    -- Armor mappings
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
    end
end