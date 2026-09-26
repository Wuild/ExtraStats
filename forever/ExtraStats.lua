-- Forever uses its native character window, stat renderer, and equipment manager.
local addonName = ...
local _, _, _, interface = GetBuildInfo()
if interface < 16000 or interface >= 17000 then return end

local data = { stats = {}, categories = {} }
ExtraStatsForeverData = data

local schools = {
    { school = Enum.Damageclass.Arcane, atlas = "UI-Character-Info-Resistance-Arcane" },
    { school = Enum.Damageclass.Fire, atlas = "UI-Character-Info-Resistance-Fire" },
    { school = Enum.Damageclass.Frost, atlas = "UI-Character-Info-Resistance-Frost" },
    { school = Enum.Damageclass.Nature, atlas = "UI-Character-Info-Resistance-Nature" },
    { school = Enum.Damageclass.Shadow, atlas = "UI-Character-Info-Resistance-Shadow" },
}
local resistanceAtlases = {}
for _, entry in ipairs(schools) do resistanceAtlases[entry.atlas] = true end

local function Category(name, stats)
    local category = { categoryName = name, unit = "player", stats = {} }
    for _, stat in ipairs(stats) do
        table.insert(category.stats, type(stat) == "table" and stat or { stat = stat })
    end
    return category
end

local function NativeCritTooltip(frame)
    CharacterCritChanceFrame_OnEnter(frame, GetCritChance(), GetRangedCritChance(), GetSpellCritChance())
end

local function NativeHitTooltip(frame)
    CharacterHitFrame_OnEnter(frame,
        GetCombatRatingBonus(CR_HIT_MELEE) + GetHitModifier(),
        GetCombatRatingBonus(CR_HIT_RANGED) + GetRangedHitModifier(),
        GetCombatRatingBonus(CR_HIT_SPELL) + GetSpellHitModifier(), STAT_HIT_CHANCE)
end

local function RegisterPercentage(id, label, getter)
    data.stats[id] = { updateFunc = function(frame, unit)
        local value = getter()
        PaperDollFrame_SetLabelAndText(frame, label, string.format("%.2f%%", value), false, value)
        frame.tooltip = label .. " " .. string.format("%.2f%%", value)
        frame.tooltip2, frame.tooltip3 = nil, nil
        frame.unit = unit
        -- The row remains attack-specific; the native tooltip shows all types.
        frame.onEnterFunc = id:match("_CRIT$") and NativeCritTooltip or NativeHitTooltip
        frame:Show()
        return value
    end }
end

local function UsesMana()
    local _, token = UnitPowerType("player")
    return token == "MANA"
end

local function ConfigureCategories()
    -- Copy references for reading only. Never add keys to Blizzard's registry.
    for id, info in pairs(PAPERDOLL_STATINFO) do data.stats[id] = info end
    RegisterPercentage("EXTRASTATS_MELEE_CRIT", STAT_CRITICAL_STRIKE, GetCritChance)
    RegisterPercentage("EXTRASTATS_RANGED_CRIT", STAT_CRITICAL_STRIKE, GetRangedCritChance)
    RegisterPercentage("EXTRASTATS_SPELL_CRIT", STAT_CRITICAL_STRIKE, GetSpellCritChance)
    -- Camelot declares HITCHANCE_* entries but never defines their setters.
    -- Use the same components as Camelot's working combined hit updater.
    RegisterPercentage("EXTRASTATS_MELEE_HIT", STAT_HIT_CHANCE, function()
        return GetCombatRatingBonus(CR_HIT_MELEE) + GetHitModifier()
    end)
    RegisterPercentage("EXTRASTATS_RANGED_HIT", STAT_HIT_CHANCE, function()
        return GetCombatRatingBonus(CR_HIT_RANGED) + GetRangedHitModifier()
    end)
    RegisterPercentage("EXTRASTATS_SPELL_HIT", STAT_HIT_CHANCE, function()
        return GetCombatRatingBonus(CR_HIT_SPELL) + GetSpellHitModifier()
    end)
    local categories = {
        Category(UnitName("player") or STAT_CATEGORY_GENERAL, { "HEALTH", { stat = "POWER", showFunc = UsesMana }, "MOVESPEED", "HASTE" }),
        -- The native attribute tooltip indexes category 2 in UNITSTAT order.
        Category(PLAYERSTAT_BASE_STATS or STAT_CATEGORY_PRIMARY_ATTRIBUTES, { "STRENGTH", "AGILITY", "STAMINA", "INTELLECT", "SPIRIT" }),
        Category(PLAYERSTAT_MELEE_COMBAT or "Melee", { "MAINHAND_DAMAGE", { stat = "OFFHAND_DAMAGE", hideAt = 0 }, "ATTACK_AP", "ATTACK_ATTACKSPEED", "EXTRASTATS_MELEE_CRIT", "EXTRASTATS_MELEE_HIT", "EXPERTISE", { stat = "ARMORPEN", hideAt = 0 } }),
        Category(PLAYERSTAT_RANGED_COMBAT or "Ranged", { { stat = "RANGED_DAMAGE", hideAt = 0 }, "RANGED_ATTACK_AP", "EXTRASTATS_RANGED_CRIT", "EXTRASTATS_RANGED_HIT" }),
        Category(PLAYERSTAT_SPELL_COMBAT or "Spell", { "SPELLPOWER", "SPELLHEALING", "MANAREGEN", "EXTRASTATS_SPELL_CRIT", "EXTRASTATS_SPELL_HIT", { stat = "SPELLPENETRATION", hideAt = 0 } }),
        Category(PLAYERSTAT_DEFENSES or STAT_CATEGORY_DEFENSE, { "ARMOR", "DEFENSE", "DODGE", "PARRY", { stat = "BLOCK", showFunc = C_PaperDollInfo.OffhandHasShield } }),
    }
    data.categories = categories
