-- Minimal deterministic harness. Does not emulate Blizzard secure execution.
NOW=100; COMBAT=false; BAG={}; ITEMS={}; PET=true; DEAD=false; PETGUID="pet-a"; HAPPINESS=3
RANGED=9000; EQUIPPED=9001; AURA=nil; SERVICES={}; CURSORX=960; CURSORY=400
FRAMES={}; TIMERS={}; SOUNDCOUNT=0; BAGSCANS=0
unpack=unpack or table.unpack
local methods={}
function methods:SetScript(k,v) self.scripts[k]=v end
function methods:HookScript(k,v) local old=self.scripts[k];self.scripts[k]=function(...) if old then old(...) end;v(...) end end
function methods:RegisterEvent(e) self.events[e]=true end
function methods:UnregisterAllEvents() self.events={} end
function methods:SetAttribute(k,v) assert(not COMBAT,"protected attribute in combat");self.attrs[k]=v end
function methods:GetAttribute(k) return self.attrs[k] end
function methods:SetShown(v) if v then self:Show() else self:Hide() end end
function methods:Show() assert(not (COMBAT and self.protected),"protected show in combat");self.shown=true end
function methods:Hide() assert(not (COMBAT and self.protected),"protected hide in combat");self.shown=false end
function methods:IsShown() return self.shown end
function methods:SetText(v) self.text=v end
function methods:GetText() return self.text end
function methods:SetChecked(v) self.checked=v end
function methods:GetChecked() return self.checked end
function methods:SetValue(v) self.value=v;if self.scripts.OnValueChanged then self.scripts.OnValueChanged(self,v) end end
function methods:SetScale(v) assert(not (COMBAT and self.protected));self.scale=v end
function methods:GetEffectiveScale() return (self.scale or 1)*(self.parent and self.parent:GetEffectiveScale() or 1) end
function methods:GetFrameLevel() return self.level or 1 end
function methods:SetFrameLevel(v) self.level=v end
function methods:GetName() return self.name end
function methods:GetCenter()
    if self==UIParent then return 960,540 end
    if self.anchor then
        local a=self.anchor; local ref=a[2]
        local scale=self:GetEffectiveScale()
        local x,y=ref:GetCenter(); x=x*ref:GetEffectiveScale()/scale;y=y*ref:GetEffectiveScale()/scale
        if a[3]=="BOTTOMLEFT" then x,y=0,0 end
        return x+(a[4] or 0),y+(a[5] or 0)
    end
    if self.parent then return self.parent:GetCenter() end
    return 960,540
end
function methods:SetPoint(...) assert(not (COMBAT and self.protected));local a={...};if type(a[2])=="table" then self.anchor=a end end
function methods:ClearAllPoints() assert(not (COMBAT and self.protected));self.anchor=nil end
function methods:CreateTexture() return CreateFrame("Texture",nil,self) end
function methods:CreateMaskTexture() return CreateFrame("Mask",nil,self) end
function methods:CreateFontString() return CreateFrame("Font",nil,self) end
for _,k in ipairs({"SetSize","SetWidth","SetHeight","SetAlpha","SetAllPoints","SetTexture","SetVertexColor",
    "SetTextColor","SetFont","SetBackdrop","SetBackdropColor","SetBackdropBorderColor","SetFrameStrata",
    "SetClampedToScreen","SetMovable","RegisterForClicks","RegisterForDrag","EnableMouse","AddMaskTexture",
    "SetDesaturated","SetDrawEdge","SetHideCountdownNumbers","SetCooldown","SetHighlightTexture",
    "SetAutoFocus","SetMinMaxValues","SetValueStep","SetObeyStepOnDrag","ClearFocus","StartMoving","StopMovingOrSizing",
    "SetOwner","AddLine","AddDoubleLine"}) do methods[k]=function() end end
