local addonName, addon = ...
_G[addonName] = addon
local MAIL_ATTACHMENT_LIMIT = 12

addon.armorTypes = {
    [Enum.ItemArmorSubclass.Generic] = {
        label = GetItemSubClassInfo(LE_ITEM_CLASS_ARMOR, Enum.ItemArmorSubclass.Generic),
        equipClasses = { "MAGE", "PRIEST", "WARLOCK", "DRUID", "SHAMAN", "PALADIN" },
        desc = "IE: Offhand and Cloaks"
    },
    [Enum.ItemArmorSubclass.Cloth]   = { label = GetItemSubClassInfo(LE_ITEM_CLASS_ARMOR, Enum.ItemArmorSubclass.Cloth), equipClasses = { "MAGE", "PRIEST", "WARLOCK" } },
    [Enum.ItemArmorSubclass.Leather] = { label = GetItemSubClassInfo(LE_ITEM_CLASS_ARMOR, Enum.ItemArmorSubclass.Leather), equipClasses = { "DRUID", "ROGUE", "MONK" } },
    [Enum.ItemArmorSubclass.Mail]    = { label = GetItemSubClassInfo(LE_ITEM_CLASS_ARMOR, Enum.ItemArmorSubclass.Mail), equipClasses = { "HUNTER", "SHAMAN" } },
    [Enum.ItemArmorSubclass.Plate]   = { label = GetItemSubClassInfo(LE_ITEM_CLASS_ARMOR, Enum.ItemArmorSubclass.Plate), equipClasses = { "WARRIOR", "PALADIN", "DEATHKNIGHT" } },
    [Enum.ItemArmorSubclass.Shield]  = { label = GetItemSubClassInfo(LE_ITEM_CLASS_ARMOR, Enum.ItemArmorSubclass.Shield), equipClasses = { "WARRIOR", "PALADIN", "SHAMAN" } }
}

addon.weaponTypes = {
    [Enum.ItemWeaponSubclass.Axe1H]    = { label = GetItemSubClassInfo(LE_ITEM_CLASS_WEAPON, Enum.ItemWeaponSubclass.Axe1H), equipClasses = { "WARRIOR", "PALADIN", "HUNTER", "ROGUE", "DEATH KNIGHT", "SHAMAN", "MONK" } },
    [Enum.ItemWeaponSubclass.Axe2H]    = { label = GetItemSubClassInfo(LE_ITEM_CLASS_WEAPON, Enum.ItemWeaponSubclass.Axe2H), equipClasses = { "WARRIOR", "PALADIN", "HUNTER", "DEATH KNIGHT", "SHAMAN" } },
    [Enum.ItemWeaponSubclass.Bows]     = { label = GetItemSubClassInfo(LE_ITEM_CLASS_WEAPON, Enum.ItemWeaponSubclass.Bows), equipClasses = { "WARRIOR", "HUNTER", "ROGUE" } },
    [Enum.ItemWeaponSubclass.Guns]     = { label = GetItemSubClassInfo(LE_ITEM_CLASS_WEAPON, Enum.ItemWeaponSubclass.Guns), equipClasses = { "WARRIOR", "HUNTER", "ROGUE" } },
    [Enum.ItemWeaponSubclass.Mace1H]   = { label = GetItemSubClassInfo(LE_ITEM_CLASS_WEAPON, Enum.ItemWeaponSubclass.Mace1H), equipClasses = { "WARRIOR", "PALADIN", "ROGUE", "PRIEST", "DEATH KNIGHT", "SHAMAN", "MONK", "DRUID" } },
    [Enum.ItemWeaponSubclass.Mace2H]   = { label = GetItemSubClassInfo(LE_ITEM_CLASS_WEAPON, Enum.ItemWeaponSubclass.Mace2H), equipClasses = { "WARRIOR", "PALADIN", "DEATH KNIGHT", "SHAMAN", "DRUID" } },
    [Enum.ItemWeaponSubclass.Polearm]  = { label = GetItemSubClassInfo(LE_ITEM_CLASS_WEAPON, Enum.ItemWeaponSubclass.Polearm), equipClasses = { "WARRIOR", "PALADIN", "HUNTER", "DEATH KNIGHT", "MONK", "DRUID" } },
    [Enum.ItemWeaponSubclass.Sword1H]  = { label = GetItemSubClassInfo(LE_ITEM_CLASS_WEAPON, Enum.ItemWeaponSubclass.Sword1H), equipClasses = { "WARRIOR", "PALADIN", "HUNTER", "ROGUE", "DEATH KNIGHT", "MAGE", "WARLOCK", "MONK" } },
    [Enum.ItemWeaponSubclass.Sword2H]  = { label = GetItemSubClassInfo(LE_ITEM_CLASS_WEAPON, Enum.ItemWeaponSubclass.Sword2H), equipClasses = { "WARRIOR", "PALADIN", "HUNTER", "DEATH KNIGHT" } },
    [Enum.ItemWeaponSubclass.Staff]    = { label = GetItemSubClassInfo(LE_ITEM_CLASS_WEAPON, Enum.ItemWeaponSubclass.Staff), equipClasses = { "WARRIOR", "HUNTER", "PRIEST", "SHAMAN", "MAGE", "WARLOCK", "MONK", "DRUID" } },
    [Enum.ItemWeaponSubclass.Unarmed]  = { label = GetItemSubClassInfo(LE_ITEM_CLASS_WEAPON, Enum.ItemWeaponSubclass.Unarmed), equipClasses = { "WARRIOR", "HUNTER", "ROGUE", "SHAMAN", "MONK", "DRUID" } },
    [Enum.ItemWeaponSubclass.Dagger]   = { label = GetItemSubClassInfo(LE_ITEM_CLASS_WEAPON, Enum.ItemWeaponSubclass.Dagger), equipClasses = { "WARRIOR", "HUNTER", "ROGUE", "PRIEST", "SHAMAN", "MAGE", "WARLOCK", "DRUID" } },
    [Enum.ItemWeaponSubclass.Crossbow] = { label = GetItemSubClassInfo(LE_ITEM_CLASS_WEAPON, Enum.ItemWeaponSubclass.Crossbow), equipClasses = { "WARRIOR", "HUNTER", "ROGUE" } },
    [Enum.ItemWeaponSubclass.Wand]     = { label = GetItemSubClassInfo(LE_ITEM_CLASS_WEAPON, Enum.ItemWeaponSubclass.Wand), equipClasses = { "PRIEST", "MAGE", "WARLOCK" } },
}

