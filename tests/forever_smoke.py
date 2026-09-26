"""Behavior checks for the Forever adapter with mocked WoW APIs."""
from pathlib import Path
import sys
ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / '.references/python'))
from lupa import LuaRuntime
lua = LuaRuntime(unpack_returned_tuples=True)
lua.execute(r'''
frames, hooks, timers = {}, {}, {}
unpack = table.unpack or unpack
local methods = {}
function methods:SetScript(name, fn) self[name] = fn end
function methods:RegisterEvent(event)
 self.registeredEvents=rawget(self,'registeredEvents') or {}; self.registeredEvents[event]=true
end
function methods:RegisterUnitEvent(event,unit)
 self.registeredEvents=rawget(self,'registeredEvents') or {}; self.registeredEvents[event]=unit
end
function methods:UnregisterEvent(event)
 if rawget(self,'registeredEvents') then self.registeredEvents[event]=nil end
end
function methods:GetScript(name) return rawget(self, name) end
function methods:GetRegions() return unpack(rawget(self,'regions') or {}) end
function methods:IsObjectType(kind) return kind=='Texture' end
function methods:GetAtlas() return rawget(self,'atlas') end
function methods:GetFrames() return rawget(self, 'visibleFrames') or {} end
function methods:GetElementData() return rawget(self, 'elementData') end
function methods:SetSize(w,h) self.width=w; self.height=h end
function methods:SetPoint(...) self.point={...} end
function methods:GetHeight() return rawget(self,'height') or 300 end
function methods:GetVerticalScrollRange() error('Restricted range read') end
function methods:GetVerticalScroll() error('Restricted offset read') end
function methods:SetVerticalScroll(value) self.offset=value end
function methods:RegisterCallback(event, fn, owner) self.callback=fn; self.callbackOwner=owner end
function methods:SetScrollPercentage(value)
 self.percentage=value
 if rawget(self,'callback') then self.callback(self.callbackOwner,value) end
end
function methods:SetVisibleExtentPercentage(value) self.visibleExtent=value end
function methods:SetPanExtentPercentage(value) self.panExtent=value end
function methods:GetFrameLevel() return 50 end
function methods:IsShown() return false end
function methods:IsVisible() return renderVisible == true end
function methods:Hide() self.hidden=true end
function methods:Show() self.hidden=false end
function methods:SetText(text) self.text = text end
function methods:SetEnabled(value) self.enabled = value end
function methods:SetDataProvider(data) self.provider = data end
function methods:CreateTexture() return CreateFrame() end
function methods:CreateFontString() return CreateFrame() end
function CreateFrame(_, name, parent, template)
    local f = setmetatable({ExtraStatsControls=false,parent=parent,template=template}, {__index = function(_, key) return methods[key] or function() end end})
    if template == 'ExtraStatsForeverStatRowTemplate' then
        f.Label=CreateFrame(); f.Value=CreateFrame(); f.Background=CreateFrame(); f.Hover=CreateFrame()
    end
    if template == 'ExtraStatsForeverCategoryTemplate' then
        f.Title=CreateFrame(); f.CollapseButton=CreateFrame(); f.UpButton=CreateFrame(); f.DownButton=CreateFrame()
    end
    table.insert(frames, f)
    if name then _G[name] = f end
    return f
end
function SmartNavigation_MarkFrameFocusable(frame) frame.focusable=true end
function SmartNavigation_MarkFrameBlockingSmartNavClick(frame) frame.blockSmartNavClick=true end
function GetBuildInfo() return '', '', '', 16001 end
Enum = { Damageclass = { Arcane=7, Fire=3, Frost=5, Nature=4, Shadow=6 } }
STAT_CRITICAL_STRIKE, STAT_CATEGORY_RESISTANCE, STAT_HIT_CHANCE = 'Crit', 'Resistance', 'Hit'
STAT_CATEGORY_GENERAL, STAT_CATEGORY_PRIMARY_ATTRIBUTES, STAT_CATEGORY_DEFENSE = 'General', 'Attributes', 'Defense'
for i=1,7 do _G['DAMAGE_SCHOOL'..i] = 'School'..i end
function UnitName() return 'Tester' end
function UnitLevel() return 20 end
powerToken='MANA'
MANA, RAGE, ENERGY = 'Mana', 'Rage', 'Energy'
function UnitPowerType() return 0,powerToken end
playerClass, assignedRole, specRole = 'WARRIOR', 'NONE', 'DAMAGER'
function UnitClass() return playerClass, playerClass end
rangedEquipped=false
function IsRangedWeapon() return rangedEquipped end
function UnitGroupRolesAssigned() return assignedRole end
function GetUnitSpeed() return 0,7,7,4.72 end
function IsSwimming() return false end
function IsFlying() return false end
function IsFalling() return false end
function GetCritChance() return 12 end
function GetRangedCritChance() return 23 end
function GetSpellCritChance() return 34 end
CR_HIT_MELEE, CR_HIT_RANGED, CR_HIT_SPELL = 6, 7, 8
function GetCombatRatingBonus(rating) return rating / 2 end
function GetHitModifier() return 1 end
function GetRangedHitModifier() return 2 end
function GetSpellHitModifier() return 3 end
function PaperDollFrame_SetLabelAndText(frame, _, text, _, value) frame.Value:SetText(text); frame.numericValue=value end
function UnitResistance() return 5, 42, 999 end
function BreakUpLargeNumbers(n) return tostring(n) end
function PaperDollFrame_SetResistanceTooltips(f, name, value) f.tooltip = name..value end
C_PaperDollInfo = { OffhandHasShield = function() return true end }
PAPERDOLL_STATINFO = setmetatable({}, {__newindex=function() error('Blizzard stat registry modified') end})
petCategory = { unit='pet', stats={{stat='HEALTH'}} }
PAPERDOLL_STATCATEGORIES = { petCategory }
nativeCategories=PAPERDOLL_STATCATEGORIES
nativeStats=PAPERDOLL_STATINFO
PaperDollFrame, CharacterModelScene, CharacterStatsPaneScrollBox = CreateFrame(), CreateFrame(), CreateFrame()
CharacterModelScene.BackgroundOverlay = CreateFrame()
CharacterModelScene.ControlFrame = CreateFrame()
CharacterSecondaryHandSlot = CreateFrame()
PaperDollSidebarTabs = CreateFrame()
CharacterFrameRightPaneHostStoneBg = CreateFrame()
PaperDollItemsFrame = CreateFrame()
CharacterHandsSlot = CreateFrame()
CharacterStatsPaneScrollBox.ScrollBox = CreateFrame()
CharacterStatsPaneScrollBox.ScrollBar = CreateFrame()
local divider=CreateFrame(); divider.atlas='UI-Character-Info-ScrollLine'
local border=CreateFrame(); border.atlas='common-insideframe'
CharacterStatsPaneScrollBox.regions={divider,border}
ScrollBoxListMixin = { Event = { OnUpdate = "OnUpdate" } }
PaperDollFrame.EquipmentManagerPane = CreateFrame()
PaperDollFrame.EquipmentManagerPane.ScrollBox = CreateFrame()
GameTooltip = { IsOwned=function() return false end }
function hooksecurefunc(object, method, fn)
    if type(object)=='string' then hooks[object]=method else hooks[method]=fn end
end
function CreateDataProvider(data) return data end
ScrollBoxConstants = { RetainScrollPosition = true }
BaseScrollBoxEvents={OnScroll='OnScroll'}
ScrollUtil = { InitScrollFrameWithScrollBar=function() error('Unsafe engine range adapter') end }
group, combat, casting, locked, channeling = 1, false, false, false, false
C_SpecializationInfo = { GetActiveSpecGroup=function() return group end, GetSpecialization=function() return 1 end, GetSpecializationInfo=function() return 1,nil,nil,nil,specRole end }
function InCombatLockdown() return combat end
function UnitCastingInfo() return casting end
function UnitChannelInfo() return channeling end
function GetNumSpecGroups() return 2 end
sets, equippedCalls = {[10]='Tank', [20]='Heal'}, {}
C_EquipmentSet = {
 GetEquipmentSetInfo=function(id) return sets[id], nil, id, false end,
 EquipmentSetContainsLockedItems=function() return locked end,
 UseEquipmentSet=function(id) table.insert(equippedCalls,id); return true end,
}
C_Timer = { After=function(_,fn) table.insert(timers,fn) end }
function flush() local t=timers; timers={}; for _,fn in ipairs(t) do fn() end end
function fire(event, arg)
 for _,f in ipairs(frames) do if rawget(f,'OnEvent') then f.OnEvent(f,event,arg) end end
end
Menu = { ModifyMenu=function(_, fn) gearMenuModifier=fn end }
local function NewMenu(items)
 local menu={CreateTitle=function() end, CreateDivider=function() end}
 function menu:CreateCheckbox(name,checked,click)
  table.insert(items,{name=name,checked=checked,click=click})
 end
 menu.CreateRadio=menu.CreateCheckbox
 function menu:CreateButton(name,click)
  local item={name=name,click=click,children={}}
  table.insert(items,item)
  return NewMenu(item.children)
 end
 return menu
end
MenuUtil = { CreateContextMenu=function(owner,fn)
 menuItems={}
 local menu=NewMenu(menuItems)
 fn(nil,menu)
 if owner == PaperDollFrame.EquipmentManagerPane then gearMenuModifier(owner,menu) end
end }

''')
for name in ('ExtraStats.lua', 'StatsUI.lua', 'EquipmentSets.lua'):
    lua.execute("assert(load(...))('ExtraStats')", (ROOT/'forever'/name).read_text())
