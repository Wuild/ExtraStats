local Plugin = {
    name = "TemplatePlugin"
}

ExtraStats:RegisterPlugin(Plugin)

function Plugin:Setup()
    -- Optional: guard if required addon/library is missing.
    -- if not SomeAddon then return end

    if ExtraStats.db.char.disabledPlugins[Plugin.name] == true then
        return
    end

    -- Example: add a stat to the base category.
    local stats = ExtraStats:LoadModule("character.stats")
    local base = stats:GetCategory("base")
    if base then
        base:Add("Example Stat", function()
            return { value = "42" }
        end)
    end

    -- Example: hook events.
    ExtraStats:On("stats.update.start", function()
        -- do work before stats rebuild
    end)

    ExtraStats:On("stats.update.end", function()
        -- do work after stats rebuild
    end)
end
