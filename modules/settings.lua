local Module = ExtraStats.modules:NewModule("settings")

local categories = {
    base = {
        label = "Base",
        desc = "Health and power."
    },
    attributes = {
        label = PLAYERSTAT_BASE_STATS,
        desc = "Primary attributes."
    },
    melee = {
        label = PLAYERSTAT_MELEE_COMBAT,
        desc = "Melee damage and ratings."
    },
    ranged = {
        label = PLAYERSTAT_RANGED_COMBAT,
        desc = "Ranged damage and ratings."
    },
    spell = {
        label = PLAYERSTAT_SPELL_COMBAT,
        desc = "Spell damage and ratings."
    },
    defenses = {
        label = PLAYERSTAT_DEFENSES,
        desc = "Mitigation and avoidance."
    },
    enhancements = {
        label = "Enhancements",
        desc = "Secondary bonuses."
    }
}

local roleLabels = {
    [CLASS_ROLE_DAMAGER] = "Damage",
    [CLASS_ROLE_HEALER] = "Healer",
    [CLASS_ROLE_TANK] = "Tank",
}
local roleOrder = { CLASS_ROLE_DAMAGER, CLASS_ROLE_HEALER, CLASS_ROLE_TANK }
local categoryOrder = { "base", "attributes", "melee", "ranged", "spell", "defenses", "enhancements" }
local selectedRole = CLASS_ROLE_DAMAGER

local function ClearTable(target)
    for key in pairs(target) do
        target[key] = nil
    end
end

local function EnsureRoleVisibility(role)
    ExtraStats.db.char.roleCategoryVisibility = ExtraStats.db.char.roleCategoryVisibility or {}
    local visibility = ExtraStats.db.char.roleCategoryVisibility[role]
    if not visibility then
        visibility = {}
        ExtraStats.db.char.roleCategoryVisibility[role] = visibility
        for categoryId in pairs(categories) do
            local fallback = ExtraStats.db.char.categories[categoryId]
            visibility[categoryId] = (fallback and fallback.enabled) ~= false
        end
    end
    return visibility
end

local function EnsureRoleStatVisibility(role, categoryId)
    ExtraStats.db.char.roleStatVisibility = ExtraStats.db.char.roleStatVisibility or {}
    local roleVisibility = ExtraStats.db.char.roleStatVisibility[role]
    if not roleVisibility then
        roleVisibility = {}
        ExtraStats.db.char.roleStatVisibility[role] = roleVisibility
    end
    local categoryVisibility = roleVisibility[categoryId]
    if not categoryVisibility then
        categoryVisibility = {}
        roleVisibility[categoryId] = categoryVisibility
    end
    return categoryVisibility
end

local function GetStatLabel(stat, index)
    if type(stat.name) == "function" then
        local ok, value = pcall(stat.name)
        if ok and type(value) == "string" and value ~= "" then
            return value
        end
    elseif type(stat.name) == "string" and stat.name ~= "" then
        return stat.name
    end
    return "Stat " .. tostring(index)
end

