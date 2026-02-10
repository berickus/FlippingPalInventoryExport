-- Main.lua
-- Slash commands and event handling
-- Compatible with WoW 11.2+ / 12.0+ (The War Within)

local addon = FlippingPalExport

--------------------------
-- Slash Commands
--------------------------

-- Inventory Export
SLASH_INVENTORYEXPORT1 = "/inventoryexport"
SLASH_INVENTORYEXPORT2 = "/ie"
SLASH_INVENTORYEXPORT3 = "/bagexport"
SlashCmdList["INVENTORYEXPORT"] = function()
    addon.SetupInventoryConfig()
end

-- Bank Export
SLASH_BANKEXPORT1 = "/bankexport"
SLASH_BANKEXPORT2 = "/be"
SlashCmdList["BANKEXPORT"] = function()
    addon.SetupBankConfig()
end

-- Warbank Export
SLASH_WARBANKEXPORT1 = "/warbankexport"
SLASH_WARBANKEXPORT2 = "/wbe"
SlashCmdList["WARBANKEXPORT"] = function()
    addon.SetupWarbankConfig()
end

-- Main command with subcommands
SLASH_FPEXPORT1 = "/fpexport"
SLASH_FPEXPORT2 = "/fpe"
SlashCmdList["FPEXPORT"] = function(msg)
    msg = msg:lower():trim()
    
    if msg == "inventory" or msg == "bags" or msg == "bag" or msg == "inv" then
        addon.SetupInventoryConfig()
    elseif msg == "bank" or msg == "personal" or msg == "character" then
        addon.SetupBankConfig()
    elseif msg == "warbank" or msg == "account" or msg == "wb" then
        addon.SetupWarbankConfig()
    else
        addon:Print("Usage:")
        print("  " .. addon:PrintYellow("/inventoryexport") .. " or " .. addon:PrintYellow("/ie") .. " - Export inventory (bags)")
        print("  " .. addon:PrintYellow("/bankexport") .. " or " .. addon:PrintYellow("/be") .. " - Export character bank")
        print("  " .. addon:PrintYellow("/warbankexport") .. " or " .. addon:PrintYellow("/wbe") .. " - Export warbank")
        print("  " .. addon:PrintYellow("/fpexport [inventory|bank|warbank]") .. " or " .. addon:PrintYellow("/fpe [inventory|bank|warbank]") .. " - Export specific type")
    end
end

--------------------------
-- Event Handling
--------------------------

local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("ADDON_LOADED")
eventFrame:RegisterEvent("BANKFRAME_OPENED")

local shownMessages = {}

eventFrame:SetScript("OnEvent", function(self, event, arg1)
    if event == "ADDON_LOADED" and arg1 == addon.name then
        addon:Print("v" .. addon.version .. " loaded! Use " .. addon:PrintYellow("/fpexport") .. " for help.")
    elseif event == "BANKFRAME_OPENED" and not shownMessages.bank then
        addon:Print("Type " .. addon:PrintYellow("/bankexport") .. " or " .. addon:PrintYellow("/warbankexport") .. " to export.")
        shownMessages.bank = true
    end
end)
