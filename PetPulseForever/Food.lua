local _,P=...
-- Full build-specific catalog; live client diet and safety checks always take precedence.
local function tooltipSafety(bag,slot)
    if P.Call("GetLocale")~="enUS" and P.Call("GetLocale")~="enGB" then return nil end
    local tooltip=P.Call("C_TooltipInfo.GetBagItem",bag,slot)
    if not tooltip or not tooltip.lines then return nil end
    for _,line in ipairs(tooltip.lines) do
        for _,field in ipairs({"leftText","rightText"}) do
            local text=P.Plain(line[field])
            if type(text)=="string" then
                text=text:lower()
                for _,word in ipairs({"well fed","stamina","strength","agility","intellect","spirit","attack power","spell power","versatility"}) do
                    if text:find(word,1,true) then return true end
                end
            end
        end
    end
    return false
end
function P.RankFood(a,b)
    if a.tier~=b.tier then return a.tier<b.tier end
    if a.risk~=b.risk then return not a.risk end
    if P.db.priority=="lowlevel" and a.level~=b.level then return a.level<b.level end
    if P.db.priority=="cheap" and a.price~=b.price then return a.price<b.price end
    if a.distance~=b.distance then return a.distance<b.distance end
    if a.price~=b.price then return a.price<b.price end
    if a.quantity~=b.quantity then return a.quantity>b.quantity end
    if a.id~=b.id then return a.id<b.id end
    if a.bag~=b.bag then return a.bag<b.bag end
    return a.slot<b.slot
end
function P.ScanFood()
    P.foodDirty=false
    P.foods={}
    P.questFoodsSkipped=0
    if not P.pet.exists or P.pet.dead then return end
    local quantities={}
    for bag=0,(NUM_BAG_SLOTS or 4) do
        for slot=1,(P.Call("C_Container.GetContainerNumSlots",bag) or 0) do
            local info=P.Call("C_Container.GetContainerItemInfo",bag,slot)
            if info then
                local id=P.Plain(info.itemID)
                local locked=P.Plain(info.isLocked)
                local questProtected=id and P.IsQuestFood(id)
                if questProtected then P.questFoodsSkipped=P.questFoodsSkipped+1 end
                if id and not P.db.protected[id] and locked==false and P.Call("C_PetInfo.CanPetEatItem",id)==true then
                    local name,link,quality,level,_,_,_,_,_,icon,price,class=P.Call("C_Item.GetItemInfo",id)
                    local quest=P.Call("C_Container.GetContainerItemQuestInfo",bag,slot)
                    local isQuest=questProtected or (quest and (P.Plain(quest.isQuestItem) or P.Plain(quest.questID)))
                    local record=P.foodCatalog[id]
                    -- Class 7 cooking ingredients are allowed when positively classified,
                    -- never excluded merely because they are crafting reagents.
                    if name and quality and quality<=1 and quest and price and level
                        and (not record or record.policy~="exclude" or record.reason=="Quest item") then
                        local _,build=P.Call("GetBuildInfo")
                        local tooltipBuff=tooltipSafety(bag,slot)
                        local reason=record and record.reason or "Uncatalogued food"
                        local risk=not record or record.policy~="safe" or tostring(build)~=P.foodCatalogBuild
                        local tier=risk and 2 or 0
                        if record and record.reason=="Quest item" and tostring(build)==P.foodCatalogBuild then tier=1 end
                        if tostring(build)~=P.foodCatalogBuild then reason="New client build — review required" end
                        if tooltipBuff==true then risk=true;tier=2;reason="Buff food" end
                        if price>=P.db.price then risk=true;tier=2;reason="High vendor value" end
                        if isQuest or class==12 or (record and record.reason=="Quest item") then
                            risk=true;tier=math.max(tier,1)
                            reason=tier==2 and (reason.." / quest material") or "Quest material — confirm before sharing"
                        end
                        -- A verified build catalog works on every locale. Missing metadata
                        -- and unknown effects never become safe through text heuristics.
                        if not risk or P.db.confirmation then
                            local count=P.Plain(info.stackCount) or 0
                            quantities[id]=(quantities[id] or 0)+count
                            P.foods[#P.foods+1]={id=id,name=name,link=link,bag=bag,slot=slot,
                                quality=quality,level=level,price=price,icon=icon,risk=risk,reason=reason,tier=tier,
                                diet=record and record.diet,
                                distance=math.max(0,(P.pet.level or 1000)-level),quantity=count}
                        end
                    end
                end
            end
        end
    end
    for _,f in ipairs(P.foods) do f.quantity=quantities[f.id] end
    table.sort(P.foods,P.RankFood)
end
function P.CanFeed()
    return not InCombatLockdown() and P.pet.exists and not P.pet.dead and not P.feedAura
        and P.Call("UnitAffectingCombat","pet")~=true
        and P.Call("SpellIsTargeting")~=true
