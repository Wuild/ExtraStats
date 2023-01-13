local name, stats = ...;

CHARACTERFRAME_EXPANDED_WIDTH = 540;

function ExtraStats:EventHandler(event, ...)
    ExtraStats:UpdateRole()
    CURRENT_CLASS = ExtraStats:GetCurrentClass()

    if event == "PLAYER_LOGIN" then
        ExtraStats:UpdateStatsDelayed()
        C_Timer.After(5, function()
            ExtraStats:print(ExtraStats:Colorize(stats.version, "blue"), "has been loaded");
            ExtraStats:print("use |cFF00FF00/stats|r to access addon settings");
            ExtraStats:print("Keep this addon alive by donating a coffee at " .. ExtraStats:Colorize("https://www.buymeacoffee.com/yuImx6KOY", "cyan"));
        end);
    else
        for i, module in pairs(ExtraStats.modules) do
            if module.Update then
                module:Update();
            end
        end
        ExtraStats:UpdateStatsDelayed()
    end
end

function ExtraStats:ShowSettings()
    LibStub("AceConfigDialog-3.0"):Open("ExtraStats", ExtraStats.OptionsPanel)
end

function ExtraStats:SlashCommand(input)
    input = string.trim(input, " ");
    if input == "" or not input then
        ExtraStats:ShowSettings();
        return
    end

    if input == "debug" then
        if ExtraStats.db.global.debug.enabled then
            ExtraStats.db.global.debug.enabled = false;
            ExtraStats:print("debugging", ExtraStats:Colorize("disabled", "red"));
        else
            ExtraStats.db.global.debug.enabled = true;
            ExtraStats:print("debugging", ExtraStats:Colorize("enabled", "green"));
        end
    end

end

function ExtraStats:DefaultSettings()
    return {
        general = {
            name = function()
                return "General";
            end,
            type = "group",
            order = 1,
            args = {
                dynamic = {
                    name = "Dynamic",
                    type = "toggle",
                    order = index,
                    set = function(info, val)
                        ExtraStats.db.char.dynamic = val;
                        ExtraStats:UpdateStatsDelayed()
                    end,
                    get = function(info)
                        return ExtraStats.db.char.dynamic
                    end
                },
            }
        },

        categories = {
            name = function()
                return "Categories";
            end,
            type = "group",
            order = 2,
            args = {}
        },

        plugins = {
            name = function()
                return "Plugins";
            end,
            type = "group",
            order = 3,
            args = {}
        }
    }
end

function ExtraStats:OnInitialize()

    self.db = LibStub("AceDB-3.0"):New("ExtraStatsSettings", stats.configsDefaults, true)
    local powerType, powerToken = UnitPowerType("player");
    ExtraStats:RegisterComm(name .. "Ver", "VersionCheck")
    ExtraStats:ScheduleRepeatingTimer("SendVersionCheck", 10)
    --ExtraStats:ScheduleRepeatingTimer("UpdateRole", 0.5)
    ExtraStats:RegisterChatCommand("stats", "SlashCommand")

    local configsTable = ExtraStats:DefaultSettings()

    CURRENT_ROLE = GetTalentGroupRole(GetActiveTalentGroup())
    CURRENT_CLASS = ExtraStats:GetCurrentClass()

    ExtraStats:CreateWindow()

    for i, module in pairs(ExtraStats.modules) do
        if module.Setup then
            module:Setup();
        end
    end

    for i, module in pairs(ExtraStats.modules) do
        if module.Settings then
            module:Settings(configsTable);
        end
    end

    ExtraStats:RegisterEvent("PLAYER_LOGIN", "EventHandler")
    ExtraStats:RegisterEvent("GROUP_ROSTER_UPDATE", "EventHandler")
    ExtraStats:RegisterEvent("PLAYER_EQUIPMENT_CHANGED", "EventHandler")
    ExtraStats:RegisterEvent("SOCKET_INFO_SUCCESS", "EventHandler")
    ExtraStats:RegisterEvent("UNIT_SPELLCAST_START", "EventHandler")
    ExtraStats:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED", "EventHandler")
    --ExtraStats:RegisterEvent("INSPECT_READY", "EventHandler")
    ExtraStats:RegisterEvent("UNIT_AURA", "EventHandler")
    --ExtraStats:RegisterEvent("UPDATE_SHAPESHIFT_FORM", "EventHandler")
    --ExtraStats:RegisterEvent("UPDATE_SHAPESHIFT_FORMS", "EventHandler")
    --ExtraStats:RegisterEvent("UPDATE_STEALTH", "EventHandler")
    ExtraStats:RegisterEvent("CHARACTER_POINTS_CHANGED", "EventHandler")
    ExtraStats:RegisterEvent("ACTIVE_TALENT_GROUP_CHANGED", "EventHandler")

    local needReload = false;

    for i, plugin in pairs(ExtraStats.plugins) do
        plugin:Setup();

        local name = plugin.name;
        configsTable.plugins.args["plugin." .. name] = {
            name = name,
            type = "toggle",
            set = function(info, val)
                if not val then
                    ExtraStats.db.char.disabledPlugins[name] = true
                else
                    ExtraStats.db.char.disabledPlugins[name] = nil
                end

                needReload = true;
            end,
            get = function(info)
                return ExtraStats.db.char.disabledPlugins[name] == nil
            end
        }
    end

    configsTable.plugins.args["reloadUI"] = {
        name = function()
            return "Reload ui";
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

    --for i, plugin in pairs(ExtraStats.plugins) do
    --    if plugin.Settings then
    --        plugin:Settings(configsTable);
    --    end
    --end

    LibStub("AceConfig-3.0"):RegisterOptionsTable("ExtraStats", {
        type = "group",
        childGroups = "tab",
        args = configsTable,
    })
end