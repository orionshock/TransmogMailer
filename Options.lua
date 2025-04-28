local addonName, addon = ...

-- Class equip restrictions for Cataclysm Classic
local classEquipRestrictions = {
    -- Armor
    [Enum.ItemArmorSubclass.Cloth] = { "MAGE", "PRIEST", "WARLOCK", "DRUID", "HUNTER", "PALADIN", "ROGUE", "SHAMAN", "WARRIOR", "DEATHKNIGHT" },
    [Enum.ItemArmorSubclass.Leather] = { "DRUID", "HUNTER", "ROGUE", "SHAMAN", "WARRIOR", "DEATHKNIGHT", "PALADIN" },
    [Enum.ItemArmorSubclass.Mail] = { "HUNTER", "SHAMAN", "WARRIOR", "PALADIN", "DEATHKNIGHT" },
    [Enum.ItemArmorSubclass.Plate] = { "WARRIOR", "PALADIN", "DEATHKNIGHT" },
    -- Weapons
    [Enum.ItemWeaponSubclass.Axe1H] = { "WARRIOR", "PALADIN", "HUNTER", "SHAMAN", "DEATHKNIGHT" },
    [Enum.ItemWeaponSubclass.Axe2H] = { "WARRIOR", "PALADIN", "HUNTER", "DEATHKNIGHT" },
    [Enum.ItemWeaponSubclass.Mace1H] = { "WARRIOR", "PALADIN", "PRIEST", "SHAMAN", "DRUID", "DEATHKNIGHT" },
    [Enum.ItemWeaponSubclass.Mace2H] = { "WARRIOR", "PALADIN", "DRUID", "DEATHKNIGHT" },
    [Enum.ItemWeaponSubclass.Sword1H] = { "WARRIOR", "PALADIN", "HUNTER", "ROGUE", "DEATHKNIGHT", "MAGE", "WARLOCK" },
    [Enum.ItemWeaponSubclass.Sword2H] = { "WARRIOR", "PALADIN", "DEATHKNIGHT" },
    [Enum.ItemWeaponSubclass.Staff] = { "DRUID", "HUNTER", "MAGE", "PRIEST", "SHAMAN", "WARLOCK", "WARRIOR" },
    [Enum.ItemWeaponSubclass.Polearm] = { "WARRIOR", "PALADIN", "HUNTER", "DRUID", "DEATHKNIGHT" },
    [Enum.ItemWeaponSubclass.Bows] = { "HUNTER", "WARRIOR", "ROGUE" },
    [Enum.ItemWeaponSubclass.Crossbow] = { "HUNTER", "WARRIOR", "ROGUE" },
    [Enum.ItemWeaponSubclass.Guns] = { "HUNTER", "WARRIOR", "ROGUE" },
    [Enum.ItemWeaponSubclass.Dagger] = { "HUNTER", "ROGUE", "PRIEST", "SHAMAN", "MAGE", "WARLOCK", "WARRIOR" },
    [Enum.ItemWeaponSubclass.Unarmed] = { "WARRIOR", "HUNTER", "ROGUE", "SHAMAN", "DRUID" },
    [Enum.ItemWeaponSubclass.Wand] = { "MAGE", "PRIEST", "WARLOCK" }
}

-- Armor and weapon types
local armorTypes = {
    {key = Enum.ItemArmorSubclass.Cloth, label = GetItemSubClassInfo(LE_ITEM_CLASS_ARMOR, Enum.ItemArmorSubclass.Cloth) or "Cloth"},
    {key = Enum.ItemArmorSubclass.Leather, label = GetItemSubClassInfo(LE_ITEM_CLASS_ARMOR, Enum.ItemArmorSubclass.Leather) or "Leather"},
    {key = Enum.ItemArmorSubclass.Mail, label = GetItemSubClassInfo(LE_ITEM_CLASS_ARMOR, Enum.ItemArmorSubclass.Mail) or "Mail"},
    {key = Enum.ItemArmorSubclass.Plate, label = GetItemSubClassInfo(LE_ITEM_CLASS_ARMOR, Enum.ItemArmorSubclass.Plate) or "Plate"}
}

