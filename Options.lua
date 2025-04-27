-- Options.lua
local addonName = "TransmogMailer"
local frame = CreateFrame("Frame", addonName .. "Options", InterfaceOptionsFramePanelContainer)
frame.name = addonName
frame:Hide()

-- Initialize the options UI
frame:SetScript("OnShow", function(self)
    local title = self:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", 10, -10)
    title:SetText("TransmogMailer Options")

    -- Modifier key button and menu
    local modifierLabel = self:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    modifierLabel:SetPoint("TOPLEFT", 10, -40)
    modifierLabel:SetText("Modifier Key:")

    local modifierButton = CreateFrame("Button", addonName .. "ModifierButton", self, "UIPanelButtonTemplate")
    modifierButton:SetPoint("TOPLEFT", 120, -35)
    modifierButton:SetSize(100, 22)
    modifierButton:SetText(TransmogMailerDB.modifier or "SHIFT")

    local modifierMenu = CreateFrame("Frame", addonName .. "ModifierMenu", self, "MenuFrameTemplate")
    modifierMenu:SetPoint("TOPLEFT", modifierButton, "BOTTOMLEFT", 0, 0)
    modifierMenu:Hide()

    local function UpdateModifierButton(modifier)
        TransmogMailerDB.modifier = modifier
        modifierButton:SetText(modifier)
    end

    -- Define menu options
    local modifierOptions = {
        { text = "SHIFT", func = function() UpdateModifierButton("SHIFT") end },
        { text = "CTRL", func = function() UpdateModifierButton("CTRL") end },
        { text = "ALT", func = function() UpdateModifierButton("ALT") end },
    }

    -- Populate the menu
    for _, option in ipairs(modifierOptions) do
        Menu.ModifyMenu("MENU_" .. addonName .. "ModifierMenu", function(owner, rootDescription)
            rootDescription:CreateButton(option.text, option.func)
        end)
    end

    modifierButton:SetScript("OnClick", function()
        Menu.OpenMenu(modifierMenu, modifierButton)
    end)

    -- Armor class mappings
    local armorTypes = {
        {key = Enum.ItemArmorSubclass.Cloth, label = GetItemSubClassInfo(LE_ITEM_CLASS_ARMOR, Enum.ItemArmorSubclass.Cloth)},
        {key = Enum.ItemArmorSubclass.Leather, label = GetItemSubClassInfo(LE_ITEM_CLASS_ARMOR, Enum.ItemArmorSubclass.Leather)},
        {key = Enum.ItemArmorSubclass.Mail, label = GetItemSubClassInfo(LE_ITEM_CLASS_ARMOR, Enum.ItemArmorSubclass.Mail)},
        {key = Enum.ItemArmorSubclass.Plate, label = GetItemSubClassInfo(LE_ITEM_CLASS_ARMOR, Enum.ItemArmorSubclass.Plate)}
    }

    -- Weapon type mappings
    local weaponTypes = {
        {key = Enum.ItemWeaponSubclass.Axe1H, label = GetItemSubClassInfo(LE_ITEM_CLASS_WEAPON, Enum.ItemWeaponSubclass.Axe1H)},
        {key = Enum.ItemWeaponSubclass.Axe2H, label = GetItemSubClassInfo(LE_ITEM_CLASS_WEAPON, Enum.ItemWeaponSubclass.Axe2H)},
        {key = Enum.ItemWeaponSubclass.Mace1H, label = GetItemSubClassInfo(LE_ITEM_CLASS_WEAPON, Enum.ItemWeaponSubclass.Mace1H)},
        {key = Enum.ItemWeaponSubclass.Mace2H, label = GetItemSubClassInfo(LE_ITEM_CLASS_WEAPON, Enum.ItemWeaponSubclass.Mace2H)},
        {key = Enum.ItemWeaponSubclass.Sword1H, label = GetItemSubClassInfo(LE_ITEM_CLASS_WEAPON, Enum.ItemWeaponSubclass.Sword1H)},
        {key = Enum.ItemWeaponSubclass.Sword2H, label = GetItemSubClassInfo(LE_ITEM_CLASS_WEAPON, Enum.ItemWeaponSubclass.Sword2H)},
        {key = Enum.ItemWeaponSubclass.Staff, label = GetItemSubClassInfo(LE_ITEM_CLASS_WEAPON, Enum.ItemWeaponSubclass.Staff)},
        {key = Enum.ItemWeaponSubclass.Polearm, label = GetItemSubClassInfo(LE_ITEM_CLASS_WEAPON, Enum.ItemWeaponSubclass.Polearm)},
        {key = Enum.ItemWeaponSubclass.Bow, label = GetItemSubClassInfo(LE_ITEM_CLASS_WEAPON, Enum.ItemWeaponSubclass.Bow)},
        {key = Enum.ItemWeaponSubclass.Crossbow, label = GetItemSubClassInfo(LE_ITEM_CLASS_WEAPON, Enum.ItemWeaponSubclass.Crossbow)},
        {key = Enum.ItemWeaponSubclass.Gun, label = GetItemSubClassInfo(LE_ITEM_CLASS_WEAPON, Enum.ItemWeaponSubclass.Gun)},
        {key = Enum.ItemWeaponSubclass.Dagger, label = GetItemSubClassInfo(LE_ITEM_CLASS_WEAPON, Enum.ItemWeaponSubclass.Dagger)},
        {key = Enum.ItemWeaponSubclass.Unarmed, label = GetItemSubClassInfo(LE_ITEM_CLASS_WEAPON, Enum.ItemWeaponSubclass.Unarmed)},
        {key = Enum.ItemWeaponSubclass.Wand, label = GetItemSubClassInfo(LE_ITEM_CLASS_WEAPON, Enum.ItemWeaponSubclass.Wand)}
    }

    local yOffset = -80
    -- Armor mappings
    for _, armor in ipairs(armorTypes) do
        local label = self:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        label:SetPoint("TOPLEFT", 10, yOffset)
        label:SetText(armor.label .. " Recipient:")

        local editBox = CreateFrame("EditBox", addonName .. armor.key .. "EditBox", self, "InputBoxTemplate")
        editBox:SetPoint("TOPLEFT", 120, yOffset)
        editBox:SetSize(150, 20)
        editBox:SetText(TransmogMailerDB.mappings[armor.key] or "")
        editBox:SetScript("OnEnterPressed", function(self)
            TransmogMailerDB.mappings[armor.key] = self:GetText()
        end)
        editBox:SetScript("OnEditFocusLost", function(self)
            TransmogMailerDB.mappings[armor.key] = self:GetText()
        end)

        yOffset = yOffset - 30
    end

    -- Weapon mappings
    yOffset = yOffset - 20 -- Add some spacing
    local weaponTitle = self:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    weaponTitle:SetPoint("TOPLEFT", 10, yOffset)
    weaponTitle:SetText("Weapon Recipients")
    yOffset = yOffset - 30

    for _, weapon in ipairs(weaponTypes) do
        local label = self:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        label:SetPoint("TOPLEFT", 10, yOffset)
        label:SetText(weapon.label .. " Recipient:")

        local editBox = CreateFrame("EditBox", addonName .. weapon.key .. "EditBox", self, "InputBoxTemplate")
        editBox:SetPoint("TOPLEFT", 120, yOffset)
        editBox:SetSize(150, 20)
        editBox:SetText(TransmogMailerDB.mappings[weapon.key] or "")
        editBox:SetScript("OnEnterPressed", function(self)
            TransmogMailerDB.mappings[weapon.key] = self:GetText()
        end)
        editBox:SetScript("OnEditFocusLost", function(self)
            TransmogMailerDB.mappings[weapon.key] = self:GetText()
        end)

        yOffset = yOffset - 30
    end
end)

-- Register the options panel
InterfaceOptions_AddCategory(frame)