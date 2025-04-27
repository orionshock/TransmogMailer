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

    -- Modifier key dropdown
    local modifierLabel = self:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    modifierLabel:SetPoint("TOPLEFT", 10, -40)
    modifierLabel:SetText("Modifier Key:")

    local modifierDropdown = CreateFrame("Frame", addonName .. "ModifierDropdown", self, "UIDropDownMenuTemplate")
    modifierDropdown:SetPoint("TOPLEFT", 120, -35)
    UIDropDownMenu_SetWidth(modifierDropdown, 100)
    UIDropDownMenu_SetText(modifierDropdown, TransmogMailerDB.modifier or "SHIFT")

    UIDropDownMenu_Initialize(modifierDropdown, function(self)
        local info = UIDropDownMenu_CreateInfo()
        for _, key in ipairs({ "SHIFT", "CTRL", "ALT" }) do
            info.text = key
            info.func = function()
                TransmogMailerDB.modifier = key
                UIDropDownMenu_SetText(modifierDropdown, key)
            end
            UIDropDownMenu_AddButton(info)
        end
    end)

    -- Armor class mappings
    local armorTypes = { "Cloth", "Leather", "Mail", "Plate" }
    local yOffset = -80
    for i, armorType in ipairs(armorTypes) do
        local label = self:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        label:SetPoint("TOPLEFT", 10, yOffset)
        label:SetText(armorType .. " Recipient:")

        local editBox = CreateFrame("EditBox", addonName .. armorType .. "EditBox", self, "InputBoxTemplate")
        editBox:SetPoint("TOPLEFT", 120, yOffset)
        editBox:SetSize(150, 20)
        editBox:SetText(TransmogMailerDB.mappings[armorType] or "")
        editBox:SetScript("OnEnterPressed", function(self)
            TransmogMailerDB.mappings[armorType] = self:GetText()
        end)
        editBox:SetScript("OnEditFocusLost", function(self)
            TransmogMailerDB.mappings[armorType] = self:GetText()
        end)

        yOffset = yOffset - 30
    end
end)

-- Register the options panel
InterfaceOptions_AddCategory(frame)
