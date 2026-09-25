-- Full-window settings page with section navigation.
local _, _, _, interface = GetBuildInfo()
if interface < 16000 or interface >= 17000 then return end
local Settings = { page = 1 }
ExtraStatsForeverOptions = Settings
local categories = { "base", "attributes", "melee", "ranged", "spell", "defenses" }
local roles = { {"AUTO", "Auto (talent build)"}, {"OFF", "All roles"}, {"TANK", "Tank"}, {"HEALER", "Healer"}, {"DAMAGER", "Damage"} }

local function GamepadActive()
    return SmartNavigation and InputUtil.IsGamepadUIEnabled() and SmartNavigation:GetActiveFrame() == CharacterFrame
end

function Settings:UpdateNavigation()
    if not self.frame or not self.frame:IsShown() or not SmartNavigation then return end
    local controls = {}
    for _, button in ipairs(self.controls) do table.insert(controls, button) end
    table.insert(controls, self.done)
    local D = SMART_NAV_INPUT_DIRECTION
    for index, button in ipairs(controls) do
        SmartNavigation_AddJumpNavigationOverride(button, D.UP, controls[index-1] or self.tabs[self.page])
        SmartNavigation_AddJumpNavigationOverride(button, D.DOWN, controls[index+1] or self.tabs[self.page])
        SmartNavigation_AddJumpNavigationOverride(button, D.LEFT, self.tabs[self.page])
        SmartNavigation_AddJumpNavigationOverride(button, D.RIGHT, controls[index+1] or self.tabs[self.page])
    end
    for index, button in ipairs(self.navigationTabs) do
        SmartNavigation_AddJumpNavigationOverride(button,D.UP,self.navigationTabs[index-1] or self.done)
        SmartNavigation_AddJumpNavigationOverride(button,D.DOWN,self.navigationTabs[index+1] or self.done)
        SmartNavigation_AddJumpNavigationOverride(button,D.RIGHT,controls[1] or self.done)
    end
    SmartNavigation:RefreshButtonGroups(CharacterFrame)
end

function Settings:SelectPage(page)
    self.page=page
    self:Render()
    if GamepadActive() then SmartNavigation:SelectButton(self.tabs[self.page], true) end
end

