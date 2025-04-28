local addonName, addon = ...

local MAIL_ATTACHMENT_LIMIT = 12

-- Armor and weapon types (shared with Options.lua)
addon.armorTypes = {
    { key = Enum.ItemArmorSubclass.Cloth,   label = GetItemSubClassInfo(LE_ITEM_CLASS_ARMOR, Enum.ItemArmorSubclass.Cloth) or "Cloth",     equipClasses = { "MAGE", "PRIEST", "WARLOCK" } },
    { key = Enum.ItemArmorSubclass.Leather, label = GetItemSubClassInfo(LE_ITEM_CLASS_ARMOR, Enum.ItemArmorSubclass.Leather) or "Leather", equipClasses = { "DRUID", "ROGUE" } },
    { key = Enum.ItemArmorSubclass.Mail,    label = GetItemSubClassInfo(LE_ITEM_CLASS_ARMOR, Enum.ItemArmorSubclass.Mail) or "Mail",       equipClasses = { "HUNTER", "SHAMAN" } },
    { key = Enum.ItemArmorSubclass.Plate,   label = GetItemSubClassInfo(LE_ITEM_CLASS_ARMOR, Enum.ItemArmorSubclass.Plate) or "Plate",     equipClasses = { "WARRIOR", "PALADIN", "DEATHKNIGHT" } }
}

addon.weaponTypes = {
    { key = Enum.ItemWeaponSubclass.Axe1H,    label = GetItemSubClassInfo(LE_ITEM_CLASS_WEAPON, Enum.ItemWeaponSubclass.Axe1H) or "One-Handed Axe",     equipClasses = { "WARRIOR", "PALADIN", "HUNTER", "SHAMAN", "DEATHKNIGHT" } },
    { key = Enum.ItemWeaponSubclass.Axe2H,    label = GetItemSubClassInfo(LE_ITEM_CLASS_WEAPON, Enum.ItemWeaponSubclass.Axe2H) or "Two-Handed Axe",     equipClasses = { "WARRIOR", "PALADIN", "HUNTER", "DEATHKNIGHT" } },
    { key = Enum.ItemWeaponSubclass.Mace1H,   label = GetItemSubClassInfo(LE_ITEM_CLASS_WEAPON, Enum.ItemWeaponSubclass.Mace1H) or "One-Handed Mace",   equipClasses = { "WARRIOR", "PALADIN", "PRIEST", "SHAMAN", "DRUID", "DEATHKNIGHT" } },
    { key = Enum.ItemWeaponSubclass.Mace2H,   label = GetItemSubClassInfo(LE_ITEM_CLASS_WEAPON, Enum.ItemWeaponSubclass.Mace2H) or "Two-Handed Mace",   equipClasses = { "WARRIOR", "PALADIN", "DRUID", "DEATHKNIGHT" } },
    { key = Enum.ItemWeaponSubclass.Sword1H,  label = GetItemSubClassInfo(LE_ITEM_CLASS_WEAPON, Enum.ItemWeaponSubclass.Sword1H) or "One-Handed Sword", equipClasses = { "WARRIOR", "PALADIN", "HUNTER", "ROGUE", "DEATHKNIGHT", "MAGE", "WARLOCK" } },
    { key = Enum.ItemWeaponSubclass.Sword2H,  label = GetItemSubClassInfo(LE_ITEM_CLASS_WEAPON, Enum.ItemWeaponSubclass.Sword2H) or "Two-Handed Sword", equipClasses = { "WARRIOR", "PALADIN", "DEATHKNIGHT" } },
    { key = Enum.ItemWeaponSubclass.Staff,    label = GetItemSubClassInfo(LE_ITEM_CLASS_WEAPON, Enum.ItemWeaponSubclass.Staff) or "Staff",              equipClasses = { "DRUID", "HUNTER", "MAGE", "PRIEST", "SHAMAN", "WARLOCK", "WARRIOR" } },
    { key = Enum.ItemWeaponSubclass.Polearm,  label = GetItemSubClassInfo(LE_ITEM_CLASS_WEAPON, Enum.ItemWeaponSubclass.Polearm) or "Polearm",          equipClasses = { "WARRIOR", "PALADIN", "HUNTER", "DRUID", "DEATHKNIGHT" } },
    { key = Enum.ItemWeaponSubclass.Bows,     label = GetItemSubClassInfo(LE_ITEM_CLASS_WEAPON, Enum.ItemWeaponSubclass.Bows) or "Bows",                equipClasses = { "HUNTER", "WARRIOR", "ROGUE" } },
    { key = Enum.ItemWeaponSubclass.Crossbow, label = GetItemSubClassInfo(LE_ITEM_CLASS_WEAPON, Enum.ItemWeaponSubclass.Crossbow) or "Crossbow",        equipClasses = { "HUNTER", "WARRIOR", "ROGUE" } },
    { key = Enum.ItemWeaponSubclass.Guns,     label = GetItemSubClassInfo(LE_ITEM_CLASS_WEAPON, Enum.ItemWeaponSubclass.Guns) or "Guns",                equipClasses = { "HUNTER", "WARRIOR", "ROGUE" } },
    { key = Enum.ItemWeaponSubclass.Dagger,   label = GetItemSubClassInfo(LE_ITEM_CLASS_WEAPON, Enum.ItemWeaponSubclass.Dagger) or "Dagger",            equipClasses = { "HUNTER", "ROGUE", "PRIEST", "SHAMAN", "MAGE", "WARLOCK", "WARRIOR" } },
    { key = Enum.ItemWeaponSubclass.Unarmed,  label = GetItemSubClassInfo(LE_ITEM_CLASS_WEAPON, Enum.ItemWeaponSubclass.Unarmed) or "Fist Weapon",      equipClasses = { "WARRIOR", "HUNTER", "ROGUE", "SHAMAN", "DRUID" } },
    { key = Enum.ItemWeaponSubclass.Wand,     label = GetItemSubClassInfo(LE_ITEM_CLASS_WEAPON, Enum.ItemWeaponSubclass.Wand) or "Wand",                equipClasses = { "MAGE", "PRIEST", "WARLOCK" } }
}

