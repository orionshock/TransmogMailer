-- TransmogMailer.lua
local addonName, addon = ...

local MAIL_ATTACHMENT_LIMIT = 12

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
frame:RegisterEvent("ADDON_LOADED")
frame:RegisterEvent("PLAYER_LOGIN")
frame:RegisterEvent("MAIL_SHOW")
frame:RegisterEvent("MAIL_CLOSED")
frame:RegisterEvent("MAIL_SEND_SUCCESS")
frame:RegisterEvent("MAIL_FAILED")
frame:Hide()

frame.mailingList = nil
frame.nextMail = nil
frame.sendingMail = false

-- Initialize saved variables and character data
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
        
        frame:UnregisterEvent("PLAYER_LOGIN")
    end
end

-- Build mailing list
function frame:BuildMailingList()
    self.mailingList = nil
    local itemsToMail = {}
    local currentPlayer = UnitName("player")
    
    -- Collect BoE items to mail
    for bag = Enum.BagIndex.Backpack, NUM_BAG_SLOTS do
        for slot = 1, C_Container.GetContainerNumSlots(bag) do
            local itemLink = C_Container.GetContainerItemLink(bag, slot)
            if itemLink and not IsBound(bag, slot) then
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
    
    self.mailingList = itemsToMail
end

-- Set up the next mail
function frame:SetNextMail()
    if not self.mailingList or self.nextMail then return end
    
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
            DEFAULT_CHAT_FRAME:AddMessage("Sending mail to " .. recipient .. ": " .. linkList, 1, 1, 0)
            self:Show() -- Start OnUpdate
            return
        end
    end
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
            DEFAULT_CHAT_FRAME:AddMessage(
                "TransmogMailer: No items in slots when trying to send to " .. self.nextMail.recipient, 1, 0, 0)
            self.nextMail = nil
            self:Hide()
        end
    end
end)

-- Event handlers
function addon:ADDON_LOADED(event, arg1)
    if arg1 == addonName then
        -- Initialize saved variables
        self:InitSV()

        -- Initialize settings
        self.InitializeSettings()
        frame:UnregisterEvent("ADDON_LOADED")
    end
end

function addon:PLAYER_LOGIN(event)
    -- Initialize saved variables and character info
    self:InitSV()
end

function addon:MAIL_SHOW(event)
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
                if frame.nextMail then
                    frame:Show()
                end
            end
        else
            frame.sendingMail = false
        end
    end
end

function addon:MAIL_SEND_SUCCESS(event)
    if frame.sendingMail then
        ClearSendMail()
        frame.nextMail = nil
        frame:SetNextMail()
        if not frame.nextMail and not frame.mailingList then
            frame:Hide()
        end
    end
end

function addon:MAIL_FAILED(event)
    frame:Hide()
    frame.nextMail = nil
    frame.mailingList = nil
    frame.sendingMail = false
    ClearSendMail()
end

function addon:MAIL_CLOSED(event)
    frame:Hide()
    frame.nextMail = nil
    frame.mailingList = nil
    frame.sendingMail = false
    ClearSendMail()
end

-- Dispatch events to addon methods
frame:SetScript("OnEvent", function(frame, event, ...)
    if type(addon[event]) == "function" then
        addon[event](addon, event, ...)
    end
end)

-- Slash command to open settings
SLASH_TRANSMOGMAILER1 = "/transmogmailer"
SlashCmdList["TRANSMOGMAILER"] = function()
    Settings.OpenToCategory(addon.categoryID)
end