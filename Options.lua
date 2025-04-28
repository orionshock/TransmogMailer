local addonName, addon = ...

-- Armor types with class restrictions for Cataclysm Classic
local armorTypes = {
    {key = Enum.ItemArmorSubclass.Cloth, label = GetItemSubClassInfo(LE_ITEM_CLASS_ARMOR, Enum.ItemArmorSubclass.Cloth) or "Cloth", equipClasses = {"MAGE", "PRIEST", "WARLOCK"}},
    {key = Enum.ItemArmorSubclass.Leather, label = GetItemSubClassInfo(LE_ITEM_CLASS_ARMOR, Enum.ItemArmorSubclass.Leather) or "Leather", equipClasses = {"DRUID", "ROGUE"}},
    {key = Enum.ItemArmorSubclass.Mail, label = GetItemSubClassInfo(LE_ITEM_CLASS_ARMOR, Enum.ItemArmorSubclass.Mail) or "Mail", equipClasses = {"HUNTER", "SHAMAN"}},
    {key = Enum.ItemArmorSubclass.Plate, label = GetItemSubClassInfo(LE_ITEM_CLASS_ARMOR, Enum.ItemArmorSubclass.Plate) or "Plate", equipClasses = {"WARRIOR", "PALADIN", "DEATHKNIGHT"}}
}

-- Weapon types with class restrictions for Cataclysm Classic
local weaponTypes = {
    {key = Enum.ItemWeaponSubclass.Axe1H, label = GetItemSubClassInfo(LE_ITEM_CLASS_WEAPON, Enum.ItemWeaponSubclass.Axe1H) or "One-Handed Axe", equipClasses = {"WARRIOR", "PALADIN", "HUNTER", "SHAMAN", "DEATHKNIGHT"}},
    {key = Enum.ItemWeaponSubclass.Axe2H, label = GetItemSubClassInfo(LE_ITEM_CLASS_WEAPON, Enum.ItemWeaponSubclass.Axe2H) or "Two-Handed Axe", equipClasses = {"WARRIOR", "PALADIN", "HUNTER", "DEATHKNIGHT"}},
    {key = Enum.ItemWeaponSubclass.Mace1H, label = GetItemSubClassInfo(LE_ITEM_CLASS_WEAPON, Enum.ItemWeaponSubclass.Mace1H) or "One-Handed Mace", equipClasses = {"WARRIOR", "PALADIN", "PRIEST", "SHAMAN", "DRUID", "DEATHKNIGHT"}},
    {key = Enum.ItemWeaponSubclass.Mace2H, label = GetItemSubClassInfo(LE_ITEM_CLASS_WEAPON, Enum.ItemWeaponSubclass.Mace2H) or "Two-Handed Mace", equipClasses = {"WARRIOR", "PALADIN", "DRUID", "DEATHKNIGHT"}},
    {key = Enum.ItemWeaponSubclass.Sword1H, label = GetItemSubClassInfo(LE_ITEM_CLASS_WEAPON, Enum.ItemWeaponSubclass.Sword1H) or "One-Handed Sword", equipClasses = {"WARRIOR", "PALADIN", "HUNTER", "ROGUE", "DEATHKNIGHT", "MAGE", "WARLOCK"}},
    {key = Enum.ItemWeaponSubclass.Sword2H, label = GetItemSubClassInfo(LE_ITEM_CLASS_WEAPON, Enum.ItemWeaponSubclass.Sword2H) or "Two-Handed Sword", equipClasses = {"WARRIOR", "PALADIN", "DEATHKNIGHT"}},
    {key = Enum.ItemWeaponSubclass.Staff, label = GetItemSubClassInfo(LE_ITEM_CLASS_WEAPON, Enum.ItemWeaponSubclass.Staff) or "Staff", equipClasses = {"DRUID", "HUNTER", "MAGE", "PRIEST", "SHAMAN", "WARLOCK", "WARRIOR"}},
    {key = Enum.ItemWeaponSubclass.Polearm, label = GetItemSubClassInfo(LE_ITEM_CLASS_WEAPON, Enum.ItemWeaponSubclass.Polearm) or "Polearm", equipClasses = {"WARRIOR", "PALADIN", "HUNTER", "DRUID", "DEATHKNIGHT"}},
    {key = Enum.ItemWeaponSubclass.Bows, label = GetItemSubClassInfo(LE_ITEM_CLASS_WEAPON, Enum.ItemWeaponSubclass.Bows) or "Bows", equipClasses = {"HUNTER", "WARRIOR", "ROGUE"}},
    {key = Enum.ItemWeaponSubclass.Crossbow, label = GetItemSubClassInfo(LE_ITEM_CLASS_WEAPON, Enum.ItemWeaponSubclass.Crossbow) or "Crossbow", equipClasses = {"HUNTER", "WARRIOR", "ROGUE"}},
    {key = Enum.ItemWeaponSubclass.Guns, label = GetItemSubClassInfo(LE_ITEM_CLASS_WEAPON, Enum.ItemWeaponSubclass.Guns) or "Guns", equipClasses = {"HUNTER", "WARRIOR", "ROGUE"}},
    {key = Enum.ItemWeaponSubclass.Dagger, label = GetItemSubClassInfo(LE_ITEM_CLASS_WEAPON, Enum.ItemWeaponSubclass.Dagger) or "Dagger", equipClasses = {"HUNTER", "ROGUE", "PRIEST", "SHAMAN", "MAGE", "WARLOCK", "WARRIOR"}},
    {key = Enum.ItemWeaponSubclass.Unarmed, label = GetItemSubClassInfo(LE_ITEM_CLASS_WEAPON, Enum.ItemWeaponSubclass.Unarmed) or "Fist Weapon", equipClasses = {"WARRIOR", "HUNTER", "ROGUE", "SHAMAN", "DRUID"}},
    {key = Enum.ItemWeaponSubclass.Wand, label = GetItemSubClassInfo(LE_ITEM_CLASS_WEAPON, Enum.ItemWeaponSubclass.Wand) or "Wand", equipClasses = {"MAGE", "PRIEST", "WARLOCK"}}
}

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
    for _, armor in ipairs(armorTypes) do
        local function GetArmorOptions()
            local container = Settings.CreateControlTextContainer()
            container:Add("", "None", "No recipient selected")
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
        
        local setting = Settings.RegisterProxySetting(category, "armor_" .. armor.key, Settings.VarType.String, armor.label .. " Recipient", "",
            function() return addon.db.mappings[armor.key] or "" end,
            function(value) addon.db.mappings[armor.key] = value end
        )
        local initializer = Settings.CreateDropdown(category, setting, GetArmorOptions, "Select the character to receive " .. armor.label .. " items")
        initializer.reinitializeOnValueChanged = true
    end

    -- Weapon mappings
    layout:AddInitializer(CreateSettingsListSectionHeaderInitializer("Weapon Recipients"))
    for _, weapon in ipairs(weaponTypes) do
        local function GetWeaponOptions()
            local container = Settings.CreateControlTextContainer()
            container:Add("", "None", "No recipient selected")
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
        
        local setting = Settings.RegisterProxySetting(category, "weapon_" .. weapon.key, Settings.VarType.String, weapon.label .. " Recipient", "",
            function() return addon.db.mappings[weapon.key] or "" end,
            function(value) addon.db.mappings[weapon.key] = value end
        )
        local initializer = Settings.CreateDropdown(category, setting, GetWeaponOptions, "Select the character to receive " .. weapon.label .. " items")
        initializer.reinitializeOnValueChanged = true
    end
end