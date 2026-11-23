local _,P=...
local G={bySpell={},byLearn={},byNPC={},knownNow={},alerts={},pointCache={}}
P.guide=G
function G:Store()
    if not P.db.guide then P.db.guide={known={},pets={},observed={},tooltips=true,alerts=true} end
    return P.db.guide
end
function G:Init()
    for key,ability in pairs(P.guideAbilities) do
        ability.key=key
        for _,rank in ipairs(ability.ranks) do
            rank.ability=ability;self.bySpell[rank.spell_id]=rank
            if rank.learn_id then self.byLearn[rank.learn_id]=rank end
            for _,npc in ipairs(rank.npc_ids or {}) do
                self.byNPC[npc]=self.byNPC[npc] or {};table.insert(self.byNPC[npc],rank)
            end
        end
    end
end
function G:Name(rank)
    return P.Call("C_Spell.GetSpellName",rank.spell_id) or rank.ability.name
end
function G:RankName(rank) return self:Name(rank).." "..P.T("Rank").." "..rank.rank end
function G:NPCID(guid)
    if type(guid)~="string" or not guid:match("^Creature%-") then return end
    local fields={};for v in guid:gmatch("[^%-]+") do fields[#fields+1]=v end
    return tonumber(fields[6])
end
function G:Family(text)
    if type(text)~="string" then return end
    for _,family in ipairs(P.moodFamilies) do
        if family.id and (text==family.name or text==P.Call("GetPetFamilyInfo",family.id)) then return family.name end
    end
end
function G:Known(rank)
    if self:Store().known[rank.spell_id] then return true end
    return self.knownNow[rank.spell_id]
end
function G:Remember(rank)
    if not rank then return end
    local store=self:Store();local fresh=not store.known[rank.spell_id]
    store.known[rank.spell_id]=true;self.knownNow[rank.spell_id]=true
    if fresh and store.plan==rank.spell_id then
        P.Alert("guideLearned",P.T("New ability learned")..": "..self:RankName(rank),false)
    end
end
function G:ScanHunter()
    for _,rank in pairs(self.bySpell) do
        if rank.learn_id then
            local a=P.Call("IsPlayerSpell",rank.learn_id)
            local b=P.Call("C_SpellBook.IsSpellKnown",rank.learn_id)
            if a==true or b==true then self:Remember(rank)
            elseif a==false or b==false then self.knownNow[rank.spell_id]=false end
        end
    end
end
function G:ReadPetSpells()
    local n=P.Call("C_SpellBook.HasPetSpells") or P.Call("HasPetSpells")
    if type(n)~="number" or n<1 or n>500 then return end
    local spells,active={},0
    local bank=Enum and Enum.SpellBookSpellBank and Enum.SpellBookSpellBank.Pet
    for i=1,n do
        local id,passive
        local info=bank and P.Call("C_SpellBook.GetSpellBookItemInfo",i,bank)
        if type(info)=="table" then id=P.Plain(info.spellID);passive=P.Plain(info.isPassive)
        else local _,raw=P.Call("GetSpellBookItemInfo",i,BOOKTYPE_PET or "pet");if type(raw)=="number" then id=raw%16777216 end end
        if id then
            local rank=self.bySpell[id]
            if rank then
                spells[rank.ability.key]=math.max(spells[rank.ability.key] or 0,rank.rank)
                if not rank.ability.passive and passive~=true then active=active+1 end
            end
        end
    end
    return spells,active
end
function G:Snapshot(useCurrent)
    local s=P.pet;if not s or not s.exists or s.dead or not s.guid or not s.name then return end
    local family=self:Family(s.family);if not family then return end
    local store=self:Store();local old=store.pets[s.guid]
    local previous=store.pets[store.focus]
    local returning=previous and previous.guid~=s.guid and previous.name==s.name and previous.family==family
    if returning then old=old or previous end
    local spells,active=self:ReadPetSpells()
    local pet={guid=s.guid,name=s.name,family=family,level=s.level,tp=s.tp,spells=spells or old and old.spells,
        portrait=old and old.portrait,active=active or old and old.active,updated=P.Call("GetServerTime")}
    store.pets[s.guid]=pet
    if useCurrent or not store.focus or returning then
        if returning and self.levelSeen then self.levelSeen[s.guid]=self.levelSeen[previous.guid] end
        if returning and self.pendingLevel and self.pendingLevel.guid==previous.guid then self.pendingLevel.guid=s.guid end
        store.focus=s.guid
    end
    -- A stabled target stays pinned while a temporary pet is used to learn.
    self:CheckLevel(pet)
    return pet
end
function G:Focus() local s=self:Store();return s.pets[s.focus] end
function G:Compatible(rank,pet)
    if not pet or not pet.family then return false end
    if #rank.ability.learned_by==0 then return true end
    for _,family in ipairs(rank.ability.learned_by) do if family==pet.family then return true end end
    return false
end
function G:Status(rank,pet)
    pet=pet or self:Focus()
    if not pet then return "Select a pet" end
    if not self:Compatible(rank,pet) then return "Different family" end
    if not pet.spells then return "Pet abilities unavailable" end
    local current=pet.spells[rank.ability.key] or 0
    if current>=rank.rank then return "Pet already knows" end
    if not pet.level or pet.level<rank.pet_level then return "Pet level too low" end
    local known=self:Known(rank)
    if known==nil then return "Hunter knowledge unverified" end
    if not known then return rank.ability.trainer and "Visit pet trainer" or "Learn by taming" end
    if not P.pet.exists or pet.guid~=P.pet.guid then return "Return to your selected pet" end
    local oldCost=0
    for _,r in ipairs(rank.ability.ranks) do if r.rank==current then oldCost=r.training_cost or 0 end end
    local cost=math.max(0,(rank.training_cost or 0)-oldCost)
    if cost>0 and (not pet.tp or pet.tp<cost) then return "Needs training points" end
    if current==0 and not rank.ability.passive and pet.active and pet.active>=4 then return "Active ability slots full" end
    return "Ready for Beast Training"
end
function G:Zone()
    local map=P.Call("C_Map.GetBestMapForUnit","player")
    local zoneType=Enum and Enum.UIMapType and Enum.UIMapType.Zone
    for _=1,8 do
        local info=map and P.Call("C_Map.GetMapInfo",map)
        if not info or not zoneType or not P.Plain(info.mapType) or info.mapType<=zoneType or not info.parentMapID or info.parentMapID==0 then break end
        map=info.parentMapID
    end
    -- Some Forever situations return a continent; resolve only an exact live zone name.
    local zoneName=P.Call("GetRealZoneText")
    local info=map and P.Call("C_Map.GetMapInfo",map)
    if map and zoneName and info and P.Plain(info.name)~=zoneName then
        local children=P.Call("C_Map.GetMapChildrenInfo",map,zoneType,true)
        local match
        for _,child in ipairs(children or {}) do
            if P.Plain(child.name)==zoneName and P.Plain(child.mapID) then
                if match then match=nil;break end
                match=child.mapID
            end
        end
        if match then map=match end
    end
    return map
end
function G:MapName(id)
    local info=id and P.Call("C_Map.GetMapInfo",id)
    return info and P.Plain(info.name) or (id and "Map "..id or P.T("Location unknown"))
end
function G:InZone(npc,map)
    if not map then return false end
    return npc.map==map or npc.ui_map_id==map or npc.maps and npc.maps[map]~=nil
end
function G:Points(npc,map)
    local packed=npc.maps and npc.maps[map]
    if not packed then return npc.ui_map_id==map and npc.coords or {} end
    if self.pointCache[packed] then return self.pointCache[packed] end
    local alphabet="ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";local values={}
    for i=1,#alphabet do values[alphabet:sub(i,i)]=i-1 end
    local points={}
    for i=1,#packed-2,3 do
        local a,b,c=values[packed:sub(i,i)],values[packed:sub(i+1,i+1)],values[packed:sub(i+2,i+2)]
        if a and b and c then
            local n=a*4096+b*64+c;local x,y=math.floor(n/501)/5,(n%501)/5
            if x<=100 and y<=100 then points[#points+1]={x=x,y=y} end
        end
    end
    self.pointCache[packed]=points;return points
end
function G:Location(npc)
    local zone=self:Zone();local map
    if self:InZone(npc,zone) then map=zone else
        for id in pairs(npc.maps or {}) do if not map or id<map then map=id end end
        map=map or npc.map or npc.ui_map_id
    end
    local points=self:Points(npc,map);local best=points[1];local distance
    local pos=map==zone and P.Call("C_Map.GetPlayerMapPosition",map,"player")
    local px,py;if pos and pos.GetXY then px,py=pos:GetXY();px=P.Plain(px);py=P.Plain(py) end
    if type(px)=="number" and type(py)=="number" then
        for _,point in ipairs(points) do
            local d=(px*100-point.x)^2+(py*100-point.y)^2
            if not distance or d<distance then best=point;distance=d end
        end
    end
    return map,best,distance
end
function G:Taught(id)
    local out={};local observed=self:Store().observed[id];local overrides={}
    for spell in pairs(observed or {}) do
        local rank=self.bySpell[spell];if rank then overrides[rank.ability.key]=true;out[#out+1]=rank end
    end
    for _,rank in ipairs(self.byNPC[id] or {}) do if not overrides[rank.ability.key] then out[#out+1]=rank end end
    table.sort(out,function(a,b) if a.ability.name~=b.ability.name then return a.ability.name<b.ability.name end;return a.rank<b.rank end)
    return out
end
function G:ObserveSpell(npc,spell,method)
    local rank=self.bySpell[spell];if not rank or not P.guideNPCs[npc] then return end
    local store=self:Store();store.observed[npc]=store.observed[npc] or {}
    -- New positive observations replace conflicting catalog ranks for this ability.
    for id in pairs(store.observed[npc]) do
        if self.bySpell[id] and self.bySpell[id].ability==rank.ability then store.observed[npc][id]=nil end
    end
    store.observed[npc][spell]=method
end
function G:Sources(rank)
    local list={};local seen={}
    for _,npcid in ipairs(rank.npc_ids or {}) do seen[npcid]=true end
    for npcid,observed in pairs(self:Store().observed) do if observed[rank.spell_id] then seen[npcid]=true end end
    for id in pairs(seen) do
        for _,taught in ipairs(self:Taught(id)) do
            if taught==rank and P.guideNPCs[id] then list[#list+1]={id=id,npc=P.guideNPCs[id]};break end
        end
    end
    return list
end
local priorities={["Ready for Beast Training"]=1,["Return to your selected pet"]=2,["Learn by taming"]=3,
    ["Visit pet trainer"]=4,["Needs training points"]=5,["Active ability slots full"]=6,["Hunter knowledge unverified"]=7}
function G:Entries(mode,query)
    query=(query or ""):lower();local list={};local zone=self:Zone();local pet=self:Focus();local playerLevel=P.Call("UnitLevel","player")
    local function add(rank,id,npc,status)
        local hay=(rank and self:RankName(rank) or "").." "..(npc and npc.name or "").." "..(npc and npc.family or "")
        if query~="" and not hay:lower():find(query,1,true) then return end
        local map,point,distance;if npc then map,point,distance=self:Location(npc) end
        list[#list+1]={rank=rank,id=id,npc=npc,status=status,map=map,point=point,distance=distance,localZone=npc and self:InZone(npc,zone)}
    end
    if mode=="beasts" then
        for id,npc in pairs(P.guideNPCs) do add(nil,id,npc,"Known habitat") end
    else
        for _,rank in pairs(self.bySpell) do
            local status=self:Status(rank,pet)
            if mode=="abilities" or priorities[status] then
                if mode=="abilities" then add(rank,nil,nil,status)
                elseif status=="Learn by taming" or status=="Hunter knowledge unverified" then
                    for _,source in ipairs(self:Sources(rank)) do
                        local n=source.npc
                        if (mode~="zone" or self:InZone(n,zone)) and (not n.min or not playerLevel or n.min<=playerLevel) then
                            add(rank,source.id,n,status)
                        end
                    end
                elseif status=="Visit pet trainer" then
                    local faction=P.Call("UnitFactionGroup","player");faction=type(faction)=="string" and faction:lower()
                    for id,n in pairs(P.guideTrainers) do
                        if (not n.side or n.side==faction or n.side=="both") and (mode~="zone" or self:InZone(n,zone)) then add(rank,id,n,status) end
                    end
                else add(rank,nil,nil,status) end
            end
        end
    end
    table.sort(list,function(a,b)
        local pa,pb=priorities[a.status] or 20,priorities[b.status] or 20
        if pa~=pb then return pa<pb end
        if a.localZone~=b.localZone then return a.localZone==true end
        if a.distance and b.distance and a.distance~=b.distance then return a.distance<b.distance end
        if a.rank and b.rank and a.rank.ability==b.rank.ability and a.rank.rank~=b.rank.rank then return a.rank.rank>b.rank.rank end
        local na=(a.rank and self:RankName(a.rank) or "")..(a.npc and a.npc.name or "")
        local nb=(b.rank and self:RankName(b.rank) or "")..(b.npc and b.npc.name or "")
        if na~=nb then return na<nb end
        return (a.id or 0)<(b.id or 0)
    end)
    return list
end
function G:Pin(entry)
    if not entry.map then P.Message(P.T("Location unknown"));return end
    if WorldMapFrame then WorldMapFrame:Show();if WorldMapFrame.SetMapID then WorldMapFrame:SetMapID(entry.map) end end
    if entry.point and UiMapPoint and UiMapPoint.CreateFromCoordinates then
        local allowed=P.Call("C_Map.CanSetUserWaypointOnMap",entry.map)
        if allowed~=false then
            P.Call("C_Map.SetUserWaypoint",UiMapPoint.CreateFromCoordinates(entry.map,entry.point.x/100,entry.point.y/100))
            P.Call("C_SuperTrack.SetSuperTrackedUserWaypoint",true)
        end
    end
end
function G:TrainerSnapshot()
    local count=P.Call("GetNumTrainerServices") or P.Call("C_Trainer.GetNumTrainerServices")
    if type(count)~="number" then return end
    if P.Call("C_Trainer.GetTrainerType")~= (Enum.TrainerType and Enum.TrainerType.Pet) then return end
    local atNPC=P.Call("UnitExists","npc")==true
    for i=1,count do
        local name,status=P.Call("GetTrainerServiceInfo",i)
        local link=P.Call("GetTrainerServiceItemLink",i)
        local id=type(link)=="string" and tonumber(link:match("spell:(%d+)"))
        local tip=not id and P.Call("C_TooltipInfo.GetTrainerService",i)
        id=id or tip and P.Plain(tip.id)
        local rank=self.bySpell[id] or self.byLearn[id]
        -- At a real trainer, available offerings are NOT hunter-known skills.
        if rank and (not atNPC or status=="used") then self:Remember(rank) end
    end
end
function G:Tooltip(tip,data)
    if not P.ready or not self:Store().tooltips then return end
    local _,unit=tip:GetUnit();local guid=P.Plain(data and data.guid) or unit and P.Call("UnitGUID",unit)
    local id=self:NPCID(guid);local npc=id and P.guideNPCs[id];if not npc then return end
    if tip.petPulseGuideGUID==guid then return end
    tip.petPulseGuideGUID=guid
    tip:AddLine(" ");tip:AddLine("PetPulse · "..P.T("Training guide"),.95,.8,.5)
    local taught=self:Taught(id)
    if #taught==0 then tip:AddLine(P.T("Abilities unverified — use Beast Lore"),.7,.7,.7,true) end
    for _,rank in ipairs(taught) do
        local status=self:Status(rank)
        local icon=P.Call("C_Spell.GetSpellTexture",rank.spell_id) or P.Call("GetSpellTexture",rank.spell_id)
        if type(icon)~="number" and type(icon)~="string" then icon="Interface\\Icons\\INV_Misc_QuestionMark" end
        local title="|T"..tostring(icon)..":28:28:0:0|t  "..self:RankName(rank)
        tip:AddLine(title.." — "..P.T(status),status=="Learn by taming" and .45 or .9,.86,.6,true)
    end
    tip:AddLine(P.T("Tame and use the ability; killing does not teach it."),.7,.72,.75,true)
    tip:Show()
end
function G:Detect(unit)
    if not P.ready or InCombatLockdown() or P.Call("UnitIsDeadOrGhost",unit)==true or P.Call("UnitPlayerControlled",unit)==true then return end
    local id=self:NPCID(P.Call("UnitGUID",unit));if not id or not P.guideNPCs[id] then return end
    self:ReadLore(unit,id)
    if not self:Store().alerts then return end
    local level=P.Call("UnitLevel",unit);local player=P.Call("UnitLevel","player")
    if type(level)~="number" or level<1 or not player or level>player then return end
    local upgrades={}
    for _,rank in ipairs(self:Taught(id)) do if self:Status(rank)=="Learn by taming" then upgrades[#upgrades+1]=self:RankName(rank) end end
    if #upgrades==0 or GetTime()-(self.alerts[id] or -1000)<600 then return end
    self.alerts[id]=GetTime()
    P.Alert("guideNearby",P.T("Training opportunity")..": "..(P.Call("UnitName",unit) or P.guideNPCs[id].name).." — "..upgrades[1]..(#upgrades>1 and " (+"..(#upgrades-1)..")" or ""),false)
end
function G:ReadLore(unit,id)
    local lore=false
    for i=1,40 do
        local aura=P.Call("C_UnitAuras.GetAuraDataByIndex",unit,i,"HARMFUL");if not aura then break end
        if P.Plain(aura.spellId)==1462 then lore=true;break end
    end
    if not lore then return end
    local tip=P.Call("C_TooltipInfo.GetUnit",unit)
    for _,line in ipairs(tip and tip.lines or {}) do
        local text=P.Plain(line.leftText)
        if type(text)=="string" then
            for spell in text:gmatch("|Hspell:(%d+)") do self:ObserveSpell(id,tonumber(spell),"Beast Lore") end
            for spell,rank in pairs(self.bySpell) do
                local sub=P.Call("C_Spell.GetSpellSubtext",spell)
                if sub and sub~="" and text:find(self:Name(rank),1,true) and (text.." "):find(sub:gsub("([^%w])","%%%1").."%f[^%d]") then self:ObserveSpell(id,spell,"Beast Lore") end
            end
        end
    end
end
function G:Refresh()
    P.ReadPet();self:ScanHunter();self:Snapshot(false);self:FlushLevelAlert()
    if P.guideWindow and P.guideWindow:IsShown() then P.RefreshGuideWindow() end
end
function G:Schedule()
    if self.scheduled then return end;self.scheduled=true
    C_Timer.After(.3,function() self.scheduled=false;if P.ready then self:Refresh() end end)
end
function G:LearnMessage(text)
    if type(text)~="string" then return end
    local templates={ERR_LEARN_ABILITY_S or "You have learned a new ability: %s.",ERR_LEARN_SPELL_S or "You have learned a new spell: %s."}
    for _,template in ipairs(templates) do
        local pattern="^"..template:gsub("%%s","\001"):gsub("([%^%$%(%)%%%.%[%]%*%+%-%?])","%%%1"):gsub("\001","(.+)").."$"
        local payload=text:match(pattern)
        if payload then
            local id=tonumber(payload:match("|Hspell:(%d+)"))
            if id then self:Remember(self.byLearn[id] or self.bySpell[id]) end
            self:Schedule();return
        end
    end
end
function G:Start()
    self:Init();self:Refresh()
    if TooltipDataProcessor and Enum.TooltipDataType and Enum.TooltipDataType.Unit then
        TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Unit,function(tip,data) if tip==GameTooltip then self:Tooltip(tip,data) end end)
    else pcall(GameTooltip.HookScript,GameTooltip,"OnTooltipSetUnit",function(tip) self:Tooltip(tip) end) end
    pcall(GameTooltip.HookScript,GameTooltip,"OnTooltipCleared",function(tip) tip.petPulseGuideGUID=nil end)
    local f=CreateFrame("Frame");self.events=f
    for _,event in ipairs({"PET_STABLE_SHOW","CHAT_MSG_SYSTEM","PLAYER_ENTERING_WORLD","PLAYER_LEVEL_UP","SPELLS_CHANGED","LEARNED_SPELL_IN_TAB","PET_BAR_UPDATE","PET_UI_UPDATE","UNIT_PET","UNIT_LEVEL","UNIT_PET_EXPERIENCE","TRAINER_SHOW","TRAINER_UPDATE","ZONE_CHANGED_NEW_AREA","ZONE_CHANGED","PLAYER_TARGET_CHANGED","UPDATE_MOUSEOVER_UNIT","NAME_PLATE_UNIT_ADDED","UNIT_AURA","UNIT_SPELLCAST_CHANNEL_START","UNIT_SPELLCAST_SUCCEEDED","PLAYER_REGEN_ENABLED"}) do pcall(f.RegisterEvent,f,event) end
    f:SetScript("OnEvent",function(_,event,unit,cast,spell)
        if event=="PET_STABLE_SHOW" then self:RecordStable()
        elseif event=="CHAT_MSG_SYSTEM" then self:LearnMessage(P.Plain(unit))
        elseif event=="UPDATE_MOUSEOVER_UNIT" then self:Detect("mouseover")
        elseif event=="PLAYER_TARGET_CHANGED" then self:Detect("target")
        elseif event=="NAME_PLATE_UNIT_ADDED" then self:Detect(unit)
        elseif event=="UNIT_AURA" then if unit=="target" or unit=="mouseover" then self:Detect(unit) end
        elseif event=="UNIT_SPELLCAST_CHANNEL_START" and unit=="player" and spell==1515 then
            self.tame={id=self:NPCID(P.Call("UnitGUID","target")),oldGUID=P.pet.guid,time=GetTime()}
        elseif event=="UNIT_SPELLCAST_SUCCEEDED" and unit=="player" and spell==1515 then
            local tame=self.tame
            if tame and tame.id and GetTime()-tame.time<30 then
                C_Timer.After(2,function()
                    local pet=self:Snapshot(false)
                    if pet and pet.guid~=tame.oldGUID then
                        for key,rankNum in pairs(pet.spells or {}) do
                            for _,rank in ipairs(P.guideAbilities[key].ranks) do if rank.rank==rankNum then self:ObserveSpell(tame.id,rank.spell_id,"Tamed") end end
                        end
                    end
                end)
            end
        elseif event=="TRAINER_SHOW" or event=="TRAINER_UPDATE" then self:TrainerSnapshot();self:Schedule()
        elseif event=="LEARNED_SPELL_IN_TAB" then self:Remember(self.byLearn[P.Plain(unit)]);self:Schedule()
        else self:Schedule() end
    end)
end