function CreateFrame(kind,name,parent,template)
    local f=setmetatable({name=name,parent=parent,scripts={},attrs={},events={},shown=true,
        protected=template and template:find("SecureAction")~=nil},{__index=methods})
    if f.protected and parent then parent.protected=true end
    FRAMES[#FRAMES+1]=f
    if name then _G[name]=f end
    if template=="OptionsSliderTemplate" then
        for _,suffix in ipairs({"Text","Low","High"}) do _G[name..suffix]=CreateFrame("Font") end
    end
    return f
end
UIParent=CreateFrame("Frame","UIParent");UIParent.protected=false
GameTooltip=CreateFrame("Tooltip"); DEFAULT_CHAT_FRAME={AddMessage=function()end}
SOUNDKIT={RAID_WARNING=1};Enum={TrainerType={Pet=1}};UISpecialFrames={};SlashCmdList={}
function RegisterStateDriver(f) f.driver=true end
function InCombatLockdown() return COMBAT end
function issecretvalue(v) return v=="SECRET" end
function GetTime() return NOW end
function GetLocale() return "enUS" end
function GetBuildInfo() return "1.60.1","71037","",16001 end
function UnitClass() return "Hunter","HUNTER" end
function UnitExists() return PET end
function UnitIsDeadOrGhost() return DEAD end
function UnitAffectingCombat() return false end
function UnitGUID() return PET and PETGUID end
function UnitName() return "Test Pet" end
function UnitCreatureFamily() return "Cat" end
function UnitLevel() return 30 end
function UnitArmor() return 100,100 end
function UnitResistance() return 0,0 end
function GetCursorPosition() return CURSORX,CURSORY end
function SetPortraitTexture() end
function PlaySound() SOUNDCOUNT=SOUNDCOUNT+1 end
function GetInventoryItemID(_,slot) if slot==18 then return RANGED elseif slot==0 then return EQUIPPED end end
C_PetInfo={GetPetHappiness=function()return HAPPINESS,125,0 end,GetPetLoyalty=function()return "Loyal" end,
    GetPetTrainingPoints=function()return 100,60 end,GetPetFoodTypes=function()return {"Meat","Fish"}end,
    CanPetEatItem=function(id)return ITEMS[id] and ITEMS[id].diet==true end}
C_Container={GetContainerNumSlots=function(bag) BAGSCANS=BAGSCANS+1;return bag==0 and #BAG or 0 end,
    GetContainerItemInfo=function(bag,slot) if bag==0 then return BAG[slot] end end,
    GetContainerItemQuestInfo=function(bag,slot)return {isQuestItem=BAG[slot].quest or false}end}
C_Item={GetItemInfoInstant=function(id)local i=ITEMS[id];if i then return id,nil,nil,nil,nil,i.class,i.sub end end,
    GetItemInfo=function(id)local i=ITEMS[id];if i and not i.uncached then
        return i.name,"item:"..id,i.quality or 1,i.level or 30,i.requiredLevel or 1,nil,nil,nil,nil,123,i.price or 10,i.class
    end end}
C_TooltipInfo={GetBagItem=function(bag,slot)return {lines={{leftText=ITEMS[BAG[slot].itemID].buff and "Well Fed: stamina" or "Restores health"}}}end}
C_UnitAuras={GetAuraDataByIndex=function(_,i)if i==1 then return AURA end end}
C_Trainer={GetTrainerType=function()return 1 end}
function GetNumTrainerServices()return #SERVICES end
function GetTrainerServiceInfo(i)local s=SERVICES[i];return s.name,s.status,1,s.level,s.rank end
function GetTrainerServiceCost(i)return SERVICES[i].cost end
function GetTrainerServiceSkillReq(i)if SERVICES[i].skillMissing then return "skill",1,false end end
function GetTrainerServiceNumAbilityReq(i)return SERVICES[i].abilityMissing and 1 or 0 end
function GetTrainerServiceAbilityReq()return "ability",false end
C_Timer={After=function(_,fn)TIMERS[#TIMERS+1]=fn end,NewTicker=function(_,fn)return {callback=fn}end}
function Drain() local t=TIMERS;TIMERS={};for _,fn in ipairs(t)do fn()end end
function Event(e,...)
    for _,f in ipairs(FRAMES)do if f.events[e] and f.scripts.OnEvent then f.scripts.OnEvent(f,e,...)end end
end
function Combat(on)
    COMBAT=on
    if on then for _,f in ipairs(FRAMES)do if f.driver then f.shown=false end end end
    Event(on and "PLAYER_REGEN_DISABLED" or "PLAYER_REGEN_ENABLED")
end
function Click(b,button)
    if b.scripts.PreClick then b.scripts.PreClick(b,button) end
    local action=b.attrs.type; local item=b.attrs["target-slot"]
    if b.scripts.PostClick then b.scripts.PostClick(b,button) end
    return action,item
end

function methods:SetShadowColor() end
function methods:SetShadowOffset() end
function methods:SetAlpha(value) self.alpha=value end
HEALTH=100;MAXHEALTH=100
function UnitHealth() return HEALTH end
function UnitHealthMax() return MAXHEALTH end

COMPLETED={};ACTIVE={};REPEATABLE={}
C_QuestLog={IsQuestFlaggedCompleted=function(q)return COMPLETED[q]==true end,
    IsOnQuest=function(q)return ACTIVE[q]==true end,IsRepeatableQuest=function(q)return REPEATABLE[q]==true end}

function methods:SetVertexColor(r,g,b,a) self.color={r,g,b,a} end
function methods:EnableMouse(value) self.mouseEnabled=value end
function methods:SetFont(path,size,flags) self.font={path,size,flags} end

function methods:SetBlendMode(mode) self.blend=mode end
function methods:GetFont() return unpack(self.font or {"Fonts\\FRIZQT__.TTF",12,""}) end
function methods:SetOwner(owner) self.owner=owner;self.lines={} end
function methods:NumLines() return #(self.lines or {}) end
function methods:AddDoubleLine(left,right)
    self.lines=self.lines or {};self.lines[#self.lines+1]={left,right}
    if self.name then
        for _,side in ipairs({"Left","Right"}) do
            local name=self.name.."Text"..side..#self.lines
            if not _G[name] then CreateFrame("Font",name,self) end
        end
    end
end
function methods:AddLine(text) self:AddDoubleLine(text,nil) end

function methods:RemoveMaskTexture() end

function methods:EnableMouseWheel() end
function methods:SetBagItem(bag,slot) self.bag=bag;self.slot=slot end
function methods:SetTexture(path) self.texture=path end
function methods:SetTextColor(r,g,b,a) self.textColor={r,g,b,a} end
function methods:SetBackdropBorderColor(r,g,b,a) self.borderColor={r,g,b,a} end
GameFontNormal=CreateFrame("Font");GameFontNormal:SetFont("Fonts\\FRIZQT__.TTF",14,"")

PETXP=250;PETXPMAX=1000
function GetPetExperience() return PETXP,PETXPMAX end
function methods:SetTexCoord(...) self.texCoord={...} end

function methods:GetUnit() return self.unitName,self.unitToken end
function methods:SetJustifyH() end
function methods:SetScrollChild(child) self.scrollChild=child end
function methods:SetVerticalScroll(v) self.scroll=v end
function methods:GetStringHeight() return 300 end
function methods:SetSpellByID(id) self.spellID=id end

function methods:SetBackdrop(value) self.backdrop=value end
function methods:SetBackdropColor(...) self.backdropColor={...} end
