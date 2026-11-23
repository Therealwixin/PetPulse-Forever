local _,P=...
-- Presentation only: this module never ranks food or changes secure actions.
function P.GetFoodDetails(food)
    local _,_,_,_,requiredLevel,itemType,subType,_,_,_,_,class=P.Call("C_Item.GetItemInfo",food.id)
    local record=P.foodCatalog[food.id]
    local kind=class==7 and "CRAFTING REAGENT" or class==12 and "QUEST ITEM"
        or record and record.reason=="Buff food" and "BUFF FOOD" or "PET-COMPATIBLE FOOD"
    local details={kind=kind,requiredLevel=requiredLevel,itemType=itemType,subType=subType,lines={},quests={}}
    local tooltip=P.Call("C_TooltipInfo.GetBagItem",food.bag,food.slot)
    local seen={}
    for _,line in ipairs(tooltip and tooltip.lines or {}) do
        local left,right=P.Plain(line.leftText),P.Plain(line.rightText)
        if type(left)=="string" and left~="" and left~=food.name and not seen[left] then
            seen[left]=true
            details.lines[#details.lines+1]={left=left,right=type(right)=="string" and right or nil}
        end
    end
    local ids={}
    local liveQuest=P.Call("C_Container.GetContainerItemQuestInfo",food.bag,food.slot)
    local liveQuestID=liveQuest and P.Plain(liveQuest.questID)
    if type(liveQuestID)=="number" and liveQuestID>0 then ids[liveQuestID]=true end
    for _,qid in ipairs(P.questFood[food.id] or {}) do ids[qid]=true end
    if ItemDB and type(ItemDB.relatedQuests)=="function" then
        local ok,related=pcall(ItemDB.relatedQuests,food.id)
        if ok and type(related)=="table" then
            for _,qid in ipairs(related) do if type(qid)=="number" then ids[qid]=true end end
        end
    end
    for qid in pairs(ids) do
        local active=P.Call("C_QuestLog.IsOnQuest",qid)
        local done=P.Call("C_QuestLog.IsQuestFlaggedCompleted",qid)
        local repeatable=P.Call("C_QuestLog.IsRepeatableQuest",qid)
        local knownRepeat=P.repeatableQuests and P.repeatableQuests[qid]
        local status
        if active==true then status="Active — keep for quest"
        elseif repeatable==true or knownRepeat then status=done and "Completed · repeatable" or "Repeatable — still useful"
        elseif done==true and active==false and repeatable==false then status="Completed"
        elseif done==false then status="Not completed"
        else status="Status unavailable" end
        details.quests[#details.quests+1]={id=qid,name=P.Call("C_QuestLog.GetTitleForQuestID",qid) or "Quest #"..qid,status=status}
    end
    table.sort(details.quests,function(a,b)return a.id<b.id end)
    return details
end
function P.AddFoodDetails(food)
    local GameTooltip=P.tooltip
    local d=P.GetFoodDetails(food)
    GameTooltip:AddLine(d.kind,1,.79,.39)
    if d.subType then GameTooltip:AddLine(d.subType,.73,.8,.86) end
    GameTooltip:AddLine(" ")
    GameTooltip:AddLine("ITEM EFFECTS & USE",.87,.89,.94)
    if #d.lines==0 then
        GameTooltip:AddLine("Item details unavailable from the client.",.62,.67,.73,true)
    else
        for i,line in ipairs(d.lines) do
            if i<=8 then
                -- Native item text includes actual buff amounts/duration, rather
                -- than parsing spell tokens or inventing player-level estimates.
                GameTooltip:AddLine(line.left,.78,.87,.75,true)
                if line.right and line.right~="" then GameTooltip:AddLine(line.right,.7,.76,.8,true) end
            end
        end
        if #d.lines>8 then GameTooltip:AddLine("More details in the item's bag tooltip.",.6,.65,.7,true) end
    end
    GameTooltip:AddLine(" ")
    GameTooltip:AddLine("QUEST USE",.87,.89,.94)
    if #d.quests==0 then
        local q=P.Call("C_Container.GetContainerItemQuestInfo",food.bag,food.slot)
        if q and (P.Plain(q.isQuestItem) or P.Plain(q.questID)) then
            GameTooltip:AddLine("Quest-tagged item — completion unavailable",1,.72,.38,true)
        else GameTooltip:AddLine("No known quest requirement",.62,.7,.75) end
    else
        for i,q in ipairs(d.quests) do
            if i<=4 then
                GameTooltip:AddLine(q.name,.83,.87,.9,true)
                local complete=q.status=="Completed"
                GameTooltip:AddLine("  "..P.T(q.status),complete and .45 or 1,complete and .85 or .72,.42,true)
            end
        end
        if #d.quests>4 then GameTooltip:AddLine("+"..(#d.quests-4).." more related quests",.65,.7,.75) end
    end
end
