local _,P=...
-- Query character completion on every selection/confirmation, not account history.
function P.IsQuestFood(id)
    local related={}
    for _,qid in ipairs(P.questFood[id] or {}) do related[qid]=true end
    if ItemDB and type(ItemDB.relatedQuests)=="function" then
        local ok,quests=pcall(ItemDB.relatedQuests,id)
        if ok and type(quests)=="table" then
            for _,qid in ipairs(quests) do if type(qid)=="number" then related[qid]=true end end
        end
    end
    for qid in pairs(related) do
        local active=P.Call("C_QuestLog.IsOnQuest",qid)
        local done=P.Call("C_QuestLog.IsQuestFlaggedCompleted",qid)
        local repeatable=P.Call("C_QuestLog.IsRepeatableQuest",qid)
        if active~=false or done~=true or repeatable~=false or (P.repeatableQuests and P.repeatableQuests[qid]) then
            return true
        end
    end
    return false
end
