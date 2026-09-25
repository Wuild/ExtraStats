local addonName = ...
local _, _, _, interface = GetBuildInfo()
if interface < 16000 or interface >= 17000 then return end

local events = CreateFrame("Frame")
local lastGroup, pendingGroup
local groupNames = { PRIMARY_TALENT_SPEC or "Primary specialization", SECONDARY_TALENT_SPEC or "Secondary specialization" }

local function GetGroupLabel(group)
    local fallback = groupNames[group] or ("Specialization " .. group)
    if not C_Traits or not C_SpecializationInfo.GetCombatConfigIDForSpecGroup then return fallback end
    local configID = C_SpecializationInfo.GetCombatConfigIDForSpecGroup(group)
    if not configID then return fallback end
    local config = C_Traits.GetConfigInfo(configID)
    if not config or not config.treeIDs then return fallback end
    for _, treeID in ipairs(config.treeIDs) do
        local ordered, groupIDs, points = {}, {}, {}
        for _, display in ipairs(C_Traits.GetGroupDisplayInfoByTreeID(treeID) or {}) do
            table.insert(ordered, display)
        end
        table.sort(ordered, function(a,b) return a.orderIndex < b.orderIndex end)
        for _, display in ipairs(ordered) do table.insert(groupIDs, display.groupID) end
        for _, info in ipairs(C_Traits.GetGroupCurrencyInfo(configID, groupIDs) or {}) do
            local currency = info.currencyInfos and info.currencyInfos[1]
            points[info.traitNodeGroupID] = currency and currency.spent or 0
        end
        local name, highest = nil, 0
        for _, display in ipairs(ordered) do
            local spent = points[display.groupID] or 0
            if not (issecretvalue and issecretvalue(spent)) and spent > highest then
                name, highest = display.displayName, spent
            end
        end
        if name and name ~= "" then return string.format("Spec %d: %s", group, name) end
    end
    return fallback
end

local function TryEquip()
    if not pendingGroup then return end
    local group = C_SpecializationInfo.GetActiveSpecGroup()
    if group ~= pendingGroup then pendingGroup = nil; return end
    local setID = ExtraStatsForeverSettings.specSets[group]
    if not setID then pendingGroup = nil; return end
    if InCombatLockdown() or UnitCastingInfo("player") or UnitChannelInfo("player") then return end
    local name, _, _, equipped = C_EquipmentSet.GetEquipmentSetInfo(setID)
    if not name then
        ExtraStatsForeverSettings.specSets[group] = nil
        pendingGroup = nil
        return
    end
    if C_EquipmentSet.EquipmentSetContainsLockedItems(setID) then return end
    pendingGroup = nil
    if not equipped and not C_EquipmentSet.UseEquipmentSet(setID) then
        print("ExtraStats: Could not equip " .. name .. ". Check missing items and bag space.")
    end
end

local function Initialize()
    ExtraStatsForeverSettings = ExtraStatsForeverSettings or {}
    ExtraStatsForeverSettings.specSets = ExtraStatsForeverSettings.specSets or {}
    local pane = PaperDollFrame.EquipmentManagerPane
    local contextSetID
    -- Capture the clicked row before Blizzard builds its tagged edit menu.
    -- Reading selectedSetID would assign the wrong set when editing another row.
    local function AttachMenuContext(row)
        local edit = row.EditButton
        if not edit or edit.extraStatsWrapped then return end
        local original = edit:GetScript("OnMouseDown")
        if not original then return end
        edit.extraStatsWrapped = true
        edit:SetScript("OnMouseDown", function(button, ...)
            contextSetID = row.setID
            original(button, ...)
            -- Keep the ID while this menu regenerates after a checkbox click.
        end)
    end
    Menu.ModifyMenu("MENU_PAPERDOLL_FRAME", function(owner, menu)
        local setID = contextSetID
        if owner ~= pane or not setID or not C_EquipmentSet.GetEquipmentSetInfo(setID) then return end
        menu:CreateDivider()
        menu:CreateTitle("Assign spec")
        for group = 1, GetNumSpecGroups() do
            local groupID = group
            menu:CreateCheckbox(GetGroupLabel(groupID), function()
                return ExtraStatsForeverSettings.specSets[groupID] == setID
            end, function()
                local assignments = ExtraStatsForeverSettings.specSets
                assignments[groupID] = assignments[groupID] ~= setID and setID or nil
            end)
        end
        menu:CreateButton("Clear assignments for this set", function()
            for group, assignedSet in pairs(ExtraStatsForeverSettings.specSets) do
                if assignedSet == setID then ExtraStatsForeverSettings.specSets[group] = nil end
            end
        end)
    end)
    hooksecurefunc("GearSetButton_UpdateSpecInfo", AttachMenuContext)
    for _, row in ipairs(pane.ScrollBox:GetFrames()) do AttachMenuContext(row) end
    lastGroup = C_SpecializationInfo.GetActiveSpecGroup()
    for _, event in ipairs({ "PLAYER_ENTERING_WORLD", "ACTIVE_TALENT_GROUP_CHANGED", "PLAYER_SPECIALIZATION_CHANGED", "PLAYER_REGEN_ENABLED", "ITEM_UNLOCKED", "UNIT_SPELLCAST_STOP", "UNIT_SPELLCAST_CHANNEL_STOP", "EQUIPMENT_SETS_CHANGED" }) do
        events:RegisterEvent(event)
    end
end

events:RegisterEvent("ADDON_LOADED")
events:SetScript("OnEvent", function(self, event, unit)
    if event == "ADDON_LOADED" then
        if unit == addonName then
            self:UnregisterEvent(event)
            Initialize()
        end
        return
    end
    if (event == "PLAYER_SPECIALIZATION_CHANGED" or event == "UNIT_SPELLCAST_STOP" or event == "UNIT_SPELLCAST_CHANNEL_STOP") and unit ~= "player" then return end
    local group = C_SpecializationInfo.GetActiveSpecGroup()
    if group and group ~= lastGroup then
        lastGroup = group
        pendingGroup = group
    end
    -- Allow the spec-change cast and inventory events to finish first.
    C_Timer.After(0.2, TryEquip)
end)
