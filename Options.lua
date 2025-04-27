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
        {key = "Cloth", label = "Cloth"},
        {key = "Leather", label = "Leather"},
        {key = "Mail", label = "Mail"},
        {key = "Plate", label = "Plate"}
    }

    -- Weapon type mappings
    local weaponTypes = {
        {key = "OneHandAxe", label = "One-Handed Axe"},
        {key = "TwoHandAxe", label = "Two-Handed Axe"},
        {key = "OneHandMace", label = "One-Handed Mace"},
        {key = "TwoHandMace", label = "Two-Handed Mace"},
        {key = "OneHandSword", label = "One-Handed Sword"},
        {key = "TwoHandSword", label = "Two-Handed Sword"},
        {key = "Staff", label = "Staff"},
        {key = "Polearm", label = "Polearm"},
        {key = "Bow", label = "Bow"},
        {key = "Crossbow", label = "Crossbow"},
        {key = "Gun", label = "Gun"},
        {key = "Dagger", label = "Dagger"},
        {key = "Fist", label = "Fist Weapon"},
        {key = "Wand", label = "Wand"}
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