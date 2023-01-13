local name = "ElvUI"
local Plugin = {
    name = name
}

table.insert(ExtraStats.plugins, Plugin)

function Plugin:Setup()

    if not ElvUI then
        return
    end

    if ExtraStats.db.char.disabledPlugins[name] == true then
        return
    end

    local E, L, V, P, G = unpack(ElvUI)

    local S = E:GetModule('Skins')

    ExtraStats.categoryYOffset = -5;
    ExtraStats.statYOffset = -5;

    ExtraStats:debug("ELVUI Detected")

    ExtraStats:On("category:build", function(frame)
        frame:StripTextures()
        frame:CreateBackdrop()
        frame:SetHeight(30)
    end);

    ExtraStats:On("stat:build", function(frame)

    end);

    ExtraStats.window:StripTextures()
    ExtraStats.window.Inset:Hide()
    S:HandleFrame(ExtraStats.window, true, nil)
    ExtraStats.window.ScrollFrame:StripTextures()
    S:HandleScrollBar(ExtraStats.window.ScrollFrame.ScrollBar)
    S:HandleScrollBar(ExtraStats.window.ScrollFrame.ScrollBar)

    ExtraStats.window:SetPoint("LEFT", PaperDollFrame, "RIGHT", -33, 30)

end