lua.execute(r'''
fire('ADDON_LOADED','ExtraStats')
assert(PAPERDOLL_STATCATEGORIES==nativeCategories and PAPERDOLL_STATINFO==nativeStats)
assert(#PAPERDOLL_STATCATEGORIES==1 and PAPERDOLL_STATCATEGORIES[1]==petCategory)
assert(#ExtraStatsForeverData.categories==6)
assert(ExtraStatsForeverData.categories[2].stats[1].stat=='STRENGTH')
assert(ExtraStatsForeverData.categories[2].stats[5].stat=='SPIRIT')
assert(#ExtraStatsForeverResistances.rows==5)
assert(ExtraStatsForeverResistances.rows[1].tooltip=='School742')
assert(hooks.UpdateStats==nil) -- No native provider/data hook remains.
local stat=CreateFrame(); stat.Value=CreateFrame()
assert(ExtraStatsForeverData.stats.EXTRASTATS_RANGED_CRIT.updateFunc(stat,'player')==23)
-- Forever's native per-attack hit setters are absent. Exercise every custom
-- percentage updater selected by a category, not just registration of the keys.
local expected = {
 EXTRASTATS_MELEE_CRIT=12, EXTRASTATS_RANGED_CRIT=23, EXTRASTATS_SPELL_CRIT=34,
 EXTRASTATS_MELEE_HIT=4, EXTRASTATS_RANGED_HIT=5.5, EXTRASTATS_SPELL_HIT=7,
}
local checked = 0
for _, category in ipairs(ExtraStatsForeverData.categories) do
 for _, entry in ipairs(category.stats) do
  assert(not entry.stat:match('^HITCHANCE_'), 'Undefined native hit setter selected')
  if expected[entry.stat] then
   local value = ExtraStatsForeverData.stats[entry.stat].updateFunc(stat, 'player')
   assert(value == expected[entry.stat], entry.stat)
   assert(stat.Value.text == string.format('%.2f%%', value))
   checked = checked + 1
  end
 end
end
assert(checked == 6)

local pane=PaperDollFrame.EquipmentManagerPane
local row={setID=10, EditButton=CreateFrame()}
row.EditButton.extraStatsWrapped=false
row.EditButton:SetScript('OnMouseDown', function()
 MenuUtil.CreateContextMenu(pane,function(_,menu)
  menu:CreateButton('Edit',function() end)
 end)
end)
hooks.GearSetButton_UpdateSpecInfo(row)
pane.selectedSetID=20 -- Editing an unselected row must still assign row 10.
row.EditButton.OnMouseDown(row.EditButton, 'LeftButton')
assert(#menuItems==4) -- Native edit entry plus assignments and clear.
menuItems[2].click(); assert(ExtraStatsForeverSettings.specSets[1]==10)
row.setID=20 -- Recycled row uses the new set ID, without wrapping twice.
hooks.GearSetButton_UpdateSpecInfo(row)
row.EditButton.OnMouseDown(row.EditButton, 'LeftButton')
menuItems[3].click(); assert(ExtraStatsForeverSettings.specSets[2]==20)
assert(ExtraStatsForeverAssignSpec==nil)
fire('PLAYER_ENTERING_WORLD'); flush(); assert(#equippedCalls==0)
group=2; fire('ACTIVE_TALENT_GROUP_CHANGED'); fire('PLAYER_SPECIALIZATION_CHANGED','player'); flush()
assert(#equippedCalls==1 and equippedCalls[1]==20)
combat=true; group=1; fire('ACTIVE_TALENT_GROUP_CHANGED'); flush(); assert(#equippedCalls==1)
combat=false; fire('PLAYER_REGEN_ENABLED'); flush(); assert(equippedCalls[2]==10)
locked=true; group=2; fire('ACTIVE_TALENT_GROUP_CHANGED'); flush(); assert(#equippedCalls==2)
group=1; fire('ACTIVE_TALENT_GROUP_CHANGED'); flush()
locked=false; fire('ITEM_UNLOCKED'); flush(); assert(equippedCalls[3]==10)
casting=true; group=2; fire('ACTIVE_TALENT_GROUP_CHANGED'); flush(); assert(#equippedCalls==3)
casting=false; fire('UNIT_SPELLCAST_STOP','player'); flush(); assert(equippedCalls[4]==20)
sets[10]=nil; group=1; fire('ACTIVE_TALENT_GROUP_CHANGED'); flush()
assert(#equippedCalls==4 and ExtraStatsForeverSettings.specSets[1]==nil)
print('PASS: categories, pet preservation, resistance values, menu assignment, spec swapping, duplicate events, combat/cast/lock deferral, latest-group selection, deleted sets')
''')