-- Tooltip scanner for binding check
local tooltipFrame = CreateFrame("GameTooltip", "TransmogMailerTooltip", UIParent)
local tooltipLeftLines = {}
for i = 1, 5 do
    local left = tooltipFrame:CreateFontString()
    left:SetFontObject(GameFontNormal)
    tooltipFrame:AddFontStrings(left, tooltipFrame:CreateFontString())
    tooltipLeftLines[i] = left
end
tooltipFrame:SetOwner(UIParent, "ANCHOR_NONE")

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

-- Create frame and register events
local frame = CreateFrame("Frame")
addon.frame = frame
frame:Hide()

frame.mailingList = nil
frame.nextMail = nil
frame.sendingMail = false


local function IsItemBoE(itemLink, bag, slot)
    return CanIMogIt:IsItemBindOnEquip(itemLink, bag, slot)
end

-- Check if a recipient can learn a transmog appearance
function addon:CanLearnAppearance(itemLink, recipient)
    local currentRealm = GetNormalizedRealmName()
    local currentFaction = UnitFactionGroup("player")
    local recipientClass = self.db.characters[currentRealm][currentFaction][recipient]
    if not recipientClass then
        print("[TransmogMailer] Error: No class found for recipient " .. recipient)
        return false
    end

    -- Check if the item is transmogable
    if not CanIMogIt:IsTransmogable(itemLink) then
        print("[TransmogMailer] Item is not transmogable: " .. itemLink)
        return false
    end

    -- Get item information
    local itemID = CanIMogIt:GetItemID(itemLink)
    local itemClass, itemSubClass, slotName = CanIMogIt:GetItemClassName(itemLink),
        CanIMogIt:GetItemSubClassName(itemLink), CanIMogIt:GetItemSlotName(itemLink)
    if not itemClass or not itemSubClass or not slotName then
        print("[TransmogMailer] Error: Invalid item info for " .. itemLink)
        return false
    end

    -- Check class restrictions from CanIMogIt
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
            print("[TransmogMailer] " .. recipient .. " (" .. recipientClass .. ") is not allowed to equip " .. itemLink)
            return false
        end
    end

    -- Check if the item is armor or weapon
    local isArmor = CanIMogIt:IsItemArmor(itemLink)
    if isArmor then
        -- For armor, check if it matches the recipient's primary armor type
        local recipientArmorTypeID = CanIMogIt.classArmorTypeMap[recipientClass]
        local recipientArmorType = select(1, GetItemSubClassInfo(4, recipientArmorTypeID))
        local isCosmetic = CanIMogIt:IsArmorCosmetic(itemLink)
        if not isCosmetic and itemSubClass ~= recipientArmorType then
            print("[TransmogMailer] " ..
            recipient ..
            " (" .. recipientClass .. ") cannot learn " .. itemSubClass .. " (requires " .. recipientArmorType .. ")")
            return false
        end
    else
        -- For weapons, check if the recipient's class can equip the weapon type
        local weaponType = nil
        for _, typeInfo in ipairs(self.weaponTypes) do
            if typeInfo.key == itemSubClass then
                weaponType = typeInfo
                break
            end
        end
        if weaponType then
            if not tContains(weaponType.equipClasses, recipientClass) then
                print("[TransmogMailer] " .. recipient .. " (" .. recipientClass .. ") cannot equip " .. itemSubClass)
                return false
            end
        else
            print("[TransmogMailer] Unknown weapon subclass: " .. itemSubClass)
            return false
        end
    end

    -- Check if the character can learn the transmog (ignoring level requirements)
    if not CanIMogIt:CharacterCanLearnTransmog(itemLink) then
        print("[TransmogMailer] " .. recipient .. " (" .. recipientClass .. ") cannot learn transmog for " .. itemLink)
        return false
    end

    return true
