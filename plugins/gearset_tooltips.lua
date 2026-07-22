local Plugin = {
    name = "Gear Set Item Tooltips",
}

ExtraStats:RegisterPlugin(Plugin)

local function NormalizeItemLink(link)
    if not link then
        return nil
    end
    return string.match(link, "|H(item:[^|]+)|h") or string.match(link, "(item:[^|]+)") or link
end

local function GetItemID(link)
    local normalized = NormalizeItemLink(link)
    return normalized and tonumber(string.match(normalized, "item:(%d+)"))
end

local function FindMatchingSets(itemLink)
    local equipment = ExtraStats:GetModule("EquipmentSet")
    if not equipment or not equipment.db or not equipment.db.char then
        return {}
    end

    local normalizedItemLink = NormalizeItemLink(itemLink)
    local itemID = GetItemID(normalizedItemLink)
    local matches = {}
    local sets = equipment.db.char.sets or {}

    for setID, set in ipairs(sets) do
        local matched = false
        local items = set.items or {}
        local itemLinks = set.itemLinks or {}
        local ignored = set.ignoredSlots or {}

        for slotID, slotName in pairs({
            [INVSLOT_HEAD] = "HeadSlot",
            [INVSLOT_NECK] = "NeckSlot",
            [INVSLOT_SHOULDER] = "ShoulderSlot",
            [INVSLOT_BACK] = "BackSlot",
            [INVSLOT_CHEST] = "ChestSlot",
            [INVSLOT_WRIST] = "WristSlot",
            [INVSLOT_HAND] = "HandsSlot",
            [INVSLOT_WAIST] = "WaistSlot",
            [INVSLOT_LEGS] = "LegsSlot",
            [INVSLOT_FEET] = "FeetSlot",
            [INVSLOT_FINGER1] = "Finger0Slot",
            [INVSLOT_FINGER2] = "Finger1Slot",
            [INVSLOT_TRINKET1] = "Trinket0Slot",
            [INVSLOT_TRINKET2] = "Trinket1Slot",
            [INVSLOT_MAINHAND] = "MainHandSlot",
            [INVSLOT_OFFHAND] = "SecondaryHandSlot",
            [INVSLOT_RANGED] = "RangedSlot",
        }) do
            if not ignored[slotID] then
                local storedLink = NormalizeItemLink(itemLinks[slotName])
                local storedID = items[slotName] or GetItemID(storedLink)
                -- Full links identify gemmed/enchanted copies. Only fall
                -- back to item IDs for sets saved before links were stored.
                if (storedLink and storedLink == normalizedItemLink) or (not storedLink and itemID and storedID == itemID) then
                    matched = true
                    break
                end
            end
        end

        if matched then
            local _, _, _, equipped = equipment:GetEquipmentSetInfo(setID)
            matches[#matches + 1] = {
                name = set.name or ("Set " .. setID),
                equipped = equipped == true,
            }
        end
    end

    return matches
end

function Plugin:Setup()
    if ExtraStats.db.char.disabledPlugins[self.name] == true then
        return
    end

    if not GameTooltip or not GameTooltip.HookScript then
        return
    end

    GameTooltip:HookScript("OnTooltipSetItem", function(tooltip)
        local _, itemLink = tooltip:GetItem()
        if not itemLink then
            return
        end

        local matches = FindMatchingSets(itemLink)
        if #matches == 0 then
            return
        end

        tooltip:AddLine(" ")
        tooltip:AddLine(string.format("Gear Sets (%d)", #matches), 0.4, 0.8, 1.0)
        for _, match in ipairs(matches) do
            if match.equipped then
                tooltip:AddLine("|TInterface\\Buttons\\UI-CheckBox-Check:12|t " .. match.name, 0.2, 1.0, 0.2)
            else
                tooltip:AddLine(match.name, 1.0, 0.82, 0.2)
            end
        end
    end)
end
