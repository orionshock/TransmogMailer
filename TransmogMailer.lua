-- TransmogMailer.lua
TransmogMailer = TransmogMailer or {}
TransmogMailerDB = TransmogMailerDB or { modifier = "SHIFT", mappings = {}, characters = {} }

local frame = CreateFrame("Frame")

-- Track character on login
frame:RegisterEvent("PLAYER_LOGIN")
frame:SetScript("OnEvent", function(self, event)
    if event == "PLAYER_LOGIN" then
        local charName = UnitName("player")
        local _, class = UnitClass("player")
        if charName and class then
            -- Ensure characters table exists
            TransmogMailerDB.characters = TransmogMailerDB.characters or {}
            local found = false
            for _, char in ipairs(TransmogMailerDB.characters) do
                if char.name == charName then
                    char.class = class -- Update class if changed
                    found = true
                    break
                end
            end
            if not found then
                table.insert(TransmogMailerDB.characters, { name = charName, class = class })
            end
        end
    end
end)

-- Check if an item is BoE and its transmog status
local function IsItemEligible(itemLink)
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
local function GetRecipient(itemType, itemSubTypeID)
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
            [Enum.ItemWeaponSubclass.Bow] = Enum.ItemWeaponSubclass.Bow,
            [Enum.ItemWeaponSubclass.Crossbow] = Enum.ItemWeaponSubclass.Crossbow,
            [Enum.ItemWeaponSubclass.Gun] = Enum.ItemWeaponSubclass.Gun,
            [Enum.ItemWeaponSubclass.Dagger] = Enum.ItemWeaponSubclass.Dagger,
            [Enum.ItemWeaponSubclass.Unarmed] = Enum.ItemWeaponSubclass.Unarmed,
            [Enum.ItemWeaponSubclass.Wand] = Enum.ItemWeaponSubclass.Wand
        })[itemSubTypeID]
    end
    return key and TransmogMailerDB.mappings[key]
end

-- Process items in bags
local function ProcessBagItems()
    local modifier = TransmogMailerDB.modifier or "SHIFT"
    if not IsModifierKeyDown(modifier) then
        print("TransmogMailer: Hold the modifier key (" .. modifier .. ") to scan bags.")
        return
    end

    local currentPlayer = UnitName("player"):lower()
    local itemsToMail = {}
    for bag = 0, NUM_BAG_SLOTS do
        for slot = 1, GetContainerNumSlots(bag) do
            local itemLink = GetContainerItemLink(bag, slot)
            if itemLink then
                local itemType, itemSubTypeID = select(6, GetItemInfo(itemLink))
                if (itemType == LE_ITEM_CLASS_ARMOR or itemType == LE_ITEM_CLASS_WEAPON) and IsItemEligible(itemLink) then
                    local recipient = GetRecipient(itemType, itemSubTypeID)
                    if recipient and recipient ~= "" then
                        if recipient:lower() == currentPlayer then
                            print("TransmogMailer: Skipped " .. itemLink .. " (recipient is current character)")
                        else
                            table.insert(itemsToMail, {bag = bag, slot = slot, itemLink = itemLink, recipient = recipient})
                        end
                    end
                end
            end
        end
    end

    if #itemsToMail == 0 then
        print("TransmogMailer: No eligible items to mail.")
        return
    end

    -- Open mail frame if not already open
    if not MailFrame:IsShown() then
        MailFrame:Show()
        MailFrameTab2:Click()
    end

    -- Mail items with a slight delay to avoid throttling
    local index = 1
    local function MailNextItem()
        if index > #itemsToMail then
            print("TransmogMailer: Finished mailing items.")
            return
        end
        local item = itemsToMail[index]
        UseContainerItem(item.bag, item.slot)
        SendMail(item.recipient, "Transmog Item", "")
        print("TransmogMailer: Mailed " .. item.itemLink .. " to " .. item.recipient)
        index = index + 1
        C_Timer.After(0.5, MailNextItem)
    end
    MailNextItem()
end

-- Slash commands
SLASH_TRANSMOGMAILER1 = "/transmogmailer"
SlashCmdList["TRANSMOGMAILER"] = function(msg)
    if msg == "scan" then
        ProcessBagItems()
    else
        Settings.OpenToCategory(TransmogMailer.categoryID)
    end
end