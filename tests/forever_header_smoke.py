"""Header mapping and native title-pane navigation regression checks."""
from pathlib import Path
import sys
ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / '.references/python'))
from lupa import LuaRuntime
lua = LuaRuntime()
lua.execute(r'''
unpack=table.unpack
local methods={}
function methods:SetScript(name,fn) self.scripts[name]=fn end
function methods:HookScript(name,fn) self.hooks[name]=fn end
function methods:Show() local was=self.shown; self.shown=true; if not was and self.hooks.OnShow then self.hooks.OnShow() end end
function methods:Hide() self.shown=false end
function methods:IsShown() return self.shown end
function methods:SetShown(value) if value then self:Show() else self:Hide() end end
function methods:CreateTexture() return CreateFrame() end
function methods:GetRegions() return end
function methods:GetCheckedTexture() return rawget(self,'checkedTexture') end
function methods:GetChecked() return rawget(self,'checked') end
function methods:SetPoint(...) self.point={...} end
function methods:GetFrameLevel() return rawget(self,"level") or 1 end
function methods:SetFrameLevel(value) self.level=value end
function methods:SetAlpha(value) self.alpha=value end
function methods:SetHeight(value) self.height=value end
function methods:SetWidth(value) self.width=value end
function methods:SetTexCoord(...) self.coords={...} end
function methods:SetTexture(value) self.texture=value end
frames={}
function CreateFrame(_,name)
 local frame=setmetatable({scripts={},hooks={},shown=true}, {__index=function(_,key) return methods[key] or function() end end})
 frames[#frames+1]=frame
 if name then _G[name]=frame end
 return frame
end
function GetBuildInfo() return '', '', '', 16001 end
function hooksecurefunc(name,fn)
 local previous=_G[name]
 _G[name]=function(...) if previous then previous(...) end; fn(...) end
end
CharacterFrame=CreateFrame()
local stats=CreateFrame()
function CharacterFrame:GetStatsPane() return stats end
PaperDollFrame=CreateFrame()
PaperDollFrame.EquipmentManagerPane=CreateFrame(); PaperDollFrame.EquipmentManagerPane:Hide()
PaperDollFrame.TitleManagerPane=CreateFrame(); PaperDollFrame.TitleManagerPane:Hide()
PaperDollFrame.TitleManagerPane.ScrollBox=CreateFrame()
function CreateDataProvider()
 local data={}
 function data:Insert(row) self[#self+1]=row end
 return data
end
ScrollBoxConstants={RetainScrollPosition=true}
function PaperDollFrame.TitleManagerPane.ScrollBox:SetDataProvider(data) self.data=data end
PLAYER_TITLE_NONE='None'
knownTitles={}
function GetCurrentTitle() return currentTitle or -1 end
function GetNumTitles() return 3 end
function IsTitleKnown(id) return knownTitles[id]~=nil end
function GetTitleName(id) return knownTitles[id],true end
function strtrim(value) return value:match('^%s*(.-)%s*$') end
CharacterStatsPanePetScrollBox=CreateFrame(); CharacterStatsPanePetScrollBox:Hide()
PaperDollSidebarTabs=CreateFrame()
CharacterFrameRightPaneHostStoneBg=CreateFrame()
CharacterFrameRightPaneHost=CreateFrame()
PaperDollLevelInfo=CreateFrame(); CharacterLevelText=CreateFrame(); CharacterLevelTextBackground=CreateFrame()
for i=1,3 do
 local tab=CreateFrame(nil,'PaperDollSidebarTab'..i)
 tab.Icon=CreateFrame(); tab.checkedTexture=CreateFrame(); tab.checked=i==1
end
PaperDollSidebarTab3.Icon.texture='native pet'
PaperDollSidebarTab3:Hide()
local nativePanes={stats,PaperDollFrame.EquipmentManagerPane,CharacterStatsPanePetScrollBox}
function PaperDollFrame_SetSidebar(_,index)
 for i,pane in ipairs(nativePanes) do pane:SetShown(i==index); _G['PaperDollSidebarTab'..i].checked=i==index end
 PaperDollFrame_UpdateSidebarTabs()
end
function PaperDollFrame_UpdateSidebarTabs() end
''')
lua.execute("assert(load(...))('ExtraStats')", (ROOT/'forever/Header.lua').read_text())
lua.execute(r'''
local events
for _,frame in ipairs(frames) do if frame.scripts.OnEvent then events=frame end end
events.scripts.OnEvent(events,'ADDON_LOADED','ExtraStats')
assert(ExtraStatsForeverTitlesTab==nil)
assert(PaperDollSidebarTab2.Icon.coords[3]==0.46875)
assert(PaperDollSidebarTab3.Icon.texture=='native pet')
assert(CharacterFrameRightPaneHostStoneBg.height==40)
assert(CharacterFrameRightPaneHostStoneBg.alpha==1)
assert(PaperDollSidebarTab1.point[4]==-17.5 and PaperDollSidebarTab2.point[4]==17.5)
PaperDollFrame_SetSidebar(PaperDollSidebarTab2,2)
assert(PaperDollFrame.EquipmentManagerPane:IsShown())
assert(not PaperDollFrame.TitleManagerPane:IsShown())
PaperDollSidebarTab3:Show(); PaperDollFrame_UpdateSidebarTabs()
assert(PaperDollSidebarTab1.point[4]==-35 and PaperDollSidebarTab3.point[4]==35)
print('PASS: no Titles tab, gear/pet icons, centered two/three-tab layouts, visible native header background')
''')
