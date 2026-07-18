local Plugin = {
    name = "Gear Sets (Titan/Bazooka)",
}

ExtraStats:RegisterPlugin(Plugin)

local BROKER_NAME = "ExtraStats_GearSets"
local BROKER_ICON = "Interface\\Icons\\INV_Misc_ArmorKit_23"
local menuFrame
local dataObject

local function GetEquipmentSet()
    return ExtraStats:GetModule("EquipmentSet")
end

local function RefreshBrokerText()
    if not dataObject then
        return
    end

    local equipment = GetEquipmentSet()
    local name, icon
    if equipment then
        for _, setID in ipairs(equipment:GetEquipmentSetIDs()) do
            local setName, setIcon, _, equipped = equipment:GetEquipmentSetInfo(setID)
            if equipped then
                name = setName
                icon = setIcon
                break
            end
        end
    end
    dataObject.text = name or "Gear Sets"
    dataObject.icon = icon or BROKER_ICON
end

local function GetActiveSetInfo()
    local equipment = GetEquipmentSet()
    if not equipment then
        return nil
    end

    for _, setID in ipairs(equipment:GetEquipmentSetIDs()) do
        local name, icon, _, equipped, missing = equipment:GetEquipmentSetInfo(setID)
        if equipped then
            return equipment, setID, name, icon, missing
        end
    end
end

local function AddSetTooltip(tooltip, equipment, setID, name, missing)
    tooltip:AddLine(name or "Gear Set")
    if (missing or 0) > 0 then
        tooltip:AddLine(string.format("Missing items: %d", missing), 1, 0.1, 0.1)
        for _, item in ipairs(equipment:GetMissingEquipmentSetItems(setID)) do
            tooltip:AddLine(string.format("%s: %s", item.slotLabel or "Slot", item.itemName or "Unknown"), 1, 0.2, 0.2)
        end
    else
        tooltip:AddLine("All items equipped", 0.2, 1, 0.2)
    end
end

local function AddAllSetsTooltip(tooltip)
    local equipment = GetEquipmentSet()
    if not equipment then
        tooltip:AddLine("No gear sets saved")
        return
    end

    local setIDs = equipment:GetEquipmentSetIDs()
    if #setIDs == 0 then
        tooltip:AddLine("No gear sets saved")
        return
    end

    tooltip:AddLine("ExtraStats Gear Sets", 0.4, 0.8, 1.0)
    for _, setID in ipairs(setIDs) do
        local name, icon, _, equipped, missing = equipment:GetEquipmentSetInfo(setID)
        local prefix = equipped and "|cFF66FF66*|r " or ""
        local setColor = equipped and { 0.2, 1.0, 0.2 } or { 1.0, 0.82, 0.2 }
        tooltip:AddLine(prefix .. (name or ("Set " .. setID)), setColor[1], setColor[2], setColor[3])
        if (missing or 0) > 0 then
            tooltip:AddLine(string.format("  Missing items: %d", missing), 1.0, 0.1, 0.1)
        else
            tooltip:AddLine("  Complete", 0.2, 1.0, 0.2)
        end
    end
end

local function InitializeMenu(_, level)
    if level ~= 1 then
        return
    end

    local equipment = GetEquipmentSet()
    if not equipment then
        return
    end

    local setIDs = equipment:GetEquipmentSetIDs()
    for _, setID in ipairs(setIDs) do
        local name, icon, _, equipped = equipment:GetEquipmentSetInfo(setID)
        local _, _, _, _, missing = equipment:GetEquipmentSetInfo(setID)
        local info = UIDropDownMenu_CreateInfo()
        local displayName = name or ("Set " .. setID)
        info.text = (missing or 0) > 0 and "|cffff3333" .. displayName .. "|r" or displayName
        info.icon = icon or BROKER_ICON
        info.checked = equipped == true
        info.tooltipTitle = displayName
        local tooltipLines = {}
        if (missing or 0) > 0 then
            tooltipLines[#tooltipLines + 1] = "|cffff3333Missing items: " .. missing .. "|r"
            for _, item in ipairs(equipment:GetMissingEquipmentSetItems(setID)) do
                tooltipLines[#tooltipLines + 1] = "|cffff6666" .. (item.slotLabel or "Slot") .. ": " .. (item.itemName or "Unknown") .. "|r"
            end
        end
        info.tooltipText = #tooltipLines > 0 and table.concat(tooltipLines, "\n") or nil
        info.tooltipOnButton = #tooltipLines > 0
        info.keepShownOnClick = false
        info.func = function()
            equipment:UseEquipmentSet(setID)
            CloseDropDownMenus()
        end
        UIDropDownMenu_AddButton(info, level)
    end

    if #setIDs == 0 then
        local info = UIDropDownMenu_CreateInfo()
        info.text = "No gear sets saved"
        info.disabled = true
        UIDropDownMenu_AddButton(info, level)
    end
end

local function ShowMenu(anchor)
    if not menuFrame then
        menuFrame = CreateFrame("Frame", "ExtraStatsGearSetsBrokerMenu", UIParent, "UIDropDownMenuTemplate")
        UIDropDownMenu_Initialize(menuFrame, InitializeMenu, "MENU")
    end

    GameTooltip:Hide()
    ToggleDropDownMenu(1, nil, menuFrame, anchor, 0, 0)
end

function Plugin:Setup()
    if ExtraStats.db.char.disabledPlugins[self.name] == true then
        return
    end

    local broker = LibStub and LibStub("LibDataBroker-1.1", true)
    if not broker then
        return
    end

    dataObject = broker:NewDataObject(BROKER_NAME, {
        type = "data source",
        label = "ExtraStats Gear Sets",
        icon = BROKER_ICON,
        text = "Gear Sets",
        OnClick = function(self)
            ShowMenu(self)
        end,
        OnTooltipShow = function(tooltip)
            local equipment, setID, name, _, missing = GetActiveSetInfo()
            if equipment then
                AddSetTooltip(tooltip, equipment, setID, name, missing)
            else
                tooltip:AddLine("No active gear set")
                tooltip:AddLine("Click to choose a gear set.", 1, 1, 1)
            end
        end,
    })

    ExtraStats:On("gear.update", RefreshBrokerText)
    ExtraStats:On("gear.swap.finished", RefreshBrokerText)
    RefreshBrokerText()
    C_Timer.After(1, RefreshBrokerText)
end
