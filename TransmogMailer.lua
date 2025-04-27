-- TransmogMailer.lua
TransmogMailer = TransmogMailer or {}
TransmogMailerDB = TransmogMailerDB or { modifier = "SHIFT", mappings = {} }

local frame = CreateFrame("Frame")

-- Check if an item is BoE and its transmog status
local function IsItemEligible(itemLink)
    if not itemLink then return false end
    local bindType = select(14, GetItemInfo(itemLink))
    if bindType ~= LE_ITEM_BIND_ON_EQUIP then return false end

    -- Check if the appearance is learnable and unlearned
    if CanIMogIt then
        local canLearn = CanIMogIt:IsLearnable(itemLink)
        local learned = CanIMogIt:IsLearned(itemLink)
        return canLearn and not learned
    end
    return false -- Fail-safe if CanIMogIt is not loaded
end

-- Get the recipient for an armor or weapon type
local function GetRecipient(itemType, itemSubTypeID)
    local key
    if itemType == LE_ITEM_CLASS_ARMOR then
        if itemSubTypeID == Enum.ItemArmorSubclass.Cloth then key = Enum.ItemArmorSubclass.Cloth
        elseif itemSubTypeID == Enum.ItemArmorSubclass.Leather then key = Enum.ItemArmorSubclass.Leather
        elseif itemSubTypeID == Enum.ItemArmorSubclass.Mail then key = Enum.ItemArmorSubclass.Mail
        elseif itemSubTypeID == Enum.ItemArmorSubclass.Plate then key = Enum.ItemArmorSubclass.Plate
        end
    elseif itemType == LE_ITEM_CLASS_WEAPON then
        if itemSubTypeID == Enum.ItemWeaponSubclass.Axe1H then key = Enum.ItemWeaponSubclass.Axe1H
        elseif itemSubTypeID == Enum.ItemWeaponSubclass.Axe2H then key = Enum.ItemWeaponSubclass.Axe2H
        elseif itemSubTypeID == Enum.ItemWeaponSubclass.Mace1H then key = Enum.ItemWeaponSubclass.Mace1H
        elseif itemSubTypeID == Enum.ItemWeaponSubclass.Mace2H then key = Enum.ItemWeaponSubclass.Mace2H
        elseif itemSubTypeID == Enum.ItemWeaponSubclass.Sword1H then key = Enum.ItemWeaponSubclass.Sword1H
        elseif itemSubTypeID == Enum.ItemWeaponSubclass.Sword2H then key = Enum.ItemWeaponSubclass.Sword2H
        elseif itemSubTypeID == Enum.ItemWeaponSubclass.Staff then key = Enum.ItemWeaponSubclass.Staff
        elseif itemSubTypeID == Enum.ItemWeaponSubclass.Polearm then key = Enum.ItemWeaponSubclass.Polearm
        elseif itemSubTypeID == Enum.ItemWeaponSubclass.Bow then key = Enum.ItemWeaponSubclass.Bow
        elseif itemSubTypeID == Enum.ItemWeaponSubclass.Crossbow then key = Enum.ItemWeaponSubclass.Crossbow
        elseif itemSubTypeID == Enum.ItemWeaponSubclass.Gun then key = Enum.ItemWeaponSubclass.Gun
        elseif itemSubTypeID == Enum.ItemWeaponSubclass.Dagger then key = Enum.ItemWeaponSubclass.Dagger
        elseif itemSubTypeID == Enum.ItemWeaponSubclass.Unarmed then key = Enum.ItemWeaponSubclass.Unarmed
        elseif itemSubTypeID == Enum.ItemWeaponSubclass.Wand then key = Enum.ItemWeaponSubclass.Wand
        end
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

    local currentPlayer = UnitName("player")
    for bag = 0, NUM_BAG_SLOTS do
        for slot = 1, GetContainerNumSlots(bag) do
            local itemLink = GetContainerItemLink(bag, slot)
            if itemLink then
                local itemType, itemSubTypeID = select(6, GetItemInfo(itemLink))
                if (itemType == LE_ITEM_CLASS_ARMOR or itemType == LE_ITEM_CLASS_WEAPON) and IsItemEligible(itemLink) then
                    local recipient = GetRecipient(itemType, itemSubTypeID)
                    if recipient and recipient ~= "" and recipient:lower() ~= currentPlayer:lower() then
                        -- Open mail frame if not already open
                        if not MailFrame:IsShown() then
                            MailFrame:Show()
                            MailFrameTab2:Click()
                        end
                        -- Mail the item
                        UseContainerItem(bag, slot)
                        SendMail(recipient, "Transmog Item", "")
                        print("TransmogMailer: Mailed " .. itemLink .. " to " .. recipient)
                    end
                end
            end
        end
    end
end

-- Slash commands
SLASH_TRANSMOGMAILER1 = "/transmogmailer"
SlashCmdList["TRANSMOGMAILER"] = function(msg)
    if msg == "scan" then
        ProcessBagItems()
    else
        InterfaceOptionsFrame_OpenToCategory("TransmogMailer")
    end
end