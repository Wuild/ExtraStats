local Plugin = {
    name = "Gear Sets (Titan/Bazooka)",
    displayNameKey = "gearsets.broker_plugin",
}

ExtraStats:RegisterPlugin(Plugin)

local BROKER_NAME = "ExtraStats_GearSets"
local BROKER_ICON = "Interface\\Icons\\INV_Misc_ArmorKit_23"
local menuFrame
local dataObject

local function GetEquipmentSet()
    return ExtraStats:GetModule("EquipmentSet")
end

local function RefreshDisplay()
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
    if dataObject then
        dataObject.text = name or ExtraStats:translate("gearsets.name")
        dataObject.icon = icon or BROKER_ICON
    end
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
    tooltip:AddLine(name or ExtraStats:translate("gearsets.single"))
    if (missing or 0) > 0 then
        tooltip:AddLine(ExtraStats:translate("gearsets.missing_count", missing), 1, 0.1, 0.1)
        for _, item in ipairs(equipment:GetMissingEquipmentSetItems(setID)) do
            tooltip:AddLine(string.format("%s: %s", item.slotLabel or ExtraStats:translate("common.slot"), item.itemName or ExtraStats:translate("common.unknown")), 1, 0.2, 0.2)
        end
    else
        tooltip:AddLine(ExtraStats:translate("gearsets.all_equipped"), 0.2, 1, 0.2)
    end
end

local function AddAllSetsTooltip(tooltip)
    local equipment = GetEquipmentSet()
    if not equipment then
        tooltip:AddLine(ExtraStats:translate("gearsets.none_saved"))
        return
    end

    local setIDs = equipment:GetEquipmentSetIDs()
    if #setIDs == 0 then
        tooltip:AddLine(ExtraStats:translate("gearsets.none_saved"))
        return
    end

    tooltip:AddLine(ExtraStats:translate("gearsets.title"), 0.4, 0.8, 1.0)
    for _, setID in ipairs(setIDs) do
        local name, icon, _, equipped, missing = equipment:GetEquipmentSetInfo(setID)
        local prefix = equipped and "|cFF66FF66*|r " or ""
        local setColor = equipped and { 0.2, 1.0, 0.2 } or { 1.0, 0.82, 0.2 }
        tooltip:AddLine(prefix .. (name or ExtraStats:translate("gearsets.default_name", setID)), setColor[1], setColor[2], setColor[3])
        if (missing or 0) > 0 then
            tooltip:AddLine("  " .. ExtraStats:translate("gearsets.missing_count", missing), 1.0, 0.1, 0.1)
        else
            tooltip:AddLine("  " .. ExtraStats:translate("gearsets.complete"), 0.2, 1.0, 0.2)
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
        local displayName = name or ExtraStats:translate("gearsets.default_name", setID)
        info.text = (missing or 0) > 0 and "|cffff3333" .. displayName .. "|r" or displayName
        info.icon = icon or BROKER_ICON
        info.checked = equipped == true
        info.tooltipTitle = displayName
        local tooltipLines = {}
        if (missing or 0) > 0 then
            tooltipLines[#tooltipLines + 1] = "|cffff3333" .. ExtraStats:translate("gearsets.missing_count", missing) .. "|r"
            for _, item in ipairs(equipment:GetMissingEquipmentSetItems(setID)) do
                tooltipLines[#tooltipLines + 1] = "|cffff6666" .. (item.slotLabel or ExtraStats:translate("common.slot")) .. ": " .. (item.itemName or ExtraStats:translate("common.unknown")) .. "|r"
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
        info.text = ExtraStats:translate("gearsets.none_saved")
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

local function OpenEquipmentTab()
    if not CharacterFrame then
        return
    end

    ShowUIPanel(CharacterFrame)
    if CharacterFrame_ShowSubFrame then
        CharacterFrame_ShowSubFrame("PaperDollFrame")
    elseif PaperDollFrame then
        PaperDollFrame:Show()
    end

    if ExtraStats.window and ExtraStats.window.HandleTabClick then
        ExtraStats.window:HandleTabClick(3)
    end
end

function Plugin:Settings(configsTable)
    configsTable.general.args.behavior.args.gearSetsMinimap = {
        name = ExtraStats:translate("gearsets.show_minimap"),
        desc = ExtraStats:translate("gearsets.show_minimap_desc"),
        type = "toggle",
        order = 4,
        width = "full",
        disabled = function()
            return ExtraStats.db.char.disabledPlugins[self.name] == true
        end,
        get = function()
            return ExtraStats.db.char.gearSetsMinimap.hide ~= true
        end,
        set = function(_, shown)
            local settings = ExtraStats.db.char.gearSetsMinimap
            settings.hide = not shown

            local dbIcon = LibStub("LibDBIcon-1.0", true)
            if not dbIcon or not dbIcon:IsRegistered(BROKER_NAME) then
                return
            end
            if shown then
                dbIcon:Show(BROKER_NAME)
            else
                dbIcon:Hide(BROKER_NAME)
            end
        end,
    }
end

function Plugin:Setup()
    if ExtraStats.db.char.disabledPlugins[self.name] == true then
        return
    end

    local broker = LibStub("LibDataBroker-1.1")
    local dbIcon = LibStub("LibDBIcon-1.0")
    dataObject = broker:NewDataObject(BROKER_NAME, {
        type = "data source",
        label = ExtraStats:translate("gearsets.title"),
        icon = BROKER_ICON,
        text = ExtraStats:translate("gearsets.name"),
        OnClick = function(self, button)
            if button == "RightButton" then
                OpenEquipmentTab()
            else
                ShowMenu(self)
            end
        end,
        OnTooltipShow = function(tooltip)
            local equipment, setID, name, _, missing = GetActiveSetInfo()
            if equipment then
                AddSetTooltip(tooltip, equipment, setID, name, missing)
            else
                tooltip:AddLine(ExtraStats:translate("gearsets.no_active"))
            end
            tooltip:AddLine(ExtraStats:translate("gearsets.left_click"), 1, 1, 1)
            tooltip:AddLine(ExtraStats:translate("gearsets.right_click"), 1, 1, 1)
        end,
    })

    local minimapSettings = ExtraStats.db.char.gearSetsMinimap
    local previousAngle = rawget(minimapSettings, "angle")
    if previousAngle and rawget(minimapSettings, "minimapPos") == nil then
        minimapSettings.minimapPos = previousAngle
        minimapSettings.angle = nil
    end
    dbIcon:Register(BROKER_NAME, dataObject, minimapSettings)

    ExtraStats:On("gear.update", RefreshDisplay)
    ExtraStats:On("gear.swap.finished", RefreshDisplay)
    RefreshDisplay()
    C_Timer.After(1, RefreshDisplay)
end
