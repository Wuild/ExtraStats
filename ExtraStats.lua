local name, stats = ...;

CHARACTERFRAME_EXPANDED_WIDTH = 540;

local EVENT_DIRTY_CATEGORIES = {
    PLAYER_ENTERING_WORLD = { "base", "attributes", "melee", "ranged", "spell", "defenses", "enhancements" },
    PLAYER_EQUIPMENT_CHANGED = { "base", "attributes", "melee", "ranged", "spell", "defenses", "enhancements" },
    SOCKET_INFO_SUCCESS = { "base", "attributes", "melee", "ranged", "spell", "defenses", "enhancements" },
    UNIT_STATS = { "base", "attributes" },
    UNIT_DAMAGE = { "melee", "ranged" },
    UNIT_RANGEDDAMAGE = { "ranged" },
    UNIT_ATTACK_SPEED = { "melee" },
    UNIT_ATTACK_POWER = { "melee" },
    UNIT_RANGED_ATTACK_POWER = { "ranged" },
    UNIT_ATTACK = { "melee", "ranged" },
    UNIT_SPELL_HASTE = { "spell" },
    COMBAT_RATING_UPDATE = { "melee", "ranged", "spell", "defenses", "enhancements" },
    UNIT_RESISTANCES = { "defenses" },
    UNIT_MAXHEALTH = { "base" },
    PLAYER_DAMAGE_DONE_MODS = { "melee", "ranged", "spell" },
    CHARACTER_POINTS_CHANGED = { "base", "attributes", "melee", "ranged", "spell", "defenses", "enhancements" },
    PLAYER_TALENT_UPDATE = { "base", "attributes", "melee", "ranged", "spell", "defenses", "enhancements" },
    ACTIVE_TALENT_GROUP_CHANGED = { "base", "attributes", "melee", "ranged", "spell", "defenses", "enhancements" },
    UNIT_AURA = { "base", "attributes", "melee", "ranged", "spell", "defenses", "enhancements" },
}

local function GetDirtyCategories(event, target)
    if string.sub(event, 1, 5) == "UNIT_" and target ~= "player" then
        return nil
    end
    return EVENT_DIRTY_CATEGORIES[event]
end

local function SetAllCategoriesCollapsed(collapsed)
    local statsModule = ExtraStats:LoadModule("character.stats")
    if not statsModule or not statsModule.GetCategories then
        return
    end
    ExtraStats.db.char.categoryCollapsed = ExtraStats.db.char.categoryCollapsed or {}
    for _, category in pairs(statsModule:GetCategories()) do
        ExtraStats.db.char.categoryCollapsed[category.id] = collapsed
    end
    ExtraStats:UpdateStatsDelayed()
end

local function ResetCategoryOrder()
    ExtraStats.db.char.categoryOrder = {}
    ExtraStats:UpdateStatsDelayed()
end

local function ResetCategoryVisibility()
    local defaults = stats.configsDefaults and stats.configsDefaults.char and stats.configsDefaults.char.categories
    if not defaults then
        return
    end
    for categoryId, data in pairs(defaults) do
        if ExtraStats.db.char.categories[categoryId] then
            ExtraStats.db.char.categories[categoryId].enabled = data.enabled
        end
    end
    ExtraStats:UpdateStatsDelayed()
end

function ExtraStats:EventHandler(event, target, ...)
    CURRENT_CLASS = ExtraStats:GetCurrentClass()
    ExtraStats:UpdateRole()
    if ExtraStats.window and ExtraStats.window.UpdateRoleIcons then
        ExtraStats.window:UpdateRoleIcons()
    end

    if event == "PLAYER_LOGIN" then
        C_Timer.After(5, function()
            ExtraStats:print(ExtraStats:translate("message.loaded", ExtraStats:Colorize(stats.version, "blue")));
            ExtraStats:print(ExtraStats:translate("message.settings_hint"));
            ExtraStats:print(ExtraStats:translate("message.support", ExtraStats:Colorize("https://www.buymeacoffee.com/yuImx6KOY", "cyan")));
        end);
    else
        local dirtyCategories = GetDirtyCategories(event, target)
        if dirtyCategories then
            ExtraStats:MarkStatsDirty(dirtyCategories)
            ExtraStats:UpdateStatsDelayed()
        end
    end
end

function ExtraStats:ShowSettings()
    LibStub("AceConfigDialog-3.0"):Open("ExtraStats", ExtraStats.OptionsPanel)
end