lua.execute(r'''
local ui=ExtraStatsForeverStats
assert(ui.settings.rolePreset=='AUTO')
assert(ui:IsCategoryShown('melee') and not ui:IsCategoryShown('defenses'))
specRole='TANK'; assert(ui:GetRole()=='TANK' and ui:IsCategoryShown('defenses'))
assignedRole='HEALER'; playerClass='PRIEST'
assert(ui:GetRole()=='HEALER' and ui:IsCategoryShown('spell') and not ui:IsCategoryShown('defenses'))
ui.settings.rolePreset='DAMAGER'; playerClass='HUNTER'
assert(ui:IsCategoryShown('ranged') and not ui:IsCategoryShown('spell'))
local profile=ui:GetProfile(); profile.categories.defenses=true
assert(ui:IsCategoryShown('defenses'))
ui.settings.rolePreset='HEALER'; assert(not ui:IsCategoryShown('defenses'))
ui.settings.rolePreset='OFF'
assert(ui:IsCategoryShown('spell') and ui:IsCategoryShown('defenses'))
local function Populate()
 local pane={elementData={}}
 for index=1,6 do
  local cat=ExtraStatsForeverData.categories[index]
  table.insert(pane.elementData,{isHeader=true,name=cat.categoryName})
  for _,entry in ipairs(cat.stats) do table.insert(pane.elementData,{name=entry.stat}) end
 end
 return pane
end
ui.settings.collapsed.melee=true
local pane=Populate(); ui:Apply(pane)
for _,entry in ipairs(pane.elementData) do assert(entry.name~='ATTACK_AP') end
ui:Move('defenses',-1)
assert(ui.settings.order[4]=='defenses')
assert(ExtraStatsForeverData.categories[2].stats[1].stat=='STRENGTH')
local profile=ui:GetProfile(); profile.stats.STRENGTH=false
pane=Populate(); ui:Apply(pane)
for _,entry in ipairs(pane.elementData) do assert(entry.name~='STRENGTH') end
local row=ExtraStatsForeverResistances.rows[1]
assert(row.width==72 and row.height==32)
assert(row.Value.text==42 and row.Icon.width==32)
assert(row.focusable and row.blockSmartNavClick)
for index,icon in ipairs(ExtraStatsForeverResistances.rows) do
 assert(icon.point[4]==0 and icon.point[5]==-(index-1)*33)
end
function UnitResistance() return 0,0,0 end
ExtraStatsForeverResistances.OnEvent()
assert(row.tooltip=='School70')
print('PASS: clicked/recycled gear-set edit menu, automatic/manual roles, per-role filters, collapse/order, attribute invariant, vertical resistance values and controller-focusable tooltips')
''')

