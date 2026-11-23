local _,P=...
local events=CreateFrame("Frame")
local inventoryEvents={BAG_UPDATE_DELAYED=true,PLAYER_EQUIPMENT_CHANGED=true,GET_ITEM_INFO_RECEIVED=true,ITEM_LOCK_CHANGED=true}
function P.Refresh(inventory)
    if not P.ready then return end
    P.ReadPet(); P.ReadAura()
    if inventory or P.foodDirty then P.ScanFood(); P.ReadAmmo() end
    P.ReadTraining(); P.PrepareFeed(); P.Paint()
end
function P.Schedule(inventory)
    P.foodDirty=P.foodDirty or inventory
    if P.scheduled then return end
    P.scheduled=true
    C_Timer.After(.12,function() P.scheduled=false; P.Refresh() end)
end
local function initialize()
    local _,class=P.Call("UnitClass","player")
    if class~="HUNTER" then return end
    PetPulseForeverDB=type(PetPulseForeverDB)=="table" and PetPulseForeverDB or {}
    P.Merge(PetPulseForeverDB,P.defaults); P.db=PetPulseForeverDB
    if P.db.foodPolicyVersion~=2 then P.db.priority="lowlevel";P.db.foodPolicyVersion=2 end
    for key,bounds in pairs({scale={.8,1.6},opacity={.3,1},animation={.08,.4},delay={.2,.6},warning={1,10000},critical={0,9999}}) do
        P.db[key]=P.Clamp(P.db[key],bounds[1],bounds[2])
    end
    P.db.warning=math.max(P.db.warning,P.db.critical+1)
    P.ReadPet(); P.ReadAura(); P.ScanFood(); P.ReadAmmo()
    P.BuildHUD(); P.ready=true; P.Refresh(true);P.guide:Start();P.BuildMinimapButton()
    SLASH_PETPULSEFOREVER1="/petpulse"; SlashCmdList.PETPULSEFOREVER=P.Command
    for _,event in ipairs({"BAG_UPDATE_DELAYED","PLAYER_EQUIPMENT_CHANGED","GET_ITEM_INFO_RECEIVED","ITEM_LOCK_CHANGED",
        "UNIT_PET_EXPERIENCE","UNIT_PET","UNIT_HAPPINESS","UNIT_AURA","UNIT_LEVEL","UNIT_FLAGS","UNIT_HEALTH","UNIT_MAXHEALTH","UNIT_RESISTANCES","UNIT_STATS",
        "UNIT_PORTRAIT_UPDATE","PET_UI_UPDATE","PET_BAR_UPDATE","TRAINER_SHOW","TRAINER_UPDATE","TRAINER_CLOSED",
        "QUEST_LOG_UPDATE","QUEST_TURNED_IN","PLAYER_ENTERING_WORLD","PLAYER_REGEN_DISABLED","PLAYER_REGEN_ENABLED"}) do
        -- Version-specific event availability is checked without producing UI errors.
        pcall(events.RegisterEvent,events,event)
    end
    -- Low-frequency status fallback; never scans bags unless inventory/pet data changed.
    P.ticker=C_Timer.NewTicker(1,function()
        if P.alertUntil and GetTime()>P.alertUntil then P.hud.alert:SetText(""); P.alertUntil=nil end
        P.statusTicks=(P.statusTicks or 0)+1
        if P.statusTicks>=5 then P.statusTicks=0;P.Refresh()
        elseif P.feedAura then P.ReadAura();P.Paint()
        elseif P.tipKey=="feed" then P.Paint() end
    end)
end
events:RegisterEvent("PLAYER_LOGIN")
events:SetScript("OnEvent",function(_,event,unit)
    if event=="PLAYER_LOGIN" then initialize(); return end
    if not P.ready then return end
    if event:match("^UNIT_") and unit~="pet" and not (event=="UNIT_PET" and unit=="player") then return end
    if event=="UNIT_PET_EXPERIENCE" or event=="UNIT_HEALTH" or event=="UNIT_MAXHEALTH" then
        P.ReadPet(); P.Paint(); return
    end
    if event=="PLAYER_REGEN_DISABLED" then
        if P.foodMenu then P.foodMenu:Hide();GameTooltip:Hide() end
        P.pendingFood=nil
        P.SavePosition()
        -- Secure state drivers hide actions. The animated, unprotected HUD stays usable.
        P.Paint(); return
    elseif event=="PLAYER_REGEN_ENABLED" then
        P.CancelConfirmation();P.layoutDeferred=nil;P.ApplyLayout();P.Refresh(true);P.SyncSecure();return
    elseif event=="TRAINER_SHOW" then P.trainerOpen=true
    elseif event=="TRAINER_CLOSED" then P.trainerOpen=false; P.trainingOptions=nil end
    if inventoryEvents[event] or event=="UNIT_PET" then P.CancelConfirmation() end
    P.Schedule(inventoryEvents[event] or event=="QUEST_LOG_UPDATE" or event=="QUEST_TURNED_IN" or event=="UNIT_PET" or event=="PET_UI_UPDATE" or event=="PLAYER_ENTERING_WORLD")
end)
