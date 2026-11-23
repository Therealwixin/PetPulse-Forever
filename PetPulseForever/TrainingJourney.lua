local _,P=...
local G=P.guide
-- Reference locations, not live sightings. See TRAINING-GUIDE.md for provenance.
P.guideStables={}
local seeds={
 {"Erma",1429,42.9,65.9,"alliance"},{"Shelby Stoneflint",1426,47,52.7,"alliance"},
 {"Seriadne",1438,56.6,59.6,"alliance"},{"Shoja'my",1411,52,41.8,"horde"},
 {"Seikwa",1412,46,63.5,"horde"},{"Morganus",1420,60,52.2,"horde"},
 {"Jenova Stoneshield",1453,67.2,37.7,"alliance"},{"Ulbrek Firehand",1455,69.3,83.6,"alliance"},
 {"Alassin",1457,39.3,10,"alliance"},{"Xon'cha",1454,70.4,15,"horde"},
 {"Bulrug",1456,45.1,60.2,"horde"},{"Anya Maulray",1458,67.4,37.6,"horde"},
 {"Kirk Maxwell",1436,52.9,53.1,"alliance"},{"Penny",1433,21.7,46.6,"alliance"},
 {"Lina Hearthstove",1432,34.6,48.1,"alliance"},{"Sarah Goode",1421,43.4,41.2,"horde"},
 {"Sikwa",1413,51.7,29.7,"horde"},{"Reggifuz",1413,62.2,39.2,"both"},
 {"Laziphus",1446,52.3,28,"both"},{"Grimestack",1434,27.3,77.2,"both"},
 {"Azzleby",1452,60.4,37.9,"both"},{"Squire Leoren Mal'derath",1451,49.3,36.4,"both"},
 {"Maluressian",1440,36.5,50.4,"alliance"},{"Shyrka Wolfrunner",1444,74.5,43.3,"horde"},
}
for _,v in ipairs(seeds) do P.guideStables[v[1]]={name=v[1],ui_map_id=v[2],coords={{x=v[3],y=v[4]}},side=v[5]} end
local function xy(v)
    if not v or not v.GetXY then return end
    local x,y=v:GetXY();x=P.Plain(x);y=P.Plain(y)
    if type(x)=="number" and type(y)=="number" and x==x and y==y then return x,y end
end
function G:TravelDistance(map,point)
    if not map or not point then return end
    local zone=self:Zone();local pos=P.Call("C_Map.GetPlayerMapPosition",zone,"player")
    local px,py=xy(pos);if not px then return end
    local vector=P.Call("CreateVector2D",point.x/100,point.y/100)
    local ca,a=P.Call("C_Map.GetWorldPosFromMapPos",zone,pos)
    local cb,b=P.Call("C_Map.GetWorldPosFromMapPos",map,vector)
    local ax,ay=xy(a);local bx,by=xy(b)
    if ca and ca==cb and ax and bx then return (ax-bx)^2+(ay-by)^2,"world" end
    if map==zone then return (px*100-point.x)^2+(py*100-point.y)^2,"zone" end
