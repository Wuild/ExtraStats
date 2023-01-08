local name, stats = ...;

CHARACTERFRAME_EXPANDED_WIDTH = 540;

function ExtraStats:EventHandler(event, ...)
    if event == "PLAYER_LOGIN" then
        ExtraStats:UpdateStats()
        C_Timer.After(5, function()
            ExtraStats:print(ExtraStats:Colorize(stats.version, "blue"), "has been loaded");
            ExtraStats:print("use |cFF00FF00/stats|r to access addon settings");
            ExtraStats:print("Keep this addon alive by donating a coffee at " .. ExtraStats:Colorize("https://www.buymeacoffee.com/yuImx6KOY", "cyan"));
        end);
    else
        ExtraStats:UpdateStats()
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

function ExtraStats:OnInitialize()

    self.db = LibStub("AceDB-3.0"):New("ExtraStatsSettings", stats.configsDefaults, true)

    ExtraStats:RegisterComm(name .. "Ver", "VersionCheck")
    ExtraStats:ScheduleRepeatingTimer("SendVersionCheck", 10)
    ExtraStats:RegisterChatCommand("stats", "SlashCommand")

    ExtraStats:RegisterEvent("PLAYER_LOGIN", "EventHandler")
    ExtraStats:RegisterEvent("GROUP_ROSTER_UPDATE", "EventHandler")
    ExtraStats:RegisterEvent("PLAYER_EQUIPMENT_CHANGED", "EventHandler")
    ExtraStats:RegisterEvent("SOCKET_INFO_SUCCESS", "EventHandler")
    ExtraStats:RegisterEvent("INSPECT_READY", "EventHandler")
    ExtraStats:RegisterEvent("UNIT_AURA", "EventHandler")
    ExtraStats:RegisterEvent("UPDATE_SHAPESHIFT_FORM", "EventHandler")
    ExtraStats:RegisterEvent("UPDATE_SHAPESHIFT_FORMS", "EventHandler")
    ExtraStats:RegisterEvent("UPDATE_STEALTH", "EventHandler")

    ExtraStats:CreateWindow()

end