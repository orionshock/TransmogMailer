local addonName, addon = ...
_G[addonName] = addon
local MAIL_ATTACHMENT_LIMIT = 12

addon.armorTypes = {
    [Enum.ItemArmorSubclass.Generic] = {
        label = GetItemSubClassInfo(Enum.ItemClass.Armor, Enum.ItemArmorSubclass.Generic),
        equipClasses = { "WARRIOR", "PALADIN", "HUNTER", "ROGUE", "PRIEST", "DEATHKNIGHT", "SHAMAN", "MAGE", "WARLOCK", "MONK", "DRUID", "DEMONHUNTER", "EVOKER" },
        desc = "IE: Offhand and Cloaks"
    },
    [Enum.ItemArmorSubclass.Cloth]   = { label = GetItemSubClassInfo(Enum.ItemClass.Armor, Enum.ItemArmorSubclass.Cloth), equipClasses = { "MAGE", "PRIEST", "WARLOCK" } },
    [Enum.ItemArmorSubclass.Leather] = { label = GetItemSubClassInfo(Enum.ItemClass.Armor, Enum.ItemArmorSubclass.Leather), equipClasses = { "DRUID", "ROGUE", "MONK" } },
    [Enum.ItemArmorSubclass.Mail]    = { label = GetItemSubClassInfo(Enum.ItemClass.Armor, Enum.ItemArmorSubclass.Mail), equipClasses = { "HUNTER", "SHAMAN" } },
    [Enum.ItemArmorSubclass.Plate]   = { label = GetItemSubClassInfo(Enum.ItemClass.Armor, Enum.ItemArmorSubclass.Plate), equipClasses = { "WARRIOR", "PALADIN", "DEATHKNIGHT" } },
    [Enum.ItemArmorSubclass.Shield]  = { label = GetItemSubClassInfo(Enum.ItemClass.Armor, Enum.ItemArmorSubclass.Shield), equipClasses = { "WARRIOR", "PALADIN", "SHAMAN" } }
}

addon.weaponTypes = {
    [Enum.ItemWeaponSubclass.Axe1H]    = { label = GetItemSubClassInfo(Enum.ItemClass.Weapon, Enum.ItemWeaponSubclass.Axe1H), equipClasses = { "WARRIOR", "PALADIN", "HUNTER", "ROGUE", "DEATHKNIGHT", "SHAMAN", "MONK" } },
    [Enum.ItemWeaponSubclass.Axe2H]    = { label = GetItemSubClassInfo(Enum.ItemClass.Weapon, Enum.ItemWeaponSubclass.Axe2H), equipClasses = { "WARRIOR", "PALADIN", "HUNTER", "DEATHKNIGHT", "SHAMAN" } },
    [Enum.ItemWeaponSubclass.Bows]     = { label = GetItemSubClassInfo(Enum.ItemClass.Weapon, Enum.ItemWeaponSubclass.Bows), equipClasses = { "WARRIOR", "HUNTER", "ROGUE" } },
    [Enum.ItemWeaponSubclass.Guns]     = { label = GetItemSubClassInfo(Enum.ItemClass.Weapon, Enum.ItemWeaponSubclass.Guns), equipClasses = { "WARRIOR", "HUNTER", "ROGUE" } },
    [Enum.ItemWeaponSubclass.Mace1H]   = { label = GetItemSubClassInfo(Enum.ItemClass.Weapon, Enum.ItemWeaponSubclass.Mace1H), equipClasses = { "WARRIOR", "PALADIN", "ROGUE", "PRIEST", "DEATHKNIGHT", "SHAMAN", "MONK", "DRUID" } },
    [Enum.ItemWeaponSubclass.Mace2H]   = { label = GetItemSubClassInfo(Enum.ItemClass.Weapon, Enum.ItemWeaponSubclass.Mace2H), equipClasses = { "WARRIOR", "PALADIN", "DEATHKNIGHT", "SHAMAN", "DRUID" } },
    [Enum.ItemWeaponSubclass.Polearm]  = { label = GetItemSubClassInfo(Enum.ItemClass.Weapon, Enum.ItemWeaponSubclass.Polearm), equipClasses = { "WARRIOR", "PALADIN", "HUNTER", "DEATHKNIGHT", "MONK", "DRUID" } },
    [Enum.ItemWeaponSubclass.Sword1H]  = { label = GetItemSubClassInfo(Enum.ItemClass.Weapon, Enum.ItemWeaponSubclass.Sword1H), equipClasses = { "WARRIOR", "PALADIN", "HUNTER", "ROGUE", "DEATHKNIGHT", "MAGE", "WARLOCK", "MONK" } },
    [Enum.ItemWeaponSubclass.Sword2H]  = { label = GetItemSubClassInfo(Enum.ItemClass.Weapon, Enum.ItemWeaponSubclass.Sword2H), equipClasses = { "WARRIOR", "PALADIN", "HUNTER", "DEATHKNIGHT" } },
    [Enum.ItemWeaponSubclass.Staff]    = { label = GetItemSubClassInfo(Enum.ItemClass.Weapon, Enum.ItemWeaponSubclass.Staff), equipClasses = { "WARRIOR", "HUNTER", "PRIEST", "SHAMAN", "MAGE", "WARLOCK", "MONK", "DRUID" } },
    [Enum.ItemWeaponSubclass.Unarmed]  = { label = GetItemSubClassInfo(Enum.ItemClass.Weapon, Enum.ItemWeaponSubclass.Unarmed), equipClasses = { "WARRIOR", "HUNTER", "ROGUE", "SHAMAN", "MONK", "DRUID" } },
    [Enum.ItemWeaponSubclass.Dagger]   = { label = GetItemSubClassInfo(Enum.ItemClass.Weapon, Enum.ItemWeaponSubclass.Dagger), equipClasses = { "WARRIOR", "HUNTER", "ROGUE", "PRIEST", "SHAMAN", "MAGE", "WARLOCK", "DRUID" } },
    [Enum.ItemWeaponSubclass.Crossbow] = { label = GetItemSubClassInfo(Enum.ItemClass.Weapon, Enum.ItemWeaponSubclass.Crossbow), equipClasses = { "WARRIOR", "HUNTER", "ROGUE" } },
    [Enum.ItemWeaponSubclass.Wand]     = { label = GetItemSubClassInfo(Enum.ItemClass.Weapon, Enum.ItemWeaponSubclass.Wand), equipClasses = { "PRIEST", "MAGE", "WARLOCK" } },
}

