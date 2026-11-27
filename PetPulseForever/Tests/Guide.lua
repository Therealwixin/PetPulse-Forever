local P=TEST_NS;local G=P.guide;local n=0
local bite=P.guideAbilities.bite.ranks[2]
local function vector(x,y)return {GetXY=function()return x,y end}end
local function reset()
    GetRealZoneText=nil;COMBAT=false;NOW=100;P.db.language="EN";P.db.guide={known={},pets={},observed={},tooltips=true,alerts=true}
    G.knownNow={};G.alerts={};G.levelSeen={};G.pendingLevel=nil;G.scheduled=nil;TIMERS={}
    P.pet={exists=true,guid="main",name="Mittens",family="Cat",level=7,tp=100}
    P.db.guide.focus="main";P.db.guide.pets.main={guid="main",name="Mittens",family="Cat",level=7,tp=100,spells={bite=1},active=1}
    UnitLevel=function(unit)return unit=="player" and 30 or P.pet.level end
    UnitFactionGroup=function()return "Alliance"end
    IsPlayerSpell=function()return false end;IsSpellKnown=nil;Enum.SpellBookSpellBank=nil;C_SpellBook=nil;HasPetSpells=function()return 1 end
    GetSpellBookItemInfo=function()return "SPELL",P.guideAbilities.bite.ranks[1].spell_id end
    C_Map={GetBestMapForUnit=function()return 1429 end,GetMapInfo=function(id)return {name="Zone "..id}end,
        GetPlayerMapPosition=function()return vector(.43,.66)end}
    C_Spell=nil;CreateVector2D=vector;UnitExists=function(unit)return unit~="npc"end
    UnitGUID=function(unit)return unit=="pet" and "main" or "Creature-0-0-0-0-118-12345"end
    UnitName=function(unit)return unit=="npc" and "Erma" or "Mittens"end
    UnitIsDeadOrGhost=function()return false end;UnitPlayerControlled=function()return false end
    G:ScanHunter()
end
local function test(name,fn)reset();fn();n=n+1;print("PASS guide: "..name)end