lua.execute(r'''
local ui=ExtraStatsForeverStats
ui:OpenMenu(ui.button)
assert(#menuItems==14)
menuItems[3].click() -- Tank role radio
assert(ui:GetRole()=='TANK')
ui:OpenMenu(ui.button)
local defense=menuItems[11]
assert(defense.children[1].checked())
defense.children[1].click(); assert(not ui:IsCategoryShown('defenses'))
local header=CreateFrame(nil,nil,nil,"ExtraStatsForeverCategoryTemplate")
header.ExtraStatsControls=false
header.elementData={isHeader=true,extraStatsCategory='base'}
ui.headers={header}
ui:DecorateHeaders()
header.ExtraStatsControls.collapse.OnClick()
assert(ui.settings.collapsed.base)
header.elementData.extraStatsCategory='spell'
ui:DecorateHeaders()
header.ExtraStatsControls.collapse.OnClick()
assert(ui.settings.collapsed.spell)
ui:OpenMenu(ui.button); menuItems[13].click()
assert(ui:GetRole()=='HEALER' and ui.settings.rolePreset=='AUTO')
assert(not next(ui.settings.collapsed))
print('PASS: role/filter menus and recycled native header controls')
''')

lua.execute(r'''
local ui=ExtraStatsForeverStats
-- Give every native read-only updater a test implementation on the addon copy.
for _,category in ipairs(ExtraStatsForeverData.categories) do
 for _,stat in ipairs(category.stats) do
  if not ExtraStatsForeverData.stats[stat.stat] then
   ExtraStatsForeverData.stats[stat.stat]={updateFunc=function(frame)
    frame.Value:SetText(12); return 12
   end}
  end
 end
end
local secretHealth={}
function UnitHealth() return secretHealth end
function UnitPower() return 77 end
renderVisible=true
ui.headers={}; ui.rows={}; ui.settings.rolePreset='OFF'
ui:Refresh()
assert(#ui.headers==6 and #ui.rows>20)
assert(ui.rows[1].Value.text==secretHealth) -- Passed directly, no tostring/math.
assert(PAPERDOLL_STATCATEGORIES==nativeCategories and PAPERDOLL_STATINFO==nativeStats)
assert(next(PAPERDOLL_STATINFO)==nil)
assert(hooks.UpdateStats==nil)
local count=#ui.rows
ui.settings.collapsed.melee=true
ui:Refresh()
assert(ui.rows[count].hidden)
ui.refreshQueued=false; timers={}
hooks.PaperDollFrame_UpdateStats()
assert(ui.refreshQueued and #timers==1)
flush()
assert(not ui.refreshQueued)
print('PASS: untouched Blizzard registries/update method, isolated rendering, secret health passthrough, deferred secure-hook refresh')
''')

lua.execute(r'''
local ui=ExtraStatsForeverStats
for _,button in pairs(ui.roleIcons) do
 assert(button.parent==PaperDollItemsFrame and button.point[1]=='TOP')
 assert(button.point[2]==CharacterModelScene)
end
assert(ui.button.parent==PaperDollSidebarTabs and ui.button.point[1]=='RIGHT')
assert(rawget(ui.scroll,'template')==nil)
assert(ui.scrollBar.template=='MinimalScrollBar' and ui.scrollBar.parent==ui.scroll)
assert(rawget(ui.scroll,'OnScrollRangeChanged')==nil)
assert(ExtraStatsForeverResistances.point[2]==CharacterHandsSlot)
assert(ExtraStatsForeverResistances.point[3]=='TOPLEFT')
assert(ExtraStatsForeverResistances.point[4]==-12)
print('PASS: paper-doll role/cog anchors, equipment-relative resistance badges, modern overlay scrollbar')
''')

lua.execute(r'''
local ui=ExtraStatsForeverStats
ui.contentHeight=900; ui.scroll.height=300; ui:UpdateScrollMetrics()
assert(ui.scrollRange==600 and ui.scrollBar.visibleExtent==1/3)
ui.scroll.OnMouseWheel(ui.scroll,-1); assert(ui.scroll.offset==30)
ui.scrollBar.callback(ui,0.5); assert(ui.scroll.offset==300)
ui:SetScrollOffset(9999); assert(ui.scroll.offset==600 and ui.scrollBar.percentage==1)
ui.contentHeight=200; ui:UpdateScrollMetrics()
assert(ui.scroll.offset==0 and ui.scrollBar.percentage==0)
local secret={}
function issecretvalue(value) return value==secret end
ui.scroll.height=secret; ui.contentHeight=900; ui:UpdateScrollMetrics()
assert(ui.viewportHeight==300 and ui.scrollRange==600)
ui.scrollBar.callback(ui,secret); assert(ui.scroll.offset==0)
ui.scroll.OnSizeChanged(ui.scroll,secret)
assert(ui.viewportHeight==300)
print('PASS: wheel/drag/clamping, content shrink, secret geometry guards, no restricted scroll-range queries')
''')