local frame = CreateFrame("Frame")
addon.frame = frame
frame:Hide()

frame.mailingList = nil
frame.nextMail = nil
frame.sendingMail = false
frame.waitingForSend = false
frame.mailboxOpen = false

--- Evaluates whether a recipient can learn the appearance from an item link.
--- @param itemLink string Item hyperlink.
--- @param recipient string Recipient character name.
--- @return boolean canLearn True when the recipient should receive the item for appearance learning.
function addon:CanLearnAppearance(itemLink, recipient)
    local currentRealm = GetNormalizedRealmName()
    local currentFaction = UnitFactionGroup("player")
    local characters = self.db.characters[currentRealm]
    local recipientClass = characters and characters[currentFaction] and characters[currentFaction][recipient]
    if not recipientClass then
        return false
    end

    if not CanIMogIt then
        return false
    end

    if not CanIMogIt:IsReadyForCalculations(itemLink) then
        return false
    end

    if not CanIMogIt:IsTransmogable(itemLink) then
        return false
    end

    local knowsTransmog
    if self.db.collectionMode == "APPEARANCE" then
        knowsTransmog = CanIMogIt:PlayerKnowsTransmog(itemLink)
    else
        knowsTransmog = CanIMogIt:PlayerKnowsTransmogFromItem(itemLink)
    end
    if knowsTransmog ~= false then
        return false
    end

    local _, _, _, _, _, _, _, _, _, _, _, itemClass, itemSubClass = C_Item.GetItemInfo(itemLink)
    if not itemClass or not itemSubClass then
        return false
    end

    local classRestrictions = CanIMogIt:GetItemClassRestrictions(itemLink)
    if classRestrictions then
        local canEquip = false
        for _, allowedClass in ipairs(classRestrictions) do
            if allowedClass == recipientClass or
                allowedClass == LOCALIZED_CLASS_NAMES_MALE[recipientClass] or
                allowedClass == LOCALIZED_CLASS_NAMES_FEMALE[recipientClass] then
                canEquip = true
                break
            end
        end
        if not canEquip then
            return false
        end
    end

    if CanIMogIt:IsItemArmor(itemLink) then
        local armorType = self.armorTypes[itemSubClass]
        if armorType then
            if not tContains(armorType.equipClasses, recipientClass) then
                return false
            end
        else
            return false
        end
    else
        local weaponType = self.weaponTypes[itemSubClass]
        if weaponType then
            if not tContains(weaponType.equipClasses, recipientClass) then
                return false
            end
        else
            return false
        end
    end

    return true
end

