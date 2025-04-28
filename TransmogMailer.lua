-- TransmogMailer.lua
local addonName, addon = ...

local MAIL_ATTACHMENT_LIMIT = 12

-- Create frame and register events
local frame = CreateFrame("Frame")
frame:RegisterEvent("ADDON_LOADED")
frame:RegisterEvent("MAIL_SHOW")
frame:SetScript("OnEvent", function(self, event, arg1)
    if event == "ADDON_LOADED" and arg1 == addonName then
        -- Initialize saved variables
        addon.db = TransmogMailerDB or { modifier = "NONE", mappings = {}, characters = {} }
        TransmogMailerDB = addon.db

        -- Store current character info
        local currentRealm = GetNormalizedRealmName()
        local currentFaction = UnitFactionGroup("player")
        local name = UnitName("player")
        local _, class = UnitClass("player")
        
        addon.db.characters[currentRealm] = addon.db.characters[currentRealm] or {}
        addon.db.characters[currentRealm][currentFaction] = addon.db.characters[currentRealm][currentFaction] or {}
        addon.db.characters[currentRealm][currentFaction][name] = class:upper()

        -- Initialize settings
        addon.InitializeSettings()
        self:UnregisterEvent("ADDON_LOADED")
    elseif event == "MAIL_SHOW" and addon.db.modifier ~= "NONE" then
        local modifier = addon.db.modifier
        local isModified = IsShiftKeyDown() and modifier == "SHIFT" or
                           IsControlKeyDown() and modifier == "CTRL" or
                           IsAltKeyDown() and modifier == "ALT"
        
        if isModified then
            local itemsToMail = {}
            local currentPlayer = UnitName("player")
            
            for bag = Enum.BagIndex.Backpack, NUM_BAG_SLOTS do
                for slot = 1, C_Container.GetContainerNumSlots(bag) do
                    local itemLink = C_Container.GetContainerItemLink(bag, slot)
                    if itemLink then
                        local itemID = C_Container.GetContainerItemID(bag, slot)
                        local _, _, _, _, _, itemClass, itemSubClass = GetItemInfo(itemID)
                        
                        if itemClass == LE_ITEM_CLASS_ARMOR or itemClass == LE_ITEM_CLASS_WEAPON then
                            local recipient = addon.db.mappings[itemSubClass]
                            if recipient and recipient ~= "" and recipient ~= currentPlayer then
                                if CanIMogIt and CanIMogIt:IsValidAppearanceForCharacter(itemLink, recipient) then
                                    itemsToMail[recipient] = itemsToMail[recipient] or {}
                                    table.insert(itemsToMail[recipient], {bag = bag, slot = slot})
                                end
                            end
                        end
                    end
                end
            end
            
            for recipient, items in pairs(itemsToMail) do
                local mailCount = math.ceil(#items / MAIL_ATTACHMENT_LIMIT)
                for mailIndex = 1, mailCount do
                    local startIndex = (mailIndex - 1) * MAIL_ATTACHMENT_LIMIT + 1
                    local endIndex = math.min(startIndex + MAIL_ATTACHMENT_LIMIT - 1, #items)
                    
                    MailFrameTab_OnClick(nil, 2) -- Switch to Send Mail tab
                    SendMailNameEditBox:SetText(recipient)
                    
                    for i = startIndex, endIndex do
                        local item = items[i]
                        C_Container.UseContainerItem(item.bag, item.slot)
                    end
                    
                    SendMailMailButton:Click()
                end
            end
        end
    end
end)

-- Slash command to open settings
SLASH_TRANSMOGMAILER1 = "/transmogmailer"
SlashCmdList["TRANSMOGMAILER"] = function()
    Settings.OpenToCategory(addon.categoryID)
end