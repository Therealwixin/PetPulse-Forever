local _,P=...
local mealPhrases={
    {"Nom nom...", "A little meal, a happier friend."},
    {"Happy munching...", "Made with love. Gone in bites."},
    {"Snack time!", "A little break for your best friend."},
    {"Munch, munch...", "Adventure can wait for one more bite."},
    {"Tasty little break...", "Good company. Good snacks."},
    {"Nom nom...", "Tiny bites, big friendship."},
    {"One more bite...", "Every adventure needs a snack buddy."},
    {"Cozy snack time...", "Just you, your buddy, and a bite."},
    {"Munchies!", "A well-earned little treat."},
    {"Best buddy break...", "Sharing a quiet moment together."},
}
function P.UpdateMealBadge()
    if not P.hud or not P.hud.meal then return end
    local aura=P.feedAura
    local remaining=aura and aura.expires and aura.expires>0 and aura.expires-GetTime()
    if not aura or not P.pet.exists or P.pet.dead or (remaining and remaining<=0) then
        P.mealSession=nil;P.hud.meal:Hide();return
    end
    local session=P.mealSession
    if not session or session.guid~=P.pet.guid or
        (remaining and session.expires and math.abs(aura.expires-session.expires)>.5) then
        -- Choose once per meal, excluding the previous caption without reroll loops.
        local index=math.random(1,#mealPhrases-(P.lastMealPhrase and 1 or 0))
        if P.lastMealPhrase and index>=P.lastMealPhrase then index=index+1 end
        P.lastMealPhrase=index
        session={guid=P.pet.guid,index=index};P.mealSession=session
    end
    if remaining then session.expires=aura.expires end
    local phrase=mealPhrases[session.index]
    P.hud.meal.title:SetText(P.T(phrase[1]..(remaining and " "..math.ceil(remaining).."s" or "")))
    P.hud.meal.caption:SetText(P.T(phrase[2]))
    P.hud.meal:Show()
end
function P.BuildHealthWarning()
    local f=CreateFrame("Frame",nil,P.hud)
    f:SetAllPoints(P.hud);f:EnableMouse(false);f:SetAlpha(0)
    local dot=f:CreateTexture(nil,"OVERLAY");dot:SetTexture(P.media.."pip.tga")
    dot:SetSize(13,13);dot:SetPoint("LEFT",P.hud,"LEFT",-8,0);dot:SetVertexColor(1,.52,.23)
    local label=f:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall")
    label:SetPoint("TOP",P.hud,"BOTTOM",0,-7);P.BindLabel(label,"LOW HP")
    label:SetFont("Fonts\\ARIALN.TTF",11,"OUTLINE");label:SetTextColor(1,.69,.4)
    P.healthWarning=f
    if C_CurveUtil and Enum.LuaCurveType and UnitHealthPercent then
        P.healthCurve=C_CurveUtil.CreateCurve()
        P.healthCurve:SetType(Enum.LuaCurveType.Step)
        P.healthCurve:AddPoint(0,.85);P.healthCurve:AddPoint(.2,0);P.healthCurve:AddPoint(1,0)
    end
end
function P.UpdateHealthWarning()
    if not P.healthWarning then return end
    if not P.db.petHealth or not P.pet.exists or P.pet.dead then P.healthWarning:SetAlpha(0);return end
    if P.healthCurve then
        -- Secret health is evaluated by the native curve and sent straight to
        -- a display-only alpha sink. Never compare or branch on its result.
        local ok,alpha=pcall(UnitHealthPercent,"pet",false,P.healthCurve)
        if ok then
            local applied=pcall(P.healthWarning.SetAlpha,P.healthWarning,alpha)
            if applied then return end
        end
    end
    local hp=P.pet.healthPercent
    P.healthWarning:SetAlpha(hp and hp<.2 and .85 or 0)
end
function P.ReadPet()
    local s={}
    s.exists=P.Call("UnitExists","pet")==true
    s.dead=P.Call("UnitIsDeadOrGhost","pet")==true
    s.guid=P.Call("UnitGUID","pet")
    s.name=P.Call("UnitName","pet")
    s.family=P.Call("UnitCreatureFamily","pet")
    s.level=P.Call("UnitLevel","pet")
    local hp=P.Call("UnitHealth","pet")
    local maxHP=P.Call("UnitHealthMax","pet")
    if type(hp)=="number" and type(maxHP)=="number" and maxHP>0 then s.healthPercent=hp/maxHP end
    if s.exists then
        local xp,totalXP=P.Call("GetPetExperience")
        if type(xp)=="number" and type(totalXP)=="number" and xp==xp and totalXP==totalXP
            and xp>=0 and totalXP>0 and totalXP<math.huge and xp<math.huge then
            s.xp=math.min(xp,totalXP);s.xpMax=totalXP;s.xpFraction=s.xp/totalXP
        end
        s.happiness,s.damage=P.Call("C_PetInfo.GetPetHappiness")
        s.loyalty=P.Call("C_PetInfo.GetPetLoyalty")
        s.diet=P.Call("C_PetInfo.GetPetFoodTypes")
        local total,used=P.Call("C_PetInfo.GetPetTrainingPoints")
        if total and used then s.tp=total-used end
    end
    local old=P.pet
    P.pet=s
    if old and old.guid==s.guid and old.happiness and s.happiness and old.happiness~=s.happiness then
        P.moodChange={at=GetTime(),direction=s.happiness>old.happiness and "Improving" or "Declining"}
    elseif not old or old.guid~=s.guid then P.moodChange=nil end
    if s.dead and not P.deathWarned and P.hud then
        if P.db.petDeath then P.Alert("petDeath","PET HAS DIED — Revive Pet",true) end
        P.deathWarned=true
    elseif s.exists and not s.dead then P.deathWarned=false end
    if old and old.guid~=s.guid then P.trainingOptions=nil; P.foodDirty=true; P.CancelConfirmation() end
    if old and old.level~=s.level then P.foodDirty=true end
    if old and old.happiness~=s.happiness and s.happiness==1 and P.db.happiness then
        P.Alert("happiness","Pet unhappy — feeding recommended",false)
    end
end
function P.CareAdvice()
    local s=P.pet
    if s.dead then return "Revive your companion", "Click the portrait to cast Revive Pet." end
    if not s.exists then return "Call your companion", "Click the portrait to cast Call Pet." end
    if s.healthPercent and s.healthPercent<.2 then return "Your pet needs healing", "Use Mend Pet or bring your pet to safety." end
    if P.feedAura then return (s.name or "Your companion").." is enjoying a meal", "A little food, a little more happiness. Let them finish." end
    if s.happiness==3 then return "All good — no food needed", "Save your food for when happiness drops." end
    if not s.happiness then return "Mood unavailable", "The client is not exposing a readable mood." end
    if P.foods and P.foods[1] then
        return "A meal would help",P.foods[1].risk and "Only protected food is available; review it first." or "Use Smart Feed below for a safe meal."
    end
    return "Bring suitable food", "No unprotected compatible food is available."
end
function P.ReadAura()
    P.feedAura=nil
    if not P.pet.exists then return end
    for i=1,40 do
        local a=P.Call("C_UnitAuras.GetAuraDataByIndex","pet",i,"HELPFUL")
        if not a then break end
        if P.Plain(a.spellId)==1539 then
            P.feedAura={duration=P.Plain(a.duration),expires=P.Plain(a.expirationTime)}
            return
        end
    end
end
function P.FeedStatus()
    if not P.pet.exists then return "No active pet" end
    if P.pet.dead then return "Pet is dead" end
    local a=P.feedAura
    if a then
        if a.expires and a.expires>GetTime() then
            return "Feed Pet Active — "..math.ceil(a.expires-GetTime()).."s Remaining"
        end
        return "Feeding — Duration Unavailable"
    end
    if P.pet.happiness==3 then return "Happy — Stable" end
    if not P.pet.happiness then return "Happiness Unavailable" end
    if not P.foods or #P.foods==0 then return "No Compatible Food" end
    return "Feeding Recommended"
end
function P.ReadAmmo()
    local ranged=P.Call("GetInventoryItemID","player",18)
    local _,_,_,_,_,weaponClass,weaponSub=P.Call("C_Item.GetItemInfoInstant",ranged or 0)
    local sub=weaponClass==2 and ((weaponSub==2 or weaponSub==18) and 2 or weaponSub==3 and 3) or nil
    local state={total=nil,equipped=0,sub=sub,weapon=ranged}
    if sub then
        state.total=0
        local playerLevel=P.Call("UnitLevel","player")
        local equippedID=P.Call("GetInventoryItemID","player",0)
        state.equippedID=equippedID
        for bag=0,(NUM_BAG_SLOTS or 4) do
            for slot=1,(P.Call("C_Container.GetContainerNumSlots",bag) or 0) do
                local info=P.Call("C_Container.GetContainerItemInfo",bag,slot)
                if info then
                    local id=P.Plain(info.itemID)
                    local _,_,_,_,_,class,kind=P.Call("C_Item.GetItemInfoInstant",id or 0)
                    if class==6 and kind==sub then
                        local name,_,_,_,requiredLevel=P.Call("C_Item.GetItemInfo",id)
                        local count=P.Plain(info.stackCount)
                        if not name or not requiredLevel or not playerLevel or not count then
                            state.unknown=true
                        elseif requiredLevel<=playerLevel then
                            state.total=state.total+count
                            if id==equippedID then state.equipped=state.equipped+count end
                        end
                    end
                end
            end
        end
        if state.unknown then state.total=nil end
    end
    local tier=P.AmmoTier(state.total,P.db.warning,P.db.critical)
    local old=P.ammoState
    state.tier=tier
    P.ammoState=state
    if not old then P.ammoNotice=nil end
    P.UpdateAmmoWarning()
end

function P.BuildCenterWarnings()
    local f=CreateFrame("Frame",nil,UIParent)
    f:SetSize(660,50);f:SetPoint("CENTER",UIParent,"CENTER",0,85);f:SetFrameStrata("HIGH");f:EnableMouse(false)
    f.text=f:CreateFontString(nil,"OVERLAY","GameFontNormalLarge");f.text:SetAllPoints(f)
    f.text:SetFont("Fonts\\FRIZQT__.TTF",22,"OUTLINE");f.text:SetShadowColor(0,0,0,1);f.text:SetShadowOffset(2,-2)
    f:Hide();P.ammoWarning=f
    local level=CreateFrame("Frame",nil,UIParent);level:SetSize(660,90);level:SetPoint("CENTER",UIParent,"CENTER",0,-15);level:SetFrameStrata("HIGH");level:EnableMouse(false)
    level.title=level:CreateFontString(nil,"OVERLAY","GameFontNormalLarge");level.title:SetPoint("TOP",level,"TOP",0,0);level.title:SetWidth(660)
    level.title:SetFont("Fonts\\FRIZQT__.TTF",28,"OUTLINE");level.title:SetTextColor(1,.82,.2);level.title:SetShadowColor(0,0,0,1);level.title:SetShadowOffset(2,-2)
    level.detail=level:CreateFontString(nil,"OVERLAY","GameFontHighlight");level.detail:SetPoint("TOP",level.title,"BOTTOM",0,-10);level.detail:SetWidth(640)
    level.detail:SetFont("Fonts\\FRIZQT__.TTF",17,"OUTLINE")
    level:SetScript("OnUpdate",function(self)
        local left=(self.expires or 0)-GetTime()
        if left<=0 then self:Hide()else self:SetAlpha(math.min(1,left))end
    end)
    level:Hide();P.petLevelWarning=level
end
function P.UpdateAmmoWarning()
    local f=P.ammoWarning;if not f then return end
    local a=P.ammoState
    if not P.db.ammo or not a or not a.tier or a.tier>=3 or a.total==nil then
        f:Hide();P.ammoNotice=nil;return
    end
    local key=a.total==0 and "ammo0" or a.tier==1 and "ammo1" or "ammo2"
    local message=a.total==0 and "OUT OF AMMO" or (a.tier==1 and "CRITICAL AMMO — " or "LOW AMMO — ")..a.total.." LEFT"
    local text=P.T(message).." · "..P.T(a.sub==3 and "Bullets" or "Arrows")
    f.text:SetText(text);f.text:SetTextColor(a.tier==1 and 1 or 1,a.tier==1 and .25 or .8,a.tier==1 and .2 or .15);f:Show()
    local notice=tostring(a.weapon)..":"..key
    if notice~=P.ammoNotice then
        P.ammoNotice=notice
        local now=GetTime()
        if now-(P.alertTimes[key] or -100)>8 then
            P.alertTimes[key]=now
            if P.db.sound and SOUNDKIT then PlaySound(SOUNDKIT.RAID_WARNING,"Master")end
        end
        P.Message(text)
    end
end
function P.ShowPetLevelUp(pet,ranks)
    local f=P.petLevelWarning;if not f or P.db.guide and P.db.guide.levelAlerts==false then return end
    f.title:SetText(string.format(P.T("%s reached level %d!"),pet.name,pet.level))
    local names={};for i=1,math.min(3,#ranks)do names[#names+1]=P.guide:RankName(ranks[i])end
    f.detail:SetText(#ranks>0 and P.T("New training options")..": "..table.concat(names,", ")..(#ranks>3 and " (+"..(#ranks-3)..")" or "") or P.T("Another level, another adventure together."))
    f.expires=GetTime()+7;f:SetAlpha(1);f:Show()
end

