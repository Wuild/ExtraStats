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
        for _, setID in ipairs(equipment:GetEquipmentSetIDsSorted()) do
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

    for _, setID in ipairs(equipment:GetEquipmentSetIDsSorted()) do
        local name, icon, _, equipped, missing = equipment:GetEquipmentSetInfo(setID)
        if equipped then
            return equipment, setID, name, icon, missing
        end
    end
end

local function GetItemLocationText(item)
    local location = ExtraStats:translate("gearsets.location_" .. item.location)
    if item.ignored then
        location = ExtraStats:translate("gearsets.location_ignored", location)
    end
    return location
end

local function AddSetItemsToTooltip(tooltip, equipment, setID, items)
    items = items or equipment:GetEquipmentSetTooltipItems(setID)
    if #items == 0 then
        return
    end
    tooltip:AddLine(" ")
    tooltip:AddLine(ExtraStats:translate("gearsets.items_header"), 1, 0.82, 0.2)
    for _, item in ipairs(items) do
        local location = GetItemLocationText(item)
        local r, g, b = 1, 1, 1
        if item.location == "equipped" then
            r, g, b = 0.2, 1, 0.2
        elseif item.location == "missing" then
            r, g, b = 1, 0.2, 0.2
        end
        local itemText = item.slotLabel .. ": " .. (item.itemLink or item.itemName)
        if tooltip.AddDoubleLine then
            tooltip:AddDoubleLine(itemText, location, 1, 1, 1, r, g, b)
        else
            tooltip:AddLine(itemText .. " — " .. location, r, g, b)
        end
    end
end

local function AddSetTooltip(tooltip, equipment, setID, name, missing)
    local items = equipment:GetEquipmentSetTooltipItems(setID)
    missing = 0
    for _, item in ipairs(items) do
        if item.location == "missing" then
            missing = missing + 1
        end
    end
    tooltip:AddLine(name or ExtraStats:translate("gearsets.single"))
    if (missing or 0) > 0 then
        tooltip:AddLine(ExtraStats:translate("gearsets.missing_count", missing), 1, 0.1, 0.1)
    else
        tooltip:AddLine(ExtraStats:translate("gearsets.all_equipped"), 0.2, 1, 0.2)
    end
    AddSetItemsToTooltip(tooltip, equipment, setID, items)
end

local function AddAllSetsTooltip(tooltip)
    local equipment = GetEquipmentSet()
    if not equipment then
        tooltip:AddLine(ExtraStats:translate("gearsets.none_saved"))
        return
    end

    local setIDs = equipment:GetEquipmentSetIDsSorted()
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

local function InitializeMenu(_, level, menuList)
    local equipment = GetEquipmentSet()
    if not equipment then
        return
    end

    if level == 2 then
        local setID = menuList or UIDROPDOWNMENU_MENU_VALUE
        if not setID then
            return
        end

        local equipInfo = UIDropDownMenu_CreateInfo()
        equipInfo.text = ExtraStats:translate("gearsets.equip")
        equipInfo.notCheckable = true
        equipInfo.func = function()
            equipment:UseEquipmentSet(setID)
            CloseDropDownMenus()
        end
        UIDropDownMenu_AddButton(equipInfo, level)

        if equipment:CanMoveEquipmentSetBank(setID, "toBank") then
            local moveToBankInfo = UIDropDownMenu_CreateInfo()
            moveToBankInfo.text = ExtraStats:translate("gearsets.move_to_bank")
            moveToBankInfo.notCheckable = true
            moveToBankInfo.disabled = equipment:IsBankTransferActive()
            moveToBankInfo.func = function()
                CloseDropDownMenus()
                ExtraStats_RequestEquipmentSetBankMove(setID, "toBank")
            end
            UIDropDownMenu_AddButton(moveToBankInfo, level)
        end

        if equipment:CanMoveEquipmentSetBank(setID, "fromBank") then
            local moveFromBankInfo = UIDropDownMenu_CreateInfo()
            moveFromBankInfo.text = ExtraStats:translate("gearsets.move_from_bank")
            moveFromBankInfo.notCheckable = true
            moveFromBankInfo.disabled = equipment:IsBankTransferActive()
            moveFromBankInfo.func = function()
                CloseDropDownMenus()
                ExtraStats_RequestEquipmentSetBankMove(setID, "fromBank")
            end
            UIDropDownMenu_AddButton(moveFromBankInfo, level)
        end
        return
    end

    if level ~= 1 then
        return
    end

    local setIDs = equipment:GetEquipmentSetIDsSorted()
    for _, setID in ipairs(setIDs) do
        local name, icon, _, equipped = equipment:GetEquipmentSetInfo(setID)
        local locationItems = equipment:GetEquipmentSetTooltipItems(setID)
        local missing = 0
        for _, item in ipairs(locationItems) do
            if item.location == "missing" then
                missing = missing + 1
            end
        end
        local info = UIDropDownMenu_CreateInfo()
        local displayName = name or ExtraStats:translate("gearsets.default_name", setID)
        info.text = (missing or 0) > 0 and "|cffff3333" .. displayName .. "|r" or displayName
        info.icon = icon or BROKER_ICON
        info.checked = equipped == true
        info.hasArrow = true
        info.menuList = setID
        info.value = setID
        local selectedSetID = setID
        info.func = function()
            equipment:UseEquipmentSet(selectedSetID)
            CloseDropDownMenus()
        end
        info.tooltipTitle = displayName
        local tooltipLines = {}
        if (missing or 0) > 0 then
            tooltipLines[#tooltipLines + 1] = "|cffff3333" .. ExtraStats:translate("gearsets.missing_count", missing) .. "|r"
        end
        tooltipLines[#tooltipLines + 1] = ExtraStats:translate("gearsets.items_header")
        for _, item in ipairs(locationItems) do
            local line = (item.slotLabel or ExtraStats:translate("common.slot"))
                .. ": " .. (item.itemLink or item.itemName or ExtraStats:translate("common.unknown"))
                .. " — " .. GetItemLocationText(item)
            if item.location == "missing" then
                line = "|cffff6666" .. line .. "|r"
            elseif item.location == "equipped" then
                line = "|cff66ff66" .. line .. "|r"
            end
            tooltipLines[#tooltipLines + 1] = line
        end
        info.tooltipText = table.concat(tooltipLines, "\n")
        info.tooltipOnButton = true
        info.keepShownOnClick = false
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