end

-- Build mailing list
function frame:BuildMailingList()
    self.mailingList = nil
    local itemsToMail = {}
    local currentPlayer = UnitName("player")
    print("[TransmogMailer][Debug] Starting BuildMailingList for player: " .. (currentPlayer or "nil"))

    -- Collect BoE items to mail
    for bag = Enum.BagIndex.Backpack, NUM_BAG_SLOTS do
        for slot = 1, C_Container.GetContainerNumSlots(bag) do
            local itemLink = C_Container.GetContainerItemLink(bag, slot)
            if itemLink and not IsBound(bag, slot) then
                print("[TransmogMailer][Debug] Item is BoE (not bound) for bag: " .. bag .. ", slot: " .. slot)
                local itemID = C_Container.GetContainerItemID(bag, slot)
                local itemClass, itemSubClass = select(12, C_Item.GetItemInfo(itemID))
                if itemClass == LE_ITEM_CLASS_ARMOR or itemClass == LE_ITEM_CLASS_WEAPON then
                    local prefix = itemClass == LE_ITEM_CLASS_ARMOR and "armor_" or "weapon_"
                    print("[TransmogMailer][Debug] Calculated prefix: " .. prefix .. ", SubClass: " .. (itemSubClass or "nil"))
                    local recipient = addon.db.mappings[prefix .. itemSubClass]
                    if recipient and recipient ~= "_none" and recipient ~= "" and recipient ~= currentPlayer then
                        print("[TransmogMailer][Debug] Valid recipient: " .. recipient .. ", checking CanLearnAppearance")
                        if addon:CanLearnAppearance(itemLink, recipient) then
                            print("[TransmogMailer][Debug] CanLearnAppearance returned true for " .. itemLink .. " to " .. recipient)
                            itemsToMail[recipient] = itemsToMail[recipient] or {}
                            table.insert(itemsToMail[recipient], { bag = bag, slot = slot })
                            print("[TransmogMailer][Debug] Added item to itemsToMail for " .. recipient .. ": bag=" .. bag .. ", slot=" .. slot)
                        else
                            print("[TransmogMailer][Debug] CanLearnAppearance returned false for " .. itemLink .. " to " .. recipient)
                        end
                    else
                        print("[TransmogMailer][Debug] Skipped recipient: " .. (recipient or "nil") .. " (invalid: _none, empty, or current player)")
                    end
                else
                end
            end
        end
    end

    self.mailingList = itemsToMail
    local itemCount = 0
    local recipients = ""
    for recipient, items in pairs(itemsToMail) do
        itemCount = itemCount + #items
        recipients = recipients .. (recipients == "" and "" or ", ") .. recipient
        print("[TransmogMailer][Debug] Recipient: " .. recipient .. ", Item count: " .. #items)
    end
    print("[TransmogMailer] Built mailing list: " ..
        itemCount .. " items for recipients: " .. (recipients == "" and "none" or recipients))
    print("[TransmogMailer][Debug] Mailing list complete, total items: " .. itemCount)
end

-- Set up the next mail
function frame:SetNextMail()
    if not self.mailingList or self.nextMail then
        print("[TransmogMailer] SetNextMail skipped: mailingList=" ..
        tostring(self.mailingList ~= nil) .. ", nextMail=" .. tostring(self.nextMail ~= nil))
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
                C_Container.UseContainerItem(itemLoc.bag, itemLoc.slot)
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
            -- Clean up empty recipient lists
            if #itemList == 0 then
                self.mailingList[recipient] = nil
                if next(self.mailingList) == nil then
                    self.mailingList = nil
                end
            end
            print("[TransmogMailer] Queuing mail to " .. recipient .. ": " .. linkList)
            self:Show() -- Start OnUpdate
            return
        end
    end
    print("[TransmogMailer] SetNextMail found no items to mail")
end

-- OnUpdate for mail sending
frame:SetScript("OnShow", function(self) self.elapsed = 0 end)
frame:SetScript("OnUpdate", function(self, elapsed)
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
            print("[TransmogMailer] No items in mail slots for " .. self.nextMail.recipient .. ", aborting")
            self.nextMail = nil
            self:Hide()
        end
    end
end)

function addon:MAIL_SHOW(event)
    print("[TransmogMailer] MAIL_SHOW event fired")
    if self.db.modifier ~= "NONE" then
        local modifier = self.db.modifier
        local isModified = IsShiftKeyDown() and modifier == "SHIFT" or
            IsControlKeyDown() and modifier == "CTRL" or
            IsAltKeyDown() and modifier == "ALT"
        print("[TransmogMailer] Modifier check: setting=" ..
        modifier .. ", IsAltKeyDown=" .. tostring(IsAltKeyDown()) .. ", isModified=" .. tostring(isModified))

        if isModified then
            print("[TransmogMailer] Modifier condition met, starting mailing")
            frame.sendingMail = true
            frame:BuildMailingList()
            if frame.mailingList then
                print("[TransmogMailer] Mailing list created, setting next mail")
                frame:SetNextMail()
                if frame.nextMail then
                    print("[TransmogMailer] Next mail set, showing frame")
                    frame:Show()
                else
                    print("[TransmogMailer] No next mail set")
                end
            else
                print("[TransmogMailer] No mailing list created")
            end
        else
            print("[TransmogMailer] Modifier condition not met, mailing disabled")
            frame.sendingMail = false
        end
    else
        print("[TransmogMailer] Modifier is NONE, mailing disabled")
    end
end

function addon:MAIL_SEND_SUCCESS(event)
    print("[TransmogMailer] MAIL_SEND_SUCCESS")
    if frame.sendingMail then
        ClearSendMail()
        frame.nextMail = nil
        frame:SetNextMail()
        if not frame.nextMail and not frame.mailingList then
            print("[TransmogMailer] No more mails to send, hiding frame")
            frame:Hide()
        end
    end
end

function addon:MAIL_FAILED(event)
    print("[TransmogMailer] MAIL_FAILED")
    frame:Hide()
    frame.nextMail = nil
    frame.mailingList = nil
    frame.sendingMail = false
    ClearSendMail()
end

function addon:MAIL_CLOSED(event)
    print("[TransmogMailer] MAIL_CLOSED")
    frame:Hide()
    frame.nextMail = nil
    frame.mailingList = nil
    frame.sendingMail = false
    ClearSendMail()
end

-- Event handlers

-- Initialize saved variables and character data
function addon:InitSV()
    if GetNormalizedRealmName() and not self.db then
        self.db = TransmogMailerDB or { modifier = "NONE", mappings = {}, characters = {} }
        TransmogMailerDB = self.db
        print("[TransmogMailer] Initialized saved variables, modifier set to: " .. tostring(self.db.modifier))

        local currentRealm = GetNormalizedRealmName()
        local currentFaction = UnitFactionGroup("player")
        local name = UnitName("player")
        local _, class = UnitClass("player")

        self.db.characters[currentRealm] = self.db.characters[currentRealm] or {}
        self.db.characters[currentRealm][currentFaction] = self.db.characters[currentRealm][currentFaction] or {}
        self.db.characters[currentRealm][currentFaction][name] = class:upper()

        -- Initialize mappings with "_none" for all armor and weapon types
        for _, armor in ipairs(self.armorTypes) do
            self.db.mappings["armor_" .. armor.key] = self.db.mappings["armor_" .. armor.key] or "_none"
        end
        for _, weapon in ipairs(self.weaponTypes) do
            self.db.mappings["weapon_" .. weapon.key] = self.db.mappings["weapon_" .. weapon.key] or "_none"
        end

        frame:UnregisterEvent("PLAYER_LOGIN")
        return true
    end
    return false
end

function addon:ADDON_LOADED(event, arg1)
    if arg1 == addonName then
        print("[TransmogMailer] ADDON_LOADED for " .. addonName)
        -- Initialize saved variables
        local svLoaded = self:InitSV()
        if svLoaded then
            -- Initialize settings
            self.InitializeSettings()
        end
    end
end

function addon:PLAYER_LOGIN(event)
    print("[TransmogMailer] PLAYER_LOGIN, initializing saved variables")
    -- Initialize saved variables and character info
    local svLoaded = self:InitSV()
    if svLoaded then
        -- Initialize settings
        self.InitializeSettings()
    end
end

-- Dispatch events to addon methods
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

-- Slash command to open settings
SLASH_TRANSMOGMAILER1 = "/transmogmailer"
SlashCmdList["TRANSMOGMAILER"] = function()
    Settings.OpenToCategory(addon.categoryID)
end
