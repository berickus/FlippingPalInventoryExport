-- InventoryExport.lua
-- Exports player inventory (bags + reagent bag) to CSV
-- Compatible with WoW 11.2+ / 12.0+ (The War Within)

local addon = FlippingPalExport

--------------------------
-- Bag Names
--------------------------

local BAG_NAMES = {
    [0] = "Backpack",
    [1] = "Bag 1",
    [2] = "Bag 2",
    [3] = "Bag 3",
    [4] = "Bag 4",
    [5] = "Reagent Bag"
}

--------------------------
-- Export Function
--------------------------

local function ExportInventory()
    local itemDataList = {}
    
    -- Scan regular bags (indices 0-4)
    for i, bagIndex in ipairs(addon.INVENTORY_BAGS) do
        if addon:IsCheckboxChecked(i) then
            local numSlots = addon:SafeGetContainerNumSlots(bagIndex)
            
            for slot = 1, numSlots do
                local itemInfo = addon:SafeGetContainerItemInfo(bagIndex, slot)
                if itemInfo and itemInfo.hyperlink then
                    local data = addon:GetItemExportData(itemInfo.hyperlink, itemInfo.stackCount, bagIndex, slot)
                    if data then
                        table.insert(itemDataList, data)
                    end
                end
            end
        end
    end
    
    -- Scan reagent bag (checkbox index 6)
    if addon:IsCheckboxChecked(6) then
        local bagIndex = addon.REAGENT_BAG
        local numSlots = addon:SafeGetContainerNumSlots(bagIndex)
        
        for slot = 1, numSlots do
            local itemInfo = addon:SafeGetContainerItemInfo(bagIndex, slot)
            if itemInfo and itemInfo.hyperlink then
                local data = addon:GetItemExportData(itemInfo.hyperlink, itemInfo.stackCount, bagIndex, slot)
                if data then
                    table.insert(itemDataList, data)
                end
            end
        end
    end
    
    -- Aggregate duplicates and format CSV lines
    local aggregated = addon:AggregateItems(itemDataList)
    local lines = { addon.CSV_HEADER }
    for _, data in ipairs(aggregated) do
        table.insert(lines, addon:FormatCSVLine(data))
    end
    
    return table.concat(lines)
end

--------------------------
-- Setup Config
--------------------------

local function SetupInventoryConfig()
    addon:ShowConfigFrame("inventory", "Inventory Export", ExportInventory)
    
    -- Setup checkboxes for regular bags
    for i, bagIndex in ipairs(addon.INVENTORY_BAGS) do
        local numSlots = addon:SafeGetContainerNumSlots(bagIndex)
        local bagName = BAG_NAMES[bagIndex] or ("Bag " .. bagIndex)
        
        if numSlots > 0 then
            bagName = bagName .. " (" .. numSlots .. " slots)"
        elseif bagIndex == 0 then
            bagName = bagName .. " (empty)"
        else
            bagName = bagName .. " (not equipped)"
        end
        
        -- Always show backpack, only show other bags if equipped
        if bagIndex == 0 or numSlots > 0 then
            addon:SetupCheckbox(i, bagName, true)
        end
    end
    
    -- Setup checkbox for reagent bag (index 6)
    local reagentSlots = addon:SafeGetContainerNumSlots(addon.REAGENT_BAG)
    if reagentSlots > 0 then
        local reagentName = BAG_NAMES[5] .. " (" .. reagentSlots .. " slots)"
        addon:SetupCheckbox(6, reagentName, true)
    end
end

--------------------------
-- Register Commands
--------------------------

addon.SetupInventoryConfig = SetupInventoryConfig
