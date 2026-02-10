-- UI.lua
-- Shared UI components: Export frame and Config frame
-- Compatible with WoW 11.2+ / 12.0+ (The War Within)

local addon = FlippingPalExport

--------------------------
-- Export Result Frame
--------------------------

local exportFrame = CreateFrame("Frame", "FlippingPalExportFrame", UIParent, "DialogBoxFrame")
exportFrame:ClearAllPoints()
exportFrame:SetPoint("CENTER")
exportFrame:SetSize(700, 600)
exportFrame:SetBackdrop({
    bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
    edgeFile = "Interface\\PVPFrame\\UI-Character-PVP-Highlight",
    edgeSize = 16,
    insets = { left = 8, right = 8, top = 8, bottom = 8 },
})
exportFrame:SetMovable(true)
exportFrame:SetClampedToScreen(true)
exportFrame:SetScript("OnMouseDown", function(self, button)
    if button == "LeftButton" then
        self:StartMoving()
    end
end)
exportFrame:SetScript("OnMouseUp", function(self)
    self:StopMovingOrSizing()
end)

-- Scroll frame
local scrollFrame = CreateFrame("ScrollFrame", "FlippingPalExportScrollFrame", exportFrame, "UIPanelScrollFrameTemplate")
scrollFrame:SetPoint("LEFT", 16, 0)
scrollFrame:SetPoint("RIGHT", -32, 0)
scrollFrame:SetPoint("TOP", 0, -32)
scrollFrame:SetPoint("BOTTOM", FlippingPalExportFrameButton, "TOP", 0, 0)

-- Edit box for CSV output
local editBox = CreateFrame("EditBox", "FlippingPalExportEditBox", scrollFrame)
editBox:SetSize(scrollFrame:GetSize())
editBox:SetMultiLine(true)
editBox:SetAutoFocus(true)
editBox:SetFontObject("ChatFontNormal")
editBox:SetScript("OnEscapePressed", function() exportFrame:Hide() end)
scrollFrame:SetScrollChild(editBox)

-- Resizing
exportFrame:SetResizable(true)
exportFrame:SetResizeBounds(400, 300, 1200, 900)

local resizeButton = CreateFrame("Button", "FlippingPalExportResizeButton", exportFrame)
resizeButton:SetPoint("BOTTOMRIGHT", -6, 7)
resizeButton:SetSize(16, 16)
resizeButton:SetNormalTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Up")
resizeButton:SetHighlightTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Highlight")
resizeButton:SetPushedTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Down")

resizeButton:SetScript("OnMouseDown", function(self, button)
    if button == "LeftButton" then
        exportFrame:StartSizing("BOTTOMRIGHT")
        self:GetHighlightTexture():Hide()
    end
end)
resizeButton:SetScript("OnMouseUp", function(self)
    exportFrame:StopMovingOrSizing()
    self:GetHighlightTexture():Show()
    editBox:SetWidth(scrollFrame:GetWidth())
end)

exportFrame:Hide()

-- Store reference
addon.exportFrame = exportFrame
addon.exportEditBox = editBox

--------------------------
-- Config Frame
--------------------------

local configFrame = CreateFrame("Frame", "FlippingPalConfigFrame", UIParent, "BasicFrameTemplateWithInset")
configFrame:SetSize(250, 420)
configFrame:SetPoint("CENTER", UIParent, "CENTER")
configFrame:SetMovable(true)
configFrame:EnableMouse(true)
configFrame:RegisterForDrag("LeftButton")
configFrame:SetScript("OnDragStart", configFrame.StartMoving)
configFrame:SetScript("OnDragStop", configFrame.StopMovingOrSizing)

-- Title
configFrame.title = configFrame:CreateFontString(nil, "OVERLAY")
configFrame.title:SetFontObject("GameFontHighlight")
configFrame.title:SetPoint("LEFT", configFrame.TitleBg, "LEFT", 5, 0)
configFrame.title:SetText("Export Config")

-- Export mode tracking
configFrame.exportMode = nil
configFrame.exportFunction = nil

-- Type Label
configFrame.typeLabel = configFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
configFrame.typeLabel:SetPoint("TOP", configFrame, "TOP", 0, -35)
configFrame.typeLabel:SetText("Export Type")

--------------------------
-- Checkboxes
--------------------------

local checkboxStartY = -60
local checkboxSpacing = 30
local MAX_CHECKBOXES = 8

configFrame.checkBoxes = {}
for i = 1, MAX_CHECKBOXES do
    local cb = CreateFrame("CheckButton", nil, configFrame, "UICheckButtonTemplate")
    cb:SetPoint("TOPLEFT", configFrame, "TOPLEFT", 15, checkboxStartY - (i * checkboxSpacing))
    cb.text:SetFontObject("GameFontNormalLarge")
    cb:SetSize(30, 30)
    cb:Hide()
    configFrame.checkBoxes[i] = cb
end

--------------------------
-- Export Button
--------------------------

configFrame.exportButton = CreateFrame("Button", nil, configFrame, "GameMenuButtonTemplate")
configFrame.exportButton:SetPoint("BOTTOM", configFrame, "BOTTOM", 0, 15)
configFrame.exportButton:SetSize(140, 40)
configFrame.exportButton:SetText("Export")
configFrame.exportButton:SetNormalFontObject("GameFontNormalLarge")
configFrame.exportButton:SetHighlightFontObject("GameFontHighlightLarge")

configFrame.exportButton:SetScript("OnClick", function()
    configFrame:Hide()
    
    if configFrame.exportFunction then
        local exportText = configFrame.exportFunction()
        addon.exportEditBox:SetText(exportText)
        addon.exportFrame:Show()
        addon.exportEditBox:HighlightText()
        addon.exportEditBox:SetFocus(true)
    end
end)

configFrame:Hide()

-- Store reference
addon.configFrame = configFrame

--------------------------
-- UI Helper Functions
--------------------------

function addon:HideAllCheckboxes()
    for i = 1, MAX_CHECKBOXES do
        self.configFrame.checkBoxes[i]:Hide()
    end
end

function addon:SetupCheckbox(index, text, checked)
    local cb = self.configFrame.checkBoxes[index]
    if cb then
        cb.text:SetText(text)
        cb:Show()
        cb:SetChecked(checked ~= false) -- Default to checked
    end
end

function addon:IsCheckboxChecked(index)
    local cb = self.configFrame.checkBoxes[index]
    return cb and cb:IsShown() and cb:GetChecked()
end

function addon:ShowConfigFrame(mode, title, exportFunc)
    self:HideAllCheckboxes()
    self.configFrame.exportMode = mode
    self.configFrame.typeLabel:SetText(title)
    self.configFrame.exportFunction = exportFunc
    self.configFrame:Show()
end
