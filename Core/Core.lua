-- Core.lua
-- Shared utilities, constants, and addon namespace
-- Compatible with WoW 11.2+ / 12.0+ (The War Within)

--------------------------
-- Addon Namespace
--------------------------

FlippingPalExport = FlippingPalExport or {}
local addon = FlippingPalExport
local GetAddOnMetadata = C_AddOns.GetAddOnMetadata

addon.name = GetAddOnMetadata(..., "Title")
addon.version = GetAddOnMetadata(..., "Version")

--------------------------
-- Bag Index Constants (TWW 11.2+)
-- Using raw numbers to avoid deprecated Enum issues
--------------------------

addon.INVENTORY_BAGS = {0, 1, 2, 3, 4}  -- Backpack + 4 bag slots
addon.REAGENT_BAG = 5                    -- Reagent bag slot
addon.CHARACTER_BANK_TABS = {6, 7, 8, 9, 10, 11}  -- Bank tabs (6 max)
addon.ACCOUNT_BANK_TABS = {12, 13, 14, 15, 16}    -- Warbank tabs (5 max)

-- Bank type enums for C_Bank API
addon.BANK_TYPE_CHARACTER = Enum.BankType.Character
addon.BANK_TYPE_ACCOUNT = Enum.BankType.Account

--------------------------
-- Debug Logging
--------------------------

function addon:DebugLog(msg)
    for i = 1, NUM_CHAT_WINDOWS do
        local name = GetChatWindowInfo(i)
        if name == "BEDebug" then
            local chatFrame = _G["ChatFrame" .. i]
            if chatFrame then
                chatFrame:AddMessage("|cff00ff00[BEDebug]|r " .. msg)
            end
            return
        end
    end
end

--------------------------
-- Safe Container Wrappers
--------------------------

function addon:SafeGetContainerNumSlots(bagIndex)
    local success, result = pcall(function()
        return C_Container.GetContainerNumSlots(bagIndex)
    end)
    if success and result then
        return result
    end
    return 0
end

function addon:SafeGetContainerItemInfo(bagIndex, slot)
    local success, result = pcall(function()
        return C_Container.GetContainerItemInfo(bagIndex, slot)
    end)
    if success then
        return result
    end
    return nil
end

--------------------------
-- Item Filtering Logic
--------------------------

-- Function to determine if an item in your bag is still WuE
local cTip = CreateFrame("GameTooltip", "MyScanTooltip", nil, "GameTooltipTemplate")

local function IsItemWarboundUntilEquipped(bag, slot)
    cTip:SetOwner(UIParent, "ANCHOR_NONE")
    cTip:SetBagItem(bag, slot)

    -- Check lines 2-4 for the binding info
    for i = 2, 5 do
        local line = _G["MyScanTooltipTextLeft"..i]
        if line then
            local text = line:GetText()
            -- You are looking for text that indicates it is still tradeable
            if text and (text:find("Binds to Warband until equipped") or text:find("Warbound until equipped")) then
                cTip:Hide()
                return true
            end
        end
    end
    cTip:Hide()
    return false
end

addon.bindTypeNames = {
    [0] = "None",
    [1] = "BoP",
    [2] = "BoE",
    [3] = "BoU",
    [4] = "Quest",
    [7] = "BtA",
    [8] = "BtW",
    [9] = "WuE"
}

-- Check if an item should be included in export (AH-tradeable non-commodity items only)
function addon:ShouldIncludeItem(itemLink, bagIndex, slotIndex)
    if not itemLink then return false end
    
    local itemName, _, _, _, _, _, _, stackCount, _, _, _, _, _, bindType = C_Item.GetItemInfo(itemLink)
    
    -- Exclude commodities (stackable items: reagents, gems, enchants, etc.)
    -- Commodities have a max stack size > 1
    if stackCount and stackCount > 1 then
        return false
    end
    
    local bindTypeName = self.bindTypeNames[bindType] or ("Unknown(" .. tostring(bindType) .. ")")
    local isBoundStr = "N/A"
    
    if bagIndex and slotIndex then
        local itemInfo = C_Container.GetContainerItemInfo(bagIndex, slotIndex)
        if itemInfo then
            isBoundStr = itemInfo.isBound and "Yes" or "No"
        end
    end
    
    -- bindType: 0 = none, 1 = BoP, 2 = BoE, 3 = BoU, 4 = Quest, 
    --           7 = BtA (Bind to Account), 8 = BtW (Bind to Warband), 9 = WuE (Warbound until Equipped)
    
    -- Skip BoP or Quest items (can never be sold)
    if bindType == 1 or bindType == 4 then
        return false
    end
    
    -- Skip account-bound items (BtA, BtW, WuE - can never be sold on AH)
    if bindType == 7 or bindType == 8 or bindType == 9 then
        return false
    end
    
    -- For BoE items, check if already bound
    if bindType == 2 then
        if bagIndex and slotIndex then
            local itemInfo = C_Container.GetContainerItemInfo(bagIndex, slotIndex)
            if itemInfo and itemInfo.isBound then
                return false
            end

            if IsItemWarboundUntilEquipped(bagIndex, slotIndex) then
                return false
            end
        end
    end

    return true
end

--------------------------
-- Print Helpers
--------------------------

function addon:Print(msg)
    print("|cffff0000" .. self.name .. ":|r " .. msg)
end

function addon:PrintYellow(msg)
    return "|cffffff00" .. msg .. "|r"
end
