local addonName, addon = ...

StaticPopupDialogs["TRANSMOGMAILER_CONFIRM_DELETE_CHARACTER"] = {
    text =
    "Are you sure you want to delete %s from TransmogMailer? This will reset all mappings for this character to None.",
    button1 = "Yes",
    button2 = "No",
    --- Deletes selected character from tracking and clears related mappings.
    --- @param self any Popup frame.
    --- @param data table Payload containing characterName.
    --- @return nil
    OnAccept = function(self, data)
        local characterName = data.characterName
        local currentRealm = GetNormalizedRealmName()
        local currentFaction = UnitFactionGroup("player")

        if addon.db.characters and addon.db.characters[currentRealm] and addon.db.characters[currentRealm][currentFaction] then
            addon.db.characters[currentRealm][currentFaction][characterName] = nil
        end

        for key, value in pairs(addon.db.mappings) do
            if value == characterName then
                addon.db.mappings[key] = "_none"
            end
        end

        for _, initializer in ipairs(addon.dependentInitializers) do
            local setting = initializer:GetSetting()
            if setting and setting:GetValue() == characterName then
                setting:SetValue("_none")
            end
        end

        addon.cleanupSetting:SetValue("")
    end,
    timeout = 0,
    whileDead = true,
    hideOnEscape = true
}

--- Registers addon settings controls and mapping dropdowns.
--- @return nil
function addon.InitializeSettings()
    local category, layout = Settings.RegisterVerticalLayoutCategory(addonName)
    Settings.RegisterAddOnCategory(category)
    addon.categoryID = category:GetID()

    addon.dependentInitializers = {}

    --- Builds dropdown options for mailbox modifier key behavior.
    --- @return table options Modifier key option list.
    local function GetModifierOptions()
        local container = Settings.CreateControlTextContainer()
        container:Add("NONE", "None", "Disable mailing functionality")
        container:Add("SHIFT", "Shift", "Use Shift key as modifier")
        container:Add("CTRL", "Ctrl", "Use Ctrl key as modifier")
        container:Add("ALT", "Alt", "Use Alt key as modifier")
        return container:GetData()
    end

    local modifierSetting = Settings.RegisterProxySetting(category, "modifier", Settings.VarType.String, "Modifier Key",
        "NONE",
        function() return addon.db.modifier end,
        function(value) addon.db.modifier = value end
    )
    local modifierInitializer = Settings.CreateDropdown(category, modifierSetting, GetModifierOptions,
        "Select the modifier key for mailing transmog items")
    modifierInitializer.reinitializeOnValueChanged = true

    layout:AddInitializer(CreateSettingsListSectionHeaderInitializer("Armor Recipients"))
    for armorKey, armorInfo in pairs(addon.armorTypes) do
        --- Builds recipient options for an armor subclass mapping.
        --- @return table options Armor recipient option list.
        local function GetArmorOptions()
            local container = Settings.CreateControlTextContainer()
            container:Add("_none", "None", "No recipient selected")
            local currentRealm = GetNormalizedRealmName()
            local currentFaction = UnitFactionGroup("player")
            if addon.db.characters and currentRealm and currentFaction and addon.db.characters[currentRealm] and addon.db.characters[currentRealm][currentFaction] then
                for name, class in pairs(addon.db.characters[currentRealm][currentFaction]) do
                    if armorInfo.equipClasses and tContains(armorInfo.equipClasses, class) then
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

        local setting = Settings.RegisterProxySetting(category, "armor_" .. armorKey, Settings.VarType.String,
            armorInfo.label .. " Recipient", "_none",
            function()
                local value = addon.db.mappings["armor_" .. armorKey]
                return (value == nil or value == "") and "_none" or value
            end,
            function(value) addon.db.mappings["armor_" .. armorKey] = value end
        )
        local desc = "Select the character to receive " .. armorInfo.label .. " items."
        if armorInfo.desc then
            desc = desc .. "\n" .. armorInfo.desc
        end
        local initializer = Settings.CreateDropdown(category, setting, GetArmorOptions, desc)
        table.insert(addon.dependentInitializers, initializer)
    end

    layout:AddInitializer(CreateSettingsListSectionHeaderInitializer("Weapon Recipients"))
    for weaponKey, weaponInfo in pairs(addon.weaponTypes) do
        if not weaponInfo.disabled == true then
            --- Builds recipient options for a weapon subclass mapping.
            --- @return table options Weapon recipient option list.
            local function GetWeaponOptions()
                local container = Settings.CreateControlTextContainer()
                container:Add("_none", "None", "No recipient selected")
                local currentRealm = GetNormalizedRealmName()
                local currentFaction = UnitFactionGroup("player")
                if addon.db.characters and currentRealm and currentFaction and addon.db.characters[currentRealm] and addon.db.characters[currentRealm][currentFaction] then
                    for name, class in pairs(addon.db.characters[currentRealm][currentFaction]) do
                        if weaponInfo.equipClasses and tContains(weaponInfo.equipClasses, class) then
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

            local setting = Settings.RegisterProxySetting(category, "weapon_" .. weaponKey, Settings.VarType.String,
                weaponInfo.label .. " Recipient", "_none",
                function()
                    local value = addon.db.mappings["weapon_" .. weaponKey]
                    return (value == nil or value == "") and "_none" or value
                end,
                function(value)
                    addon.db.mappings["weapon_" .. weaponKey] = value
                end
            )
            local desc = "Select the character to receive " .. weaponInfo.label .. " items."
            if weaponInfo.desc then
                desc = desc .. "\n" .. weaponInfo.desc
            end
            local initializer = Settings.CreateDropdown(category, setting, GetWeaponOptions, desc)
            table.insert(addon.dependentInitializers, initializer)
        end
    end

    layout:AddInitializer(CreateSettingsListSectionHeaderInitializer("Character Cleanup"))

    --- Builds selectable characters for cleanup operations.
    --- @return table options Character cleanup option list.
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

    local cleanupSetting = Settings.RegisterProxySetting(category, "cleanup_character", Settings.VarType.String,
        "Character to Delete", "",
        function() return addon.cleanupValue or "" end,
        function(value)
            addon.cleanupValue = value
            if value and value ~= "" and value ~= UnitName("player") then
                StaticPopup_Show("TRANSMOGMAILER_CONFIRM_DELETE_CHARACTER", value, nil, { characterName = value })
            end
        end
    )
    addon.cleanupSetting = cleanupSetting
    local cleanupInitializer = Settings.CreateDropdown(category, cleanupSetting, GetCharacterOptions,
        "Select a character to delete from TransmogMailer")
end
