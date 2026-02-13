-- WarbankExport.lua
-- Exports account bank (warbank) contents to CSV
-- Compatible with WoW 11.2+ / 12.0+ (The War Within)

local addon = FlippingPalExport

--------------------------
-- Export Function
--------------------------

local function ExportAccountBank()
    local itemDataList = {}
    
    -- Scan account bank tabs (bag indices 12-16)
    for i, bagIndex in ipairs(addon.ACCOUNT_BANK_TABS) do
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

local function SetupWarbankConfig()
    addon:ShowConfigFrame("warbank", "Warbank Export", ExportAccountBank)
    
    -- Get number of purchased account bank tabs
    local numTabs = 1
    if C_Bank and C_Bank.FetchNumPurchasedBankTabs then
        numTabs = C_Bank.FetchNumPurchasedBankTabs(addon.BANK_TYPE_ACCOUNT) or 1
    end
    
    -- Cap at 5 tabs maximum for warbank
    numTabs = math.max(1, math.min(5, numTabs))
    
    for i = 1, numTabs do
        local tabName = "Warbank Tab " .. i
        
        -- Try to get actual tab name if API exists
        if C_Bank and C_Bank.FetchBankTabData then
            -- Note: Account bank tabs are 0-indexed in this API
            local tabData = C_Bank.FetchBankTabData(addon.BANK_TYPE_ACCOUNT, i - 1)
            if tabData and tabData.name and tabData.name ~= "" then
                tabName = tabData.name
            end
        end
        
        addon:SetupCheckbox(i, tabName, true)
    end
end

--------------------------
-- Register Commands
--------------------------

addon.SetupWarbankConfig = SetupWarbankConfig
