"""Controller routes and input-mode transitions on the real addon adapter."""
from forever_header_smoke import lua, ROOT
lua.execute(r'''
function hooksecurefunc(object,key,fn)
 if type(object)=='string' then
  local old=_G[object]; _G[object]=function(...) if old then old(...) end; key(...) end
 else
  local old=object[key]; object[key]=function(...) old(...); fn(...) end
 end
end
local function frame() return CreateFrame() end
CharacterHeadSlot=frame(); CharacterHandsSlot=frame(); CharacterWristSlot=frame()
CharacterTrinket1Slot=frame(); CharacterMainHandSlot=frame()
PaperDollItemsFrame=frame(); PaperDollItemsFrame.EquipmentSlots={CharacterHeadSlot,CharacterHandsSlot}
ExtraStatsForeverStats={rows={},navigationRows={frame(),frame()},roleIcons={TANK=frame(),HEALER=frame(),DAMAGER=frame()},button=frame(),scrollBar=frame(),Refresh=function() end}
ExtraStatsForeverResistances={rows={frame(),frame(),frame(),frame(),frame()}}
local gear=PaperDollFrame.EquipmentManagerPane
gear.ScrollBox=frame(); gear.ScrollBar=frame(); gear.NewSet=frame(); gear.EquipSet=frame(); gear.SaveSet=frame()
gear.equipmentSetIDs={10,20}
gear.rows={frame(),frame()}; gear.rows[1].setID=10; gear.rows[2].setID=20
function gear.ScrollBox:GetFrames() return gear.rows end
function PaperDollFrame.TitleManagerPane.ScrollBox:GetFrames() return {titleRow} end
titleRow=frame()
CharacterStatsPanePetScrollBox.ScrollBox=frame()
function CharacterStatsPanePetScrollBox.ScrollBox:GetFrames() return {} end
local tabs=frame(); PaperDollFrame.TabIndicators=tabs
function tabs:UpdateTabVisibility() self.visibleTabs={}; for _,tab in ipairs(self.tabs) do if tab:IsShown() then table.insert(self.visibleTabs,tab) end end end
function tabs:SetCurrentIndex(index) self.currentIndex=index end
function tabs:UpdateTabIndicators() end
SmartNavigation={RefreshButtonGroups=function() end,GetActiveFrame=function() return CharacterFrame end,SelectButton=function(_,button) selectedButton=button end}
InputUtil={IsGamepadUIEnabled=function() return true end}
SMART_NAV_INPUT_DIRECTION={UP='up',DOWN='down',LEFT='left',RIGHT='right'}
function SmartNavigation_AddJumpNavigationOverride(frame,direction,target)
 frame.routes=rawget(frame,'routes') or {}; frame.routes[direction]=target
end
function SmartNavigation_ClearIgnoreStatus(frame) frame.ignored=false end
function SmartNavigation_MarkFrameIgnored(frame) frame.ignored=true end
function SmartNavigation_MarkFrameFocusable(frame) frame.focusable=true end
function route(frame,direction) local target=frame.routes[direction]; if type(target)=='function' then return target() end; return target end
local timers={}
C_Timer={After=function(_,fn) table.insert(timers,fn) end}
function flush() local pending=timers; timers={}; for _,fn in ipairs(pending) do fn() end end
''')
lua.execute("assert(load(...))('ExtraStats')", (ROOT/'forever/Controller.lua').read_text())
lua.execute(r'''
frames[#frames].scripts.OnEvent(frames[#frames],'ADDON_LOADED','ExtraStats')
flush()
local c=ExtraStatsForeverController
local gear=PaperDollFrame.EquipmentManagerPane
assert(not PaperDollSidebarTabs.ignored)
assert(PaperDollFrame.TabIndicators.tabs[2]==PaperDollSidebarTab2)
assert(route(PaperDollSidebarTab1,'right')==PaperDollSidebarTab2)
assert(ExtraStatsForeverTitlesTab==nil)
assert(gear.ScrollBox.point[2]==gear and gear.ScrollBox.point[5]==105)
assert(gear.NewSet:IsShown() and gear.EquipSet:IsShown())
PaperDollFrame_SetSidebar(PaperDollSidebarTab2,2); flush()
assert(c:FirstContent()==gear.rows[1])
assert(route(gear.rows[1],'down')==nil) -- Native scrolling for non-final sets.
assert(route(gear.rows[2],'down')==gear.NewSet)
assert(route(gear.NewSet,'up')==gear.rows[2])
assert(route(gear.NewSet,'down')==gear.EquipSet)
assert(route(gear.EquipSet,'right')==gear.SaveSet)
gear.rows={}; c:Refresh()
assert(c:FirstContent()==gear.NewSet)
assert(route(gear.NewSet,'up')==PaperDollSidebarTab2)
assert(route(PaperDollSidebarTab3,'right')==ExtraStatsForeverStats.button)
assert(route(ExtraStatsForeverStats.button,'left')==PaperDollSidebarTab3)
assert(route(CharacterHandsSlot,'left')==ExtraStatsForeverResistances.rows[1])
assert(route(ExtraStatsForeverStats.navigationRows[1],'down')==ExtraStatsForeverStats.navigationRows[2])
gear:InitializeGamepad(); flush()
assert(gear.ScrollBox.point[2]==gear and gear.NewSet:IsShown())
CharacterFrame:SetupGamepad(); flush()
assert(#PaperDollFrame.TabIndicators.tabs==4)
print('PASS: Stats/gear/pet bumper and directional routes, populated and empty gear sets, New/Equip/Save paths, stats/roles/cog/resistance routes, input-mode reinitialization')
''')