end

local function UpdateResistance(row)
    local _, effective = UnitResistance("player", row.school)
    row.Value:SetText(effective) -- Pass protected values directly to the font string.
    local name = _G["DAMAGE_SCHOOL" .. row.school]
    row.tooltip, row.tooltip2, row.tooltip3 = name, nil, nil
    if not issecretvalue or (not issecretvalue(effective) and not issecretvalue(UnitLevel("player"))) then
        PaperDollFrame_SetResistanceTooltips(row, name, effective, "player", row.school)
    end
end

local function ShowResistanceTooltip(self)
    UpdateResistance(self)
    PaperDollStatTooltip(self)
end

local function CreateResistances()
    local panel = CreateFrame("Frame", "ExtraStatsForeverResistances", PaperDollItemsFrame)
    panel:SetSize(72, 164)
    panel:SetPoint("TOPRIGHT", CharacterHandsSlot, "TOPLEFT", -12, 0)
    -- Above the item/model input layers so mouse hover reaches the whole badge.
    panel:SetFrameLevel(PaperDollItemsFrame:GetFrameLevel() + 20)
    panel.rows = {}
    for index, entry in ipairs(schools) do
        local row = CreateFrame("Frame", nil, panel)
        row:SetSize(72, 32)
        row:SetPoint("TOPRIGHT", panel, "TOPRIGHT", 0, -(index - 1) * 33)
        row:EnableMouse(true)
        if SmartNavigation_MarkFrameFocusable then
            SmartNavigation_MarkFrameFocusable(row)
            SmartNavigation_MarkFrameBlockingSmartNavClick(row)
        end
        row.Icon = row:CreateTexture(nil, "ARTWORK")
        row.Icon:SetSize(32, 32)
        row.Icon:SetPoint("RIGHT", row, "RIGHT", 0, 0)
        row.Icon:SetAtlas(entry.atlas)
        row.Value = row:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        row.Value:SetPoint("LEFT", row, "LEFT", 0, 0)
        row.Value:SetPoint("RIGHT", row.Icon, "LEFT", -6, 0)
        row.Value:SetJustifyH("RIGHT")
        row.school = entry.school
        row:SetScript("OnEnter", ShowResistanceTooltip)
        row:SetScript("OnLeave", function() GameTooltip:Hide() end)
        table.insert(panel.rows, row)
    end
    local function Update()
        for _, row in ipairs(panel.rows) do
            UpdateResistance(row)
            if GameTooltip:IsOwned(row) then PaperDollStatTooltip(row) end
        end
    end
    panel:RegisterUnitEvent("UNIT_RESISTANCES", "player")
    panel:RegisterUnitEvent("UNIT_LEVEL", "player")
    panel:RegisterEvent("PLAYER_ENTERING_WORLD")
    panel:RegisterEvent("PLAYER_EQUIPMENT_CHANGED")
    panel:SetScript("OnEvent", Update)
    panel:SetScript("OnShow", Update)
    Update()
end

function data.GetBackgroundMode()
    return ExtraStatsForeverSettings and ExtraStatsForeverSettings.backgroundMode == "DARK" and "DARK" or "LIGHT"
end

local function RestoreBackgroundColors()
    -- Dark matches Forever's native grayscale and full overlay.
    local dark = data.GetBackgroundMode() == "DARK"
    if CharacterModelScene.BackgroundOverlay then
        CharacterModelScene.BackgroundOverlay:SetAlpha(dark and 1 or 0.45)
    end
    for _, suffix in ipairs({ "TopLeft", "TopRight", "BotLeft", "BotRight" }) do
        local background = _G["CharacterModelFrameBackground" .. suffix]
        if background then
            background:SetDesaturated(dark)
            background:SetVertexColor(1, 1, 1)
            background:SetAlpha(1)
        end
    end
end

function data.SetBackgroundMode(mode)
    if mode ~= "DARK" and mode ~= "LIGHT" then return end
    ExtraStatsForeverSettings = ExtraStatsForeverSettings or {}
    ExtraStatsForeverSettings.backgroundMode = mode
    RestoreBackgroundColors()
end

local events = CreateFrame("Frame")
events:RegisterEvent("ADDON_LOADED")
events:SetScript("OnEvent", function(self, _, name)
    if name ~= addonName then return end
    self:UnregisterEvent("ADDON_LOADED")
    ConfigureCategories()
    CreateResistances()
    -- Forever desaturates the racial backdrop whenever it sets the player model.
    hooksecurefunc("PaperDollBgDesaturate", RestoreBackgroundColors)
    RestoreBackgroundColors()
end)