function ExtraStats:SlashCommand(input)
    local cmd, arg1 = ExtraStats:GetArgs(input, 2);

    if cmd == "debug" then
        if ExtraStats.db.global.debug.enabled then
            ExtraStats.db.global.debug.enabled = false;
            ExtraStats:print("debugging", ExtraStats:Colorize("disabled", "red"));
        else
            ExtraStats.db.global.debug.enabled = true;
            ExtraStats:print("debugging", ExtraStats:Colorize("enabled", "green"));
        end
    elseif cmd == "equip" then
        EquipmentSet = ExtraStats:GetModule("EquipmentSet")
        local _, _, id = EquipmentSet:GetEquipmentSetInfoByName(arg1);
        EquipmentSet:UseEquipmentSet(id)
    end

end

function ExtraStats:DefaultSettings()
    return {
        general = {
            name = function()
                return ExtraStats:translate("settings.general");
            end,
            type = "group",
            order = 1,
            desc = ExtraStats:translate("settings.general_desc"),
            args = {
                about = {
                    name = ExtraStats:translate("settings.about"),
                    type = "group",
                    inline = true,
                    order = 1,
                    args = {
                        title = {
                            name = "ExtraStats",
                            type = "description",
                            order = 1,
                            fontSize = "medium",
                            width = "full",
                        },
                        version = {
                            name = function()
                                return ExtraStats:translate("settings.version", stats.version or ExtraStats:translate("common.unknown"));
                            end,
                            type = "description",
                            order = 2,
                            width = "full",
                        },
                        support = {
                            name = ExtraStats:translate("settings.support_link", "https://www.patreon.com/c/Wuild"),
                            type = "description",
                            order = 3,
                            width = "full",
                        },
                    }
                },
                behavior = {
                    name = ExtraStats:translate("settings.behavior"),
                    type = "group",
                    inline = true,
                    order = 2,
                    args = {
                        debug = {
                            name = ExtraStats:translate("settings.enable_debug"),
                            type = "toggle",
                            order = 1,
                            width = "full",
                            set = function(_, val)
                                ExtraStats.db.global.debug.enabled = val
                            end,
                            get = function(_)
                                return ExtraStats.db.global.debug.enabled
                            end
                        },
                        rolePresets = {
                            name = ExtraStats:translate("settings.enable_role_presets"),
                            type = "toggle",
                            order = 2,
                            width = "full",
                            set = function(_, val)
                                ExtraStats.db.char.dynamic = val
                                ExtraStats:UpdateStats()
                                if ExtraStats.window and ExtraStats.window.UpdateRoleIcons then
                                    ExtraStats.window:UpdateRoleIcons()
                                end
                            end,
                            get = function(_)
                                return ExtraStats.db.char.dynamic
                            end
                        },
                        rolePresetValue = {
                            name = ExtraStats:translate("settings.role_preset"),
                            type = "select",
                            order = 3,
                            width = "full",
                            values = {
                                AUTO = ExtraStats:translate("settings.auto_from_talents"),
                                [CLASS_ROLE_DAMAGER] = ExtraStats:translate("role.damage"),
                                [CLASS_ROLE_HEALER] = ExtraStats:translate("role.healer"),
                                [CLASS_ROLE_TANK] = ExtraStats:translate("role.tank"),
                            },
                            set = function(_, val)
                                ExtraStats.db.char.rolePreset = val
                                ExtraStats:UpdateStats()
                                if ExtraStats.window and ExtraStats.window.UpdateRoleIcons then
                                    ExtraStats.window:UpdateRoleIcons()
                                end
                            end,
                            get = function(_)
                                return ExtraStats.db.char.rolePreset or "AUTO"
                            end,
                            disabled = function()
                                return not ExtraStats.db.char.dynamic
                            end
                        },
                    }
                },
                actions = {
                    name = ExtraStats:translate("settings.quick_actions"),
                    type = "group",
                    inline = true,
                    order = 3,
                    args = {
                        resetLayout = {
                            name = ExtraStats:translate("settings.reset_layout"),
                            type = "execute",
                            order = 1,
                            func = function()
                                ResetCategoryOrder()
                                SetAllCategoriesCollapsed(false)
                            end
                        },
                        resetVisibility = {
                            name = ExtraStats:translate("settings.reset_visibility"),
                            type = "execute",
                            order = 2,
                            func = function()
                                ResetCategoryVisibility()
                            end
                        },
                        expandAll = {
                            name = ExtraStats:translate("settings.expand_all"),
                            type = "execute",
                            order = 3,
                            func = function()
                                SetAllCategoriesCollapsed(false)
                            end
                        },
                        collapseAll = {
                            name = ExtraStats:translate("settings.collapse_all"),
                            type = "execute",
                            order = 4,
                            func = function()
                                SetAllCategoriesCollapsed(true)
                            end
                        },
                    }
                },
            }
        },

        categories = {
            name = function()
                return ExtraStats:translate("settings.categories");
            end,
            type = "group",
            order = 2,
            desc = ExtraStats:translate("settings.categories_desc"),
            args = {}
        },

        layout = {
            name = function()
                return ExtraStats:translate("settings.layout");
            end,
            type = "group",
            order = 3,
            desc = ExtraStats:translate("settings.layout_desc"),
            args = {
                collapseAll = {
                    name = ExtraStats:translate("settings.collapse_all"),
                    type = "execute",
                    order = 1,
                    func = function()
                        SetAllCategoriesCollapsed(true)
                    end
                },
                expandAll = {
                    name = ExtraStats:translate("settings.expand_all"),
                    type = "execute",
                    order = 2,
                    func = function()
                        SetAllCategoriesCollapsed(false)
                    end
                },
                resetOrder = {
                    name = ExtraStats:translate("settings.reset_order"),
                    type = "execute",
                    order = 3,
                    func = function()
                        ResetCategoryOrder()
                    end
                },
            }
        },

        plugins = {
            name = function()
                return ExtraStats:translate("settings.plugins");
            end,
            type = "group",
            order = 4,
            desc = ExtraStats:translate("settings.plugins_desc"),
            args = {}
        }
    }