--- Builds a recipient-to-items map from current bags based on configured mappings.
--- @return nil
function frame:BuildMailingList()
    self.mailingList = nil
    local itemsToMail = {}
    local currentPlayer = UnitName("player")

    for bag = Enum.BagIndex.Backpack, NUM_BAG_SLOTS do
        for slot = 1, C_Container.GetContainerNumSlots(bag) do
            local itemInfo = C_Container.GetContainerItemInfo(bag, slot)
            local itemLink = itemInfo and itemInfo.hyperlink
            if itemLink and not itemInfo.isBound and not itemInfo.isLocked then
                local _, _, _, _, _, itemClass, itemSubClass = C_Item.GetItemInfoInstant(itemLink)
                if itemClass == Enum.ItemClass.Armor or itemClass == Enum.ItemClass.Weapon then
                    local prefix = itemClass == Enum.ItemClass.Armor and "armor_" or "weapon_"
                    local recipient = addon.db.mappings[prefix .. itemSubClass]
                    if recipient and recipient ~= "_none" and recipient ~= "" and recipient ~= currentPlayer then
                        if addon:CanLearnAppearance(itemLink, recipient) then
                            itemsToMail[recipient] = itemsToMail[recipient] or {}
                            table.insert(itemsToMail[recipient], { bag = bag, slot = slot, link = itemLink })
                        end
                    end
                end
            end
        end
    end
    if not next(itemsToMail) then
        DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00[TransmogMailer]|r Nothing to Send")
    end
    self.mailingList = itemsToMail
end

--- Prepares the next outgoing mail with up to attachment limit items.
--- @return nil
function frame:SetNextMail()
    if not self.mailboxOpen or not self.sendingMail or self.nextMail then
        return
    end
    if not self.mailingList or not next(self.mailingList) then
        self.sendingMail = false
        self:Hide()
        return
    end
    if CursorHasItem() then
        addon:MAIL_FAILED()
        return
    end
    -- Never include attachments or money from a manually composed message.
    for slot = 1, MAIL_ATTACHMENT_LIMIT do
        if GetSendMailItem(slot) then
            addon:MAIL_FAILED()
            return
        end
    end
    if GetSendMailMoney() > 0 or GetSendMailCOD() > 0 then
        addon:MAIL_FAILED()
        return
    end

    local recipient, itemList = next(self.mailingList)
    local mail = { items = {}, recipient = recipient }
    self.nextMail = mail
    for i = #itemList, 1, -1 do
        local itemLoc = itemList[i]
        local itemInfo = C_Container.GetContainerItemInfo(itemLoc.bag, itemLoc.slot)
        if itemInfo and itemInfo.hyperlink == itemLoc.link and not itemInfo.isLocked and
            not itemInfo.isBound and addon:CanLearnAppearance(itemLoc.link, recipient) then
            C_Container.PickupContainerItem(itemLoc.bag, itemLoc.slot)
            if CursorHasItem() then
                local slot = #mail.items + 1
                ClickSendMailItemButton(slot)
                if CursorHasItem() then
                    ClearCursor()
                    addon:MAIL_FAILED()
                    return
                end
                itemLoc.itemID = itemInfo.itemID
                itemLoc.count = itemInfo.stackCount
                table.insert(mail.items, itemLoc)
            end
        end
        table.remove(itemList, i)
        if #mail.items == MAIL_ATTACHMENT_LIMIT then
            break
        end
    end
    if #itemList == 0 then
        self.mailingList[recipient] = nil
    end
    if #mail.items == 0 then
        self.nextMail = nil
    end
    self:Show()
end

--- Resets elapsed update timer when the mail frame becomes visible.
--- @param self Frame Mail processing frame.
--- @return nil
frame:SetScript("OnShow", function(self)
    self.elapsed = 0
end)
--- Processes periodic mail preparation and sending while visible.
--- @param self Frame Mail processing frame.
--- @param elapsed number Frame update delta time.
--- @return nil
frame:SetScript("OnUpdate", function(self, elapsed)
    if self.waitingForSend or not self.mailboxOpen then return end
    self.elapsed = self.elapsed + elapsed
    if self.elapsed < 1 then return end
    self.elapsed = 0

    if not self.nextMail then
        self:SetNextMail()
        return
    end
    for slot, item in ipairs(self.nextMail.items) do
        local _, itemID, _, count = GetSendMailItem(slot)
        if itemID ~= item.itemID or count ~= item.count then
            addon:MAIL_FAILED()
            return
        end
    end
    for slot = #self.nextMail.items + 1, MAIL_ATTACHMENT_LIMIT do
        if GetSendMailItem(slot) then
            addon:MAIL_FAILED()
            return
        end
    end
    if GetSendMailMoney() > 0 or GetSendMailCOD() > 0 then
        addon:MAIL_FAILED()
        return
    end
    DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00[TransmogMailer]|r Sending " .. #self.nextMail.items ..
        " item(s) to " .. self.nextMail.recipient)
    self.waitingForSend = true
    SendMail(self.nextMail.recipient, "Transmog Items", "")