lua.execute(r'''
local ui=ExtraStatsForeverStats
local activeConfig=1
local talentPoints={ [1]={1,2,15}, [2]={0,20,0} }
C_ClassTalents={GetActiveConfigID=function() return activeConfig end}
C_Traits={
 GetConfigInfo=function() return {treeIDs={999}} end,
 GetGroupDisplayInfoByTreeID=function() return {
  {groupID=30,orderIndex=2,displayName='Third'},
  {groupID=10,orderIndex=0,displayName='First'},
  {groupID=20,orderIndex=1,displayName='Second'},
 } end,
 GetGroupCurrencyInfo=function(configID)
  local p=talentPoints[configID]
  return {
   {traitNodeGroupID=20,currencyInfos={{spent=p[2]}}},
   {traitNodeGroupID=10,currencyInfos={{spent=p[1]}}},
   {traitNodeGroupID=30,currencyInfos={{spent=p[3]}}},
  }
 end,
}
ui.settings.rolePreset='AUTO'; playerClass='WARRIOR'; assignedRole='HEALER'
assert(ui:GetRole()=='TANK' and ui.autoTreeName=='Third')
activeConfig=2; assert(ui:GetRole()=='DAMAGER')
playerClass='PALADIN'; assert(ui:GetRole()=='TANK')
playerClass='PRIEST'; assert(ui:GetRole()=='HEALER')
playerClass='DRUID'; assert(ui:GetRole()=='TANK')
activeConfig=1; playerClass='SHAMAN'; assert(ui:GetRole()=='HEALER')
talentPoints[1]={0,0,0}; assert(ui:GetRole()=='DAMAGER')
talentPoints[1]={5,5,0}; playerClass='PALADIN'; assert(ui:GetRole()=='HEALER')
ui.settings.rolePreset='TANK'; assert(ui:GetRole()=='TANK')
print('PASS: active talent config, sorted talent groups, highest-point tree, all hybrid class mappings, ties, empty build, manual override')
''')

lua.execute(r'''
assert(ExtraStatsForeverStats.rows[1].template=='ExtraStatsForeverStatRowTemplate')
assert(CharacterStatsPaneScrollBox.regions[1].hidden==true)
assert(rawget(CharacterStatsPaneScrollBox.regions[2],'hidden')==nil)
print('PASS: Classic stat-row template reused; native bottom divider hidden without hiding frame border')
''')

lua.execute(r'''
local ui=ExtraStatsForeverStats
ui.settings.orderCustom=false; ui.settings.rolePreset='HEALER'; playerClass='PRIEST'
rangedEquipped=true
assert(ui:IsCategoryShown('ranged'))
assert(ui:GetOrder()[2]=='spell' and ui:GetOrder()[3]=='ranged' and ui:GetOrder()[6]=='attributes')
rangedEquipped=false; assert(not ui:IsCategoryShown('ranged'))
ui.settings.rolePreset='DAMAGER'; playerClass='HUNTER'; assert(ui:GetOrder()[2]=='ranged')
ui.settings.rolePreset='TANK'; assert(ui:GetOrder()[2]=='defenses')
ui.settings.rolePreset='HEALER'; playerClass='PRIEST'
ui:Move('melee',-1); assert(ui.settings.orderCustom and ui:GetOrder()[3]=='melee')
ui.settings.rolePreset='TANK'; assert(ui:GetOrder()[3]=='melee')
ui.settings.orderCustom=false; assert(ui:GetOrder()[2]=='defenses')
local found=false
for _,stat in ipairs(ExtraStatsForeverData.categories[3].stats) do
 if stat.stat=='EXPERTISE' then assert(stat.hideAt==nil); found=true end
end
assert(found)
print('PASS: healer/caster/hunter/tank priority, equipped ranged weapon visibility, custom order preservation, expertise visible at zero')
''')

lua.execute(r'''
HEALTH, STAT_HEALTH_TOOLTIP = 'Health', 'Native health description'
function PaperDollStatTooltip(row) tooltipRow=row; tooltipKind='generic' end
function CharacterCritChanceFrame_OnEnter(row, melee, ranged, spell)
 tooltipKind='crit'; tooltipRow=row; tooltipNumbers={melee,ranged,spell}
end
function CharacterHitFrame_OnEnter(row, melee, ranged, spell, label)
 tooltipKind='hit'; tooltipRow=row; tooltipNumbers={melee,ranged,spell}; tooltipLabel=label
end
CharacterStatFrameMixin={OnEnter=function(row)
 if rawget(row,'onEnterFunc') then row:onEnterFunc() else PaperDollStatTooltip(row) end
end}
''')
lua.execute(r'''
local ui=ExtraStatsForeverStats
ui.settings.rolePreset='OFF'; ui.settings.collapsed={}
local protectedPower={}
function UnitPower() return protectedPower end
for _,token in ipairs({'MANA','RAGE','ENERGY'}) do
 powerToken=token
 ui:Refresh()
 if token=='MANA' then
  assert(ui.rows[2].Label.text==_G[token]..':')
  assert(ui.rows[2].Value.text==protectedPower)
  assert(ui.rows[2].tooltip==_G[token])
 else
  for _,row in ipairs(ui.rows) do
   assert(row.hidden or row.statName~='POWER')
  end
 end
 assert(ui.labels.POWER==_G[token])
end
powerToken='MANA'; timers={}; ui.refreshQueued=false
fire('UNIT_DISPLAYPOWER','player'); flush()
assert(ui.rows[2].Label.text=='Mana:')
print('PASS: localized resource labels, tooltip/menu names, power-type changes, secret value passthrough')
''')

