local _,P=...
function P.ReadTraining()
    P.trainingOptions=nil
    if not P.trainerOpen or not P.pet.exists or not Enum.TrainerType then return end
    if P.Call("C_Trainer.GetTrainerType")~=Enum.TrainerType.Pet then return end
    local n=P.Call("GetNumTrainerServices")
    if not n then return end
    local out={}
    for i=1,n do
        local name,status,_,level,rank=P.Call("GetTrainerServiceInfo",i)
        local cost=P.Call("GetTrainerServiceCost",i)
        local eligible=status=="available" and name and cost and P.pet.tp and cost<=P.pet.tp
            and level and P.pet.level and level<=P.pet.level
        local skill,_,hasSkill=P.Call("GetTrainerServiceSkillReq",i)
        if skill and hasSkill~=true then eligible=false end
        local count=P.Call("GetTrainerServiceNumAbilityReq",i)
        if not count then eligible=false else
            for j=1,count do
                local ability,has=P.Call("GetTrainerServiceAbilityReq",i,j)
                if ability and has~=true then eligible=false end
            end
        end
        if eligible then out[#out+1]={name=name,rank=rank,cost=cost} end
    end
    -- No cross-pet or stale session cache: service availability is authoritative.
    P.trainingOptions=out
end
function P.OpenTraining()
    if InCombatLockdown() then P.Message("Beast Training cannot be opened in combat."); return end
    if ClassTrainerFrame and P.trainerOpen then ClassTrainerFrame:Show(); return end
    P.Message("Open Beast Training from your spellbook to verify available upgrades.")
end
