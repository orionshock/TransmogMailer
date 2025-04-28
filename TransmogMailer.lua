-- TransmogMailer.lua
local addonName, addon = ...

addon.db = TransmogMailerDB or { modifier = "SHIFT", mappings = {}, characters = {} }

local frame = CreateFrame("Frame")

-- Track character on login
frame:RegisterEvent("PLAYER_LOGIN")
frame:SetScript("OnEvent", function(self, event)
    if event == "PLAYER_LOGIN" then
        local charName = UnitName("player")
        local _, class = UnitClass("player")
        local realm = GetNormalizedRealmName()
        local faction = UnitFactionGroup("player")
        if charName and class and realm and faction then
            -- Ensure characters table exists
            addon.db.characters = addon.db.characters or {}
            local found = false
            for _, char in ipairs(addon.db.characters) do
                if char.name == charName and char.realm == realm then
                    char.class = class -- Update class if changed
                    char.faction = faction -- Update faction if changed
                    found = true
                    break
                end
            end
            if not found then
                table.insert(addon.db.characters, { name = charName, class = class, realm = realm, faction = faction })
            end
        end
    elseif event == "MAIL_SHOW" then
        local modifier = addon.db.modifier or "SHIFT"
        if IsModifierKeyDown(modifier) then
            addon.ProcessBagItems()
        end
    end
end)

-- Register MAIL_SHOW event
frame:RegisterEvent("MAIL_SHOW")

-- Check if an item is BoE and its transmog status
function addon.IsItemEligible(itemLink)
    if not itemLink or not CanIMogIt then
        return false
    end
    local bindType = select(14, GetItemInfo(itemLink))
    if bindType ~= LE_ITEM_BIND_ON_EQUIP then
        return false
    end
    local canLearn = CanIMogIt:IsLearnable(itemLink)
    local learned = CanIMogIt:IsLearned(itemLink)
    return canLearn and not learned
end

-- Get the recipient for an armor or weapon type
function addon.GetRecipient(itemType, itemSubTypeID)
    local key
    if itemType == LE_ITEM_CLASS_ARMOR then
        key = ({
            [Enum.ItemArmorSubclass.Cloth] = Enum.ItemArmorSubclass.Cloth,
            [Enum.ItemArmorSubclass.Leather] = Enum.ItemArmorSubclass.Leather,
            [Enum.ItemArmorSubclass.Mail] = Enum.ItemArmorSubclass.Mail,
            [Enum.ItemArmorSubclass.Plate] = Enum.ItemArmorSubclass.Plate
        })[itemSubTypeID]
    elseif itemType == LE_ITEM_CLASS_WEAPON then
        key = ({
            [Enum.ItemWeaponSubclass.Axe1H] = Enum.ItemWeaponSubclass.Axe1H,
            [Enum.ItemWeaponSubclass.Axe2H] = Enum.ItemWeaponSubclass.Axe2H,
            [Enum.ItemWeaponSubclass.Mace1H] = Enum.ItemWeaponSubclass.Mace1H,
            [Enum.ItemWeaponSubclass.Mace2H] = Enum.ItemWeaponSubclass.Mace2H,
            [Enum.ItemWeaponSubclass.Sword1H] = Enum.ItemWeaponSubclass.Sword1H,
            [Enum.ItemWeaponSubclass.Sword2H] = Enum.ItemWeaponSubclass.Sword2H,
            [Enum.ItemWeaponSubclass.Staff] = Enum.ItemWeaponSubclass.Staff,
            [Enum.ItemWeaponSubclass.Polearm] = Enum.ItemWeaponSubclass.Polearm,
            [Enum.ItemWeaponSubclass.Bows] = Enum.ItemWeaponSubclass.Bows,
            [Enum.ItemWeaponSubclass.Crossbow] = Enum.ItemWeaponSubclass.Crossbow,
            [Enum.ItemWeaponSubclass.Guns] = Enum.ItemWeaponSubclass.Guns,
            [Enum.ItemWeaponSubclass.Dagger] = Enum.ItemWeaponSubclass.Dagger,
            [Enum.ItemWeaponSubclass.Unarmed] = Enum.ItemWeaponSubclass.Unarmed,
            [Enum.ItemWeaponSubclass.Wand] = Enum.ItemWeaponSubclass.Wand
        })[itemSubTypeID]
    end
    return key and addon.db.mappings[key]
end

-- Process items in bags
function addon.ProcessBagItems()
    local modifier = addon.db.modifier or "SHIFT"
    if not IsModifierKeyDown(modifier) then
        print("TransmogMailer: Hold the modifier key (" .. modifier .. ") to scan bags.")
        return
    end

    local currentPlayer = UnitName("player"):lower()
    local itemsByRecipient = {}
    for bag = 0, NUM_BAG_SLOTS do
        for slot = 1, C_Container.GetContainerNumSlots(bag) do
            local itemLink = C_Container.GetContainerItemLink(bag, slot)
            if itemLink then
                local itemType, itemSubTypeID = select(6, GetItemInfo(itemLink))
                if (itemType == LE_ITEM_CLASS_ARMOR or itemType == LE_ITEM_CLASS_WEAPON) and addon.IsItemEligible(itemLink) then
                    local recipient = addon.GetRecipient(itemType, itemSubTypeID)
                    if recipient and recipient ~= "" then
                        if recipient:lower() == currentPlayer then
                            print("TransmogMailer: Skipped " .. itemLink .. " (recipient is current character)")
                        else
                            itemsByRecipient[recipient] = itemsByRecipient[recipient] or {}
                            table.insert(itemsByRecipient[recipient], {bag = bag, slot = slot, itemLink = itemLink})
                        end
                    end
                end
            end
        end
    end

    if not next(itemsByRecipient) then
        print("TransmogMailer: No eligible items to mail.")
        return
    end

    -- Open mail frame if not already open
    if not MailFrame:IsShown() then
        MailFrame:Show()
        MailFrameTab2:Click()
    end

    -- Send mails with batched items (up to 12 items per mail)
    local MAIL_ATTACHMENT_LIMIT = 12
    for recipient, items in pairs(itemsByRecipient) do
        local itemCount = #items
        for startIndex = 1, itemCount, MAIL_ATTACHMENT_LIMIT do
            local mailItems = {}
            for i = startIndex, math.min(startIndex + MAIL_ATTACHMENT_LIMIT - 1, itemCount) do
                table.insert(mailItems, items[i])
            end

            -- Send mail with batched items
            for _, item in ipairs(mailItems) do
                C_Container.UseContainerItem(item.bag, item.slot)
            end
            SendMail(recipient, "Transmog Items", "")
            print("TransmogMailer: Mailed " .. #mailItems .. " items to " .. recipient)
            C_Timer.After(0.5, function()
                -- Clear attachments after sending
                ClearSendMail()
            end)
        end
    end
end

-- Slash commands
SLASH_TRANSMOGMAILER1 = "/transmogmailer"
SlashCmdList["TRANSMOGMAILER"] = function(msg)
    if msg == "scan" then
        addon.ProcessBagItems()
    else
        Settings.OpenToCategory(addon.categoryID)
    end
end