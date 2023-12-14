local equipment = ExtraStats:NewModule("EquipmentSet")

local slotInfo = {
    [1] = { name = "HeadSlot", tooltip = HEADSLOT, id = INVSLOT_HEAD },
    [2] = { name = "NeckSlot", tooltip = NECKSLOT, id = INVSLOT_NECK },
    [3] = { name = "ShoulderSlot", tooltip = SHOULDERSLOT, id = INVSLOT_SHOULDER },
    [4] = { name = "BackSlot", tooltip = BACKSLOT, id = INVSLOT_BACK },
    [5] = { name = "ChestSlot", tooltip = CHESTSLOT, id = INVSLOT_CHEST },
    [6] = { name = "ShirtSlot", tooltip = SHIRTSLOT, id = INVSLOT_BODY },
    [7] = { name = "TabardSlot", tooltip = TABARDSLOT, id = INVSLOT_TABARD },
    [8] = { name = "WristSlot", tooltip = WRISTSLOT, id = INVSLOT_WRIST },
    [9] = { name = "HandsSlot", tooltip = HANDSSLOT, id = INVSLOT_HAND },
    [10] = { name = "WaistSlot", tooltip = WAISTSLOT, id = INVSLOT_WAIST },
    [11] = { name = "LegsSlot", tooltip = LEGSSLOT, id = INVSLOT_LEGS },
    [12] = { name = "FeetSlot", tooltip = FEETSLOT, id = INVSLOT_FEET },
    [13] = { name = "Finger0Slot", tooltip = FINGER0SLOT, id = INVSLOT_FINGER1 },
    [14] = { name = "Finger1Slot", tooltip = FINGER1SLOT, id = INVSLOT_FINGER2 },
    [15] = { name = "Trinket0Slot", tooltip = TRINKET0SLOT, id = INVSLOT_TRINKET1 },
    [16] = { name = "Trinket1Slot", tooltip = TRINKET1SLOT, id = INVSLOT_TRINKET2 },
    [17] = { name = "MainHandSlot", tooltip = MAINHANDSLOT, id = INVSLOT_MAINHAND },
    [18] = { name = "SecondaryHandSlot", tooltip = SECONDARYHANDSLOT, id = INVSLOT_OFFHAND },
    [19] = { name = "RangedSlot", tooltip = RANGEDSLOT, id = INVSLOT_RANGED },
    [20] = { name = "AmmoSlot", tooltip = AMMOSLOT, id = INVSLOT_AMMO },
}

function equipment:OnInitialize()
    equipment.db = ExtraStats.db:RegisterNamespace("equipments", {
        char = {
            sets = {}
        }
    })

    for index, set in pairs(equipment.db.char.sets) do
        if set.name == "TEMP_SET" then
            table.remove(equipment.db.char.sets, index)
        end
    end
end

function equipment:CreateEquipmentSet(name)
    local set = {
        name = name,
        icon = nil,
        items = {}
    }

    table.insert(equipment.db.char.sets, set)
end

function equipment:GetEquipmentSetID(name)
    for index, set in pairs(equipment.db.char.sets) do
        if set.name == name then
            return index
        end
    end
    return nil;
end


--- name, icon, id, isEquipped, numlost, items

function equipment:GetEquipmentSetInfo(id)
    local set = equipment.db.char.sets[id];

    local isSetEquipped = true;

    local missingItems = 0;

    for key, slot in pairs(slotInfo) do
        local item = GetInventoryItemID("player", slot.id);

        local isEquipped = item == set.items[slot.name];

        if item == 0 then
            item = nil
        end

        if item ~= set.items[slot.name] then
            isSetEquipped = false
        end

        if set.items[slot.name] then
            if not isEquipped then
                local itemID, x, y = equipment:FindItemInBags(set.items[slot.name]);
                if x == nil and y == nil then
                    missingItems = missingItems + 1;
                end
            end
        end
    end

    return set.name, set.icon, id, isSetEquipped, missingItems, {}
end

function equipment:DeleteEquipmentSet(setId)
    table.remove(equipment.db.char.sets, setId);
end

function equipment:SaveEquipmentSet(setId, icon)
    local set = equipment.db.char.sets[setId]
    if set then
        if icon then
            set.icon = icon;
        end
        for key, slot in pairs(slotInfo) do
            set.items[slot.name] = nil
            local item = GetInventoryItemID("player", slot.id);

            if item == 0 then
                set.items[slot.name] = nil
            elseif item then
                set.items[slot.name] = item
            end
        end
    end
end

function equipment:SlotInfo()
    local slots = slotInfo;
    table.sort(slots, function(a, b)
        return a.id > b.id
    end);
    return slots;
end

function equipment:ModifyEquipmentSet(setId, name, icon)
    local set = equipment.db.char.sets[setId]
    if set then
        if name then
            set.name = name;
        end
        if icon then
            set.icon = icon;
        end
    end
end

function equipment:GetEquipmentSetIDs()
    local ids = {};

    for index, set in pairs(equipment.db.char.sets) do
        table.insert(ids, index)
    end

    return ids
end

function equipment:ClearIgnoredSlotsForSave()

end

function equipment:GetIgnoredSlots()

end

function equipment:IgnoreSlotForSave()

end

function equipment:FindItemInBags(itemID)
    for i = 0, NUM_BAG_SLOTS do
        for z = 1, C_Container.GetContainerNumSlots(i) do
            if C_Container.GetContainerItemID(i, z) == itemID then
                return itemID, i, z
            end
        end
    end
    return nil, nil, nil
end

local selectedSet, gearThread;

local frame = CreateFrame("Frame", nil)
frame:SetScript("OnUpdate", function()
    if gearThread then
        coroutine.resume(gearThread)
    end
end)

local function equipItems()
    for key, slot in pairs(slotInfo) do
        if selectedSet.items[slot.name] == nil then
            ClearCursor()
            PickupInventoryItem(slot.id);
            PutItemInBackpack();
            coroutine.yield()
        else
            if GetInventoryItemID("player", slot.id) ~= selectedSet.items[slot.name] then
                local itemID, bagId, slotId;
                while true do
                    itemID, bagId, slotId = equipment:FindItemInBags(selectedSet.items[slot.name]);
                    local info = C_Container.GetContainerItemInfo(bagId, slotId)

                    if info.isLocked then
                        coroutine.yield()
                    else
                        break
                    end
                end

                C_Container.PickupContainerItem(bagId, slotId)
                EquipCursorItem(slot.id)
            end
        end
    end

    selectedSet = nil;
end

function equipment:UseEquipmentSet(id)
    local set = equipment.db.char.sets[id];

    selectedSet = set;

    ExtraStats:print("Equipping items from set:", set.name)

    gearThread = coroutine.create(equipItems)

end

function equipment:GetNumEquipmentSets()
    return ExtraStats:tablelength(equipment.db.char.sets)
end