function Settings:Render()
    local ui = ExtraStatsForeverStats
    ui.labels.POWER = ui:GetPowerName()
    for _, button in ipairs(self.controls) do button:Hide() end
    self.controls = {}
    local index = 0
    local function Control(label, getter, action, x, y, radio)
        index = index + 1
        local poolKey = (radio and "radio" or "check") .. index
        local button = self.pool[poolKey]
        if not button then
            button = CreateFrame("CheckButton", nil, self.content, radio and "UIRadioButtonTemplate" or "UICheckButtonTemplate")
            button:SetSize(20, 20)
            button:SetHitRectInsets(0, -165, 0, 0)
            button.Label = button:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
            button.Label:SetPoint("LEFT", button, "RIGHT", 4, 0)
            button.Label:SetWidth(165)
            button.Label:SetJustifyH("LEFT")
            self.pool[poolKey] = button
        end
        button:ClearAllPoints()
        button:SetPoint("TOPLEFT", self.content, "TOPLEFT", x, -y)
        button.Label:SetText(label)
        button:SetChecked(getter())
        button:SetScript("OnClick", function()
            action()
            ui:Refresh()
            self:Render()
            if GamepadActive() then SmartNavigation:SelectButton(button, true) end
        end)
        button:Show()
        table.insert(self.controls, button)
    end
    self.actionLeft:Hide(); self.actionRight:Hide()
    if self.page == 1 then
        self.heading:SetText("General")
        self.section1:SetText("ROLE PRESET")
        self.section1:SetPoint("TOPLEFT",16,-76)
        self.section2:SetText("PAPER-DOLL BACKGROUND")
        self.section2:SetPoint("TOPLEFT",16,-242)
        self.description:SetText("Role and appearance")
        for i, option in ipairs(roles) do
            local role = option[1]
            Control(option[2], function() return ui.settings.rolePreset == role end,
                function() ui.settings.rolePreset = role end, 16, 106+(i-1)*24, true)
        end
        for i, option in ipairs({ {"DARK", "Dark"}, {"LIGHT", "Light"} }) do
            local mode = option[1]
            Control(option[2], function() return ExtraStatsForeverData.GetBackgroundMode() == mode end,
                function() ExtraStatsForeverData.SetBackgroundMode(mode) end, 16, 272+(i-1)*24, true)
        end
        self.actionLeft:SetText("Auto order")
        self.actionRight:SetText("Reset stats")
        self.actionLeft:SetScript("OnClick", function() ui.settings.orderCustom=false; ui:Refresh(); self:Render() end)
        self.actionRight:SetScript("OnClick", function()
            ui.settings.orderCustom=false; ui.settings.order={unpack(categories)}
            ui.settings.collapsed={}; ui.settings.profiles={}; ui.settings.rolePreset="AUTO"
            ui:Refresh(); self:Render()
        end)
    else
        local id = categories[self.page-1]
        local category = ui.categories[id]
        local profile, role = ui:GetProfile()
        self.heading:SetText(category.categoryName)
        self.section1:SetText("CATEGORY")
        self.section1:SetPoint("TOPLEFT",16,-100)
        self.section2:SetText("VISIBLE STATS")
        self.section2:SetPoint("TOPLEFT",16,-196)
        local shown, reason = ui:GetCategoryVisibility(id)
        self.description:SetText(({OFF="All roles", TANK="Tank", HEALER="Healer", DAMAGER="Damage"})[role] .. " - " .. (shown and "Shown" or "Hidden") .. "\n" .. reason)
        Control("Show category", function() return ui:IsCategoryShown(id) end,
            function() profile.categories[id] = not ui:IsCategoryShown(id) end, 16, 130)
        Control("Collapse category", function() return ui.settings.collapsed[id] == true end,
            function() ui.settings.collapsed[id] = not ui.settings.collapsed[id] end, 16, 156)
        for i, stat in ipairs(category.stats) do
            local key = stat.stat
            Control(ui.labels[key] or key, function() return profile.stats[key] ~= false end,
                function() profile.stats[key] = profile.stats[key] == false end, 16 + math.floor((i-1)/4)*190, 226+((i-1)%4)*26)
        end
    end
    if self.page == 1 then
        self.actionLeft:Show(); self.actionRight:Show()
        table.insert(self.controls, self.actionLeft); table.insert(self.controls, self.actionRight)
    end
    self.navigationTabs={self.tabs[1]}
    for position,id in ipairs(ui:GetOrder()) do
        for page,category in ipairs(categories) do
            if category==id then
                local button=self.tabs[page+1]
                button:ClearAllPoints()
                button:SetPoint("TOPLEFT",self.rail,"TOPLEFT",6,-102-(position-1)*32)
                button:SetPoint("TOPRIGHT",self.rail,"TOPRIGHT",-6,-102-(position-1)*32)
                button.Up:SetEnabled(position>1); button.Down:SetEnabled(position<#categories)
                table.insert(self.navigationTabs,button)
                break
            end
        end
    end
    for index, button in ipairs(self.tabs) do
        button.Selected:SetShown(index==self.page)
        button.Hover:Hide()
    end
    self:UpdateNavigation()
end

function Settings:Create()
    local panel = CreateFrame("Frame", "ExtraStatsForeverSettingsPanel", CharacterFrame)
    self.frame = panel
    panel:Hide()
    panel:SetPoint("TOPLEFT", CharacterFrame, "TOPLEFT", 7, -24)
    panel:SetPoint("BOTTOMRIGHT", CharacterFrame, "BOTTOMRIGHT", -7, 7)
    panel:SetFrameLevel(CharacterFrame:GetFrameLevel()+10)
    panel:EnableMouse(true)
    -- Reuse the actual Camelot Skills/Reputation pane artwork.
    local leftBackground=panel:CreateTexture(nil,"BACKGROUND")
    leftBackground:SetAtlas("UI-Character-Info-General-BG")
    leftBackground:SetPoint("TOPLEFT"); leftBackground:SetPoint("BOTTOMLEFT")
    leftBackground:SetWidth(190)
    local rightBackground=panel:CreateTexture(nil,"BACKGROUND")
    rightBackground:SetAtlas("UI-Character-Info-Stat-BG")
    rightBackground:SetPoint("TOPLEFT",panel,"TOPLEFT",190,0)
    rightBackground:SetPoint("BOTTOMRIGHT")
    local seam=panel:CreateTexture(nil,"OVERLAY")
    seam:SetAtlas("common-framedivider")
    seam:SetPoint("TOPLEFT",panel,"TOPLEFT",185,0)
    seam:SetPoint("BOTTOMLEFT",panel,"BOTTOMLEFT",185,0)
    seam:SetWidth(11)
    local title=panel:CreateFontString(nil,"OVERLAY","GameFontNormalLarge")
    title:SetPoint("TOPLEFT",36,-18); title:SetText("Settings")
    local divider=panel:CreateTexture(nil,"ARTWORK")
    divider:SetPoint("TOPLEFT",16,-50); divider:SetPoint("TOPRIGHT",-16,-50)
    divider:SetHeight(8); divider:SetAtlas("UI-Character-Info-ScrollLine-Long")
    local rail=CreateFrame("Frame",nil,panel)
    rail:SetPoint("TOPLEFT",10,-60); rail:SetPoint("BOTTOMLEFT",10,12)
    rail:SetWidth(174)
    self.rail=rail
    for _,section in ipairs({{"GENERAL",0},{"CATEGORIES",76}}) do
        local label=rail:CreateFontString(nil,"OVERLAY","GameFontNormalSmall")
        label:SetPoint("TOPLEFT",12,-section[2]); label:SetText(section[1])
    end
    self.content=CreateFrame("Frame",nil,panel)
    self.content:SetPoint("TOPLEFT",panel,"TOPLEFT",196,-62)
    self.content:SetPoint("BOTTOMRIGHT",panel,"BOTTOMRIGHT",-12,54)
    self.heading=self.content:CreateFontString(nil,"OVERLAY","GameFontHighlightLarge")
    self.heading:SetPoint("TOPLEFT",16,-14)
    self.description=self.content:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall")
    self.description:SetPoint("TOPLEFT",16,-40); self.description:SetWidth(350); self.description:SetHeight(48); self.description:SetJustifyV("TOP"); self.description:SetJustifyH("LEFT")
    self.section1=self.content:CreateFontString(nil,"OVERLAY","GameFontNormalSmall")
    self.section1:SetPoint("TOPLEFT",16,-76)
    self.section2=self.content:CreateFontString(nil,"OVERLAY","GameFontNormalSmall")
    for _,section in ipairs({self.section1,self.section2}) do
        section:SetWidth(340); section:SetJustifyH("LEFT")
        local bar=self.content:CreateTexture(nil,"BACKGROUND")
        bar:SetAtlas("common-button-list-collapseExpand")
        bar:SetPoint("TOPLEFT",section,"TOPLEFT",-8,6)
        bar:SetPoint("TOPRIGHT",section,"TOPRIGHT",8,6)
        bar:SetHeight(26)
    end
    self.tabs={}
    for index,name in ipairs({"General","Overview","Attributes","Melee","Ranged","Spell","Defenses"}) do
        local page=index
        local button=CreateFrame("Button",nil,rail)
        button:SetHeight(30)
        button:SetPoint("TOPLEFT",rail,"TOPLEFT",6,-20-(index-1)*32)
        button:SetPoint("TOPRIGHT",rail,"TOPRIGHT",-6,-20-(index-1)*32)
        -- Native Skills rows use rounded end caps and 20% selected opacity.
        local function Highlight(layer, alpha)
            local group=CreateFrame("Frame",nil,button)
            group:SetAllPoints(); group:EnableMouse(false)
            local left=group:CreateTexture(nil,layer)
            left:SetAtlas("charactercreate-customize-dropdown-linemouseover-side")
            left:SetWidth(6); left:SetPoint("TOPLEFT"); left:SetPoint("BOTTOMLEFT")
            local right=group:CreateTexture(nil,layer)
            right:SetAtlas("charactercreate-customize-dropdown-linemouseover-side")
            right:SetTexCoord(1,0,0,1)
            right:SetWidth(6); right:SetPoint("TOPRIGHT"); right:SetPoint("BOTTOMRIGHT")
            local middle=group:CreateTexture(nil,layer)
            middle:SetAtlas("charactercreate-customize-dropdown-linemouseover-middle")
            middle:SetPoint("TOPLEFT",left,"TOPRIGHT")
            middle:SetPoint("BOTTOMRIGHT",right,"BOTTOMLEFT")
            group:SetAlpha(alpha)
            return group
        end
        button.Selected=Highlight("BACKGROUND",0.20)
        button.Hover=Highlight("BACKGROUND",0.10)
        button.Hover:Hide()
        local label=button:CreateFontString(nil,"OVERLAY","GameFontHighlight")
        label:SetPoint("LEFT",10,0); label:SetText(name)
        button:SetScript("OnEnter",function() if self.page~=page then button.Hover:Show() end end)
        button:SetScript("OnLeave",function() button.Hover:Hide() end)
        button:SetScript("OnClick",function() self:SelectPage(page) end)
        if page>1 then
            local function Arrow(direction,x,texture)
                local arrow=CreateFrame("Button",nil,button)
                arrow:SetSize(18,18); arrow:SetPoint("RIGHT",button,"RIGHT",x,0)
                arrow:SetNormalTexture(texture)
                arrow:SetHighlightTexture("Interface\\Buttons\\UI-Common-MouseHilight","ADD")
                arrow:SetScript("OnClick",function()
                    ExtraStatsForeverStats:Move(categories[page-1],direction)
                    self:Render()
                end)
                arrow:Hide()
                return arrow
            end
            button.Up=Arrow(-1,-22,"Interface\\Buttons\\UI-ScrollBar-ScrollUpButton-Up")
            button.Down=Arrow(1,-2,"Interface\\Buttons\\UI-ScrollBar-ScrollDownButton-Up")
            button:SetScript("OnUpdate",function()
                local hover=button:IsMouseOver() or button.Up:IsMouseOver() or button.Down:IsMouseOver()
                button.Up:SetShown(hover); button.Down:SetShown(hover)
            end)
        end
        self.tabs[index]=button
    end
    -- Keep a stable entry point for the controller adapter.
    self.selector=self.tabs[1]
    local function Button(parent,text,width,point,x,y)
        local button=CreateFrame("Button",nil,parent,"UIPanelButtonTemplate")
        button:SetSize(width,24); button:SetPoint(point,parent,point,x,y); button:SetText(text)
        return button
    end
    self.actionLeft=Button(panel,"",140,"BOTTOMLEFT",212,16)
    self.actionRight=Button(panel,"",140,"BOTTOMRIGHT",-28,16)
    self.done=Button(panel,"Back to character",160,"TOPRIGHT",-20,-16)
    self.done:SetScript("OnClick",function() self:Close() end)
    table.insert(UISpecialFrames, "ExtraStatsForeverSettingsPanel")
    self.pool,self.controls={},{}
    panel:SetScript("OnShow",function()
        self:Render()
        ExtraStatsForeverStats.button:LockHighlight()
        if GamepadActive() then
            CharacterFrame:SwapToRightSide()
            SmartNavigation:SetScrollFrameForFrame(CharacterFrame,nil)
            SmartNavigation:SelectButton(self.selector)
        end
    end)
    panel:SetScript("OnHide",function()
        self:RestoreCharacter()
        ExtraStatsForeverStats.button:UnlockHighlight()
        if ExtraStatsForeverController then ExtraStatsForeverController:QueueRefresh() end
    end)
    -- Native tabs and the character-window mode/collapse controls own visibility.
    hooksecurefunc("PaperDollFrame_SetSidebar",function() panel:Hide() end)
    hooksecurefunc(CharacterFrame,"HidePaperDollRightPane",function() panel:Hide() end)
    for _,pane in ipairs({CharacterFrame:GetStatsPane(),PaperDollFrame.EquipmentManagerPane,CharacterStatsPanePetScrollBox}) do
        pane:HookScript("OnShow",function() panel:Hide() end)
    end
    PaperDollFrame:HookScript("OnHide",function() panel:Hide() end)
end

function Settings:RestoreCharacter()
    local hidden=self.hiddenFrames
    self.hiddenFrames=nil
    for _,frame in ipairs(hidden or {}) do frame:Show() end
    if hidden and GamepadActive() then
        SmartNavigation:SelectButton(ExtraStatsForeverStats.button, true)
    end
end

function Settings:Close()
    if self.frame then self.frame:Hide() end
    self:RestoreCharacter()
    PaperDollFrame_SetSidebar(PaperDollSidebarTab1,1)
end

function Settings:Toggle()
    if not self.frame then self:Create() end
    if self.frame:IsShown() then self:Close(); return end
    -- Restore the player model when entering settings from the pet tab.
    PaperDollFrame_SetSidebar(PaperDollSidebarTab1,1)
    self.hiddenFrames={}
    for _,frame in ipairs({CharacterFrameLeftPaneHost, CharacterFrameRightPaneHost,
        CharacterModelScene, PaperDollItemsFrame, PaperDollSidebarTabs,
        CharacterFrame:GetStatsPane(), PaperDollFrame.EquipmentManagerPane,
        CharacterStatsPanePetScrollBox, CharacterFrameModeTabs,
        CharacterFrameRightPaneToggleButton, PaperDollFrame.TabIndicators, CharacterFrameTabIndicators}) do
        if frame:IsShown() then table.insert(self.hiddenFrames,frame); frame:Hide() end
    end
    self.frame:Show()
    if ExtraStatsForeverController then ExtraStatsForeverController:QueueRefresh() end
end
