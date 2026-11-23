local _,P=...
function P.CurrentFood()
    if P.manualFood and P.manualFood.guid~=P.pet.guid then P.manualFood=nil end
    if P.manualFood then
        for _,food in ipairs(P.foods or {}) do if food.id==P.manualFood.id then return food end end
        -- An explicit choice never silently falls back to another food.
        return nil
    end
    return P.foods and P.foods[1]
end
function P.FoodChoices()
    local allowed={}
    for _,food in ipairs(P.foods or {}) do allowed[food.id]=food end
    local choices,byID={},{}
    for bag=0,(NUM_BAG_SLOTS or 4) do
        for slot=1,(P.Call("C_Container.GetContainerNumSlots",bag) or 0) do
            local info=P.Call("C_Container.GetContainerItemInfo",bag,slot)
            local id=info and P.Plain(info.itemID)
            if id and P.Call("C_PetInfo.CanPetEatItem",id)==true then
                local name,_,_,_,_,_,_,_,_,icon=P.Call("C_Item.GetItemInfo",id)
                if name then
                    if not byID[id] then
                        local candidate=allowed[id]
                        local entry={id=id,name=name,icon=icon,quantity=0,bag=candidate and candidate.bag or bag,
                            slot=candidate and candidate.slot or slot,allowed=candidate~=nil,risk=candidate and candidate.risk}
                        byID[id]=entry;choices[#choices+1]=entry
                    end
                    byID[id].quantity=byID[id].quantity+(P.Plain(info.stackCount) or 0)
                end
            end
        end
    end
    table.sort(choices,function(a,b) if a.allowed~=b.allowed then return a.allowed end;return a.name<b.name end)
    return choices
end
function P.SelectFood(id)
    if InCombatLockdown() then return end
    P.ReadPet();P.ReadAura();P.ScanFood();P.CancelConfirmation()
    if id then
        local valid=false
        for _,food in ipairs(P.foods) do if food.id==id then valid=true;break end end
        if not valid then P.RefreshFoodMenu();return false end
        P.manualFood={id=id,guid=P.pet.guid}
    else P.manualFood=nil end
    P.PrepareFeed();P.Paint();P.foodMenu:Hide();return true
end
function P.RefreshFoodMenu()
    local f=P.foodMenu;if not f then return end
    P.ReadPet();P.ScanFood()
    f.choices=P.FoodChoices()
    local pages=math.max(1,math.ceil(#f.choices/8))
    f.page=P.Clamp(f.page or 1,1,pages)
    f.pageText:SetText(f.page.." / "..pages)
    f.auto:SetText(P.T("Automatic choice"))
    f.heading:SetText(P.T("Choose food"))
    f.hint:SetText(P.T("Select here, then left-click Feed. Amber foods need confirmation."))
    f.empty:SetText(#f.choices==0 and P.T("No suitable food") or "")
    for i,row in ipairs(f.rows) do
        local entry=f.choices[(f.page-1)*8+i];row.entry=entry
        row:SetShown(entry~=nil)
        if entry then
            row.icon:SetTexture(entry.icon)
            row.label:SetText(entry.name.."  x"..entry.quantity)
            local selected=P.manualFood and P.manualFood.id==entry.id
            row.marker:SetText(selected and "*" or "")
            row.label:SetTextColor(unpack(not entry.allowed and {.45,.45,.45} or entry.risk and {1,.72,.34} or {.95,.93,.86}))
        end
    end
end
function P.ToggleFoodMenu()
    if InCombatLockdown() then P.Message("Feeding is unavailable in combat.");return end
    local f=P.foodMenu
    if f:IsShown() then f:Hide();return end
    P.tooltip:Hide();P.tipKey=nil;P.tipOwner=nil
    f.page=1;P.RefreshFoodMenu();f:Show();P.OpenShard()
end
function P.BuildFoodMenu()
    local f=CreateFrame("Frame","PetPulseForeverFoodMenu",UIParent,"BackdropTemplate")
    P.foodMenu=f;f:SetSize(330,380);f:SetFrameStrata("DIALOG");f:SetClampedToScreen(true);f:EnableMouse(true)
    f:SetPoint("TOPLEFT",P.nodes.feed,"BOTTOMRIGHT",8,-4)
    f:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8X8",edgeFile="Interface\\Buttons\\WHITE8X8",edgeSize=1})
    f:SetBackdropColor(.045,.04,.03,.98);f:SetBackdropBorderColor(.55,.43,.23,1)
    table.insert(UISpecialFrames,"PetPulseForeverFoodMenu")
    local close=CreateFrame("Button",nil,f,"UIPanelCloseButton");close:SetPoint("TOPRIGHT")
    f.heading=f:CreateFontString(nil,"OVERLAY","GameFontNormal");f.heading:SetPoint("TOPLEFT",14,-14)
    f.hint=f:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall");f.hint:SetPoint("TOPLEFT",14,-42);f.hint:SetWidth(298)
    f.auto=CreateFrame("Button",nil,f,"UIPanelButtonTemplate");f.auto:SetPoint("TOPLEFT",14,-73);f.auto:SetSize(300,24)
    f.auto:SetScript("OnClick",function() P.SelectFood(nil) end)
    f.empty=f:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall");f.empty:SetPoint("TOP",0,-125)
    f.rows={}
    for i=1,8 do
        local row=CreateFrame("Button",nil,f);f.rows[i]=row
        row:SetSize(302,27);row:SetPoint("TOPLEFT",12,-103-(i-1)*28)
        row:SetHighlightTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight","ADD")
        row.icon=row:CreateTexture(nil,"ARTWORK");row.icon:SetSize(24,24);row.icon:SetPoint("LEFT",0,0)
        row.label=row:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall");row.label:SetPoint("LEFT",29,0);row.label:SetWidth(255)
        row.marker=row:CreateFontString(nil,"OVERLAY","GameFontNormal");row.marker:SetPoint("RIGHT",0,0)
        row:SetScript("OnEnter",function(self)
            local e=self.entry;if not e then return end
            local info=P.Call("C_Container.GetContainerItemInfo",e.bag,e.slot)
            if not info or P.Plain(info.itemID)~=e.id then P.RefreshFoodMenu();return end
            GameTooltip:SetOwner(self,"ANCHOR_RIGHT");GameTooltip:SetBagItem(e.bag,e.slot)
            if not e.allowed then GameTooltip:AddLine(P.T("Blocked by your food protection settings."),1,.4,.3,true) end
            GameTooltip:Show()
        end)
        row:SetScript("OnLeave",function() GameTooltip:Hide() end)
        row:SetScript("OnClick",function(self) if self.entry and self.entry.allowed then P.SelectFood(self.entry.id) end end)
    end
    f.pageText=f:CreateFontString(nil,"OVERLAY","GameFontNormalSmall");f.pageText:SetPoint("BOTTOM",0,18)
    for _,dir in ipairs({-1,1}) do
        local step=dir
        local b=CreateFrame("Button",nil,f,"UIPanelButtonTemplate");b:SetSize(34,24);b:SetPoint("BOTTOM",step*62,12)
        b:SetText(step<0 and "<" or ">");b:SetScript("OnClick",function() f.page=(f.page or 1)+step;P.RefreshFoodMenu() end)
    end
    f:EnableMouseWheel(true);f:SetScript("OnMouseWheel",function(_,delta) f.page=(f.page or 1)-delta;P.RefreshFoodMenu() end)
    f:SetScript("OnHide",function() GameTooltip:Hide() end);f:Hide()
end