local tooltipFrame = CreateFrame("GameTooltip", "TransmogMailerTooltip", UIParent)
local tooltipLeftLines = {}
for i = 1, 5 do
    local left = tooltipFrame:CreateFontString()
    left:SetFontObject(GameFontNormal)
    tooltipFrame:AddFontStrings(left, tooltipFrame:CreateFontString())
    tooltipLeftLines[i] = left
end
tooltipFrame:SetOwner(UIParent, "ANCHOR_NONE")

--- Scans an inventory item tooltip to determine bind status.
--- @param bag number Bag index.
--- @param slot number Slot index.
--- @return boolean isBound True when the item is soulbound or account-bound.
local function IsBound(bag, slot)
    tooltipFrame:ClearLines()
    tooltipFrame:SetBagItem(bag, slot)
    if not tooltipFrame:IsShown() then
        tooltipFrame:SetOwner(UIParent, "ANCHOR_NONE")
        tooltipFrame:SetBagItem(bag, slot)
        if not tooltipFrame:IsShown() then
            error(("TransmogMailer - Cannot Scan Tooltip - Bag: %s, Slot: %s"):format(bag, slot))
        end
    end
    for i = 2, 5 do
        local txt = tooltipLeftLines[i]:GetText()
        if txt == ITEM_SOULBOUND or txt == ITEM_BNETACCOUNTBOUND then
            return true
        end
    end
    return false
end

local frame = CreateFrame("Frame")
addon.frame = frame
frame:Hide()

frame.mailingList = nil
frame.nextMail = nil
frame.sendingMail = false
frame.clearingMail = false
frame.mailSentTimestamp = 0
frame.mailSentCount = 0
frame.lastMailShow = 0