end)

--- Handles mailbox open event and optionally starts a mailing session.
--- @param event string Event name.
--- @return nil
function addon:MAIL_SHOW(event)
    if frame.mailboxOpen or not self.db then return end
    frame.mailboxOpen = true
    if self.db.modifier ~= "NONE" then
        local modifier = self.db.modifier
        local isModified = IsShiftKeyDown() and modifier == "SHIFT" or
            IsControlKeyDown() and modifier == "CTRL" or
            IsAltKeyDown() and modifier == "ALT"
        if isModified then
            frame.sendingMail = true
            frame:BuildMailingList()
            if frame.mailingList then
                frame:SetNextMail()
            end
        else
            frame.sendingMail = false
        end
    end
end

--- Handles successful mail send events and advances queued mail.
--- @param event string Event name.
--- @return nil
function addon:MAIL_SEND_SUCCESS(event)
    if not frame.waitingForSend then return end
    frame.waitingForSend = false
    frame.nextMail = nil
    -- Blizzard resets the compose frame on this event. Prepare the next
    -- message on a later update, after all event handlers have run.
    frame.elapsed = 0
    frame:Show()
end

--- Stops the queue, leaving unsent attachments available for manual recovery.
function addon:MAIL_FAILED()
    frame:Hide()
    frame.nextMail = nil
    frame.mailingList = nil
    frame.sendingMail = false
    frame.waitingForSend = false
end

function addon:MAIL_CLOSED()
    self:MAIL_FAILED()
    frame.mailboxOpen = false
end

--- Initializes saved variables and character metadata for the current session.
--- @return boolean initialized True when initialization completes in this call.
function addon:InitSV()
    if GetNormalizedRealmName() and UnitFactionGroup("player") and UnitName("player") and not self.db then
        self.db = TransmogMailerDB or { modifier = "NONE", collectionMode = "ALL_ITEMS", mappings = {}, characters = {} }
        TransmogMailerDB = self.db
        self.db.modifier = self.db.modifier or "NONE"
        self.db.mappings = self.db.mappings or {}
        self.db.characters = self.db.characters or {}
        self.db.collectionMode = self.db.collectionMode or "ALL_ITEMS"

        local currentRealm = GetNormalizedRealmName()
        local currentFaction = UnitFactionGroup("player")
        local name = UnitName("player")
        local _, class = UnitClass("player")

        self.db.characters[currentRealm] = self.db.characters[currentRealm] or {}
        self.db.characters[currentRealm][currentFaction] = self.db.characters[currentRealm][currentFaction] or {}
        self.db.characters[currentRealm][currentFaction][name] = class:upper()

        for key in pairs(self.armorTypes) do
            self.db.mappings["armor_" .. key] = self.db.mappings["armor_" .. key] or "_none"
        end
        for key in pairs(self.weaponTypes) do
            self.db.mappings["weapon_" .. key] = self.db.mappings["weapon_" .. key] or "_none"
        end

        frame:UnregisterEvent("PLAYER_LOGIN")
        return true
    end
    return false
end

--- Handles addon load event and initializes settings for this addon.
--- @param event string Event name.
--- @param arg1 string Loaded addon name.
--- @return nil
function addon:ADDON_LOADED(event, arg1)
    if arg1 == addonName then
        local svLoaded = self:InitSV()
        if svLoaded then
            self.InitializeSettings()
        end
    end
end

--- Handles player login event and initializes settings if needed.
--- @param event string Event name.
--- @return nil
function addon:PLAYER_LOGIN(event)
    local svLoaded = self:InitSV()
    if svLoaded then
        self.InitializeSettings()
    end
end

--- Dispatches frame events to matching addon methods when available.
--- @param frame Frame Event frame.
--- @param event string Event name.
--- @param ... any Event payload.
--- @return nil
frame:SetScript("OnEvent", function(frame, event, ...)
    if type(addon[event]) == "function" then
        addon[event](addon, event, ...)
    end
end)

frame:RegisterEvent("ADDON_LOADED")
frame:RegisterEvent("PLAYER_LOGIN")
frame:RegisterEvent("MAIL_SHOW")
frame:RegisterEvent("MAIL_CLOSED")
frame:RegisterEvent("MAIL_SEND_SUCCESS")
frame:RegisterEvent("MAIL_FAILED")

--- Opens the addon settings category from slash command.
--- @return nil
SLASH_TRANSMOGMAILER1 = "/transmogmailer"
SlashCmdList["TRANSMOGMAILER"] = function()
    if addon.categoryID then
        Settings.OpenToCategory(addon.categoryID)
    end
end