test("catalog IDs, families, ranks and all compressed habitat bounds",function()
    local a,r,c=0,0,0
    for _,ability in pairs(P.guideAbilities)do a=a+1;local prev=0
        for _,rank in ipairs(ability.ranks)do r=r+1;assert(rank.rank>prev and G.bySpell[rank.spell_id]==rank);prev=rank.rank
            for _,id in ipairs(rank.npc_ids or {})do assert(P.guideNPCs[id],id)end
        end
    end
    for _,npc in pairs(P.guideNPCs)do c=c+1
        for map,packed in pairs(npc.maps or {})do assert(#packed%3==0);local points=G:Points(npc,map);assert(#points==#packed/3)
            for _,p in ipairs(points)do assert(p.x>=0 and p.x<=100 and p.y>=0 and p.y<=100)end
        end
    end
    assert(a==32 and r==155 and c==813)
end)
test("hunter knowledge uses learn spell, never the active pet spell",function()
    IsPlayerSpell=function(id)return id==bite.spell_id end;G:ScanHunter();assert(G:Known(bite)==false)
    IsPlayerSpell=function(id)return id==bite.learn_id end;G:ScanHunter();assert(G:Known(bite)==true)
end)
test("missing knowledge API stays unknown",function()
    IsPlayerSpell=nil;G.knownNow={};G:ScanHunter();assert(G:Known(bite)==nil)
    G:Focus().level=20;assert(G:Status(bite)=="Hunter knowledge unverified")
end)
test("temporary pet does not replace the pinned main",function()
    P.pet.guid="temporary";P.pet.name="Teacher";G:Snapshot(false)
    assert(G:Focus().name=="Mittens" and G:Store().pets.temporary.name=="Teacher")
    G:Snapshot(true);assert(G:Focus().name=="Teacher")
end)
test("family and pet level gate recommendations",function()
    assert(G:Status(bite)=="Pet level too low");G:Focus().level=8;assert(G:Status(bite)=="Learn by taming")
    G:Focus().family="Crab";assert(G:Status(bite)=="Different family")
end)
test("known rank uses incremental training cost",function()
    local pet=G:Focus();pet.level=8;pet.tp=2;G:Remember(bite);assert(G:Status(bite)=="Needs training points")
    pet.tp=3;assert(G:Status(bite)=="Ready for Beast Training")
    pet.spells.bite=2;assert(G:Status(bite)=="Pet already knows")
end)
test("four active slots block only a new active ability",function()
    local pet=G:Focus();pet.level=30;pet.active=4;pet.spells={};G:Remember(bite)
    assert(G:Status(bite)=="Active ability slots full")
    pet.spells.bite=1;assert(G:Status(bite)=="Ready for Beast Training")
end)
test("personal observations override catalog without learning hunter rank",function()
    local higher=P.guideAbilities.bite.ranks[3];G:ObserveSpell(118,higher.spell_id,"Tamed")
    local seen=false;for _,r in ipairs(G:Taught(118))do if r.ability.key=="bite" then assert(r==higher);seen=true end end
    assert(seen and G:Known(higher)==false)
end)
test("trainer offers do not become hunter knowledge",function()
    SERVICES={{name="Bite",status="available"}};GetTrainerServiceItemLink=function()return "|Hspell:"..bite.learn_id.."|h[Bite]|h"end
    UnitExists=function()return true end;G:TrainerSnapshot();assert(G:Known(bite)==false)
    SERVICES[1].status="used";G:TrainerSnapshot();assert(G:Known(bite)==true)
end)
test("only learning system messages record a known spell",function()
    local link="|Hspell:"..bite.learn_id.."|h[Bite]|h"
    G:LearnMessage("Check out "..link);assert(G:Known(bite)==false)
    G:LearnMessage("You have learned a new ability: "..link..".");assert(G:Known(bite)==true)
end)
test("zone entries and literal search restrict the beast catalog",function()
    G:Focus().level=20;local list=G:Entries("zone","Prowler");assert(#list>0)
    for _,e in ipairs(list)do assert(e.npc.name:lower():find("prowler",1,true) and G:InZone(e.npc,1429))end
    assert(#G:Entries("beasts","[unmatched")==0)
end)
test("tooltip does not duplicate on repeated processing",function()
    GameTooltip.lines={};GameTooltip.petPulseGuideGUID=nil;GameTooltip.unitToken="mouseover"
    G:Tooltip(GameTooltip);local count=#GameTooltip.lines;assert(count>0)
    G:Tooltip(GameTooltip);assert(#GameTooltip.lines==count)
    assert(G:NPCID("Pet-0-0-0-0-118-123")==nil)
end)
test("nearby opportunity deduplicates and suppresses combat",function()
    G:Focus().level=20;G:Detect("target");assert(G.alerts[118]==100)
    NOW=105;G:Detect("target");assert(G.alerts[118]==100)
    NOW=1000;COMBAT=true;G:Detect("target");assert(G.alerts[118]==100)
end)
test("stable routing excludes opposite faction and prefers measured local point",function()
    local s=G:NearestStable();assert(s.npc.name=="Erma" and s.map==1429 and s.metric=="zone")
    UnitFactionGroup=function()return "Horde"end;assert(G:NearestStable().npc.side~="alliance")
end)
test("world distances compare across maps only on same continent",function()
    C_Map.GetWorldPosFromMapPos=function(map,pos)local x,y=pos:GetXY();return map==999 and 2 or 1,vector(x*100+(map==2 and 1 or 0),y*100)end
    local near={name="Near",ui_map_id=2,coords={{x=43,y=66}}}
    local far={name="Far",ui_map_id=1429,coords={{x=90,y=90}}}
    local other={name="Other continent",ui_map_id=999,coords={{x=43,y=66}}}
    local choice=G:Nearest({{npc=far},{npc=near},{npc=other}});assert(choice.npc==near and choice.metric=="world")
end)
test("real stable interaction records an observed position",function()
    UnitGUID=function()return "Creature-0-0-0-0-6749-123"end;G:RecordStable()
    assert(G:Store().stables.Erma.observed and G:NearestStable().npc.observed)
end)
test("taming route includes stable source and coordinates",function()
    G:Focus().level=8;local text,stable,source=G:Journey(bite)
    assert(stable and source and text:find("Erma",1,true) and source.npc.max<=30)
    G:Remember(bite);local known,s=G:Journey(bite);assert(not s and known:find("no taming needed",1,true))
end)
test("level alert fires once after unlock and never at initial login",function()
    local alerts,messages=0,{};local oldAlert,oldMessage=P.Alert,P.Message
    P.Alert=function()alerts=alerts+1 end;P.Message=function(t)messages[#messages+1]=t end
    local pet=G:Focus();G:CheckLevel(pet);G:FlushLevelAlert();assert(alerts==0)
    pet.level=8;G:CheckLevel(pet);G:FlushLevelAlert();assert(alerts==1 and #messages>1 and G:Store().lastUnlock.level==8)
    G:CheckLevel(pet);G:FlushLevelAlert();assert(alerts==1)
    P.Alert=oldAlert;P.Message=oldMessage
end)
test("level-up queues through combat and ignores temporary pets",function()
    local pet=G:Focus();G:CheckLevel(pet);pet.level=8;COMBAT=true;G:CheckLevel(pet);G:FlushLevelAlert();assert(G.pendingLevel)
    COMBAT=false;G:FlushLevelAlert();assert(not G.pendingLevel)
    G:CheckLevel({guid="temporary",level=10});assert(not G.pendingLevel)
end)
test("disabled level alerts and unrelated levels remain quiet",function()
    local pet=G:Focus();G:CheckLevel(pet);G:Store().levelAlerts=false;pet.level=8;G:CheckLevel(pet);assert(not G.pendingLevel)
    assert(#G:LevelUnlocks(pet,8)==0)
end)
test("guide UI opens, filters, paginates and exposes stable map action",function()
    G:Focus().level=20;if P.guideWindow then P.guideWindow:Hide()end;P.ToggleGuide()
    local w=P.guideWindow;assert(w:IsShown() and w.levelToggle:GetChecked())
    P.GuideDetails({rank=bite});assert(w.stableEntry and w.mapEntry and w.detail:GetText():find("Erma",1,true))
    w.mode="beasts";w.page=2;P.RefreshGuideWindow();assert(w.page==2 and #w.entries==813)
    w.search:SetText("Prowler");P.RefreshGuideWindow();assert(#w.entries>0 and #w.entries<813)
    P.SetLanguage("SK");assert(w.levelToggle and P.T("Level-up alerts")=="Tipy pri levelupe")
    P.SetLanguage("EN")
end)
test("settings and guide remain mutually exclusive through tabs and reopen",function()
    if P.guideWindow then P.guideWindow:Hide() end
    if P.settings then P.settings:Hide() end
    P.ToggleSettings();P.ShowSettingsPage("credits");assert(P.settings:IsShown())
    P.ShowSettingsPage("training");assert(P.guideWindow:IsShown() and not P.settings:IsShown())
    P.ToggleSettings();assert(P.settings:IsShown() and not P.guideWindow:IsShown())
    P.ToggleGuide();assert(P.guideWindow:IsShown() and not P.settings:IsShown())
    P.ToggleGuide();assert(not P.guideWindow:IsShown() and not P.settings:IsShown())
end)
test("native dialogs use opaque backing and untinted Blizzard borders",function()
    for _,f in ipairs({P.settings,P.guideWindow}) do
        assert(f.opaqueBackground and f.backdrop.edgeFile=="Interface\\DialogFrame\\UI-DialogBox-Border")
        assert(f.backdropColor[4]==1 and f.borderColor[1]==1 and f.borderColor[2]==1 and f.borderColor[3]==1)
    end
end)
test("combat transition leaves settings intact without touching secure guide",function()
    P.ToggleSettings();assert(P.settings:IsShown());COMBAT=true
    P.ShowSettingsPage("training");assert(P.settings:IsShown() and not P.guideWindow:IsShown())
    COMBAT=false;P.ToggleGuide();assert(not P.settings:IsShown() and P.guideWindow:IsShown())
end)
test("opening a results page selects its first detail immediately",function()
    local w=P.guideWindow;w.search:SetText("");w.mode="beasts";w.page=2;w.selected=nil
    P.RefreshGuideWindow();assert(w.selected==w.entries[15] and w.detail:GetText():find(w.selected.npc.name,1,true))
end)
test("main pet choice persists while a temporary pet is summoned",function()
    local main=G:ChooseMain("main");assert(main and G:Store().mainChosen)
    P.pet.guid="temporary";P.pet.name="Teacher";G:Snapshot(false)
    assert(G:Focus().guid=="main")
    local saved=P.Copy(G:Store());P.db.guide=saved;assert(G:Focus().name=="Mittens")
end)
test("overview distinguishes ready, acquisition and unknown data",function()
    G:Focus().level=8;G:Remember(bite)
    local rows,counts,status=G:PetOverview();assert(counts.ready>=1 and status=="Ready to teach now")
    local seen={};for _,e in ipairs(rows)do assert(not seen[e.rank.ability.key]);seen[e.rank.ability.key]=true end
    G:Store().known={};G.knownNow={};rows,counts,status=G:PetOverview();assert(counts.ready==0 and status=="Hunter knowledge unverified")
    G:Focus().spells=nil;rows,counts,status=G:PetOverview();assert(status=="Pet abilities unavailable")
end)
test("overview never reports up to date when level is unreadable",function()
    G:Focus().level=nil;local _,_,status=G:PetOverview();assert(status=="Pet abilities unavailable")
end)
test("up to date means all compatible level eligible ranks already known by pet",function()
    local pet=G:Focus();pet.level=14
    for key,a in pairs(P.guideAbilities)do pet.spells[key]=999 end
    local rows,counts,status=G:PetOverview();assert(#rows==0 and status=="Up to date for this level")
end)
test("bestiary combines family level zone and literal search",function()
    local rows=G:BrowseEntries("beasts","Prowler","Wolf",true,true);assert(#rows>0)
    for _,e in ipairs(rows)do assert(e.npc.family=="Wolf" and e.eligible and G:InZone(e.npc,1429))end
    assert(#G:BrowseEntries("beasts","[missing","Cat",false,false)==0)
end)
test("featured picks classify level without presenting rarity as damage",function()
    local rows=G:BrowseEntries("picks","",nil,false,false);assert(#rows==8)
    local found={};for _,e in ipairs(rows)do found[e.id]=e end
    assert(found[5807].eligible and not found[2850].eligible and found[276111].pick.role=="Rare appearance")
    assert(found[2850].status=="Higher level required")
    assert(G:FamilyIcon("Cat")~=G:FamilyIcon("Wolf"))
end)
test("level filter respects upper bound and hunter taming minimum",function()
    UnitLevel=function()return 9 end;assert(#G:BrowseEntries("picks","",nil,true,false)==0)
    UnitLevel=function()return 36 end;assert(#G:BrowseEntries("picks","Swamp Jaguar",nil,true,false)==0)
    UnitLevel=function()return 37 end;assert(#G:BrowseEntries("picks","Swamp Jaguar",nil,true,false)==1)
end)
test("continent fallback resolves exact live zone without guessing",function()
    GetRealZoneText=function()return "Elwynn Forest"end
    C_Map.GetBestMapForUnit=function()return 1415 end
    C_Map.GetMapInfo=function()return {name="Eastern Kingdoms"}end
    C_Map.GetMapChildrenInfo=function()return {{name="Elwynn Forest",mapID=1429},{name="Westfall",mapID=1436}}end
    assert(G:Zone()==1429)
    GetRealZoneText=function()return "Unknown"end;assert(G:Zone()==1415)
end)
test("new guide home and browser expose only relevant actions",function()
    local w=P.guideWindow;w.mode="pet";w.search:SetText("");w.family=nil;w.levelOnly=false;w.zoneOnly=false;G:Focus().level=14;P.RefreshGuideWindow()
    assert(not w.familyButton:IsShown() and w.focus:GetText():find("Your Main Pet",1,true) and #w.rows==14)
    w.mode="picks";w.selected=nil;P.RefreshGuideWindow();assert(w.familyButton:IsShown() and not w.track:IsShown() and not w.nextSource:IsShown())
    local entry;for _,e in ipairs(w.entries)do if e.id==276111 then entry=e end end
    P.GuideDetails(entry);assert(w.detail:GetText():find("Rare appearance",1,true))
    w.choose.scripts.OnClick();assert(w.chooser:IsShown())
end)
test("summon snapshots group into one choice without deleting history",function()
    local store=G:Store();store.pets.old=P.Copy(store.pets.main);store.pets.old.guid="old"
    store.pets.older=P.Copy(store.pets.main);store.pets.older.guid="older"
    assert(#G:SavedPets()==1 and store.pets.old and store.pets.older)
    store.pets.other={guid="other",name="Other",family="Cat",level=10};assert(#G:SavedPets()==2)
end)
test("main selection follows a new summon GUID and retains portrait",function()
    local pet=G:Focus();pet.portrait=12345;G.levelSeen.main=7
    P.pet.guid="new-main";P.pet.level=8;local current=G:Snapshot(false)
    assert(G:Focus()==current and current.portrait==12345 and G.pendingLevel and G.pendingLevel.guid=="new-main")
end)
test("main portrait uses live unit and cached portrait when stabled",function()
    local old=SetPortraitTexture;local called
    SetPortraitTexture=function(texture,unit)called=unit;texture:SetTexture(12345)end
    local icon={SetTexture=function(self,v)self.texture=v end,GetTexture=function(self)return self.texture end}
    G:PaintMainPortrait(icon);assert(called=="pet" and G:Focus().portrait==12345)
    P.pet.guid="teacher";called=nil;G:PaintMainPortrait(icon);assert(not called and icon.texture==12345)
    G:Focus().portrait=nil;G:PaintMainPortrait(icon);assert(icon.texture:find("Ability_Hunter_Pet_Cat",1,true))
    SetPortraitTexture=old
end)
test("upcoming ranks respect family level and current pet ranks",function()
    local pet=G:Focus();pet.level=14
    for key,a in pairs(P.guideAbilities)do for _,rank in ipairs(a.ranks)do if rank.pet_level<=14 then pet.spells[key]=rank.rank end end end
    local _,_,status=G:PetOverview();assert(status=="Up to date for this level")
    local upcoming=G:Upcoming();assert(#upcoming>0)
    local seen={};local previous=0
    for _,e in ipairs(upcoming)do assert(e.future and e.rank.pet_level>14 and e.rank.pet_level>=previous and G:Compatible(e.rank,pet))
        assert(not seen[e.rank.ability.key]);seen[e.rank.ability.key]=true;previous=e.rank.pet_level
    end
    local w=P.guideWindow;w.mode="pet";w.search:SetText("");w.selected=nil;P.RefreshGuideWindow()
    assert(w.showingUpcoming and #w.entries>0 and w.hint:GetText():find("Next upgrade",1,true))
    assert(w.detail:GetText():find("Unlocks at pet level",1,true))
end)
test("maxed catalog and missing spellbook never fabricate upcoming ranks",function()
    local pet=G:Focus();pet.level=60;for key in pairs(P.guideAbilities)do pet.spells[key]=999 end
    assert(#G:Upcoming()==0);pet.spells=nil;assert(#G:Upcoming()==0)
end)
test("gun warning persists centrally and updates without sound per shot",function()
    P.db.ammo=true;P.db.sound=true;P.alertTimes={};P.ammoNotice=nil
    P.ammoState={weapon=90,sub=3,total=250,tier=2};local before=SOUNDCOUNT
    P.UpdateAmmoWarning();assert(P.ammoWarning:IsShown() and P.ammoWarning.text:GetText():find("Bullets",1,true) and SOUNDCOUNT==before+1)
    NOW=NOW+30;P.ammoState.total=249;P.UpdateAmmoWarning();assert(P.ammoWarning:IsShown() and SOUNDCOUNT==before+1)
    P.ammoState.total=200;P.ammoState.tier=1;P.UpdateAmmoWarning();assert(SOUNDCOUNT==before+2)
    P.ammoState.total=0;P.UpdateAmmoWarning();assert(P.ammoWarning.text:GetText():find("OUT OF AMMO",1,true) and SOUNDCOUNT==before+3)
end)
test("ammo warning survives unrelated alerts and hides on refill unknown or disabled",function()
    P.db.ammo=true;P.ammoState={weapon=90,sub=3,total=15,tier=1};P.UpdateAmmoWarning()
    local text=P.ammoWarning.text:GetText();P.Alert("other","Other message",false);assert(P.ammoWarning.text:GetText()==text)
    P.ammoState.total=500;P.ammoState.tier=3;P.UpdateAmmoWarning();assert(not P.ammoWarning:IsShown())
    P.ammoState.total=nil;P.ammoState.tier=nil;P.UpdateAmmoWarning();assert(not P.ammoWarning:IsShown())
    P.ammoState.total=10;P.ammoState.tier=1;P.db.ammo=false;P.UpdateAmmoWarning();assert(not P.ammoWarning:IsShown());P.db.ammo=true
end)
test("startup ammo warning waits for its frame instead of consuming notice",function()
    local f=P.ammoWarning;P.ammoWarning=nil;P.ammoNotice=nil;P.ammoState={weapon=90,sub=3,total=10,tier=1}
    P.UpdateAmmoWarning();assert(P.ammoNotice==nil);P.ammoWarning=f;P.UpdateAmmoWarning();assert(f:IsShown() and P.ammoNotice)
end)
test("muting sounds leaves central ammo warning visible",function()
    P.db.sound=false;P.ammoNotice=nil;P.alertTimes={};local before=SOUNDCOUNT
    P.ammoState={weapon=90,sub=2,total=150,tier=1};P.UpdateAmmoWarning()
    assert(SOUNDCOUNT==before and P.ammoWarning:IsShown() and P.ammoWarning.text:GetText():find("Arrows",1,true));P.db.sound=true
end)
test("pet level notification shows even without a newly unlocked rank and expires",function()
    local pet=G:Focus();P.ShowPetLevelUp(pet,{})
    assert(P.petLevelWarning:IsShown() and P.petLevelWarning.title:GetText():find(pet.name,1,true))
    assert(P.petLevelWarning.detail:GetText():find("adventure",1,true))
    NOW=NOW+8;P.petLevelWarning.scripts.OnUpdate(P.petLevelWarning);assert(not P.petLevelWarning:IsShown())
end)
test("central ammo and pet level notices coexist without overwriting",function()
    P.ammoState={weapon=90,sub=3,total=20,tier=1};P.UpdateAmmoWarning();local text=P.ammoWarning.text:GetText()
    P.ShowPetLevelUp(G:Focus(),{bite});assert(P.ammoWarning:IsShown() and P.petLevelWarning:IsShown() and P.ammoWarning.text:GetText()==text)
    assert(P.ammoWarning.anchor[5]~=P.petLevelWarning.anchor[5])
end)
test("world tooltip renders each ability with a readable spell icon",function()
    C_Spell={GetSpellTexture=function(id)return id+100000 end}
    GameTooltip.lines={};GameTooltip.petPulseGuideGUID=nil;GameTooltip.unitToken="mouseover"
    G:Tooltip(GameTooltip)
    for _,rank in ipairs(G:Taught(118))do
        local expected="|T"..(rank.spell_id+100000)..":28:28:0:0|t  "..G:RankName(rank);local found=false
        for _,line in ipairs(GameTooltip.lines)do if line[1]:find(expected,1,true)then found=true end end
        assert(found)
    end
end)
test("world tooltip keeps readable names when spell texture is unavailable",function()
    GameTooltip.lines={};GameTooltip.petPulseGuideGUID=nil;GameTooltip.unitToken="mouseover"
    G:Tooltip(GameTooltip);local found=false
    for _,line in ipairs(GameTooltip.lines)do if line[1]:find("INV_Misc_QuestionMark:28:28:0:0|t",1,true)then found=true end end
    assert(found)
end)
test("training back button restores the previous settings page",function()
    if P.guideWindow:IsShown()then P.guideWindow:Hide()end
    if not P.settings:IsShown()then P.ToggleSettings()end
    P.ShowSettingsPage("pets");P.ShowSettingsPage("training");assert(P.guideWindow:IsShown() and not P.settings:IsShown())
    P.guideWindow.back.scripts.OnClick();assert(P.settings:IsShown() and P.settings.pages.pets:IsShown() and not P.guideWindow:IsShown())
end)
test("minimap button opens settings and guide with separate clicks",function()
    Minimap=CreateFrame("Frame",nil,UIParent);P.BuildMinimapButton();local b=P.minimapButton
    assert(b and b:IsShown() and b.icon.texture:find("minimap.tga",1,true))
    P.settings:Hide();b.scripts.OnClick(b,"LeftButton");assert(P.settings:IsShown())
    b.scripts.OnClick(b,"RightButton");assert(P.guideWindow:IsShown() and not P.settings:IsShown())
end)
test("minimap drag saves angle without opening a panel on release",function()
    local b=P.minimapButton;local before=P.guideWindow:IsShown();CURSORX=1100;CURSORY=540
    b.scripts.OnDragStart(b);b.scripts.OnUpdate(b);assert(type(P.db.minimapAngle)=="number")
    b.scripts.OnDragStop(b);assert(not b.scripts.OnUpdate)
    b.scripts.OnClick(b,"LeftButton");assert(P.guideWindow:IsShown()==before)
    local angle=P.db.minimapAngle;P.UpdateMinimapButton();assert(P.db.minimapAngle==angle)
end)
test("minimap hide toggle and combat click are safe",function()
    local b=P.minimapButton;P.db.minimap=false;P.UpdateMinimapButton();assert(not b:IsShown())
    P.db.minimap=true;P.UpdateMinimapButton();assert(b:IsShown())
    P.guideWindow:Hide();P.settings:Hide();NOW=NOW+1;COMBAT=true;b.scripts.OnClick(b,"LeftButton");assert(not P.settings:IsShown());COMBAT=false
end)
test("actionID-only modern pet spells suppress already known nearby ranks",function()
    Enum.SpellBookSpellBank={Player=0,Pet=1}
    C_SpellBook={HasPetSpells=function()return 1 end,
        GetSpellBookItemInfo=function(_,bank)assert(bank==1);return {actionID=bite.spell_id+16777216} end}
    G:Focus().level=20;G:Detect("mouseover")
    assert(G:Focus().spells.bite==2 and not G.alerts[118])
    assert(G:Known(bite)==false,"pet knowledge must not become hunter knowledge")
end)
test("current pet spell changes are checked before the delayed refresh",function()
    G:Focus().level=20;GetSpellBookItemInfo=function()return "SPELL",bite.spell_id end
    G:Detect("target");assert(not G.alerts[118])
end)
test("higher pet rank also suppresses lower source rank",function()
    G:Focus().level=30
    GetSpellBookItemInfo=function()return "SPELL",P.guideAbilities.bite.ranks[3].spell_id end
    G:Detect("target");assert(not G.alerts[118])
end)
test("partial spellbook preserves snapshot and does not announce an upgrade",function()
    G:Focus().level=20;G:Focus().spells.bite=2
    HasPetSpells=function()return 2 end
    GetSpellBookItemInfo=function(i)if i==1 then return "SPELL",bite.spell_id end end
    assert(G:ReadPetSpells()==nil);G:Snapshot(false);assert(G:Focus().spells.bite==2)
    G:Detect("target");assert(not G.alerts[118])
end)
test("legacy hunter teaching knowledge suppresses a taming alert",function()
    G:Focus().level=20
    IsSpellKnown=function(id,pet)assert(pet==false);return id==bite.learn_id end
    G:Detect("target");assert(G:Known(bite)==true and not G.alerts[118])
end)
test("temporary pet spellbook does not overwrite selected main pet",function()
    G:Focus().level=20;P.pet.guid="temporary"
    UnitGUID=function(unit)return unit=="pet" and "temporary" or "Creature-0-0-0-0-118-12345"end
    GetSpellBookItemInfo=function()return "SPELL",bite.spell_id end
    G:Detect("target");assert(G:Focus().spells.bite==1 and G.alerts[118]==100)
end)
test("pinned HUD stays open outside cursor and unpin restores collapse",function()
    P.db.hover=true;P.db.locked=true;CURSORX=0;CURSORY=0
    P.SetPinnedOpen(true);P.UpdateHUD(P.hud,1);NOW=NOW+2;P.UpdateHUD(P.hud,1)
    assert(P.expanded and P.progress==1 and P.hud.pin:IsShown())
    P.hud.pin.scripts.OnClick();assert(not P.db.pinnedOpen)
    P.UpdateHUD(P.hud,1);NOW=NOW+2;P.UpdateHUD(P.hud,1);P.UpdateHUD(P.hud,1)
    assert(not P.expanded and P.progress==0)
end)
test("saved pin reopens HUD on layout and does not change hover preference",function()
    P.db.hover=false;P.db.pinnedOpen=true;P.expanded=false;P.linear=0;P.progress=0
    P.ApplyLayout();P.UpdateHUD(P.hud,1);assert(P.expanded and P.progress==1)
    P.hud.center.scripts.OnClick(P.hud.center,"LeftButton");assert(P.expanded)
    P.SetPinnedOpen(false);assert(P.db.hover==false)
    P.hud.center.scripts.OnClick(P.hud.center,"LeftButton");assert(not P.expanded)
    P.db.hover=true
end)
test("pin toggle in combat leaves protected actions untouched",function()
    COMBAT=true;P.SetPinnedOpen(true);P.UpdateHUD(P.hud,1);assert(P.expanded)
    P.SetPinnedOpen(false);COMBAT=false
end)
print("TOTAL "..n.." training guide tests passed")