end

function ExtraStats:OnInitialize()

    self.db = LibStub("AceDB-3.0"):New("ExtraStatsSettings", stats.configsDefaults, true)
    ExtraStats:RegisterComm(name .. "Ver", "VersionCheck")
    --ExtraStats:ScheduleRepeatingTimer("SendVersionCheck", 10)
    --ExtraStats:ScheduleRepeatingTimer("UpdateRole", 0.5)
    ExtraStats:RegisterChatCommand("stats", "SlashCommand")
    ExtraStats:RegisterChatCommand("es", "SlashCommand")
end

function ExtraStats:OnEnable()
    local configsTable = ExtraStats:DefaultSettings()

    CURRENT_CLASS = ExtraStats:GetCurrentClass()
    ExtraStats:UpdateRole()

    ExtraStats:CreateWindow()

    for _, module in ExtraStats.modules:IterateModules() do
        module:Enable()

        if module.Settings then
            module:Settings(configsTable);
        end
    end

    ExtraStats:RegisterEvent("PLAYER_LOGIN", "EventHandler")
    ExtraStats:RegisterEvent("GROUP_ROSTER_UPDATE", "EventHandler")
    --ExtraStats:RegisterEvent("UNIT_SPELLCAST_START", "EventHandler")
    --ExtraStats:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED", "EventHandler")
    --ExtraStats:RegisterEvent("INSPECT_READY", "EventHandler")
    --ExtraStats:RegisterEvent("UPDATE_SHAPESHIFT_FORM", "EventHandler")
    --ExtraStats:RegisterEvent("UPDATE_SHAPESHIFT_FORMS", "EventHandler")
    --ExtraStats:RegisterEvent("UPDATE_STEALTH", "EventHandler")
    for eventName, _ in pairs(EVENT_DIRTY_CATEGORIES) do
        ExtraStats:RegisterEvent(eventName, "EventHandler")
    end

    local needReload = false;

    for _, plugin in pairs(ExtraStats.plugins) do
        plugin:Setup();

        if plugin.Settings then
            plugin:Settings(configsTable)
        end

        local pluginName = plugin.name;
        local pluginDisplayName = plugin.displayNameKey and ExtraStats:translate(plugin.displayNameKey) or pluginName;
        configsTable.plugins.args["plugin." .. pluginName] = {
            name = pluginDisplayName,
            type = "toggle",
            set = function(_, val)
                if not val then
                    ExtraStats.db.char.disabledPlugins[pluginName] = true
                else
                    ExtraStats.db.char.disabledPlugins[pluginName] = nil
                end

                needReload = true;
            end,
            get = function(_)
                return ExtraStats.db.char.disabledPlugins[pluginName] == nil
            end
        }
    end

    configsTable.plugins.args["reloadUI"] = {
        name = function()
            return ExtraStats:translate("settings.reload_ui");
        end,
        type = "execute",
        order = 99999,
        hidden = function()
            return not needReload
        end,
        func = function()
            ReloadUI();
        end
    }

    LibStub("AceConfig-3.0"):RegisterOptionsTable("ExtraStats", {
        type = "group",
        childGroups = "tab",
        args = configsTable,
    })
end
