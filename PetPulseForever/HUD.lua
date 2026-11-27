local _,P=...
local GameTooltip
local tooltipFonts={}
function P.SizeTooltipText()
    for i=1,GameTooltip:NumLines() do
        for _,side in ipairs({"Left","Right"}) do
            local line=_G[GameTooltip:GetName().."Text"..side..i]
            if line then
                local base=tooltipFonts[line]
                if not base then
                    local path,size,flags=line:GetFont()
                    if path and size then base={path,size,flags};tooltipFonts[line]=base end
                end
                if base then line:SetFont(base[1],base[2]+2,base[3]) end
            end
        end
    end
end
local names={[1]="Unhappy",[2]="Content",[3]="Happy"}
local positions={happiness={0,54},feed={0,-54},training={-54,0},ammo={54,0}}
local function textRow(label,value)
    GameTooltip:AddDoubleLine(label,value==nil and "Unavailable" or tostring(value),.57,.67,.72,.89,.93,.94)
end
function P.Tooltip(key,owner)
    if not P.pet then return end
    GameTooltip:SetOwner(owner,"ANCHOR_NONE")
    GameTooltip:SetPoint("BOTTOMLEFT",P.hud,"TOPRIGHT",64,14)
    local s=P.pet
    if key=="happiness" then
        GameTooltip:AddLine("Companion Care",1,.82,.49)
        local title,advice=P.CareAdvice()
        GameTooltip:AddLine(title,.94,.95,.97,true)
        GameTooltip:AddLine(advice,.68,.76,.82,true)
        GameTooltip:AddLine(" ")
        textRow("Current mood",names[s.happiness] or "Unavailable")
        textRow("Feeding",P.FeedStatus())
        if P.moodChange then
            textRow("Observed mood",P.moodChange.direction.." · "..math.floor(GetTime()-P.moodChange.at).."s ago")
        end
        local meals,seen=0,{}
        for _,food in ipairs(P.foods or {}) do
            if not food.risk and not seen[food.id] then meals=meals+food.quantity;seen[food.id]=true end
        end
        textRow("Safe meals carried",meals)
        if (P.questFoodsSkipped or 0)>0 then textRow("Quest stacks protected",P.questFoodsSkipped) end
        if s.healthPercent then textRow("Health",math.floor(s.healthPercent*100).."%") end
    elseif key=="pet" then
        GameTooltip:AddLine(s.name or "No active pet",.44,.88,.76)
        if s.dead then GameTooltip:AddLine("Left-click: Revive Pet",1,.65,.4)
        elseif not s.exists then
            GameTooltip:AddLine("Left-click: Call Pet",.8,.8,.8)
            GameTooltip:AddLine("Shift-click: Revive Pet if dismissed dead",.65,.7,.75)
        else
            if s.xpFraction then
                textRow("Pet XP",string.format("%d / %d (%.1f%%)",s.xp,s.xpMax,s.xpFraction*100))
                textRow("XP to next level",s.xpMax-s.xp)
            else textRow("Pet XP",P.T("Unavailable")) end
            textRow("Level",s.level); textRow("Happiness",s.dead and "Pet is dead" or names[s.happiness])
            textRow("Damage modifier",s.damage and s.damage.."%")
            textRow("Loyalty",s.loyalty); textRow("Training points",s.tp)
            if key=="pet" then
                textRow("Family",s.family)
                local _,armor=P.Call("UnitArmor","pet"); textRow("Armor",armor)
                for _,school in ipairs({{"Fire",2},{"Frost",4},{"Nature",3},{"Shadow",5},{"Arcane",6}}) do
                    local _,res=P.Call("UnitResistance","pet",school[2]); textRow(school[1].." resistance",res)
                end
                local diet={}
                for _,v in ipairs(s.diet or {}) do if P.Plain(v) then diet[#diet+1]=v end end
                textRow("Diet",#diet>0 and table.concat(diet,", ") or nil)
                GameTooltip:AddLine(" "); GameTooltip:AddLine("Right-click: settings",.5,.6,.65)
                if not P.db.locked then GameTooltip:AddLine("Drag to move",.5,.6,.65) end
            end
        end
    elseif key=="feed" then
        GameTooltip:AddLine("Smart Feed",.44,.88,.76)
        GameTooltip:AddLine("Right-click: choose food",.85,.76,.56)
        if P.manualFood then GameTooltip:AddLine("Manual choice",.85,.76,.56) end
        if P.manualFood and not P.CurrentFood() then GameTooltip:AddLine("Selected food unavailable — right-click to choose again",1,.6,.3,true) end
        GameTooltip:AddLine(P.FeedStatus(),.9,.9,.9)
        local f=P.CurrentFood()
        GameTooltip:AddLine(" ")
        GameTooltip:AddLine(f and f.name or "No suitable food",.95,.9,.73,true)
        if f then
            textRow("Available quantity",f.quantity)
            textRow("Diet",f.diet or "Client verified")
            textRow("Food level",f.level)
            P.AddFoodDetails(f)
            GameTooltip:AddLine(" ")
            GameTooltip:AddLine("FEEDING DECISION",.87,.89,.94)
            GameTooltip:AddLine(f.reason or "Food selected",.65,.73,.78,true)
            if f.risk then GameTooltip:AddLine("Protected — click to review",1,.7,.3,true)
            else GameTooltip:AddLine("Left-click: feed now",.44,.88,.76) end
            GameTooltip:AddLine("Alternative foods",.6,.7,.75)
            local seen={[f.id]=true}; local shown=0
            for _,v in ipairs(P.foods) do
                if not seen[v.id] and shown<3 then
                    textRow(v.name,v.quantity); seen[v.id]=true; shown=shown+1
                end
            end
            if shown==0 then GameTooltip:AddLine("None",.6,.65,.7) end
        end
        GameTooltip:AddLine("Exact feeding gain unavailable.",.5,.6,.65)
    elseif key=="training" then
        GameTooltip:AddLine("Beast Training",.44,.88,.76)
        GameTooltip:AddLine("Right-click: training guide",.95,.8,.5)
        local options=P.trainingOptions
        if not options then
            GameTooltip:AddLine("Open Beast Training to verify upgrades.",.8,.85,.9,true)
        elseif #options==0 then GameTooltip:AddLine("No verified affordable upgrades",.8,.85,.9)
        else
            GameTooltip:AddLine("Pet Training Available",1,.72,.3)
            for i,v in ipairs(options) do
                if i<=12 then textRow(v.name..(v.rank and " "..v.rank or ""),v.cost.." TP") end
            end
        end
        GameTooltip:AddLine("Availability comes from the current pet training session.",.5,.6,.65,true)
        GameTooltip:AddLine("Left-click: open Beast Training",.5,.6,.65)
    elseif key=="ammo" then
        local a=P.ammoState or {}
        GameTooltip:AddLine("Ammunition",.44,.88,.76)
        textRow("Compatible ammunition",a.total or (a.sub and "Unavailable" or "Not required / unknown weapon"))
        if a.sub then
            textRow("Type",a.sub==2 and "Arrows" or "Bullets")
            textRow("Equipped ammunition in bags",a.equipped)
            if a.equipped==0 then GameTooltip:AddLine("Equip compatible ammunition before firing.",1,.4,.3,true) end
        end
        GameTooltip:AddLine("Counts carried compatible ammunition; excludes bank and incompatible projectiles.",.5,.6,.65,true)
    end
    P.SizeTooltipText()
    GameTooltip:Show()
    P.tipKey=key; P.tipOwner=owner
end
local function leave(self)
    if self and P.tipOwner and P.tipOwner~=self then return end
    if P.hoverNode then P.hoverNode.hover:Hide();P.hoverNode.glow:Hide();P.hoverNode=nil end
    GameTooltip:Hide();P.tipKey=nil;P.tipOwner=nil
end
local function enter(self)
    if P.hoverNode then P.hoverNode.hover:Hide();P.hoverNode.glow:Hide() end
    P.hoverNode=self.key=="pet" and P.hud.center or P.nodes[self.key]
    if P.hoverNode then P.hoverNode.hover:Show();P.hoverNode.glow:Show() end
    P.OpenShard()
    P.Tooltip(self.key,self)
end
local function node(parent,key,size)
    local b=CreateFrame("Button",nil,parent)
    b:SetSize(size,size); b.key=key
    b.bg=b:CreateTexture(nil,"BACKGROUND"); b.bg:SetAllPoints(); b.bg:SetTexture(P.media.."disc.tga")
    b.icon=b:CreateTexture(nil,"ARTWORK"); b.icon:SetPoint("CENTER"); b.icon:SetSize(size-8,size-8)
    b.mask=b:CreateMaskTexture(); b.mask:SetAllPoints(b.icon)
    b.mask:SetTexture(P.media.."mask.tga"); b.icon:AddMaskTexture(b.mask)
    b.ring=b:CreateTexture(nil,"OVERLAY"); b.ring:SetPoint("CENTER");b.ring:SetSize(size+4,size+4); b.ring:SetTexture(P.media.."socket.tga")
    b.ring:SetVertexColor(1,1,1)
    b.hover=b:CreateTexture(nil,"OVERLAY",nil,7)
    b.hover:SetTexture(P.media.."hover-ring.tga");b.hover:SetPoint("CENTER")
    b.hover:SetSize(size+18,size+18);b.hover:SetVertexColor(1,.78,.36)
    b.hover:SetBlendMode("ADD");b.hover:SetAlpha(.7);b.hover:Hide()
    b.glow=b:CreateTexture(nil,"OVERLAY",nil,6)
    b.glow:SetAllPoints(b.icon);b.glow:SetTexture(P.media.."disc.tga")
    b.glow:SetVertexColor(1,.86,.42);b.glow:SetBlendMode("ADD");b.glow:SetAlpha(.12);b.glow:Hide()
    b.label=b:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall"); b.label:SetPoint("CENTER")
    b:SetScript("OnEnter",enter); b:SetScript("OnLeave",leave)
    return b
end
function P.SyncSecure()
    if InCombatLockdown() or not P.hud then return end
    for key,b in pairs(P.secureNodes) do
        local n=P.nodes[key]
        local x,y=n:GetCenter()
        if x and y then
            local scale=n:GetEffectiveScale()/UIParent:GetEffectiveScale()
            b:SetScale(scale); b:ClearAllPoints()
            b:SetPoint("CENTER",UIParent,"BOTTOMLEFT",x,y)
            -- Point offsets are expressed in the button's scaled coordinate system.
            b:SetSize(32,32)
        end
        b:SetShown(P.db.locked and P.expanded and P.db.modules[key] and P.progress>.98)
    end
    if P.petAction then
        local x,y=P.hud:GetCenter()
        P.petAction:SetScale(P.hud:GetEffectiveScale()/UIParent:GetEffectiveScale())
        P.petAction:ClearAllPoints(); P.petAction:SetPoint("CENTER",UIParent,"BOTTOMLEFT",x,y)
        P.petAction:SetShown(P.db.locked)
    end
end
function P.Layout(progress)
    P.hud.shard:SetAlpha(progress)
    P.hud.menu:SetShown(progress>.98 and P.db.locked)
    if P.hud.pin then
        P.hud.pin:SetShown(progress>.98 and P.db.locked)
        for _,part in ipairs(P.hud.pin.parts) do
            if P.db.pinnedOpen then part:SetVertexColor(1,.8,.35) else part:SetVertexColor(.7,.65,.54) end
        end
    end
    local plateSize=120+40*progress
    P.hud.shard:SetSize(plateSize,plateSize)
    if P.hud.meal then
        P.hud.meal:ClearAllPoints();P.hud.meal:SetPoint("BOTTOM",P.hud,"CENTER",0,34+54*progress)
    end
    for key,n in pairs(P.nodes) do
        local pos=positions[key]
        n:ClearAllPoints()
        if key=="ammo" then
            -- The same count travels around the portrait, never through it.
            local angle=progress*math.pi/2
            n:SetPoint("CENTER",P.hud,"CENTER",54*math.sin(angle),-38*math.cos(angle))
            n:SetAlpha(P.db.ammoBelow and 1 or progress);n:SetShown(P.db.modules.ammo and (P.db.ammoBelow or progress>0))
            n.bg:SetAlpha(progress);n.ring:SetAlpha(progress)
            -- A count below the portrait must not move out from under a click
            -- and leave a newly revealed Feed button under that same cursor.
            n:EnableMouse(progress>.98)
        else
            n:SetPoint("CENTER",P.hud,"CENTER",pos[1]*progress,pos[2]*progress)
            n:SetAlpha(progress);n:SetShown(progress>0 and P.db.modules[key])
            n:EnableMouse(progress>.5)
        end
    end
    P.SyncSecure()
end
function P.OpenShard()
    if not P.db.hover and not P.expanded then return end
    P.expanded=true; P.outsideAt=nil
    P.hud:SetScript("OnUpdate",P.UpdateHUD)
end
function P.SetPinnedOpen(enabled)
    P.db.pinnedOpen=enabled==true
    P.outsideAt=nil
    if P.db.pinnedOpen then P.expanded=true end
    P.Layout(P.progress)
    P.hud:SetScript("OnUpdate",P.UpdateHUD)
end
function P.UpdateHUD(self,elapsed)
    if not P.db.locked or P.db.pinnedOpen then P.expanded=true;P.outsideAt=nil end
    if P.foodMenu and P.foodMenu:IsShown() then P.expanded=true;P.outsideAt=nil end
    local target=P.expanded and 1 or 0
    local step=elapsed/math.max(.08,P.db.animation)
    if P.linear<target then P.linear=math.min(target,P.linear+step)
    elseif P.linear>target then P.linear=math.max(target,P.linear-step) end
    local eased=1-(1-P.linear)^3
    if P.progress~=eased then P.progress=eased; P.Layout(eased) end
    P.hoverElapsed=(P.hoverElapsed or 0)+elapsed
    if P.hoverElapsed>.035 then
        P.hoverElapsed=0
        local x,y=GetCursorPosition(); local cx,cy=self:GetCenter(); local scale=self:GetEffectiveScale()
        local inside=(P.foodMenu and P.foodMenu:IsShown()) or (cx and P.Inside(x/scale-cx,y/scale-cy,90,P.expanded))
        if inside then P.outsideAt=nil
        elseif P.expanded and P.db.hover and P.db.locked and not P.db.pinnedOpen and not P.dragging then
            P.outsideAt=P.outsideAt or GetTime()
            if GetTime()-P.outsideAt>=P.db.delay then P.expanded=false; leave() end
        end
    end
    if P.progress==0 and not P.expanded then self:SetScript("OnUpdate",nil) end
end
function P.ApplyLayout()
    if not P.hud then return end
    if InCombatLockdown() then P.layoutDeferred=true; return end
    P.hud:SetScale(P.db.scale); P.hud:SetAlpha(P.db.opacity)
    P.hud:ClearAllPoints(); P.hud:SetPoint("CENTER",UIParent,"CENTER",P.db.x,P.db.y)
    if P.hud.mover then P.hud.mover:SetShown(not P.db.locked) end
    if not P.db.locked or P.db.pinnedOpen then
        P.expanded=true; P.hud:SetScript("OnUpdate",P.UpdateHUD)
    end
    P.Layout(P.progress)
end
function P.SavePosition()
    if not P.dragging then return end
    P.hud:StopMovingOrSizing(); P.dragging=false
    local x,y=P.hud:GetCenter(); local ux,uy=UIParent:GetCenter()
    local ratio=UIParent:GetEffectiveScale()/P.hud:GetEffectiveScale()
    P.db.x=x-ux*ratio; P.db.y=y-uy*ratio
    P.ApplyLayout()
end
function P.StartDrag()
    if P.db.locked or InCombatLockdown() then return end
    GameTooltip:Hide(); P.tipKey=nil; P.tipOwner=nil
    P.dragging=true; P.hud:StartMoving()
end
function P.SetLocked(locked)
    if InCombatLockdown() then P.Message("Move mode is available after combat."); return end
    P.SavePosition(); P.db.locked=locked
    P.CancelConfirmation(); P.ApplyLayout(); P.PrepareFeed()
    if P.settings and P.settings:IsShown() then P.RefreshSettings() end
end
function P.Paint()
    if not P.hud then return end
    local s=P.pet; local c=P.colors[s.happiness] or P.colors.neutral
    P.hud.center.ring:SetVertexColor(1,1,1)
    if s.dead then P.hud.center.icon:SetTexture(P.Call("C_Spell.GetSpellTexture",982) or "Interface\\Icons\\Ability_Hunter_BeastSoothe")
    elseif s.exists then SetPortraitTexture(P.hud.center.icon,"pet")
    else P.hud.center.icon:SetTexture("Interface\\Icons\\Ability_Hunter_BeastCall") end
    P.hud.center.icon:SetDesaturated(false)
    P.hud.actionLabel:SetText(P.T(s.dead and "REVIVE" or not s.exists and "CALL" or ""))
    P.hud.gem:SetVertexColor(unpack(s.dead and P.colors[1] or c))
    P.UpdateXPRing()
    P.UpdateHealthWarning()
    P.UpdateMealBadge()
    local h=P.nodes.happiness
    local mood=s.happiness==3 and "happy" or s.happiness==1 and "unhappy" or "content"
    local style=P.db.moodStyle
    local modern=style~="classic"
    h.icon:SetTexture(P.MoodTexture(style,mood))
    if h.modernMood~=modern then
        if modern then h.icon:RemoveMaskTexture(h.mask) else h.icon:AddMaskTexture(h.mask) end
        h.modernMood=modern
    end
    h.icon:SetSize(modern and 44 or 24,modern and 44 or 24)
    h.bg:SetAlpha(modern and 0 or 1);h.ring:SetAlpha(modern and 0 or 1)
    h.icon:SetVertexColor(1,1,1); h.icon:SetDesaturated(not s.exists or s.dead)
    h.ring:SetVertexColor(1,1,1)
    local a=P.ammoState or {}; local ac=P.colors[a.tier] or P.colors.neutral
    P.nodes.ammo.ring:SetVertexColor(1,1,1)
    P.nodes.ammo.label:SetText(P.T(a.total==nil and "—" or a.total))
    P.ApplyAmmoStyle(P.nodes.ammo.label,a.total,a.tier)
    P.UpdateAmmoWarning()
    P.hud.badge:SetVertexColor(unpack(ac)); P.hud.badge:SetShown(P.db.ammo and a.tier and a.tier<3)
    local training=P.db.training and P.trainingOptions and #P.trainingOptions>0
    P.nodes.training.ring:SetVertexColor(unpack(training and {1,.82,.52} or {1,1,1}))
    local f=P.CurrentFood()
    P.nodes.feed.icon:SetTexture(f and f.icon or "Interface\\Icons\\Ability_Hunter_BeastTraining")
    P.nodes.feed.icon:SetDesaturated(not f or not P.CanFeed())
    P.nodes.feed.ring:SetVertexColor(1,1,1)
    local aura=P.feedAura
    if aura and aura.expires and aura.duration and aura.duration>0 and aura.expires>GetTime() then
        P.feedCooldown:SetCooldown(aura.expires-aura.duration,aura.duration); P.feedCooldown:Show()
    else P.feedCooldown:Hide() end
    if P.tipKey and P.tipOwner then P.Tooltip(P.tipKey,P.tipOwner) end
end
local function xpCoordinates(texture,percent)
    local col,row=percent%16,math.floor(percent/16)
    texture:SetTexCoord(col/16,(col+1)/16,row/8,(row+1)/8)
end
function P.UpdateXPRing()
    if not P.hud or not P.hud.xpFill then return end
    local s=P.pet
    local visible=s.exists and not s.dead and s.xpFraction~=nil
    P.hud.xpTrack:SetShown(visible);P.hud.xpFill:SetShown(visible)
    if visible then
        local step=math.floor(s.xpFraction*100)
        if P.hud.xpStep~=step then xpCoordinates(P.hud.xpFill,step);P.hud.xpStep=step end
    else P.hud.xpStep=nil end
end
function P.BuildHUD()
    GameTooltip=CreateFrame("GameTooltip","PetPulseForeverTooltip",UIParent,"GameTooltipTemplate")
    P.tooltip=GameTooltip;P.LocalizeTooltip(GameTooltip)
    P.linear=0; P.progress=0; P.expanded=false
    local f=CreateFrame("Frame","PetPulseForeverHUD",UIParent)
    P.hud=f; f:SetSize(44,44); f:SetClampedToScreen(true); f:SetMovable(true)
    f:SetFrameStrata("MEDIUM")
    f.shard=f:CreateTexture(nil,"BACKGROUND",nil,-1)
    f.shard:SetPoint("CENTER"); f.shard:SetSize(160,160)
    f.shard:SetTexture(P.media.."shard.tga"); f.shard:SetAlpha(0)
    f.halo=f:CreateTexture(nil,"BACKGROUND")
    f.halo:SetPoint("CENTER");f.halo:SetSize(66,66);f.halo:SetTexture(P.media.."portrait-halo.tga")
    f.center=node(f,"pet",44); f.center:SetAllPoints()
    f.center.ring:SetTexture(P.media.."portrait-frame.tga")
    f.center.ring:ClearAllPoints();f.center.ring:SetPoint("CENTER");f.center.ring:SetSize(58,58)
    f.xpTrack=f.center:CreateTexture(nil,"OVERLAY",nil,2)
    f.xpFill=f.center:CreateTexture(nil,"OVERLAY",nil,3)
    for _,texture in ipairs({f.xpTrack,f.xpFill}) do
        texture:SetTexture(P.media.."xp-ring.tga");texture:SetSize(58,58);texture:SetPoint("CENTER")
        texture:Hide()
    end
    xpCoordinates(f.xpTrack,100);f.xpTrack:SetVertexColor(.2,.16,.29,.9)
    f.xpFill:SetVertexColor(.72,.53,1,1)
    f.gem=f.center:CreateTexture(nil,"OVERLAY")
    f.gem:SetTexture(P.media.."portrait-gem.tga");f.gem:SetPoint("CENTER");f.gem:SetSize(58,58)
    f.actionLabel=f:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall")
    f.actionLabel:SetPoint("TOP",f,"BOTTOM",0,-6)
    f.actionLabel:SetFont("Fonts\\ARIALN.TTF",10,"OUTLINE")
    f.center:RegisterForClicks("LeftButtonUp","RightButtonUp")
    f.center:RegisterForDrag("LeftButton")
    f.center:SetScript("OnClick",function(_,button)
        if button=="RightButton" then P.ToggleSettings()
        elseif not P.db.hover and not P.db.pinnedOpen then
            P.expanded=not P.expanded; P.outsideAt=nil; f:SetScript("OnUpdate",P.UpdateHUD)
        end
    end)
    f.center:SetScript("OnDragStart",P.StartDrag)
    f.center:SetScript("OnDragStop",P.SavePosition)
    f.badge=f:CreateTexture(nil,"OVERLAY"); f.badge:SetTexture(P.media.."pip.tga")
    f.badge:SetSize(10,10); f.badge:SetPoint("BOTTOMRIGHT",2,-1)
    f.alert=f:CreateFontString(nil,"OVERLAY","GameFontNormalLarge")
    f.alert:SetPoint("TOP",f,"BOTTOM",0,-82); f.alert:SetTextColor(1,.48,.32)
    f.meal=CreateFrame("Frame",nil,f);f.meal:SetSize(220,30);f.meal:EnableMouse(false)
    f.meal.title=f.meal:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall")
    f.meal.title:SetPoint("TOP",0,0);f.meal.title:SetFont("Fonts\\ARIALN.TTF",12,"OUTLINE")
    f.meal.title:SetTextColor(1,.86,.57)
    f.meal.caption=f.meal:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall")
    f.meal.caption:SetPoint("TOP",0,-14);f.meal.caption:SetFont("Fonts\\ARIALN.TTF",10,"OUTLINE")
    f.meal.caption:SetTextColor(.87,.91,.84);f.meal.caption:SetText(P.T("A little meal, a happier friend."))
    f.meal:Hide()
    P.nodes={}
    for key in pairs(positions) do P.nodes[key]=node(f,key,32) end
    P.nodes.training.icon:SetTexture("Interface\\Icons\\Ability_Hunter_BeastTaming")
    P.nodes.ammo.icon:Hide()
    P.nodes.ammo.label:SetFont("Fonts\\FRIZQT__.TTF",12,"")
    P.nodes.ammo.label:SetShadowColor(0,0,0,1);P.nodes.ammo.label:SetShadowOffset(0,-1)
    P.nodes.feed:RegisterForClicks("LeftButtonUp","RightButtonUp")
    P.nodes.feed:SetScript("OnClick",function(_,button)
        if button=="RightButton" then P.ToggleFoodMenu();return end
        if InCombatLockdown() then P.Message("Feeding is unavailable in combat.") end
    end)
    P.nodes.training:RegisterForClicks("LeftButtonUp","RightButtonUp")
    P.nodes.training:SetScript("OnClick",function(_,button) if button=="RightButton" then P.ToggleGuide() else P.OpenTraining() end end)
    P.feedCooldown=CreateFrame("Cooldown",nil,P.nodes.feed,"CooldownFrameTemplate")
    P.feedCooldown:SetAllPoints(P.nodes.feed.icon); P.feedCooldown:SetDrawEdge(false)
    P.feedCooldown:SetHideCountdownNumbers(true); P.feedCooldown:EnableMouse(false)
    P.secureNodes={}
    for _,key in ipairs({"feed","training"}) do
        local b=P.MakeSecureButton("PetPulseForeverAction_"..key,UIParent)
        b:SetFrameStrata("MEDIUM"); b:SetFrameLevel(f:GetFrameLevel()+10)
        b.key=key; b:SetScript("OnEnter",enter); b:SetScript("OnLeave",leave)
        b:Hide(); RegisterStateDriver(b,"visibility","[combat] hide; ignore")
        P.secureNodes[key]=b
    end
    P.feedAction=P.secureNodes.feed
    P.feedAction:RegisterForClicks("LeftButtonUp","RightButtonUp")
    P.feedAction:SetAttribute("type2", "")
    P.feedAction:SetScript("PreClick",P.FeedPreClick)
    P.feedAction:HookScript("PostClick",function(b,button)
        if button=="RightButton" then P.ToggleFoodMenu();P.PrepareFeed();return end
        if b.confirmFood and not InCombatLockdown() then P.ShowConfirmation(b.confirmFood); b.confirmFood=nil end
    end)
    P.secureNodes.training:RegisterForClicks("LeftButtonUp","RightButtonUp")
    P.secureNodes.training:SetAttribute("type2", "")
    P.secureNodes.training:HookScript("PostClick",function(_,button) if button=="RightButton" then P.ToggleGuide() end end)
    P.secureNodes.training:SetAttribute("type","spell")
    P.secureNodes.training:SetAttribute("spell",5149)
    P.petAction=P.MakeSecureButton("PetPulseForeverPetAction",UIParent)
    P.petAction:SetSize(44,44);P.petAction:SetFrameStrata("MEDIUM")
    P.petAction:SetFrameLevel(f:GetFrameLevel()+10);P.petAction.key="pet"
    P.petAction:RegisterForClicks("LeftButtonUp","RightButtonUp")
    P.petAction:SetAttribute("type1","macro")
    local revive=P.Call("C_Spell.GetSpellName",982) or "Revive Pet"
    local call=P.Call("C_Spell.GetSpellName",883) or "Call Pet"
    P.petAction:SetAttribute("macrotext1","/cast [mod:shift] "..revive.."; [@pet,dead] "..revive.."; [nopet] "..call)
    P.petAction:SetScript("OnEnter",enter);P.petAction:SetScript("OnLeave",leave)
    P.petAction:HookScript("PostClick",function(_,button)
        if button=="RightButton" then P.ToggleSettings()
        elseif not P.db.hover and not P.db.pinnedOpen then P.expanded=not P.expanded;f:SetScript("OnUpdate",P.UpdateHUD) end
    end)
    f.menu=CreateFrame("Button",nil,f,"BackdropTemplate")
    f.menu:SetSize(22,22);f.menu:SetPoint("CENTER",f,"CENTER",34,22)
    f.menu:SetFrameLevel(f:GetFrameLevel()+12)
    f.menu.plate=f.menu:CreateTexture(nil,"BACKGROUND")
    f.menu.plate:SetAllPoints();f.menu.plate:SetTexture(P.media.."menu-medallion.tga")
    f.menu.bars={}
    for i=1,3 do
        local bar=f.menu:CreateTexture(nil,"OVERLAY");bar:SetTexture("Interface\\Buttons\\WHITE8X8")
        bar:SetSize(i==2 and 8 or 11,2);bar:SetPoint("CENTER",0,8-i*4);bar:SetVertexColor(.95,.8,.5)
        f.menu.bars[i]=bar
    end
    f.menu:SetScript("OnEnter",function(self)
        P.OpenShard();self.plate:SetVertexColor(1.35,1.2,.85)
        GameTooltip:SetOwner(self,"ANCHOR_RIGHT");GameTooltip:AddLine(P.T("Settings"));P.SizeTooltipText();GameTooltip:Show()
    end)
    f.menu:SetScript("OnLeave",function(self) self.plate:SetVertexColor(1,1,1);GameTooltip:Hide() end)
    f.menu:SetScript("OnClick",function() GameTooltip:Hide();P.ToggleSettings() end)
    f.menu:Hide()
    f.pin=CreateFrame("Button",nil,f)
    f.pin:SetSize(22,22);f.pin:SetPoint("CENTER",f,"CENTER",-34,22)
    f.pin:SetFrameLevel(f:GetFrameLevel()+12)
    f.pin.plate=f.pin:CreateTexture(nil,"BACKGROUND")
    f.pin.plate:SetAllPoints();f.pin.plate:SetTexture(P.media.."menu-medallion.tga")
    f.pin.parts={}
    -- Small pushpin silhouette, using the same medallion as the settings button.
    for _,shape in ipairs({{8,2,0,5},{5,5,0,2},{11,2,0,-1},{2,5,0,-4}}) do
        local part=f.pin:CreateTexture(nil,"OVERLAY")
        part:SetTexture("Interface\\Buttons\\WHITE8X8")
        part:SetSize(shape[1],shape[2]);part:SetPoint("CENTER",shape[3],shape[4])
        f.pin.parts[#f.pin.parts+1]=part
    end
    f.pin:SetScript("OnEnter",function(self)
        P.OpenShard();self.plate:SetVertexColor(1.35,1.2,.85)
        GameTooltip:SetOwner(self,"ANCHOR_LEFT")
        GameTooltip:AddLine(P.T(P.db.pinnedOpen and "Unpin HUD" or "Stick Open"))
        GameTooltip:AddLine(P.T(P.db.pinnedOpen and "Click to restore normal opening behaviour." or "Keep the pet controls open, even when your mouse leaves."),1,.9,.7,true)
        P.SizeTooltipText();GameTooltip:Show()
    end)
    f.pin:SetScript("OnLeave",function(self) self.plate:SetVertexColor(1,1,1);GameTooltip:Hide() end)
    f.pin:SetScript("OnClick",function() P.SetPinnedOpen(not P.db.pinnedOpen);GameTooltip:Hide() end)
    f.pin:Hide()
    P.BuildHealthWarning()
    P.BuildCenterWarnings()
    -- Dedicated move mode: the entire visible shard is a drag handle, with no
    -- food/training actions intercepting the pointer while it is unlocked.
    f.mover=CreateFrame("Button",nil,f,"BackdropTemplate")
    f.mover:SetSize(166,166); f.mover:SetPoint("CENTER"); f.mover:SetFrameLevel(f:GetFrameLevel()+30)
    f.mover:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8X8",edgeFile="Interface\\Buttons\\WHITE8X8",edgeSize=1})
    f.mover:SetBackdropColor(.05,.1,.12,.18); f.mover:SetBackdropBorderColor(.72,.59,.35,.7)
    f.mover:RegisterForDrag("LeftButton"); f.mover:RegisterForClicks("RightButtonUp")
    f.mover:SetScript("OnDragStart",P.StartDrag); f.mover:SetScript("OnDragStop",P.SavePosition)
    f.mover:SetScript("OnClick",function() P.SetLocked(true) end)
    local hint=f.mover:CreateFontString(nil,"OVERLAY","GameFontNormalSmall")
    hint:SetPoint("TOP",0,-5); P.BindLabel(hint,"UNLOCKED · DRAG TO MOVE")
    f.mover.lock=CreateFrame("Button",nil,f.mover,"UIPanelButtonTemplate")
    f.mover.lock:SetSize(82,23); f.mover.lock:SetPoint("TOP",f.mover,"BOTTOM",0,-5)
    P.BindLabel(f.mover.lock,"Lock HUD"); f.mover.lock:SetScript("OnClick",function() P.SetLocked(true) end)
    f.mover:Hide()
    P.BuildConfirmation();P.BuildFoodMenu(); P.ApplyLayout()
end