lua.execute(r'''
local ui=ExtraStatsForeverStats
ui.settings.rolePreset='OFF'; ui.settings.collapsed={}; ui.settings.profiles={}
ui:Refresh()
ui.rows[1].OnEnter(ui.rows[1])
assert(tooltipKind=='generic' and tooltipRow.tooltip2==STAT_HEALTH_TOOLTIP)
ui.rows[2].OnEnter(ui.rows[2])
assert(tooltipKind=='generic' and tooltipRow.tooltip=='Mana')
local row=CreateFrame(); row.Value=CreateFrame()
for _,kind in ipairs({'MELEE','RANGED','SPELL'}) do
 ExtraStatsForeverData.stats['EXTRASTATS_'..kind..'_CRIT'].updateFunc(row,'player')
 CharacterStatFrameMixin.OnEnter(row)
 assert(tooltipKind=='crit' and tooltipRow.unit=='player')
 assert(tooltipNumbers[1]==12 and tooltipNumbers[2]==23 and tooltipNumbers[3]==34)
 ExtraStatsForeverData.stats['EXTRASTATS_'..kind..'_HIT'].updateFunc(row,'player')
 CharacterStatFrameMixin.OnEnter(row)
 assert(tooltipKind=='hit' and tooltipLabel==STAT_HIT_CHANCE)
 assert(tooltipNumbers[1]==4 and tooltipNumbers[2]==5.5 and tooltipNumbers[3]==7)
end
local resistance=ExtraStatsForeverResistances.rows[1]
resistance.OnEnter(resistance)
assert(tooltipKind=='generic' and tooltipRow==resistance)
print('PASS: native row tooltip dispatcher, full native crit/hit breakdowns, health/power descriptions and native resistance tooltip')
''')

lua.execute(r'''
local ui=ExtraStatsForeverStats
ui.settings.rolePreset='OFF'; playerClass='WARRIOR'; ui.settings.orderCustom=false; ui.settings.collapsed={}
ui:DropCategory('spell','melee')
assert(table.concat(ui:GetOrder(),',')=='base,spell,melee,ranged,defenses,attributes')
ui:DropCategory('base',nil)
assert(ui:GetOrder()[6]=='base')
local unchanged=table.concat(ui:GetOrder(),',')
ui:DropCategory('spell','spell'); assert(table.concat(ui:GetOrder(),',')==unchanged)
ui.settings.orderCustom=false; ui:Refresh()
function ui.scroll:GetLeft() return 0 end
function ui.scroll:GetTop() return 1000 end
function ui.scroll:GetWidth() return 200 end
function ui.scroll:GetEffectiveScale() return 1 end
GameTooltip.Hide=function() end
local cursorX,cursorY=80,995
function GetCursorPosition() return cursorX,cursorY end
local source=ui.headers[2]
assert(rawget(source,'OnMouseDown')==nil)
source.OnDragStart()
assert(ui.drag.id=='melee' and ui.drag.before=='base' and ui.drag.valid)
assert(not ui.dragGhost.hidden and ui.dragGhost.Label.text==ui.categories.melee.categoryName)
source.OnDragStop()
assert(ui:GetOrder()[1]=='melee' and not ui.drag)
assert(ui.dragGhost.hidden and ui.dropLine.hidden)
flush()
local saved=table.concat(ui:GetOrder(),',')
source=ui.headers[2]; source.OnDragStart()
cursorX=-20; source.OnDragStop()
assert(table.concat(ui:GetOrder(),',')==saved)
flush()
cursorX=80; cursorY=1000-ui.viewportHeight+5
ui:SetScrollOffset(0)
source=ui.headers[1]; source.OnDragStart()
ui:UpdateCategoryDrag(0.1)
assert(ui.scrollOffset>0)
source.OnHide(); assert(not ui.drag and table.concat(ui:GetOrder(),',')==saved)
print('PASS: drag before/end, self-drop, actual header drag handlers, outside cancellation, edge scrolling, hide cancellation, no header-click toggle')
''')

