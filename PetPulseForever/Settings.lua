local _,P=...
local function label(parent,text,x,y)
    local t=parent:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall")
    t:SetPoint("TOPLEFT",x,y); P.BindLabel(t,text); return t
end
local function apply()
    P.CancelConfirmation(); P.foodDirty=true
    P.ApplyLayout(); P.Refresh(true);P.UpdateMinimapButton()
    if P.settings and P.settings.ammoPreview then P.ApplyAmmoStyle(P.settings.ammoPreview,1347,3) end
end
local function check(parent,text,key,x,y,group)
    local b=CreateFrame("CheckButton",nil,parent,"UICheckButtonTemplate")
    b:SetSize(24,24); b:SetPoint("TOPLEFT",x,y)
    label(parent,text,x+29,y-6)
    b:SetScript("OnClick",function(self)
        local db=group and P.db[group] or P.db
        if key=="locked" and not group then P.SetLocked(self:GetChecked()==true)
        else db[key]=self:GetChecked()==true end
        apply()
    end)
    b.refresh=function() b:SetChecked((group and P.db[group] or P.db)[key]) end
    parent.controls[#parent.controls+1]=b
end
local serial=0
local function slider(parent,text,key,lo,hi,step,x,y)
    serial=serial+1
    local s=CreateFrame("Slider","PetPulseForeverSlider"..serial,parent,"OptionsSliderTemplate")
    s:SetPoint("TOPLEFT",x,y); s:SetWidth(230); s:SetMinMaxValues(lo,hi); s:SetValueStep(step)
    s:SetObeyStepOnDrag(true)
    _G[s:GetName().."Low"]:SetText(lo); _G[s:GetName().."High"]:SetText(hi)
    local title=_G[s:GetName().."Text"]
    s:SetScript("OnValueChanged",function(_,v)
        v=math.floor(v/step+.5)*step
        title:SetText(P.T(text)..": "..string.format(step<1 and "%.2f" or "%d",v))
        if P.settings.refreshing then return end
        P.db[key]=v
        if key=="critical" then P.db.warning=math.max(P.db.warning,v+1)
        elseif key=="warning" then P.db.critical=math.min(P.db.critical,v-1) end
        apply()
    end)
    s.refresh=function() s:SetValue(P.db[key]) end
    parent.controls[#parent.controls+1]=s
end
local function button(parent,text,x,y,w,fn)
    local b=CreateFrame("Button",nil,parent,"UIPanelButtonTemplate")
    b:SetPoint("TOPLEFT",x,y); b:SetSize(w,25); P.BindLabel(b,text); b:SetScript("OnClick",fn)
    return b
end
local function edit(parent,x,y,w)
    local e=CreateFrame("EditBox",nil,parent,"InputBoxTemplate")
    e:SetAutoFocus(false); e:SetPoint("TOPLEFT",x,y); e:SetSize(w,24)
    e:SetScript("OnEscapePressed",function(self) self:ClearFocus() end)
    return e
end
function P.RefreshSettings()
    local f=P.settings; if not f then return end
    for frame,text in pairs(P.localizedLabels) do frame:SetText(P.T(text)) end
    f.refreshing=true
    for _,c in ipairs(f.controls) do c.refresh() end
    local ids={}; for id,on in pairs(P.db.protected) do if on then ids[#ids+1]=id end end
    table.sort(ids); for i,id in ipairs(ids) do ids[i]=tostring(id) end
    f.blacklist:SetText(table.concat(ids,", "))
    f.x:SetText(math.floor(P.db.x)); f.y:SetText(math.floor(P.db.y))
    f.priority:SetText(P.T("Food priority: ")..P.T(P.db.priority=="lowlevel" and "Lower item level" or P.db.priority=="cheap" and "Lowest vendor value" or "Best level match"))
    for code,b in pairs(f.languages or {}) do b:SetAlpha(P.db.language==code and 1 or .5) end
    for style,b in pairs(f.moodButtons or {}) do b:SetAlpha(P.db.moodStyle==style and 1 or .5) end
    if f.ammoPreview then P.ApplyAmmoStyle(f.ammoPreview,1347,3) end
    for key,b in pairs(f.fontButtons or {}) do b:SetAlpha(P.db.ammoFont==key and 1 or .5) end
    for _,b in pairs(f.moodButtons or {}) do
        local selected=P.db.moodStyle==b.style
        b:SetAlpha(1);b:SetBackdropBorderColor(selected and .95 or .25,selected and .76 or .22,selected and .4 or .16,1)
    end
    f.refreshing=false
end
function P.ShowSettingsPage(key)
    if key=="training" then P.ToggleGuide();return end
    local f=P.settings
    f.currentPage=key
    for name,page in pairs(f.pages) do page:SetShown(name==key);f.tabs[name]:SetAlpha(name==key and 1 or .6) end
end
function P.ApplyAmmoStyle(label,count,tier)
    local font,size,flags="Fonts\\FRIZQT__.TTF",count and count>=10000 and 11 or 13,"OUTLINE"
    if P.db.ammoFont=="blizzard" and GameFontNormal and GameFontNormal.GetFont then
        font,size,flags=GameFontNormal:GetFont();size=math.max(12,size or 12)
    end
    label:SetFont(font,size,flags or "")
    label:SetShadowColor(0,0,0,1);label:SetShadowOffset(1,-1)
    local color=tier and tier<3 and P.colors[tier] or {P.db.ammoR,P.db.ammoG,P.db.ammoB}
    label:SetTextColor(unpack(color))
end
function P.ToggleSettings()
    if P.guideWindow and P.guideWindow:IsShown() then
        if InCombatLockdown() then P.Message(P.T("Open the training guide after combat."));return end
        P.guideWindow:Hide()
    end
    if P.settings then
        if P.settings:IsShown() then P.settings:Hide() else P.RefreshSettings(); P.settings:Show() end
        return
    end
    local f=CreateFrame("Frame","PetPulseForeverSettings",UIParent,"BackdropTemplate")
    P.settings=f; f.controls={}
    f:SetSize(760,740); f:SetPoint("CENTER"); f:SetFrameStrata("DIALOG")
    f:SetClampedToScreen(true); f:EnableMouse(true)
    P.StyleDialog(f)
    f.logo=f:CreateTexture(nil,"ARTWORK");f.logo:SetTexture(P.media.."logo.tga")
    f.logo:SetSize(200,50);f.logo:SetPoint("CENTER",f,"TOP",0,-36)
    local close=CreateFrame("Button",nil,f,"UIPanelCloseButton"); close:SetPoint("TOPRIGHT")
    table.insert(UISpecialFrames,"PetPulseForeverSettings")
    f.pages={};f.tabs={}
    for i,entry in ipairs({{"general","General"},{"ammo","Ammunition"},{"pets","Mood icons"},{"training","Training guide"},{"credits","Credits"}}) do
        local key=entry[1]
        local page=CreateFrame("Frame",nil,f);page:SetPoint("TOPLEFT",0,-25);page:SetSize(760,710)
        page.controls=f.controls;f.pages[key]=page
        f.tabs[key]=button(f,entry[2],24+(i-1)*143,-70,136,function() P.ShowSettingsPage(key) end)
    end
    local g=f.pages.general
    slider(g,"UI Scale","scale",.8,1.6,.05,28,-90)
    slider(g,"HUD Opacity","opacity",.3,1,.05,380,-90)
    slider(g,"Animation Speed (seconds)","animation",.08,.4,.01,28,-148)
    slider(g,"Collapse Delay (seconds)","delay",.2,.6,.01,380,-148)
    button(g,"Unlock / Move HUD",24,-185,230,function() f:Hide(); P.SetLocked(false) end)
    check(g,"Mouseover expansion","hover",376,-185)
    check(g,"Happiness alerts","happiness",24,-216)
    check(g,"Training notifications","training",376,-216)
    check(g,"Ammo alerts","ammo",24,-247)
    check(g,"Sound alerts","sound",376,-247)
    check(g,"Pet death warning","petDeath",24,-272)
    check(g,"Low pet health indicator","petHealth",376,-272)
    label(g,"MODULE VISIBILITY",24,-302)
    check(g,"Happiness","happiness",24,-326,"modules")
    check(g,"Smart Feed","feed",160,-326,"modules")
    check(g,"Training","training",376,-326,"modules")
    check(g,"Ammo","ammo",540,-326,"modules")
    slider(g,"Ammo warning threshold","warning",1,1000,1,28,-370)
    slider(g,"Critical ammo threshold","critical",0,999,1,380,-370)
    f.priority=button(g,"",24,-410,255,function()
        P.db.priority=P.db.priority=="lowlevel" and "cheap" or P.db.priority=="cheap" and "effective" or "lowlevel"; apply(); P.RefreshSettings()
    end)
    check(g,"Allow valuable food with confirmation","confirmation",376,-410)
    label(g,"Protected Foods — item IDs, separated by commas",24,-452)
    f.blacklist=edit(g,30,-472,410)
    button(g,"Save",460,-472,90,function()
        local ids={}; for id in f.blacklist:GetText():gmatch("%d+") do ids[tonumber(id)]=true end
        P.db.protected=ids; f.blacklist:ClearFocus(); apply()
    end)
    label(g,"Position X / Y",24,-515)
    f.x=edit(g,120,-508,65); f.y=edit(g,205,-508,65)
    button(g,"Apply",285,-508,70,function()
        P.db.x=P.Clamp(tonumber(f.x:GetText()) or P.db.x,-3000,3000)
        P.db.y=P.Clamp(tonumber(f.y:GetText()) or P.db.y,-2000,2000); apply()
        f.x:ClearFocus(); f.y:ClearFocus()
    end)
    button(g,"Reset Position",370,-508,180,function() P.db.x=0; P.db.y=-140; apply(); P.RefreshSettings() end)
    button(g,"Reset Defaults",24,-558,160,function()
        local progress=P.db.guide
        PetPulseForeverDB=P.Copy(P.defaults); P.db=PetPulseForeverDB
        if progress then P.db.guide=progress end
        apply(); P.RefreshSettings()
    end)
    label(g,"Valuable foods are never consumed without confirmation.\nDisable the option to exclude them entirely. Vendor-value limit: /petpulse price <copper>",24,-600)
    check(g,"Show minimap icon","minimap",380,-640)
    label(g,"Language",24,-645)
    f.languages={}
    for i,code in ipairs({"EN","SK","CZ"}) do
        local lang=code
        f.languages[lang]=button(g,lang,115+(i-1)*60,-638,52,function() P.SetLanguage(lang) end)
    end
    local a=f.pages.ammo
    check(a,"Show ammo below the collapsed portrait","ammoBelow",28,-100)
    label(a,"Normal ammo color (warnings keep their alert colors)",28,-150)
    slider(a,"Red","ammoR",0,1,.01,32,-205)
    slider(a,"Green","ammoG",0,1,.01,32,-265)
    slider(a,"Blue","ammoB",0,1,.01,32,-325)
    for i,entry in ipairs({{"Ivory",1,.94,.78},{"White",1,1,1},{"Gold",1,.8,.32},{"Hunter green",.68,.84,.6}}) do
        local color=entry
        button(a,color[1],300+(i-1)%2*150,-180-math.floor((i-1)/2)*38,140,function()
            P.db.ammoR=color[2];P.db.ammoG=color[3];P.db.ammoB=color[4];apply();P.RefreshSettings()
        end)
    end
    label(a,"Ammo font",28,-390)
    f.fontButtons={}
    f.fontButtons.classic=button(a,"Classic serif",28,-415,225,function() P.db.ammoFont="classic";apply();P.RefreshSettings() end)
    f.fontButtons.blizzard=button(a,"Blizzard UI",280,-415,225,function() P.db.ammoFont="blizzard";apply();P.RefreshSettings() end)
    label(a,"Preview",350,-280)
    f.ammoPreview=label(a,"1347",350,-310)
    local pets=f.pages.pets
    label(pets,"Choose a companion style — preview all three moods",24,-103)
    f.moodButtons={}
    for i,entry in ipairs(P.moodFamilies) do
        local family=entry
        local card=CreateFrame("Button",nil,pets,"BackdropTemplate")
        local col=(i-1)%4;local row=math.floor((i-1)/4)
        card:SetSize(170,98);card:SetPoint("TOPLEFT",24+col*180,-132-row*104)
        card:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8X8",edgeFile="Interface\\Buttons\\WHITE8X8",edgeSize=1})
        card:SetBackdropColor(.065,.06,.045,.95);card.style=family.key
        P.BindLabel(card:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall"),family.name):SetPoint("TOP",0,-8)
        for moodIndex,mood in ipairs({"happy","content","unhappy"}) do
            local icon=card:CreateTexture(nil,"ARTWORK");icon:SetTexture(P.MoodTexture(family.key,mood))
            icon:SetSize(48,48);icon:SetPoint("TOPLEFT",7+(moodIndex-1)*54,-30)
        end
        card:SetScript("OnClick",function() P.db.moodStyle=family.key;P.Paint();P.RefreshSettings() end)
        f.moodButtons[family.key]=card
    end
    local credits=f.pages.credits
    local title=label(credits,"PetPulse",40,-123)
    title:SetFont("Fonts\\FRIZQT__.TTF",26,"");title:SetTextColor(.94,.86,.67)
    label(credits,"Addon Creator",42,-183):SetTextColor(.7,.68,.6)
    local author=label(credits,"Wixin",42,-211);author:SetFont("Fonts\\FRIZQT__.TTF",20,"")
    label(credits,"Special Thanks",42,-265):SetTextColor(.7,.68,.6)
    local thanks=label(credits,"Ewelyn & Lucy",42,-292);thanks:SetFont("Fonts\\FRIZQT__.TTF",18,"")
    label(credits,"Created for all Hunters and their beloved pets.",42,-348):SetTextColor(.93,.83,.62)
    local divider=credits:CreateTexture(nil,"ARTWORK");divider:SetTexture("Interface\\Buttons\\WHITE8X8")
    divider:SetSize(676,1);divider:SetPoint("TOPLEFT",42,-394);divider:SetVertexColor(.45,.37,.24,.6)
    for i,entry in ipairs({{"Version",P.version},{"Revision",P.revision},{"Release date",P.releaseDate},
        {"Game","WoW: Forever"},{"Interface",tostring(P.targetInterface)}}) do
        label(credits,entry[1],42,-422-(i-1)*30):SetTextColor(.7,.68,.6)
        label(credits,entry[2],230,-422-(i-1)*30)
    end
    label(credits,"Training data: TrueshotLodge / chazlander (MIT)",42,-575):SetTextColor(.7,.68,.6)
    label(credits,"Testing release",42,-607):SetTextColor(.7,.68,.6)
    P.ShowSettingsPage("general")
    P.RefreshSettings()
end
function P.Command(msg)
    local cmd,arg=msg:match("^(%S*)%s*(.-)$")
    if cmd=="training" or cmd=="guide" then P.ToggleGuide()
    elseif cmd=="minimap" then P.db.minimap=not P.db.minimap;P.UpdateMinimapButton();P.RefreshSettings()
    elseif cmd=="price" and tonumber(arg) then
        P.db.price=math.max(0,math.floor(tonumber(arg))); apply(); P.Message("Protected value threshold updated.")
    elseif cmd=="lock" or cmd=="unlock" then
        P.SetLocked(cmd=="lock")
        if not P.db.locked and P.settings then P.settings:Hide() end
        P.Message(P.db.locked and "HUD locked." or "HUD unlocked — drag anywhere on the shard, then click Lock HUD.")
    elseif cmd=="diagnostics" then
        local version,build,_,interface=P.Call("GetBuildInfo")
        P.Message("Client "..tostring(version).." / "..tostring(build).." / Interface "..tostring(interface))
        P.Message("Diet API: "..tostring(C_PetInfo and type(C_PetInfo.CanPetEatItem)=="function")..". Training data: "..(P.trainingOptions and "current session" or "unavailable"))
    else P.ToggleSettings() end
end

function P.UpdateMinimapButton()
    local b=P.minimapButton;if not b then return end
    b:SetShown(P.db.minimap~=false)
    local angle=tonumber(P.db.minimapAngle) or 225
    if angle~=angle or math.abs(angle)==math.huge then angle=225 end
    local rad=math.rad(angle);local x,y=math.cos(rad),math.sin(rad)
    local radius=(Minimap.GetWidth and Minimap:GetWidth() or 140)/2+8
    if P.Call("GetMinimapShape")=="SQUARE" then local scale=math.max(math.abs(x),math.abs(y));x=x/scale;y=y/scale end
    b:ClearAllPoints();b:SetPoint("CENTER",Minimap,"CENTER",x*radius,y*radius)
end
function P.BuildMinimapButton()
    if not Minimap or P.minimapButton then return end
    local b=CreateFrame("Button","PetPulseForeverMinimapButton",Minimap);P.minimapButton=b
    b:SetSize(32,32);b:SetFrameLevel(Minimap:GetFrameLevel()+8);b:RegisterForClicks("LeftButtonUp","RightButtonUp");b:RegisterForDrag("LeftButton")
    local bg=b:CreateTexture(nil,"BACKGROUND");bg:SetTexture(P.media.."disc.tga");bg:SetAllPoints(b)
    b.icon=b:CreateTexture(nil,"ARTWORK");b.icon:SetTexture(P.media.."minimap.tga");b.icon:SetSize(22,22);b.icon:SetPoint("CENTER",b,"CENTER",0,0)
    local border=b:CreateTexture(nil,"OVERLAY");border:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder");border:SetSize(54,54);border:SetPoint("TOPLEFT",b,"TOPLEFT",0,0)
    b:SetHighlightTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight","ADD")
    b:SetScript("OnEnter",function(self)
        GameTooltip:SetOwner(self,"ANCHOR_LEFT");GameTooltip:AddLine("PetPulse")
        GameTooltip:AddLine(P.T("Left-click: settings"),1,1,1)
        GameTooltip:AddLine(P.T("Right-click: Training Guide"),1,1,1)
        GameTooltip:AddLine(P.T("Drag to move around the minimap."),.8,.8,.8);GameTooltip:Show()
    end)
    b:SetScript("OnLeave",function()GameTooltip:Hide()end)
    b:SetScript("OnClick",function(self,mouse)
        if self.dragging or GetTime()<(self.ignoreClickUntil or 0) then return end
        GameTooltip:Hide()
        if InCombatLockdown()then P.Message(P.T("Open PetPulse after combat."));return end
        if mouse=="RightButton" then P.ToggleGuide()else P.ToggleSettings()end
    end)
    b:SetScript("OnDragStart",function(self)
        self.dragging=true;GameTooltip:Hide()
        self:SetScript("OnUpdate",function()
            local x,y=GetCursorPosition();local cx,cy=Minimap:GetCenter();local scale=Minimap:GetEffectiveScale()
            if cx and cy and scale and scale>0 then
                P.db.minimapAngle=math.deg(math.atan2(y/scale-cy,x/scale-cx));P.UpdateMinimapButton()
            end
        end)
    end)
    b:SetScript("OnDragStop",function(self)self.dragging=nil;self.ignoreClickUntil=GetTime()+.2;self:SetScript("OnUpdate",nil)end)
    b:SetScript("OnHide",function(self)self.dragging=nil;self:SetScript("OnUpdate",nil)end)
    P.UpdateMinimapButton()
end
