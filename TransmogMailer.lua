-- TransmogMailer.lua
TransmogMailer = TransmogMailer or {}
TransmogMailerDB = TransmogMailerDB or { modifier = "SHIFT", mappings = {} }

local frame = CreateFrame("Frame")
local MAILBOX_ITEMS_PER_PAGE = 7

-- Check if an item is BoE and its transmog status
local function IsItemEligible(itemLink, armorType)
    if not itemLink then return false end
    local bindType = select(14, GetItemInfo(itemLink))
    if bindType ~= LE_ITEM_BIND_ON_EQUIP then return false end

    -- Check if the appearance is unlearned
    if IsAddOnLoaded("CanIMogIt") then
        local canLearn = CanIMogIt:IsLearnable(itemLink)
        local learned = CanIMogIt:IsLearned(itemLink)
        return canLearn and not learned
    else
        -- Fallback: Assume unlearned if BoE and matches armor type
        return true
    end
end

-- Get the recipient for an armor type
local function GetRecipient(armorType)
    return TransmogMailerDB.mappings[armorType]
end

-- Process mailbox items
local function ProcessMailboxItems()
    local modifier = TransmogMailerDB.modifier or "SHIFT"
    if not IsModifierKeyDown(modifier) then return end

    local numItems = GetInboxNumItems()
    for i = 1, numItems do
        local itemLink = GetInboxItemLink(i)
        if itemLink then
            local itemType, itemSubType = select(6, GetItemInfo(itemLink))
            local armorType
            if itemType == "Armor" then
                if itemSubType == "Cloth" then
                    armorType = "Cloth"
                elseif itemSubType == "Leather" then
                    armorType = "Leather"
                elseif itemSubType == "Mail" then
                    armorType = "Mail"
                elseif itemSubType == "Plate" then
                    armorType = "Plate"
                end
            end

            if armorType and IsItemEligible(itemLink, armorType) then
                local recipient = GetRecipient(armorType)
                if recipient and recipient ~= "" then
                    -- Take the item from the mailbox
                    TakeInboxItem(i)
                    -- Wait for the item to be in bags, then mail it
                    C_Timer.After(0.5, function()
                        local bag, slot = FindItemInBags(itemLink)
                        if bag and slot then
                            UseContainerItem(bag, slot)
                            SendMail(recipient, "Transmog Item", "")
                        end
                    end)
                end
            end
        end
    end
end

-- Find an item in bags
function FindItemInBags(itemLink)
    for bag = 0, NUM_BAG_SLOTS do
        for slot = 1, GetContainerNumSlots(bag) do
            local link = GetContainerItemLink(bag, slot)
            if link == itemLink then
                return bag, slot
            end
        end
    end
    return nil, nil
end

-- Hook mailbox interactions
frame:RegisterEvent("MAIL_INBOX_UPDATE")
frame:SetScript("OnEvent", function(self, event)
    if event == "MAIL_INBOX_UPDATE" then
        ProcessMailboxItems()
    end
end)

-- Slash command to open options
SLASH_TRANSMOGMAILER1 = "/transmogmailer"
SlashCmdList["TRANSMOGMAILER"] = function()
    InterfaceOptionsFrame_OpenToCategory("TransmogMailer")
end
