"""Exercise settings tab controls without requiring an in-game renderer."""
from forever_smoke import lua, ROOT
lua.execute("assert(load(...))('ExtraStats')", (ROOT/'forever/SettingsUI.lua').read_text())
lua.execute(r'''
UISpecialFrames={}
SmartNavigation=nil
CharacterFrame=CreateFrame()
CharacterFrameLeftPaneHost=CreateFrame()
CharacterFrameRightPaneHost=CreateFrame()
CharacterFrameModeTabs=CreateFrame()
CharacterFrameRightPaneToggleButton=CreateFrame()
CharacterFrameTabIndicators=CreateFrame()
PaperDollFrame.TabIndicators=CreateFrame()
function CharacterFrame:GetStatsPane() return CharacterStatsPaneScrollBox end
CharacterStatsPanePetScrollBox=CreateFrame()
function PaperDollFrame_SetSidebar() CharacterStatsPaneScrollBox:Show() end
C_ClassTalents.GetActiveConfigID=function() return 100 end
local ui=ExtraStatsForeverStats
ui.settings.rolePreset='OFF'
local options=ExtraStatsForeverOptions
local normalFrames={CharacterFrameLeftPaneHost,CharacterFrameRightPaneHost,CharacterModelScene,
 PaperDollItemsFrame,PaperDollSidebarTabs,CharacterStatsPaneScrollBox,CharacterFrameModeTabs,
 CharacterFrameRightPaneToggleButton,PaperDollFrame.TabIndicators,CharacterFrameTabIndicators}
for _,frame in ipairs(normalFrames) do
 frame.IsShown=function(self) return not self.hidden end
 frame:Show()
end
ui.button.OnClick()
for _,frame in ipairs(normalFrames) do assert(frame.hidden) end
assert(#options.tabs==7 and options.content.parent==options.frame)
assert(options.frame.parent==CharacterFrame)
options.frame.OnShow()
assert(#options.controls==9 and options.heading.text=='General')
options.controls[6].OnClick() -- Dark
assert(ExtraStatsForeverSettings.backgroundMode=='DARK')
options.controls[7].OnClick() -- Light
assert(ExtraStatsForeverSettings.backgroundMode=='LIGHT')
options.controls[3].OnClick() -- Tank
assert(ui.settings.rolePreset=='TANK')
options:SelectPage(2)
assert(options.page==2 and options.heading.text==ui.categories.base.categoryName)
local was=ui:IsCategoryShown('base')
options.controls[1].OnClick()
assert(ui:IsCategoryShown('base')~=was)
options.controls[3].OnClick() -- Health visibility
assert(ui:GetProfile().stats.HEALTH==false)
assert(options.actionLeft.hidden and options.actionRight.hidden)
options.tabs[2].Down.OnClick()
assert(ui.settings.orderCustom)
options:SelectPage(1)
assert(options.page==1)
options.actionRight.OnClick()
assert(ui.settings.rolePreset=='AUTO' and not ui.settings.orderCustom)
options:SelectPage(7)
assert(options.page==7)
assert(#UISpecialFrames==1 and UISpecialFrames[1]=="ExtraStatsForeverSettingsPanel")
assert(options.done.point[1]=="TOPRIGHT")
assert(options.frame.point[2]==CharacterFrame and options.frame.point[4]==-7)
options.done.OnClick()
assert(options.frame.hidden)
-- Explicit close must restore the character even without mock script dispatch.
for _,frame in ipairs(normalFrames) do assert(not frame.hidden) end
options.frame.OnHide() -- Repeated cleanup must be harmless.
for _,frame in ipairs(normalFrames) do assert(not frame.hidden) end
assert(options.hiddenFrames==nil)
-- Escape uses the OnHide path rather than the Back button callback.
options:Toggle()
for _,frame in ipairs(normalFrames) do assert(frame.hidden) end
options.frame:Hide()
options.frame.OnHide()
for _,frame in ipairs(normalFrames) do assert(not frame.hidden) end
assert(ui.button.parent==PaperDollSidebarTabs and ui.button.point[1]=='RIGHT')
local oldClass=UnitClass
ui.settings.rolePreset='TANK'; ui.settings.orderCustom=false
ui:GetProfile().categories.spell=nil
UnitClass=function() return 'Warrior','WARRIOR' end
local shown,reason=ui:GetCategoryVisibility('spell')
assert(not shown and reason:find('Warrior'))
UnitClass=function() return 'Paladin','PALADIN' end
shown,reason=ui:GetCategoryVisibility('spell')
assert(shown and reason:find('Paladin'))
assert(ui:GetOrder()[3]=='spell' and ui:GetOrder()[6]=='attributes')
ui:GetProfile().categories.spell=false
shown,reason=ui:GetCategoryVisibility('spell')
assert(not shown and reason:find('override'))
UnitClass=oldClass
print('PASS: class-aware visibility explanations, Paladin tank spell priority, explicit override preservation')
print('PASS: cog opens settings tab, mode/role/category/stat settings, ordering/reset, direct section navigation, return to stats')
''')
