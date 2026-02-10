-- BankExport.lua
-- Exports character bank contents to CSV
-- Compatible with WoW 11.2+ / 12.0+ (The War Within)

local addon = FlippingPalExport

--------------------------
-- Export Function
--------------------------

local function ExportCharacterBank()
    local list = { addon.CSV_HEADER }
    
    -- Scan character bank tabs (bag indices 6-11)
    for i, bagIndex in ipairs(addon.CHARACTER_BANK_TABS) do
        if addon:IsCheckboxChecked(i) then
            local numSlots = addon:SafeGetContainerNumSlots(bagIndex)
            
            for slot = 1, numSlots do
                local itemInfo = addon:SafeGetContainerItemInfo(bagIndex, slot)
                if itemInfo and itemInfo.hyperlink then
                    local data = addon:GetItemExportData(itemInfo.hyperlink, itemInfo.stackCount, bagIndex, slot)
                    if data then
                        table.insert(list, addon:FormatCSVLine(data))
                    end
                end
            end
        end
    end
    
    return table.concat(list)
end

--------------------------
-- Setup Config
--------------------------

local function SetupBankConfig()
    addon:ShowConfigFrame("bank", "Character Bank Export", ExportCharacterBank)
    
    -- Get number of purchased character bank tabs
    local numTabs = 1
    if C_Bank and C_Bank.FetchNumPurchasedBankTabs then
        numTabs = C_Bank.FetchNumPurchasedBankTabs(addon.BANK_TYPE_CHARACTER) or 1
    end
    
    -- Cap at 6 tabs maximum
    numTabs = math.max(1, math.min(6, numTabs))
    
    for i = 1, numTabs do
        local tabName = "Bank Tab " .. i
        
        -- Try to get actual tab name if API exists
        if C_Bank and C_Bank.FetchBankTabData then
            local tabData = C_Bank.FetchBankTabData(addon.BANK_TYPE_CHARACTER, i)
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

addon.SetupBankConfig = SetupBankConfig