end
function P.ClearAction(b)
    if InCombatLockdown() then return end
    b:SetAttribute("type",nil)
    b:SetAttribute("target-bag",nil)
    b:SetAttribute("target-slot",nil)
end
function P.SetFeedAction(b,f)
    P.ClearAction(b)
    if f and P.CanFeed() then
        b:SetAttribute("spell",6991)
        b:SetAttribute("target-bag",f.bag)
        b:SetAttribute("target-slot",f.slot)
        b:SetAttribute("type","spell")
    end
end
function P.CancelConfirmation()
    P.pendingFood=nil
    if P.confirm and not InCombatLockdown() then P.confirm:Hide(); P.ClearAction(P.confirm.accept) end
end
function P.PrepareFeed()
    if not P.feedAction or InCombatLockdown() then return end
    if not P.db.locked then P.ClearAction(P.feedAction); return end
    local f=P.CurrentFood()
    P.SetFeedAction(P.feedAction,f and not f.risk and f or nil)
end
function P.FeedPreClick(b,button)
    if button=="RightButton" then
        if not InCombatLockdown() then P.CancelConfirmation();P.ClearAction(b);b.confirmFood=nil end
        return
    end
    if InCombatLockdown() then return end
    P.CancelConfirmation()
    if not P.db.locked then P.ClearAction(b); return end
    P.ReadPet(); P.ReadAura(); P.ScanFood()
    P.PrepareFeed()
    local f=P.CurrentFood()
    b.confirmFood=nil
    if not P.CanFeed() then P.Alert("feed","Feeding unavailable: pet absent, dead, busy or in combat",false)
    elseif not f then P.Alert("food","No Compatible Food â€” check protected foods",false)
    elseif f.risk then b.confirmFood=f end
end
function P.MakeSecureButton(name,parent)
    local b=CreateFrame("Button",name,parent,"SecureActionButtonTemplate")
    b:RegisterForClicks("LeftButtonUp")
    b:SetAttribute("useOnKeyDown",false)
    return b
end
function P.BuildConfirmation()
    local f=CreateFrame("Frame","PetPulseForeverConfirm",UIParent,"BackdropTemplate")
    f:SetSize(330,150); f:SetPoint("CENTER"); f:SetFrameStrata("DIALOG")
    f:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8X8",edgeFile="Interface\\Buttons\\WHITE8X8",edgeSize=1})
    f:SetBackdropColor(.035,.055,.075,.98); f:SetBackdropBorderColor(.75,.53,.22,1)
    local label=f:CreateFontString(nil,"OVERLAY","GameFontNormal")
    label:SetPoint("TOP",0,-17); label:SetWidth(300)
    P.BindLabel(label,"Warning: This food may be valuable to your character.")
    f.item=f:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall")
    f.item:SetPoint("TOP",0,-62); f.item:SetWidth(300)
    -- Match Cancel's native red button while retaining secure feeding attributes.
    f.accept=CreateFrame("Button","PetPulseForeverFeedOnce",f,"SecureActionButtonTemplate,UIPanelButtonTemplate")
    f.accept:RegisterForClicks("LeftButtonUp")
    f.accept:SetAttribute("useOnKeyDown",false)
    f.accept:SetSize(128,28); f.accept:SetPoint("BOTTOMLEFT",18,16)
    P.BindLabel(f.accept,"Feed Once")
    f.accept:SetScript("PreClick",function(b)
        if InCombatLockdown() then return end
        P.ClearAction(b)
        local pending=P.pendingFood
        if not pending then return end
        P.ReadPet(); P.ReadAura(); P.ScanFood()
        if not P.pendingFood or pending.guid~=P.pet.guid or not P.CanFeed() then return end
        for _,food in ipairs(P.foods) do
            if food.id==pending.id and food.bag==pending.bag and food.slot==pending.slot then
                P.SetFeedAction(b,food); return
            end
        end
        P.Alert("changed","Food changed â€” select food again",false)
    end)
    f.accept:HookScript("PostClick",function() P.CancelConfirmation() end)
    local cancel=CreateFrame("Button",nil,f,"UIPanelButtonTemplate")
    cancel:SetSize(128,28); cancel:SetPoint("BOTTOMRIGHT",-18,16); P.BindLabel(cancel,"Cancel")
    cancel:SetScript("OnClick",P.CancelConfirmation)
    f:Hide()
    RegisterStateDriver(f,"visibility","[combat] hide; ignore")
    P.confirm=f
end
function P.ShowConfirmation(food)
    if InCombatLockdown() then return end
    food.guid=P.pet.guid; P.pendingFood=food
    P.confirm.item:SetText(food.name.."\n"..P.T(food.reason)..P.T(" — diet verified"))
    P.SetFeedAction(P.confirm.accept,food)
    P.confirm:Show()
end
