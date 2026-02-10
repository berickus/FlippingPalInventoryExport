-- CSVExport.lua
-- CSV generation and item data extraction
-- Compatible with WoW 11.2+ / 12.0+ (The War Within)

local addon = FlippingPalExport

--------------------------
-- CSV Header
--------------------------

addon.CSV_HEADER = "itemID;itemName;ilvl;bonusIDs;modifiers;quantity\n"

--------------------------
-- Item Data Extraction
--------------------------

function addon:GetItemExportData(itemLink, quantity, bagIndex, slotIndex)
    if not itemLink then return nil end
    
    -- Check if item should be included (AH-tradeable)
    if not self:ShouldIncludeItem(itemLink, bagIndex, slotIndex) then
        return nil
    end
    
    -- Get item ID
    local itemID = C_Item.GetItemIDForItemInfo(itemLink)
    if not itemID or itemID == 0 then return nil end
    
    -- Get item name
    local itemName = C_Item.GetItemInfo(itemLink)
    if not itemName then 
        itemName = "Unknown Item" 
    end
    
    -- Get item level
    local effectiveILvl, previewILvl, baseILvl = C_Item.GetDetailedItemLevelInfo(itemLink)
    local ilvl = effectiveILvl or baseILvl or 0
    
    -- Parse bonus IDs and modifiers from item link
    local bonusIDs, modifiers = self:ParseItemLink(itemLink)
    
    return {
        itemID = itemID,
        itemName = itemName,
        ilvl = ilvl,
        bonusIDs = bonusIDs,
        modifiers = modifiers,
        quantity = quantity or 1
    }
end

--------------------------
-- Item Link Parsing
--------------------------

function addon:ParseItemLink(itemLink)
    local bonusIDs = ""
    local modifiers = ""
    
    -- Extract the item string from the link
    local itemString = itemLink:match("item[%-?%d:]+")
    if not itemString then
        return bonusIDs, modifiers
    end
    
    local parts = { strsplit(":", itemString) }
    
    -- Parts layout (1-indexed in Lua):
    -- 1: "item"
    -- 2: itemID
    -- 3: enchantID
    -- 4-7: gem1-4
    -- 8: suffixID
    -- 9: uniqueID
    -- 10: level
    -- 11: specializationID
    -- 12: modifiersMask
    -- 13: itemContext
    -- 14: numBonusIDs
    -- 15+: bonusIDs (numBonusIDs count)
    -- After bonusIDs: numModifiers, then modifierType:modifierValue pairs
    
    if #parts < 14 then
        return bonusIDs, modifiers
    end
    
    local numBonusIDs = tonumber(parts[14]) or 0
    local bonusIDList = {}
    
    for i = 1, numBonusIDs do
        local bonusID = parts[14 + i]
        if bonusID and bonusID ~= "" then
            table.insert(bonusIDList, bonusID)
        end
    end
    bonusIDs = table.concat(bonusIDList, ":")
    
    -- Get modifiers after bonus IDs
    local modifierStartIndex = 14 + numBonusIDs + 1
    if #parts >= modifierStartIndex then
        local numModifiers = tonumber(parts[modifierStartIndex]) or 0
        local modifierList = {}
        
        for i = 1, numModifiers do
            local modType = parts[modifierStartIndex + (i * 2) - 1]
            local modValue = parts[modifierStartIndex + (i * 2)]
            if modType and modValue and modType ~= "" and modValue ~= "" then
                table.insert(modifierList, modType .. "=" .. modValue)
            end
        end
        modifiers = table.concat(modifierList, ":")
    end
    
    return bonusIDs, modifiers
end

--------------------------
-- CSV Line Formatting
--------------------------

function addon:FormatCSVLine(data)
    -- Escape semicolons in item name (replace with comma)
    local safeName = data.itemName:gsub(";", ",")
    return string.format("%s;%s;%s;%s;%s;%s\n",
        tostring(data.itemID),
        safeName,
        tostring(data.ilvl),
        data.bonusIDs,
        data.modifiers,
        tostring(data.quantity)
    )
end

--------------------------
-- Generic Bag Scanner
--------------------------

function addon:ScanBags(bagIndices, checkboxOffset)
    local lines = {}
    
    checkboxOffset = checkboxOffset or 0
    
    for i, bagIndex in ipairs(bagIndices) do
        local checkboxIndex = i + checkboxOffset
        if self:IsCheckboxChecked(checkboxIndex) then
            local numSlots = self:SafeGetContainerNumSlots(bagIndex)
            
            for slot = 1, numSlots do
                local itemInfo = self:SafeGetContainerItemInfo(bagIndex, slot)
                if itemInfo and itemInfo.hyperlink then
                    local data = self:GetItemExportData(itemInfo.hyperlink, itemInfo.stackCount, bagIndex, slot)
                    if data then
                        table.insert(lines, self:FormatCSVLine(data))
                    end
                end
            end
        end
    end
    
    return lines
end