function Module:Settings(tab)
    local categoriesSettings = {}
    local roleCategoriesSettings = {}
    local roleStatSettings = {}
    local index = 1

    for _, name in ipairs(categoryOrder) do
        local categoryId = name
        local object = categories[categoryId]
        if object then
            categoriesSettings["category." .. categoryId] = {
                name = object.label or categoryId,
                desc = object.desc,
                type = "toggle",
                order = index,
                width = "full",
                set = function(info, val)
                    ExtraStats.db.char.categories[categoryId].enabled = val;
                    ExtraStats:UpdateStats()
                end,
                get = function(info)
                    return ExtraStats.db.char.categories[categoryId].enabled
                end
            }
            roleCategoriesSettings["role.category." .. categoryId] = {
                name = object.label or categoryId,
                desc = object.desc,
                type = "toggle",
                order = index,
                width = "full",
                set = function(info, val)
                    local visibility = EnsureRoleVisibility(selectedRole)
                    visibility[categoryId] = val
                    ExtraStats:UpdateStats()
                end,
                get = function(info)
                    local visibility = EnsureRoleVisibility(selectedRole)
                    if visibility[categoryId] == nil then
                        return true
                    end
                    return visibility[categoryId]
                end,
                disabled = function()
                    return not ExtraStats.db.char.dynamic
                end
            }
            index = index + 1
        end
    end

    local function RebuildRoleStatSettings()
        ClearTable(roleStatSettings)
        local statsModule = ExtraStats:LoadModule("character.stats")
        if not statsModule or not statsModule.GetCategories then
            return
        end

        local categoryMap = {}
        for _, category in pairs(statsModule:GetCategories()) do
            categoryMap[category.id] = category
        end

        local orderedCategories = {}
        for _, name in ipairs(categoryOrder) do
            if categoryMap[name] then
                table.insert(orderedCategories, categoryMap[name])
                categoryMap[name] = nil
            end
        end
        local remaining = {}
        for _, category in pairs(categoryMap) do
            table.insert(remaining, category)
        end
        table.sort(remaining, function(a, b)
            return tostring(a.id) < tostring(b.id)
        end)
        for _, category in ipairs(remaining) do
            table.insert(orderedCategories, category)
        end

        local categoryIndex = 1
        for _, category in ipairs(orderedCategories) do
            if category and type(category.stats) == "table" then
                local categoryId = category.id
                local categoryLabel = category.text or category.id
                local statArgs = {}
                for statIndex, stat in ipairs(category.stats) do
                    local statKey = stat.name
                    if type(statKey) ~= "string" then
                        statKey = tostring(statIndex)
                    end
                    local statKeyRef = statKey
                    statArgs["role.stat." .. statIndex .. "." .. statKey] = {
                        name = GetStatLabel(stat, statIndex),
                        type = "toggle",
                        order = statIndex,
                        width = "full",
                        set = function(info, val)
                            local visibility = EnsureRoleStatVisibility(selectedRole, categoryId)
                            visibility[statKeyRef] = val
                            ExtraStats:UpdateStats()
                        end,
                        get = function(info)
                            local visibility = EnsureRoleStatVisibility(selectedRole, categoryId)
                            if visibility[statKeyRef] == nil then
                                return true
                            end
                            return visibility[statKeyRef]
                        end,
                        disabled = function()
                            return not ExtraStats.db.char.dynamic
                        end
                    }
                end

                roleStatSettings["role.stats." .. categoryId] = {
                    name = categoryLabel,
                    type = "group",
                    inline = true,
                    order = categoryIndex,
                    args = statArgs
                }
                categoryIndex = categoryIndex + 1
            end
        end
    end

    tab.categories.args.list = {
        name = "Default Categories",
        type = "group",
        inline = true,
        order = 1,
        args = categoriesSettings
    }

    local roleValues = {}
    for _, role in ipairs(roleOrder) do
        roleValues[role] = roleLabels[role] or role
    end

    tab.categories.args.rolePresets = {
        name = "Role Presets",
        type = "group",
        inline = true,
        order = 2,
        args = {
            role = {
                name = "Role",
                type = "select",
                order = 1,
                width = "full",
                values = roleValues,
                set = function(info, val)
                    selectedRole = val
                end,
                get = function(info)
                    return selectedRole
                end,
                disabled = function()
                    return not ExtraStats.db.char.dynamic
                end
            },
            hint = {
                name = "Enable role presets in General > Behavior to apply these settings.",
                type = "description",
                order = 2,
                width = "full",
                hidden = function()
                    return ExtraStats.db.char.dynamic
                end
            },
            list = {
                name = "Visible Categories",
                type = "group",
                inline = true,
                order = 3,
                args = roleCategoriesSettings
            },
            stats = {
                name = "Visible Stats",
                type = "group",
                inline = true,
                order = 4,
                args = roleStatSettings
            }
        }
    }

    RebuildRoleStatSettings()
    ExtraStats:On("stats.category.created", RebuildRoleStatSettings)
    ExtraStats:On("stats.category.stat.added", RebuildRoleStatSettings)
end