local weaponTypes = {
    {key = Enum.ItemWeaponSubclass.Axe1H, label = GetItemSubClassInfo(LE_ITEM_CLASS_WEAPON, Enum.ItemWeaponSubclass.Axe1H) or "One-Handed Axe"},
    {key = Enum.ItemWeaponSubclass.Axe2H, label = GetItemSubClassInfo(LE_ITEM_CLASS_WEAPON, Enum.ItemWeaponSubclass.Axe2H) or "Two-Handed Axe"},
    {key = Enum.ItemWeaponSubclass.Mace1H, label = GetItemSubClassInfo(LE_ITEM_CLASS_WEAPON, Enum.ItemWeaponSubclass.Mace1H) or "One-Handed Mace"},
    {key = Enum.ItemWeaponSubclass.Mace2H, label = GetItemSubClassInfo(LE_ITEM_CLASS_WEAPON, Enum.ItemWeaponSubclass.Mace2H) or "Two-Handed Mace"},
    {key = Enum.ItemWeaponSubclass.Sword1H, label = GetItemSubClassInfo(LE_ITEM_CLASS_WEAPON, Enum.ItemWeaponSubclass.Sword1H) or "One-Handed Sword"},
    {key = Enum.ItemWeaponSubclass.Sword2H, label = GetItemSubClassInfo(LE_ITEM_CLASS_WEAPON, Enum.ItemWeaponSubclass.Sword2H) or "Two-Handed Sword"},
    {key = Enum.ItemWeaponSubclass.Staff, label = GetItemSubClassInfo(LE_ITEM_CLASS_WEAPON, Enum.ItemWeaponSubclass.Staff) or "Staff"},
    {key = Enum.ItemWeaponSubclass.Polearm, label = GetItemSubClassInfo(LE_ITEM_CLASS_WEAPON, Enum.ItemWeaponSubclass.Polearm) or "Polearm"},
    {key = Enum.ItemWeaponSubclass.Bows, label = GetItemSubClassInfo(LE_ITEM_CLASS_WEAPON, Enum.ItemWeaponSubclass.Bows) or "Bows"},
    {key = Enum.ItemWeaponSubclass.Crossbow, label = GetItemSubClassInfo(LE_ITEM_CLASS_WEAPON, Enum.ItemWeaponSubclass.Crossbow) or "Crossbow"},
    {key = Enum.ItemWeaponSubclass.Guns, label = GetItemSubClassInfo(LE_ITEM_CLASS_WEAPON, Enum.ItemWeaponSubclass.Guns) or "Guns"},
    {key = Enum.ItemWeaponSubclass.Dagger, label = GetItemSubClassInfo(LE_ITEM_CLASS_WEAPON, Enum.ItemWeaponSubclass.Dagger) or "Dagger"},
    {key = Enum.ItemWeaponSubclass.Unarmed, label = GetItemSubClassInfo(LE_ITEM_CLASS_WEAPON, Enum.ItemWeaponSubclass.Unarmed) or "Fist Weapon"},
    {key = Enum.ItemWeaponSubclass.Wand, label = GetItemSubClassInfo(LE_ITEM_CLASS_WEAPON, Enum.ItemWeaponSubclass.Wand) or "Wand"}
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
            if addon.db.characters[currentRealm] and addon.db.characters[currentRealm][currentFaction] then
                for name, class in pairs(addon.db.characters[currentRealm][currentFaction]) do
                    if tContains(classEquipRestrictions[armor.key], class) then
                        container:Add(name, name, "Send to " .. name)
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
            if addon.db.characters[currentRealm] and addon.db.characters[currentRealm][currentFaction] then
                for name, class in pairs(addon.db.characters[currentRealm][currentFaction]) do
                    if tContains(classEquipRestrictions[weapon.key], class) then
                        container:Add(name, name, "Send to " .. name)
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