# Exercise registered events without calling the native paper doll hook.
lua.execute(r'''
local ui=ExtraStatsForeverStats
flush()
ui.settings.rolePreset='OFF'; ui.settings.collapsed={}; ui.settings.profiles={}
ui.settings.orderCustom=false
renderVisible=true; combat=true
ui:Refresh()
local eventFrame
for _,frame in ipairs(frames) do
 local registrations=rawget(frame,'registeredEvents')
 if registrations and registrations.UNIT_POWER_FREQUENT=='player' then eventFrame=frame; break end
end
assert(eventFrame)
local function deliver(event,unit)
 local registration=eventFrame.registeredEvents[event]
 assert(registration, 'Missing registration: '..event)
 if registration==true or registration==unit then eventFrame.OnEvent(eventFrame,event,unit) end
end
local health,power={},{}
local oldSecret=issecretvalue
function issecretvalue(value) return value==health or value==power or (oldSecret and oldSecret(value)) end
function UnitHealth() return health end
function UnitPower() return power end
local initial=ui.rows[1].Value.text
-- Other units must not change the player's rows.
deliver('UNIT_HEALTH','target'); flush()
assert(ui.rows[1].Value.text==initial)
-- Resource updates continue during combat and drag, without rebuilding rows.
ui.drag={}
deliver('UNIT_HEALTH','player')
deliver('UNIT_POWER_FREQUENT','player')
deliver('UNIT_POWER_UPDATE','player')
assert(#timers==1)
flush()
assert(ui.rows[1].Value.text==health and ui.rows[2].Value.text==power)
ui.drag=nil
local attackPower=50
ExtraStatsForeverData.stats.ATTACK_AP={updateFunc=function(row) row.Value:SetText(attackPower) end}
for _,event in ipairs({'UNIT_AURA','UNIT_STATS','UNIT_ATTACK_POWER','UNIT_ATTACK_SPEED','COMBAT_RATING_UPDATE','SPELL_POWER_CHANGED'}) do
 attackPower=attackPower+10
 deliver(event,'player'); flush()
 local found=false
 for _,row in ipairs(ui.rows) do
  if row.statName=='ATTACK_AP' then assert(row.Value.text==attackPower); found=true end
 end
 assert(found)
end
renderVisible=false; health={}
deliver('UNIT_HEALTH','player'); flush()
assert(ui.rows[1].Value.text~=health)
renderVisible=true; ui.scroll.OnShow(); flush()
assert(ui.rows[1].Value.text==health)
combat=false
print('PASS: registered combat resource/stat events, coalesced updates during drag, secret passthrough, unit filtering, hidden/show refresh')
''')

lua.execute(r'''
local ui=ExtraStatsForeverStats
STAT_MOVEMENT_SPEED='Movement Speed'
CR_SPEED=14
local secret=setmetatable({}, {__div=function() error('Arithmetic on secret speed') end})
local protected=false
local oldSecret=issecretvalue
function issecretvalue(value) return value==secret or (oldSecret and oldSecret(value)) end
function GetUnitSpeed() return 0,protected and secret or 7,7,4.72 end
function GetCombatRating() return 0 end
local calls=0
ExtraStatsForeverData.stats.MOVESPEED={updateFunc=function(row)
 calls=calls+1
 local _,run=GetUnitSpeed()
 row.speed=run/7*100
 row.Value:SetText(row.speed..'%')
 row.onEnterFunc=function(frame)
  local _,speed=GetUnitSpeed()
  local percentage=speed/7*100
  tooltipKind='movement'
 end
end}
ui:Refresh()
local row=ui.rows[3]
assert(calls==1 and row.statName=='MOVESPEED')
local hover=row.onEnterFunc
protected=true; combat=true
hover(row) -- Combat begins between render and hover.
assert(row.Value.text=='--' and rawget(row,'speed')==nil and tooltipKind=='generic')
ui:Refresh()
assert(calls==1 and row.Value.text=='--')
-- Restricted movement must not abort the remaining rows or resource updates.
assert(ui.rows[4].statName=='HASTE')
protected=false; combat=false
ui:Refresh()
assert(calls==2 and row.Value.text~='--')
row.onEnterFunc(row)
assert(tooltipKind=='movement')
print('PASS: secret movement speed bypasses native arithmetic, hover transition safe, later rows refresh, native speed/tooltip recover')
''')

lua.execute(r'''
local ui=ExtraStatsForeverStats
ui.scrollRange=500
ui.scroll:SetVerticalScroll(220)
assert(ui.scroll:GetVerticalScroll()==220 and ui.scroll:GetVerticalScrollRange()==500)
assert(ui.scroll.offset==220 and ui.scrollBar.percentage==220/500)
ui.scroll:SetVerticalScroll(900)
assert(ui.scroll:GetVerticalScroll()==500)
ui.scroll:SetVerticalScroll(-20)
assert(ui.scroll:GetVerticalScroll()==0)
assert(ui.rows[1].focusable and ui.rows[1].blockSmartNavClick)
assert(ui.button.template=='SquareIconButtonTemplate')
assert(ui.button.point[4]==-8 and ui.button.point[5]==0)
print('PASS: controller public range/offset adapter, scrollbar sync/clamping, focusable non-clickable stats, native corner settings button')
''')

# Exercise the exact native controller function from the reported stack trace.
native_nav = (ROOT/'tests/fixtures/SmartNavigationHandleScroll.lua').read_text()
lua.execute('SmartNavigationMixin = {}')
lua.execute(native_nav)
lua.execute(r'''
local ui=ExtraStatsForeverStats
function ui.scroll:IsObjectType(kind) return kind=='ScrollFrame' end
function ui.scroll:GetCenter() return 100,200 end
local target={GetCenter=function() return 100,100 end}
ui.scrollRange=500; ui:SetScrollOffset(30)
local selected=SmartNavigationMixin.HandleScroll({},target,ui.scroll)
assert(selected==target and ui.scroll:GetVerticalScroll()==130)
assert(ui.scrollBar.percentage==130/500)
print('PASS: native SmartNavigation HandleScroll uses public addon range and updates the scrollbar')
''')

