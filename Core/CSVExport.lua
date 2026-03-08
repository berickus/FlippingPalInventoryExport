-- CSVExport.lua
-- CSV generation and item data extraction
-- Compatible with WoW 11.2+ / 12.0+ (The War Within)
local addon = FlippingPalExport

--------------------------
-- CSV Header
--------------------------

addon.CSV_HEADER = "itemID;itemName;quality;ilvl;bonusIDs;modifiers;quantity\n"

-- Quality names matching WoW's Enum.ItemQuality values
addon.QUALITY_NAMES = {
    [0] = "Poor",
    [1] = "Common",
    [2] = "Uncommon",
    [3] = "Rare",
    [4] = "Epic",
    [5] = "Legendary",
    [6] = "Artifact",
    [7] = "Heirloom"
}

--------------------------
-- Item Data Extraction
--------------------------

function addon:GetItemExportData(itemLink, quantity, bagIndex, slotIndex)
    if not itemLink then return nil end

    addon:DebugLog("[Export] ---- Processing item ----")
    addon:DebugLog("[Export] Link: " .. tostring(itemLink))

    -- Check if item should be included (AH-tradeable)
    if not self:ShouldIncludeItem(itemLink, bagIndex, slotIndex) then
        addon:DebugLog("[Export] SKIP: ShouldIncludeItem returned false")
        return nil
    end
    addon:DebugLog("[Export] PASS: ShouldIncludeItem returned true")

    -- Handle caged battle pets separately
    -- battlepet link format: |Hbattlepet:speciesID:level:quality:maxHealth:power:speed:...|h[Pet Name]|h
    local speciesID, petLevel, petQuality = itemLink:match(
                                                "|Hbattlepet:(%d+):(%d+):(%d+)")
    if speciesID then
        local petName = itemLink:match("|h%[(.-)%]|h") or "Unknown Pet"
        addon:DebugLog(
            "[Export] Battle pet detected - species: " .. speciesID ..
                " level: " .. petLevel .. " quality: " .. petQuality ..
                " name: " .. petName)

        -- Use speciesID as the itemID, pet level as ilvl
        -- Pet quality uses same values as item quality (0=Poor through 4=Epic)
        local qualityName = addon.QUALITY_NAMES[tonumber(petQuality)] or
                                ("Unknown(" .. petQuality .. ")")
        return {
            itemID = "pet:" .. speciesID,
            itemName = petName,
            quality = qualityName,
            ilvl = tonumber(petLevel) or 0,
            bonusIDs = "q" .. petQuality,
            modifiers = "",
            quantity = quantity or 1
        }
    end

    -- Standard item handling below
    -- Get item ID
    local itemID = C_Item.GetItemIDForItemInfo(itemLink)
    addon:DebugLog("[Export] GetItemIDForItemInfo: " .. tostring(itemID))
    if not itemID or itemID == 0 then
        addon:DebugLog("[Export] SKIP: itemID is nil or 0")
        return nil
    end

    -- Get item name and quality
    local itemName, _, itemQuality = C_Item.GetItemInfo(itemLink)
    addon:DebugLog("[Export] GetItemInfo name: " .. tostring(itemName))
    if not itemName then itemName = "Unknown Item" end
    local qualityName = addon.QUALITY_NAMES[itemQuality] or
                            ("Unknown(" .. tostring(itemQuality) .. ")")

    -- Get item level
    local effectiveILvl, previewILvl, baseILvl =
        C_Item.GetDetailedItemLevelInfo(itemLink)
    addon:DebugLog("[Export] ilvl - effective: " .. tostring(effectiveILvl) ..
                       " base: " .. tostring(baseILvl))
    local ilvl = effectiveILvl or baseILvl or 0

    -- Parse bonus IDs and modifiers from item link
    local bonusIDs, modifiers = self:ParseItemLink(itemLink)
    addon:DebugLog("[Export] bonusIDs: '" .. bonusIDs .. "' modifiers: '" ..
                       modifiers .. "'")

    addon:DebugLog("[Export] SUCCESS: Item will be exported (ID=" ..
                       tostring(itemID) .. " Name=" .. itemName .. " Quality=" ..
                       qualityName .. ")")
    return {
        itemID = itemID,
        itemName = itemName,
        quality = qualityName,
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
    if not itemString then return bonusIDs, modifiers end

    local parts = {strsplit(":", itemString)}

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

    if #parts < 14 then return bonusIDs, modifiers end

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
            if modType and modValue and modType ~= "" and modValue ~= "" and
                modType == "9" then
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
    return string.format("%s;%s;%s;%s;%s;%s;%s\n", tostring(data.itemID),
                         safeName, tostring(data.quality), tostring(data.ilvl),
                         data.bonusIDs, data.modifiers, tostring(data.quantity))
end

--------------------------
-- Item Aggregation
--------------------------

-- Build a unique key from the fields that identify a "same" item
function addon:GetItemKey(data)
    return string.format("%s;%s;%s", tostring(data.itemID), data.bonusIDs,
                         data.modifiers)
end

-- Aggregate a list of item data tables, summing quantities for duplicates
function addon:AggregateItems(itemDataList)
    local keyMap = {} -- key -> aggregated data
    local order = {} -- preserve insertion order

    for _, data in ipairs(itemDataList) do
        local key = self:GetItemKey(data)
        if keyMap[key] then
            keyMap[key].quantity = keyMap[key].quantity + data.quantity
        else
            -- Copy the data so we don't mutate the original
            keyMap[key] = {
                itemID = data.itemID,
                itemName = data.itemName,
                quality = data.quality,
                ilvl = data.ilvl,
                bonusIDs = data.bonusIDs,
                modifiers = data.modifiers,
                quantity = data.quantity
            }
            table.insert(order, key)
        end
    end

    local aggregated = {}
    for _, key in ipairs(order) do table.insert(aggregated, keyMap[key]) end
    return aggregated
end