end
function G:Nearest(candidates)
    local options={}
    for _,entry in ipairs(candidates) do
        local map,point=self:Location(entry.npc)
        local d,metric=self:TravelDistance(map,point)
        options[#options+1]={id=entry.id,npc=entry.npc,map=map,point=point,distance=d,metric=metric}
    end
    table.sort(options,function(a,b)
        -- World distances share units; map percentages never compare across zones.
        local ap=a.metric=="world" and 0 or a.metric=="zone" and 1 or a.map==self:Zone() and 2 or 3
        local bp=b.metric=="world" and 0 or b.metric=="zone" and 1 or b.map==self:Zone() and 2 or 3
        if ap~=bp then return ap<bp end
        if a.distance and b.distance and a.distance~=b.distance then return a.distance<b.distance end
        return a.npc.name<b.npc.name
    end)
    return options[1]
end
function G:NearestStable()
    local faction=P.Call("UnitFactionGroup","player");faction=faction and faction:lower()
    local all={};for key,npc in pairs(P.guideStables) do all[key]=npc end
    for key,npc in pairs(self:Store().stables or {}) do all[key]=npc end
    local candidates={}
    for key,npc in pairs(all) do
        if npc.side=="both" or npc.side==faction then candidates[#candidates+1]={id=key,npc=npc} end
    end
    return self:Nearest(candidates)
end
function G:RecordStable()
    -- Only a real stable interaction confirms the service, never an NPC name guess.
    local name=P.Call("UnitName","npc");local id=self:NPCID(P.Call("UnitGUID","npc"))
    local map=self:Zone();local pos=map and P.Call("C_Map.GetPlayerMapPosition",map,"player")
    local x,y=xy(pos);if not id or not name or not x or x<0 or x>1 or y<0 or y>1 then return end
    local faction=P.Call("UnitFactionGroup","player");if not faction then return end
    local store=self:Store();store.stables=store.stables or {}
    store.stables[name]={name=name,id=id,ui_map_id=map,coords={{x=x*100,y=y*100}},side=faction:lower(),observed=true}
end
function G:NearestSource(rank)
    local level=P.Call("UnitLevel","player");local candidates={}
    for _,e in ipairs(self:Sources(rank)) do
        -- Require the whole level range to be tameable; do not promise an unknown level.
        if type(level)=="number" and e.npc.min and (e.npc.max or e.npc.min)<=level then candidates[#candidates+1]=e end
    end
    return self:Nearest(candidates)
end
function G:PlaceText(entry)
    if not entry then return P.T("Location unknown") end
    return entry.npc.name.." — "..self:MapName(entry.map)..(entry.point and string.format(" (%.1f, %.1f)",entry.point.x,entry.point.y) or "")
end
function G:Journey(rank)
    local lines={};local status=self:Status(rank)
    if status=="Pet already knows" or status=="Different family" then return P.T(status) end
    if self:Known(rank)==true then
        return P.T("Open Beast Training; no taming needed.").." "..P.T(status)
    elseif self:Known(rank)==nil then return P.T("Verify hunter knowledge in Beast Training first.")
    elseif rank.ability.trainer then return P.T("Visit a pet trainer, learn the rank, then teach it through Beast Training.") end
    local stable=self:NearestStable();local source=self:NearestSource(rank)
    lines[#lines+1]=P.T("Stable your main pet")..": "..(stable and self:PlaceText(stable) or P.T("No recorded friendly stable master."))
    lines[#lines+1]=P.T("Then tame")..": "..(source and self:PlaceText(source) or P.T("No documented source within your level."))
    lines[#lines+1]=P.T("Use the ability until learned, then retrieve your main pet and train it.")
    lines[#lines+1]=P.T("Closest recorded points where measurable; not a walking route. Reference locations may differ on Forever.")
    return table.concat(lines,"\n"),stable,source
end
function G:LevelUnlocks(pet,oldLevel)
    local best={}
    for _,rank in pairs(self.bySpell) do
        if self:Compatible(rank,pet) and pet.spells and rank.pet_level>oldLevel and rank.pet_level<=pet.level
            and (pet.spells[rank.ability.key] or 0)<rank.rank then
            local prev=best[rank.ability.key]
            if not prev or rank.rank>prev.rank then best[rank.ability.key]=rank end
        end
    end
    local out={};for _,r in pairs(best) do out[#out+1]=r end
    table.sort(out,function(a,b) if a.ability.passive~=b.ability.passive then return not a.ability.passive end;return a.ability.name<b.ability.name end)
    return out
end
function G:CheckLevel(pet)
    if not pet or self:Store().focus~=pet.guid or type(pet.level)~="number" or pet.level<1 then return end
    self.levelSeen=self.levelSeen or {};local old=self.levelSeen[pet.guid];self.levelSeen[pet.guid]=pet.level
    -- Session baseline suppresses login/reload and summon notifications.
    if not old or pet.level<=old or self:Store().levelAlerts==false then return end
    self.pendingLevel=self.pendingLevel or {guid=pet.guid,old=old}
    if self.pendingLevel.guid~=pet.guid then self.pendingLevel={guid=pet.guid,old=old} end
end
function G:FlushLevelAlert()
    local pending=self.pendingLevel;if not pending or InCombatLockdown() then return end
    local pet=self:Focus();if not pet or pet.guid~=pending.guid then self.pendingLevel=nil;return end
    if not pet.spells then return end -- Wait for the pet spellbook event, not a guessed empty book.
    self.pendingLevel=nil
    if self:Store().levelAlerts==false then return end
    local ranks=self:LevelUnlocks(pet,pending.old);P.ShowPetLevelUp(pet,ranks);if #ranks==0 then return end
    local names={};local saved={}
    for _,rank in ipairs(ranks) do names[#names+1]=self:RankName(rank);saved[#saved+1]=rank.spell_id end
    self:Store().lastUnlock={guid=pet.guid,level=pet.level,spells=saved}
    P.Alert("guideLevel",pet.name.." · "..P.T("New training options")..": "..names[1]..(#names>1 and " (+"..(#names-1)..")" or ""),false)
    P.Message(pet.name.." · "..P.T("Level").." "..pet.level..": "..table.concat(names,", "))
    for _,rank in ipairs(ranks) do P.Message(self:RankName(rank).."\n"..self:Journey(rank)) end
    P.Message(P.T("Open /petpulse training for details and map pins."))
end

-- Curated role-based picks, reviewed 2026-11-22; see PET-PICKS.md.
P.petPicks={
 [5807]={role="Damage / PvP",reason="Fast cat: damage and caster pressure."},
 [2850]={role="Damage / PvP",reason="Fast cat: damage and caster pressure."},
 [4124]={role="Damage / PvP",reason="Fast cat: damage and caster pressure."},
 [767]={role="Damage / PvP",reason="Fast cat: damage and caster pressure."},
 [8299]={role="Leveling / Utility",reason="Carrion bird: damage with Demoralizing Screech utility."},
 [3862]={role="Group utility",reason="Fast wolf with Furious Howl utility; dungeon tame."},
 [276111]={role="Rare appearance",reason="Distinctive rare cat appearance; rarity alone is not a damage advantage."},
 [5828]={role="Rare appearance",reason="Distinctive rare cat appearance; rarity alone is not a damage advantage."},
}
function G:FamilyIcon(family)
    for _,f in ipairs(P.moodFamilies) do if f.name==family then return P.MoodTexture(f.key,"happy") end end
    return "Interface\\Icons\\INV_Misc_QuestionMark"
end
function G:ChooseMain(guid)
    local store=self:Store();if not store.pets[guid] then return end
    store.focus=guid;store.mainChosen=true;store.plan=nil;self.pendingLevel=nil
    return store.pets[guid]
end
function G:PetOverview()
    local pet=self:Focus();local counts={ready=0,learn=0,blocked=0,unknown=0};local list={}
    if not pet or not pet.spells or not pet.level then return list,counts,pet and "Pet abilities unavailable" or "Choose your main pet" end
    for _,ability in pairs(P.guideAbilities) do
        local ready,best
        for _,rank in ipairs(ability.ranks) do
            if self:Compatible(rank,pet) and pet.level and rank.pet_level<=pet.level and rank.rank>(pet.spells[ability.key] or 0) then
                local status=self:Status(rank,pet)
                if status=="Ready for Beast Training" and (not ready or ready.rank<rank.rank) then ready=rank end
                if not best or best.rank<rank.rank then best=rank end
            end
        end
        local rank=ready or best
        if rank then
            local status=self:Status(rank,pet)
            local category=status=="Ready for Beast Training" and "ready" or
                (status=="Learn by taming" or status=="Visit pet trainer") and "learn" or
                status=="Hunter knowledge unverified" and "unknown" or "blocked"
            counts[category]=counts[category]+1
            list[#list+1]={rank=rank,status=status,category=category}
        end
    end
    local order={ready=1,learn=2,blocked=3,unknown=4}
    table.sort(list,function(a,b)if order[a.category]~=order[b.category] then return order[a.category]<order[b.category] end;return a.rank.ability.name<b.rank.ability.name end)
    local status=counts.ready>0 and "Ready to teach now" or counts.learn>0 and "New abilities to learn" or
        counts.blocked>0 and "Training requirements missing" or counts.unknown>0 and "Hunter knowledge unverified" or "Up to date for this level"
    return list,counts,status
end
function G:BrowseEntries(mode,query,family,levelOnly,zoneOnly)
    local list={};query=(query or ""):lower();local level=P.Call("UnitLevel","player");local zone=self:Zone()
    for id,npc in pairs(P.guideNPCs) do
        local pick=P.petPicks[id];local max=npc.max or npc.min
        local eligible=type(level)=="number" and max and level>=math.max(10,max)
        if (mode~="picks" or pick) and (not family or npc.family==family) and
            (not levelOnly or eligible) and (not zoneOnly or self:InZone(npc,zone)) then
            local hay=npc.name.." "..(npc.family or "")
            if query~="" then
                for map in pairs(npc.maps or {}) do hay=hay.." "..self:MapName(map) end
                if npc.map then hay=hay.." "..self:MapName(npc.map) end
            end
            if query=="" or hay:lower():find(query,1,true) then
                list[#list+1]={id=id,npc=npc,pick=pick,eligible=eligible,levelKnown=max~=nil,
                    status=not max and "Level unknown" or eligible and "Level requirement met" or "Higher level required"}
            end
        end
    end
    table.sort(list,function(a,b)
        if mode=="picks" and (a.eligible==true)~=(b.eligible==true) then return a.eligible==true end
        if mode=="picks" and (a.npc.min or 999)~=(b.npc.min or 999) then return (a.npc.min or 999)<(b.npc.min or 999) end
        if a.npc.name~=b.npc.name then return a.npc.name<b.npc.name end;return a.id<b.id
    end)
    return list
end

function G:PetIdentity(pet)
    return pet and pet.name and pet.family and pet.name.."\031"..pet.family
end
function G:SavedPets()
    -- Group summon snapshots for display without deleting historical observations.
    local groups={};local active=P.pet and P.pet.exists and P.pet.guid
    for guid,pet in pairs(self:Store().pets)do
        local key=self:PetIdentity(pet) or guid;local prior=groups[key]
        if not prior or guid==active or (prior.guid~=active and
            ((pet.updated or 0)>(prior.pet.updated or 0) or
            (pet.updated or 0)==(prior.pet.updated or 0) and ((pet.level or 0)>(prior.pet.level or 0) or
            (pet.level or 0)==(prior.pet.level or 0) and guid<prior.guid))) then groups[key]={guid=guid,pet=pet}end
    end
    local out={};for _,entry in pairs(groups)do out[#out+1]=entry end
    table.sort(out,function(a,b)if a.pet.name~=b.pet.name then return a.pet.name<b.pet.name end;return a.pet.family<b.pet.family end)
    return out
end
function G:PaintMainPortrait(texture)
    local pet=self:Focus();local live=pet and P.pet.exists and pet.guid==P.pet.guid
    if live then
        SetPortraitTexture(texture,"pet")
        local image=texture.GetTexture and texture:GetTexture()
        if type(image)=="string" or type(image)=="number" then pet.portrait=image end
    elseif pet and pet.portrait then texture:SetTexture(pet.portrait)
    else
        local family=pet and pet.family or "Cat"
        local names={["Bird of Prey"]="Owl",["Carrion Bird"]="Vulture",["Wind Serpent"]="WindSerpent",["Core Hound"]="CoreHound"}
        texture:SetTexture("Interface\\Icons\\Ability_Hunter_Pet_"..(names[family] or family:gsub(" ","")))
    end
end
function G:Upcoming()
    local pet=self:Focus();local out={}
    if not pet or not pet.level or not pet.spells then return out end
    for _,ability in pairs(P.guideAbilities)do
        local best
        for _,rank in ipairs(ability.ranks)do
            if self:Compatible(rank,pet) and rank.pet_level>pet.level and rank.rank>(pet.spells[ability.key] or 0) then
                if not best or rank.pet_level<best.pet_level or rank.pet_level==best.pet_level and rank.rank<best.rank then best=rank end
            end
        end
        if best then out[#out+1]={rank=best,status="Pet level too low",future=true}end
    end
    table.sort(out,function(a,b)if a.rank.pet_level~=b.rank.pet_level then return a.rank.pet_level<b.rank.pet_level end;return a.rank.ability.name<b.rank.ability.name end)
    return out
end