lua.execute(r'''
local ui=ExtraStatsForeverStats
ui.settings.rolePreset='OFF'; playerClass='WARRIOR'; ui.settings.orderCustom=false; ui.settings.collapsed={}; ui.settings.profiles={}
ui:Refresh()
local row=ui.rows[1]
row.OnSmartNavSelect(row)
assert(tooltipRow==row and tooltipKind=='generic')
SmartNavigation={GetCurrentButton=function() return row end, SelectButton=function(_,target,force)
 assert(force); selectedStat=target.statName; target.OnSmartNavSelect(target)
end}
InputUtil={IsGamepadUIEnabled=function() return true end}
-- Mock actual frame visibility for the focus-preservation check.
for _,frame in ipairs(ui.rows) do function frame:IsShown() return not self.hidden end end
ui:DropCategory('base',nil)
ui:Refresh()
assert(selectedStat=='HEALTH' and tooltipRow.statName=='HEALTH')
SmartNavigation=nil
print('PASS: explicit controller tooltip callback and stat identity preserved across refresh/reorder')
''')

lua.execute(r'''
local pane=PaperDollFrame.EquipmentManagerPane
sets[10]='Tank'
local row=CreateFrame(); row.setID=10; row.EditButton=CreateFrame()
row.EditButton:SetScript('OnMouseDown',function() MenuUtil.CreateContextMenu(pane,function() end) end)
hooks.GearSetButton_UpdateSpecInfo(row)
C_SpecializationInfo.GetCombatConfigIDForSpecGroup=function(groupID) return groupID*100 end
C_Traits.GetConfigInfo=function(id) return {treeIDs={1}} end
C_Traits.GetGroupDisplayInfoByTreeID=function() return {
 {groupID=3,orderIndex=3,displayName='Protection'},
 {groupID=1,orderIndex=1,displayName='Arms'},
 {groupID=2,orderIndex=2,displayName='Fury'},
} end
local byConfig={[100]={0,0,20},[200]={20,0,0}}
C_Traits.GetGroupCurrencyInfo=function(id)
 local result={}
 for index,spent in ipairs(byConfig[id]) do result[index]={traitNodeGroupID=index,currencyInfos={{spent=spent}}} end
 return result
end
row.EditButton.OnMouseDown(row.EditButton)
assert(menuItems[1].name=='Spec 1: Protection' and menuItems[2].name=='Spec 2: Arms')
-- Reread when the menu opens, including inactive-spec changes and tied builds.
byConfig[200]={5,5,0}
row.EditButton.OnMouseDown(row.EditButton)
assert(menuItems[2].name=='Spec 2: Arms')
byConfig[200]={0,15,0}
row.EditButton.OnMouseDown(row.EditButton)
assert(menuItems[2].name=='Spec 2: Fury')
byConfig[100]={0,0,0}
row.EditButton.OnMouseDown(row.EditButton)
assert(menuItems[1].name=='Primary specialization')
C_SpecializationInfo.GetCombatConfigIDForSpecGroup=function() return nil end
row.EditButton.OnMouseDown(row.EditButton)
assert(menuItems[2].name=='Secondary specialization')
print('PASS: named active/inactive spec assignments, live talent changes, deterministic ties, empty/unavailable config fallback')
''')

lua.execute(r'''
local data=ExtraStatsForeverData
local overlay=CharacterModelScene.BackgroundOverlay
function overlay:SetAlpha(value) self.alpha=value end
ExtraStatsForeverSettings.backgroundMode=nil
assert(data.GetBackgroundMode()=='LIGHT')
-- Test the actual menu callbacks, saved preference, and native refresh hook.
ExtraStatsForeverStats:OpenMenu(ExtraStatsForeverStats.button)
local appearance
for _,item in ipairs(menuItems) do if item.name=='Paper-doll background' then appearance=item end end
assert(appearance and #appearance.children==2)
local dark,light=appearance.children[1],appearance.children[2]
assert(light.checked() and not dark.checked())
dark.click()
assert(ExtraStatsForeverSettings.backgroundMode=='DARK' and overlay.alpha==1)
assert(dark.checked() and not light.checked())
overlay.alpha=1; hooks.PaperDollBgDesaturate(true)
assert(overlay.alpha==1)
light.click()
assert(ExtraStatsForeverSettings.backgroundMode=='LIGHT' and overlay.alpha==0.45)
data.SetBackgroundMode('invalid'); assert(overlay.alpha==0.45)
print('PASS: Dark/Light menu selection, immediate shading, saved preference, refresh persistence, invalid-mode guard')
''')

lua.execute(r'''
local backgrounds={}
for _,suffix in ipairs({'TopLeft','TopRight','BotLeft','BotRight'}) do
 local texture=CreateFrame()
 function texture:SetDesaturated(value) self.desaturated=value end
 _G['CharacterModelFrameBackground'..suffix]=texture
 table.insert(backgrounds,texture)
end
ExtraStatsForeverData.SetBackgroundMode('DARK')
assert(CharacterModelScene.BackgroundOverlay.alpha==1)
for _,texture in ipairs(backgrounds) do assert(texture.desaturated==true) end
ExtraStatsForeverData.SetBackgroundMode('LIGHT')
assert(CharacterModelScene.BackgroundOverlay.alpha==0.45)
for _,texture in ipairs(backgrounds) do assert(texture.desaturated==false) end
local previous
for _,role in ipairs({'TANK','HEALER','DAMAGER'}) do
 local button=ExtraStatsForeverStats.roleIcons[role]
 assert(button.width==30 and button.height==30)
 if previous then assert(button.point[4]-previous.point[4]==30) end
 previous=button
end
print('PASS: native grayscale dark mode, colored light mode, larger tightly spaced role icons')
''')
