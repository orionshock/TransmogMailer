local addonName, addon = ...

local MAIL_ATTACHMENT_LIMIT = 12

-- Armor and weapon types (shared with Options.lua)
addon.armorTypes = {
    { key = Enum.ItemArmorSubclass.Cloth,   label = GetItemSubClassInfo(LE_ITEM_CLASS_ARMOR, Enum.ItemArmorSubclass.Cloth) or "Cloth",     equipClasses = { "MAGE", "PRIEST", "WARLOCK" } },
    { key = Enum.ItemArmorSubclass.Leather, label = GetItemSubClassInfo(LE_ITEM_CLASS_ARMOR, Enum.ItemArmorSubclass.Leather) or "Leather", equipClasses = { "DRUID", "ROGUE" } },
    { key = Enum.ItemArmorSubclass.Mail,    label = GetItemSubClassInfo(LE_ITEM_CLASS_ARMOR, Enum.ItemArmorSubclass.Mail) or "Mail",       equipClasses = { "HUNTER", "SHAMAN" } },
    { key = Enum.ItemArmorSubclass.Plate,   label = GetItemSubClassInfo(LE_ITEM_CLASS_ARMOR, Enum.ItemArmorSubclass.Plate) or "Plate",     equipClasses = { "WARRIOR", "PALADIN", "DEATHKNIGHT" } }
    -- Optional: Enable for Cosmetic items
    -- { key = Enum.ItemArmorSubclass.Cosmetic, label = GetItemSubClassInfo(LE_ITEM_CLASS_ARMOR, Enum.ItemArmorSubclass.Cosmetic) or "Cosmetic", equipClasses = { "MAGE", "PRIEST", "WARLOCK", "DRUID", "ROGUE", "HUNTER", "SHAMAN", "WARRIOR", "PALADIN", "DEATHKNIGHT" } }
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
frame.clearingMail = false -- Flag to prevent recursive ClearSendMail
frame.mailSentTimestamp = 0 -- Debounce MAIL_SEND_SUCCESS

local function IsItemBoE(itemLink, bag, slot)
    return CanIMogIt:IsItemBindOnEquip(itemLink, bag, slot)
end

-- Check if a recipient can learn a transmog appearance
function addon:CanLearnAppearance(itemLink, recipient)
    local currentRealm = GetNormalizedRealmName()
    local currentFaction = UnitFactionGroup("player")
    local recipientClass = self.db.characters[currentRealm][currentFaction][recipient]
    if not recipientClass then
        print("[TransmogMailer][Debug] Error: No class found for recipient " .. (recipient or "nil"))
        return false
    end

    -- Check if CanIMogIt is loaded
    if not CanIMogIt then
        print("[TransmogMailer][Debug] Error: CanIMogIt not loaded")
        return false
    end

    -- Check if the item is transmogable
    if not CanIMogIt:IsTransmogable(itemLink) then
        print("[TransmogMailer][Debug] Item is not transmogable: " .. itemLink)
        return false
    end

    -- Get item information
    local _, _, _, _, _, _, _, _, _, _, _, itemClass, itemSubClass = C_Item.GetItemInfo(itemLink)
    if not itemClass or not itemSubClass then
        print("[TransmogMailer][Debug] Error: Invalid item info for " .. itemLink)
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
            print("[TransmogMailer][Debug] Recipient " .. recipient .. " (" .. recipientClass .. ") not allowed to equip " .. itemLink)
            return false
        end
    end

    -- Check if the item is armor or weapon
    local isArmor = CanIMogIt:IsItemArmor(itemLink)
    if isArmor then
        -- For armor, check if it matches the recipient's primary armor type
        local recipientArmorType = nil
        for _, armorType in ipairs(self.armorTypes) do
            if tContains(armorType.equipClasses, recipientClass) then
                recipientArmorType = armorType.label
                break
            end
        end
        if not recipientArmorType then
            print("[TransmogMailer][Debug] Error: No armor type found for class " .. recipientClass)
            return false
        end
        local isCosmetic = CanIMogIt:IsArmorCosmetic(itemLink)
        if not isCosmetic and itemSubClass ~= recipientArmorType then
            print("[TransmogMailer][Debug] Recipient " .. recipient .. " cannot learn " .. itemSubClass .. " (requires " .. recipientArmorType .. ")")
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
                print("[TransmogMailer][Debug] Recipient " .. recipient .. " cannot equip weapon subclass " .. itemSubClass)
                return false
            end
        else
            print("[TransmogMailer][Debug] Error: Unknown weapon subclass: " .. itemSubClass)
            return false
        end
    end

    print("[TransmogMailer][Debug] CanLearnAppearance returning true for " .. itemLink .. " to " .. recipient)
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
                local itemID = C_Container.GetContainerItemID(bag, slot)
                local itemClass, itemSubClass = select(12, C_Item.GetItemInfo(itemID))
                if itemClass == LE_ITEM_CLASS_ARMOR or itemClass == LE_ITEM_CLASS_WEAPON then
                    local prefix = itemClass == LE_ITEM_CLASS_ARMOR and "armor_" or "weapon_"
                    local recipient = addon.db.mappings[prefix .. itemSubClass]
                    print("[TransmogMailer][Debug] Recipient for " .. prefix .. (itemSubClass or "nil") .. ": " .. (recipient or "nil"))
                    if recipient and recipient ~= "_none" and recipient ~= "" and recipient ~= currentPlayer then
                        if addon:CanLearnAppearance(itemLink, recipient) then
                            itemsToMail[recipient] = itemsToMail[recipient] or {}
                            table.insert(itemsToMail[recipient], { bag = bag, slot = slot })
                            print("[TransmogMailer][Debug] Added item to mailing list: " .. itemLink .. " for " .. recipient)
                        end
                    else
                        print("[TransmogMailer][Debug] Skipped item: " .. itemLink .. ", invalid recipient: " .. (recipient or "nil"))
                    end
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
    end
    print("[TransmogMailer] Built mailing list: " .. itemCount .. " items for recipients: " .. (recipients == "" and "none" or recipients))
end

-- Set up the next mail
function frame:SetNextMail()
    if not self.mailingList or self.nextMail or self.clearingMail then
        print("[TransmogMailer][Debug] SetNextMail skipped: mailingList=" ..
            tostring(self.mailingList ~= nil) .. ", nextMail=" .. tostring(self.nextMail ~= nil) .. ", clearingMail=" .. tostring(self.clearingMail))
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
            -- Clean up empty recipient lists
            if #itemList == 0 then
                self.mailingList[recipient] = nil
                if next(self.mailingList) == nil then
                    self.mailingList = nil
                end
            end
            print("[TransmogMailer][Debug] Queuing mail to " .. recipient .. ": " .. linkList)
            self:Show()
            return
        end
    end
    print("[TransmogMailer][Debug] SetNextMail found no items to mail")
end

-- OnUpdate for mail sending
frame:SetScript("OnShow", function(self)
    self.elapsed = 0
    print("[TransmogMailer][Debug] Frame shown, starting mail processing")
end)
frame:SetScript("OnUpdate", function(self, elapsed)
    if self.clearingMail then return end
    self.elapsed = self.elapsed + elapsed
    if self.elapsed > 1 then
        self.elapsed = 0

        if not self.nextMail then
            print("[TransmogMailer][Debug] No nextMail, calling SetNextMail")
            self:SetNextMail()
            if not self.nextMail then
                print("[TransmogMailer][Debug] No more mails to send, hiding frame")
                self:Hide()
            end
            return
        end

        if GetSendMailItem(1) then
            print("[TransmogMailer][Debug] Sending mail to " .. self.nextMail.recipient)
            SendMail(self.nextMail.recipient, "Transmog Items", "")
        else
            print("[TransmogMailer][Debug] No items in mail slots for " .. self.nextMail.recipient .. ", aborting")
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
        print("[TransmogMailer][Debug] Modifier check: setting=" .. modifier .. ", isModified=" .. tostring(isModified))

        if isModified then
            print("[TransmogMailer][Debug] Modifier condition met, starting mailing")
            frame.sendingMail = true
            frame:BuildMailingList()
            if frame.mailingList then
                print("[TransmogMailer][Debug] Mailing list created, setting next mail")
                frame:SetNextMail()
            else
                print("[TransmogMailer][Debug] No mailing list created")
            end
        else
            print("[TransmogMailer][Debug] Modifier condition not met, mailing disabled")
            frame.sendingMail = false
        end
    else
        print("[TransmogMailer][Debug] Modifier is NONE, mailing disabled")
    end
end

function addon:MAIL_SEND_SUCCESS(event)
    local currentTime = GetTime()
    print("[TransmogMailer][Debug] MAIL_SEND_SUCCESS at " .. currentTime)
    if frame.sendingMail and not frame.clearingMail and (currentTime - frame.mailSentTimestamp > 0.5) then
        frame.mailSentTimestamp = currentTime
        frame.clearingMail = true
        ClearSendMail()
        frame.clearingMail = false
        frame.nextMail = nil
        frame:SetNextMail()
        if not frame.nextMail and not frame.mailingList then
            print("[TransmogMailer][Debug] No more mails to send, hiding frame")
            frame:Hide()
        end
    end
end

function addon:MAIL_FAILED(event)
    print("[TransmogMailer][Debug] MAIL_FAILED")
    if not frame.clearingMail then
        frame.clearingMail = true
        ClearSendMail()
        frame.clearingMail = false
    end
    frame:Hide()
    frame.nextMail = nil
    frame.mailingList = nil
    frame.sendingMail = false
end

function addon:MAIL_CLOSED(event)
    print("[TransmogMailer][Debug] MAIL_CLOSED")
    if not frame.clearingMail then
        frame.clearingMail = true
        ClearSendMail()
        frame.clearingMail = false
    end
    frame:Hide()
    frame.nextMail = nil
    frame.mailingList = nil
    frame.sendingMail = false
end

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
        -- Optional: Enable for Cosmetic items
        -- self.db.mappings["armor_" .. Enum.ItemArmorSubclass.Cosmetic] = self.db.mappings["armor_" .. Enum.ItemArmorSubclass.Cosmetic] or "_none"

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