--- Evaluates whether a recipient can learn the appearance from an item link.
--- @param itemLink string Item hyperlink.
--- @param recipient string Recipient character name.
--- @return boolean canLearn True when the recipient should receive the item for appearance learning.
function addon:CanLearnAppearance(itemLink, recipient)
    local currentRealm = GetNormalizedRealmName()
    local currentFaction = UnitFactionGroup("player")
    local recipientClass = self.db.characters[currentRealm][currentFaction][recipient]
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

    if CanIMogIt:PlayerKnowsTransmog(itemLink) then
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
            if allowedClass == recipientClass then
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
            local itemLink = C_Container.GetContainerItemLink(bag, slot)
            if itemLink and not IsBound(bag, slot) then
                local itemID = C_Container.GetContainerItemID(bag, slot)
                local itemClass, itemSubClass, _, _, _, _, invType = select(12, C_Item.GetItemInfo(itemID))
                if itemClass == LE_ITEM_CLASS_ARMOR or itemClass == LE_ITEM_CLASS_WEAPON then
                    local prefix = itemClass == LE_ITEM_CLASS_ARMOR and "armor_" or "weapon_"
                    local recipient = addon.db.mappings[prefix .. itemSubClass]
                    if recipient and recipient ~= "_none" and recipient ~= "" and recipient ~= currentPlayer then
                        if addon:CanLearnAppearance(itemLink, recipient) then
                            itemsToMail[recipient] = itemsToMail[recipient] or {}
                            table.insert(itemsToMail[recipient], { bag = bag, slot = slot })
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
    if not self.mailingList or self.nextMail or self.clearingMail then
        return
    end

    local onMailSlot = 1
    local linkList = ""
    for recipient, itemList in pairs(self.mailingList) do
        for i = #itemList, 1, -1 do
            local itemLoc = itemList[i]
            local itemInfo = C_Container.GetContainerItemInfo(itemLoc.bag, itemLoc.slot)
            if itemInfo and itemInfo.stackCount then
                linkList = (linkList ~= "" and linkList .. ", " or "") ..
                    (itemInfo.stackCount > 1 and itemInfo.stackCount .. "x" or "") .. itemInfo.hyperlink
                C_Container.PickupContainerItem(itemLoc.bag, itemLoc.slot)
                ClickSendMailItemButton(onMailSlot)
                self.nextMail = self.nextMail or { items = {}, recipient = recipient }
                table.insert(self.nextMail.items, itemList[i])
                itemList[i] = nil
                onMailSlot = onMailSlot + 1
                if onMailSlot > MAIL_ATTACHMENT_LIMIT then
                    break
                end
            end
        end
        if onMailSlot > 1 then
            if #itemList == 0 then
                self.mailingList[recipient] = nil
                if next(self.mailingList) == nil then
                    self.mailingList = nil
                end
            end
            DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00[TransmogMailer]|r Sending to " .. recipient .. ": " .. linkList)
            self:Show()
            return
        end
    end
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
    if self.clearingMail then return end
    self.elapsed = self.elapsed + elapsed
    if self.elapsed > 1 then
        self.elapsed = 0

        if not self.nextMail then
            self:SetNextMail()
            if not self.nextMail then
                self:Hide()
            end
            return
        end

        if GetSendMailItem(1) then
            SendMail(self.nextMail.recipient, "Transmog Items", "")
        else
            self.nextMail = nil
            self:Hide()
        end
    end
end)

--- Handles mailbox open event and optionally starts a mailing session.
--- @param event string Event name.
--- @return nil
function addon:MAIL_SHOW(event)
    if GetTime() - frame.lastMailShow < 1 then return end
    frame.lastMailShow = GetTime()
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
    local currentTime = GetTime()
    if frame.sendingMail and not frame.clearingMail and (currentTime ~= frame.mailSentTimestamp or frame.mailSentCount == 0) and (currentTime - frame.mailSentTimestamp > 0.5) then
        frame.mailSentTimestamp = currentTime
        frame.mailSentCount = frame.mailSentCount + 1
        frame.clearingMail = true
        ClearSendMail()
        frame.clearingMail = false
        frame.nextMail = nil
        frame:SetNextMail()
        if not frame.nextMail and not frame.mailingList then
            frame:Hide()
        end
    end
end

--- Handles failed mail events and clears current mailing state.
--- @param event string Event name.
--- @return nil
function addon:MAIL_FAILED(event)
    if not frame.clearingMail then
        frame.clearingMail = true
        ClearSendMail()
        frame.clearingMail = false
    end
    frame:Hide()
    frame.nextMail = nil
    frame.mailingList = nil
    frame.sendingMail = false
    frame.mailSentCount = 0
end

--- Handles mailbox close event and clears current mailing state.
--- @param event string Event name.
--- @return nil
function addon:MAIL_CLOSED(event)
    if not frame.clearingMail then
        frame.clearingMail = true
        ClearSendMail()
        frame.clearingMail = false
    end
    frame:Hide()
    frame.nextMail = nil
    frame.mailingList = nil
    frame.sendingMail = false
    frame.mailSentCount = 0
end

--- Initializes saved variables and character metadata for the current session.
--- @return boolean initialized True when initialization completes in this call.
function addon:InitSV()
    if GetNormalizedRealmName() and not self.db then
        self.db = TransmogMailerDB or { modifier = "NONE", mappings = {}, characters = {} }
        TransmogMailerDB = self.db

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
    Settings.OpenToCategory(addon.categoryID)
end
