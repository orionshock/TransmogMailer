-- Options.lua
local addonName, addon = ...

addon.db = TransmogMailerDB or { modifier = "SHIFT", mappings = {}, characters = {} }

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
    local modifierSetting = Settings.RegisterProxySetting(category, "modifier", Settings.DefaultVarLocation, Settings.VarType.String, "Modifier Key", "SHIFT")
    layout:AddInitializer(Settings.CreateDropdown(category, modifierSetting, function()
        return {
            { text = "Shift", value = "SHIFT" },
            { text = "Ctrl", value = "CTRL" },
            { text = "Alt", value = "ALT" }
        }
    end, "Modifier Key"))

    -- Armor mappings
    layout:AddInitializer(CreateSettingsListSectionHeaderInitializer("Armor Recipients"))
    for _, armor in ipairs(armorTypes) do
        local setting = Settings.RegisterProxySetting(category, "mapping_" .. armor.key, Settings.DefaultVarLocation, Settings.VarType.String, armor.label .. " Recipient", "")
        layout:AddInitializer(Settings.CreateDropdown(category, setting, function()
            local options = { { text = "None", value = "" } }
            local currentRealm = GetNormalizedRealmName()
            local currentFaction = UnitFactionGroup("player")
            for _, char in ipairs(addon.db.characters or {}) do
                if char.realm == currentRealm and char.faction == currentFaction and tContains(classEquipRestrictions[armor.key], char.class) then
                    table.insert(options, { text = char.name, value = char.name })
                end
            end
            return options
        end, armor.label))
        -- Sync setting to addon.db.mappings
        setting:OnValueChanged(function(value)
            addon.db.mappings[armor.key] = value
        end)
        -- Initialize from saved value
        if addon.db.mappings[armor.key] then
            setting:SetValue(addon.db.mappings[armor.key])
        end
    end

    -- Weapon mappings
    layout:AddInitializer(CreateSettingsListSectionHeaderInitializer("Weapon Recipients"))
    for _, weapon in ipairs(weaponTypes) do
        local setting = Settings.RegisterProxySetting(category, "mapping_" .. weapon.key, Settings.DefaultVarLocation, Settings.VarType.String, weapon.label .. " Recipient", "")
        layout:AddInitializer(Settings.CreateDropdown(category, setting, function()
            local options = { { text = "None", value = "" } }
            local currentRealm = GetNormalizedRealmName()
            local currentFaction = UnitFactionGroup("player")
            for _, char in ipairs(addon.db.characters or {}) do
                if char.realm == currentRealm and char.faction == currentFaction and tContains(classEquipRestrictions[weapon.key], char.class) then
                    table.insert(options, { text = char.name, value = char.name })
                end
            end
            return options
        end, weapon.label))
        -- Sync setting to addon.db.mappings
        setting:OnValueChanged(function(value)
            addon.db.mappings[weapon.key] = value
        end)
        -- Initialize from saved value
        if addon.db.mappings[weapon.key] then
            setting:SetValue(addon.db.mappings[weapon.key])
        end
    end
end

-- Initialize settings on load
local frame = CreateFrame("Frame")
frame:RegisterEvent("ADDON_LOADED")
frame:SetScript("OnEvent", function(self, event, arg1)
    if event == "ADDON_LOADED" and arg1 == addonName then
        -- Ensure saved variables are initialized
        addon.db.mappings = addon.db.mappings or {}
        addon.db.characters = addon.db.characters or {}
        addon.InitializeSettings()
        self:UnregisterEvent("ADDON_LOADED")
    end
end)