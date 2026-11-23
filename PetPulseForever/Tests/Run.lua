local P=TEST_NS
local count=0
local function test(name,fn) fn();count=count+1;print("PASS "..name) end
ITEMS[9000]={name="Bow",class=2,sub=2};ITEMS[9001]={name="Arrows",class=6,sub=2};ITEMS[9002]={name="Bullets",class=6,sub=3}
ITEMS[3770]={name="Mutton Chop",class=0,diet=true,level=35}
ITEMS[117]={name="Tough Jerky",class=0,diet=true,level=5}
ITEMS[999]={name="Buff Food",class=0,diet=true,buff=true}
local function stack(id,n) return {itemID=id,stackCount=n or 1,isLocked=false,iconFileID=123}end
BAG={stack(3770,8),stack(117,5),stack(9001,400),stack(9002,100)}
Event("PLAYER_LOGIN")
test("full TOC initialization",function() assert(P.ready and P.hud and SlashCmdList.PETPULSEFOREVER) end)
test("one click uses lower-level compatible safe food",function()
    local action,slot=Click(P.feedAction);assert(action=="spell" and slot==2 and not P.confirm:IsShown())
end)
test("buff food requires explicit confirmation",function()
    BAG={stack(999,3)};P.Refresh(true)
    local action=Click(P.feedAction);assert(action==nil and P.confirm:IsShown())
    local accepted,slot=Click(P.confirm.accept);assert(accepted=="spell" and slot==1 and not P.confirm:IsShown())
end)
test("buff tooltip overrides staple allowlist",function()
    ITEMS[3770].buff=true;BAG={stack(3770,2)};P.Refresh(true)
    assert(P.foods[1].risk);ITEMS[3770].buff=nil
end)
test("diet change checked again on click",function()
    BAG={stack(3770,2)};P.Refresh(true);ITEMS[3770].diet=false
    assert(Click(P.feedAction)==nil);ITEMS[3770].diet=true
end)
test("blacklist and rare excluded; quest tags and unknown materials require review",function()
    ITEMS[998]={name="Crafting",class=7,diet=true};ITEMS[997]={name="Rare",class=0,diet=true,quality=3}
    BAG={stack(3770),stack(117),stack(998),stack(997)};BAG[2].quest=true
    P.db.protected[3770]=true;P.Refresh(true)
    assert(#P.foods==2 and P.foods[1].id==117 and P.foods[1].risk and P.foods[2].id==998);P.db.protected={}
end)
test("all 411 food records have explicit policies and diets",function()
    local n=0;local counts={safe=0,confirm=0,exclude=0}
    for id,r in pairs(P.foodCatalog) do
        assert(type(id)=="number" and r.diet and r.reason and counts[r.policy])
        n=n+1;counts[r.policy]=counts[r.policy]+1
    end
    assert(n==411 and counts.safe==142 and counts.confirm==243 and counts.exclude==26)
end)
test("quest policy overrides raw boar meat recommendation",function()
    ITEMS[769]={name="Chunk of Boar Meat",class=7,sub=8,diet=true,level=5,price=3}
    ITEMS[724]={name="Goretusk Liver Pie",class=0,sub=5,diet=true,level=15,price=25,buff=true}
    BAG={stack(724),stack(769,5)};P.Refresh(true)
    assert(P.foods[1].id==769 and P.foods[1].risk and P.foods[1].tier==1)
    assert(Click(P.feedAction)==nil);P.CancelConfirmation()
    ITEMS[2672]={name="Stringy Wolf Meat",class=7,sub=8,diet=true,level=5,price=4}
    BAG={stack(724),stack(2672,5)};P.Refresh(true)
    assert(P.foods[1].id==2672 and not P.foods[1].risk)
    local action,slot=Click(P.feedAction);assert(action=="spell" and slot==2)
end)
test("catalog buff remains protected even without English tooltip",function()
    ITEMS[724].buff=false;BAG={stack(724)};P.Refresh(true)
    assert(P.foods[1].risk and P.foods[1].reason=="Buff food")
    assert(Click(P.feedAction)==nil);assert(P.confirm:IsShown());P.CancelConfirmation()
end)
test("Forever vendor fish buff is not misclassified safe",function()
    ITEMS[787]={name="Slitherskin Mackerel",class=0,diet=true};BAG={stack(787)};P.Refresh(true)
    assert(P.foods[1].risk and P.foods[1].reason=="Buff food")
end)
test("non-quest raw material respects diet blacklist value and quest flag",function()
    BAG={stack(2672)};ITEMS[2672].diet=false;P.Refresh(true);assert(#P.foods==0)
    ITEMS[2672].diet=true;P.db.protected[2672]=true;P.Refresh(true);assert(#P.foods==0)
    P.db.protected[2672]=nil;BAG[1].quest=true;P.Refresh(true);assert(#P.foods==1 and P.foods[1].risk)
    BAG[1].quest=nil;ITEMS[2672].price=1001;P.Refresh(true);assert(P.foods[1].risk)
    ITEMS[2672].price=3
end)
test("rare and missing-metadata catalog entries never become candidates",function()
    for id,r in pairs(P.foodCatalog) do
        if r.policy=="exclude" and r.reason~="Quest item" then
            ITEMS[id]={name="Excluded",class=0,diet=true};BAG={stack(id)}
            P.Refresh(true);assert(#P.foods==0)
        end
    end
end)
test("safe catalog supports every locale and protects future builds",function()
    local locale=GetLocale;GetLocale=function()return "deDE"end
    BAG={stack(2672)};P.Refresh(true);assert(not P.foods[1].risk);GetLocale=locale
    local build=GetBuildInfo;GetBuildInfo=function()return "1.60.2","99999","",16002 end
    P.Refresh(true);assert(P.foods[1].risk);GetBuildInfo=build
end)
test("pending confirmation invalidated by bag change",function()
    BAG={stack(999)};P.Refresh(true);Click(P.feedAction);assert(P.pendingFood)
    BAG={stack(3770)};Event("BAG_UPDATE_DELAYED");Drain();assert(not P.pendingFood)
    assert(Click(P.confirm.accept)==nil)
end)
test("pending confirmation revalidates slot without event",function()
    BAG={stack(999)};P.Refresh(true);Click(P.feedAction);BAG={stack(3770)}
    assert(Click(P.confirm.accept)==nil)
end)
test("pet replacement invalidates confirmation",function()
    BAG={stack(999)};P.Refresh(true);Click(P.feedAction);PETGUID="pet-b"
    assert(Click(P.confirm.accept)==nil)
end)
test("dead absent and active feeding block consumption",function()
    BAG={stack(3770)};DEAD=true;P.Refresh(true);assert(Click(P.feedAction)==nil)
    DEAD=false;PET=false;P.Refresh(true);assert(Click(P.feedAction)==nil)
    PET=true;AURA={spellId=1539,duration=20,expirationTime=NOW+8};P.Refresh(true)
    assert(Click(P.feedAction)==nil);assert(P.FeedStatus():find("8s"));AURA=nil
end)
test("no fabricated feeding duration",function()
    AURA={spellId=1539};P.Refresh();assert(P.FeedStatus():find("Duration Unavailable"));AURA=nil;P.Refresh()
end)
test("ammo exact counts and 400 301 300 201 200 0 boundaries",function()
    for _,v in ipairs({400,301,300,201,200,0})do
        BAG={stack(9001,v),stack(9002,500)};P.ReadAmmo()
        assert(P.ammoState.total==v);assert(P.ammoState.tier==(v>300 and 3 or v>200 and 2 or 1))
    end
end)
test("ammo alert cooldown and refill rearm",function()
    NOW=200;BAG={stack(9001,400)};P.ReadAmmo();BAG[1].stackCount=200
    local before=SOUNDCOUNT;P.ReadAmmo();P.ReadAmmo();assert(SOUNDCOUNT==before+1)
    NOW=210;BAG[1].stackCount=400;P.ReadAmmo();BAG[1].stackCount=200;P.ReadAmmo();assert(SOUNDCOUNT==before+2)
end)
test("gun counts bullets and excludes arrows",function()
    ITEMS[9000].sub=3;BAG={stack(9001,800),stack(9002,55)};P.ReadAmmo();assert(P.ammoState.total==55)
    ITEMS[9000].sub=2
end)
test("ammo respects level requirements and missing metadata",function()
    BAG={stack(9001,100)};ITEMS[9001].requiredLevel=50;P.ReadAmmo();assert(P.ammoState.total==0)
    ITEMS[9001].requiredLevel=1;ITEMS[9001].uncached=true;P.ReadAmmo();assert(P.ammoState.total==nil)
    ITEMS[9001].uncached=nil
end)
test("secure action aligns at non-default HUD scale",function()
    P.db.scale=1.4;P.ApplyLayout();P.OpenShard();P.UpdateHUD(P.hud,.3)
    local x,y=P.nodes.feed:GetCenter();local sx,sy=P.feedAction:GetCenter()
    assert(math.abs(x*P.nodes.feed:GetEffectiveScale()-sx*P.feedAction:GetEffectiveScale())<.01)
    assert(math.abs(y*P.nodes.feed:GetEffectiveScale()-sy*P.feedAction:GetEffectiveScale())<.01)
    P.db.scale=1;P.ApplyLayout()
end)
test("no training warning from points alone",function()
    P.trainerOpen=false;P.ReadTraining();assert(P.trainingOptions==nil)
end)
test("training requires available service level points and prerequisites",function()
    SERVICES={{name="Armor",status="available",level=20,cost=10,rank="Rank 4"},
        {name="Known",status="used",level=1,cost=0},{name="High",status="available",level=40,cost=1},
        {name="Expensive",status="available",level=1,cost=41},
        {name="Missing",status="available",level=1,cost=1,abilityMissing=true}}
    P.trainerOpen=true;P.ReadTraining();assert(#P.trainingOptions==1 and P.trainingOptions[1].name=="Armor")
    Event("TRAINER_CLOSED");Drain();assert(P.trainingOptions==nil)
end)
test("shared region includes satellite gaps without full square",function()
    assert(P.Inside(0,30,76,true));assert(P.Inside(49,0,76,true));assert(not P.Inside(60,60,76,true))
end)
test("hover delay cancels when pointer returns",function()
    P.OpenShard();CURSORX=960;CURSORY=400;P.UpdateHUD(P.hud,.2);assert(P.expanded)
    CURSORX=1300;P.UpdateHUD(P.hud,.04);NOW=NOW+.15;CURSORX=960
    P.UpdateHUD(P.hud,.04);assert(P.expanded and P.outsideAt==nil)
    CURSORX=1300;P.UpdateHUD(P.hud,.04);NOW=NOW+.4;P.UpdateHUD(P.hud,.04);assert(not P.expanded)
end)
test("combat hides secure actions and permits HUD animation",function()
    -- UIParent is not treated as protected by the real client merely for having secure children.
    UIParent.protected=false;Combat(true);assert(not P.feedAction:IsShown())
    P.OpenShard();P.UpdateHUD(P.hud,.2);P.Refresh(true)
    Combat(false);assert(not P.confirm:IsShown())
end)
test("settings initialize and refresh without recursion",function() P.ToggleSettings();P.RefreshSettings();assert(P.settings:IsShown()) end)
test("unlock enables full-shard mover and disarms feeding",function()
    BAG={stack(2672)};P.Refresh(true);P.SetLocked(false);P.UpdateHUD(P.hud,.2)
    assert(P.hud.mover:IsShown() and P.expanded and not P.feedAction:IsShown())
    assert(P.feedAction:GetAttribute("type")==nil)
    CURSORX=1500;NOW=NOW+1;P.UpdateHUD(P.hud,.04);NOW=NOW+1;P.UpdateHUD(P.hud,.04)
    assert(P.expanded);P.SetLocked(true);assert(not P.hud.mover:IsShown())
end)
test("drag position persists at non-default scale without jumping",function()
    P.db.scale=1.4;P.ApplyLayout();P.SetLocked(false);P.StartDrag()
    P.hud:ClearAllPoints();P.hud:SetPoint("CENTER",UIParent,"BOTTOMLEFT",600,400)
    local x,y=P.hud:GetCenter();P.SavePosition()
    local ax,ay=P.hud:GetCenter();assert(math.abs(x-ax)<.01 and math.abs(y-ay)<.01)
    P.SetLocked(true);P.db.scale=1;P.db.x=0;P.db.y=-140;P.ApplyLayout()
end)
test("periodic status checks never rescan inventory",function()
    P.foodDirty=false;local n=BAGSCANS;for i=1,10 do P.Refresh() end;assert(BAGSCANS==n)
end)
test("secret returns become unavailable",function()
    HAPPINESS="SECRET";P.ReadPet();assert(P.pet.happiness==nil);P.Paint();HAPPINESS=3
end)


test("Goretusk Liver stays behind safe meals but ahead of buff pie",function()
    ITEMS[723]={name="Goretusk Liver",class=7,diet=true,level=10,price=3}
    BAG={stack(724),stack(723)};P.Refresh(true)
    assert(P.foods[1].id==723 and P.foods[1].tier==1)
    assert(Click(P.feedAction)==nil);assert(P.confirm:IsShown());P.CancelConfirmation()
    BAG[3]=stack(3770);P.Refresh(true);assert(P.foods[1].id==3770)
end)
test("character completion releases only completed non-repeatable quests",function()
    COMPLETED[22]=true;BAG={stack(723)};P.Refresh(true);assert(not P.foods[1].risk)
    ACTIVE[22]=true;P.Refresh(true);assert(P.foods[1].risk);ACTIVE[22]=nil
    REPEATABLE[22]=true;P.Refresh(true);assert(P.foods[1].risk);REPEATABLE[22]=nil
    COMPLETED[22]=nil
end)
test("all required quests must be completed",function()
    for _,q in ipairs(P.questFood[769])do COMPLETED[q]=true end
    assert(not P.IsQuestFood(769));COMPLETED[P.questFood[769][1]]=nil;assert(P.IsQuestFood(769))
    COMPLETED={}
end)
test("quest completion never releases buff or high-value protection",function()
    ItemDB={relatedQuests=function()return {22}end};COMPLETED[22]=true
    BAG={stack(724)};P.Refresh(true);assert(P.foods[1].risk and P.foods[1].tier==2)
    ITEMS[723].price=2000;BAG={stack(723)};P.Refresh(true);assert(P.foods[1].tier==2)
    ITEMS[723].price=3;ItemDB=nil;COMPLETED={}
end)
test("unknown quest status stays protected and confirmation rechecks",function()
    local api=C_QuestLog.IsQuestFlaggedCompleted;C_QuestLog.IsQuestFlaggedCompleted=nil
    BAG={stack(723)};P.Refresh(true);assert(P.foods[1].risk);C_QuestLog.IsQuestFlaggedCompleted=api
    Click(P.feedAction);local action=Click(P.confirm.accept);assert(action=="spell")
end)
test("buff and expensive food are strictly last resort",function()
    ITEMS[723].level=50;ITEMS[724].level=1;BAG={stack(724),stack(723)};P.Refresh(true)
    assert(P.foods[1].id==723);ITEMS[723].level=10;ITEMS[724].level=15
    P.db.confirmation=false;P.Refresh(true);assert(#P.foods==0);P.db.confirmation=true
end)
test("death warns once and portrait changes to revive",function()
    NOW=NOW+20;DEAD=false;PET=true;P.ReadPet();local before=SOUNDCOUNT
    DEAD=true;P.ReadPet();P.Paint();assert(SOUNDCOUNT==before+1 and P.hud.actionLabel.text=="REVIVE")
    P.ReadPet();assert(SOUNDCOUNT==before+1);DEAD=false;PET=false;P.ReadPet();P.Paint()
    assert(P.hud.actionLabel.text=="CALL");PET=true;P.ReadPet();P.Paint()
end)
test("central action securely selects revive and call including in combat",function()
    local macro=P.petAction:GetAttribute("macrotext1")
    assert(macro:find("%[@pet,dead%] Revive Pet") and macro:find("%[nopet%] Call Pet"))
    assert(P.petAction:GetAttribute("type1")=="macro")
    UIParent.protected=false;Combat(true);assert(P.petAction:IsShown())
    P.Paint();Combat(false)
end)
test("low health is gentle and strictly below twenty percent",function()
    local before=SOUNDCOUNT;HEALTH=20;P.ReadPet();P.Paint();assert(P.healthWarning.alpha==0)
    HEALTH=19;P.ReadPet();P.Paint();assert(P.healthWarning.alpha==.85 and SOUNDCOUNT==before)
    HEALTH=21;P.ReadPet();P.Paint();assert(P.healthWarning.alpha==0);HEALTH=100
end)
test("secret health uses native display curve without comparison",function()
    HEALTH="SECRET";P.ReadPet();assert(P.pet.healthPercent==nil)
    P.healthCurve={};UnitHealthPercent=function()return "SECRET"end
    P.UpdateHealthWarning();assert(P.healthWarning.alpha=="SECRET")
    P.healthCurve=nil;UnitHealthPercent=nil;HEALTH=100;P.ReadPet()
end)
test("eating badge uses real aura time and moves above expanded happiness",function()
    P.feedAura={duration=20,expires=NOW+8};P.UpdateMealBadge()
    assert(P.hud.meal:IsShown() and P.hud.meal.title.text:match("8s$"))
    P.Layout(0);assert(P.hud.meal.anchor[5]==34)
    P.Layout(1);assert(P.hud.meal.anchor[5]==88)
    P.feedAura={};P.UpdateMealBadge();assert(not P.hud.meal.title.text:match("%ds$"))
    P.feedAura={expires=NOW-1};P.UpdateMealBadge();assert(not P.hud.meal:IsShown())
    P.feedAura=nil;P.Layout(P.progress)
end)
test("care advice differs from combat stats",function()
    HAPPINESS=3;P.ReadPet();local title=P.CareAdvice();assert(title=="All good — no food needed")
    HEALTH=19;P.ReadPet();title=P.CareAdvice();assert(title=="Your pet needs healing")
    HEALTH=100;P.ReadPet()
end)


test("food tooltip visibly identifies crafting reagents",function()
    BAG={stack(723)};P.Refresh(true)
    local d=P.GetFoodDetails(P.foods[1]);assert(d.kind=="CRAFTING REAGENT")
    assert(d.quests[1].id==22 and d.quests[1].status=="Not completed")
end)
test("food tooltip shows completed active and repeatable quest states",function()
    local f=P.foods[1];COMPLETED[22]=true
    assert(P.GetFoodDetails(f).quests[1].status=="Completed")
    ACTIVE[22]=true;assert(P.GetFoodDetails(f).quests[1].status=="Active — keep for quest");ACTIVE[22]=nil
    REPEATABLE[22]=true;assert(P.GetFoodDetails(f).quests[1].status=="Completed · repeatable")
    REPEATABLE={};COMPLETED={}
end)
test("food tooltip retains actual buff numbers and duration",function()
    local old=C_TooltipInfo.GetBagItem
    C_TooltipInfo.GetBagItem=function()return {lines={{leftText="Goretusk Liver Pie"},
        {leftText="Use: Gain 4 Strength for 15 min."}}}end
    BAG={stack(724)};P.Refresh(true);local d=P.GetFoodDetails(P.foods[1])
    assert(d.kind=="BUFF FOOD" and d.lines[1].left=="Use: Gain 4 Strength for 15 min.")
    C_TooltipInfo.GetBagItem=old
end)
test("tooltip inspection does not alter food ranking or confirmation",function()
    BAG={stack(724),stack(723),stack(3770)};P.Refresh(true)
    local before={};for i,f in ipairs(P.foods)do before[i]={id=f.id,risk=f.risk,tier=f.tier}end
    for _,f in ipairs(P.foods)do P.GetFoodDetails(f);P.AddFoodDetails(f)end
    for i,f in ipairs(P.foods)do assert(f.id==before[i].id and f.risk==before[i].risk and f.tier==before[i].tier)end
end)


test("ammo stays visible and moves from below portrait to right",function()
    P.Layout(0);local n=P.nodes.ammo
    assert(n:IsShown() and n.alpha==1 and n.anchor[4]==0 and n.anchor[5]==-38)
    assert(n.bg.alpha==0 and n.ring.alpha==0 and n.mouseEnabled==false)
    P.Layout(.5);assert(n:IsShown() and n.alpha==1)
    assert(n.anchor[4]>35 and n.anchor[5]<-25)
    P.Layout(1);assert(n.anchor[4]==54 and math.abs(n.anchor[5])<.001 and n.mouseEnabled)
    P.Layout(P.progress)
end)
test("ornaments stay warm metal and ammo uses classic serif",function()
    P.Paint()
    for _,key in ipairs({"happiness","feed","ammo"})do
        local c=P.nodes[key].ring.color;assert(c[1]==1 and c[2]==1 and c[3]==1)
    end
    assert(P.nodes.ammo.font==nil)
    assert(P.nodes.ammo.label.font[1]=="Fonts\\FRIZQT__.TTF")
end)
test("ammo visibility preference remains respected",function()
    P.db.modules.ammo=false;P.Layout(0);assert(not P.nodes.ammo:IsShown())
    P.db.modules.ammo=true;P.Layout(0);assert(P.nodes.ammo:IsShown());P.Layout(P.progress)
end)
test("meal captions stay stable across aura refreshes and change for the next meal",function()
    P.feedAura={expires=NOW+20};P.UpdateMealBadge()
    local caption=P.hud.meal.caption.text
    P.feedAura={expires=NOW+20};P.UpdateMealBadge();assert(P.hud.meal.caption.text==caption)
    P.feedAura=nil;P.UpdateMealBadge();assert(not P.hud.meal:IsShown())
    P.feedAura={expires=NOW+20};P.UpdateMealBadge();assert(P.hud.meal.caption.text~=caption)
    P.feedAura=nil;P.UpdateMealBadge()
end)
test("hover follows secure buttons and clears on exit without touching global tooltip",function()
    local globalOwner=GameTooltip.owner
    P.petAction.scripts.OnEnter(P.petAction);assert(P.hud.center.hover:IsShown())
    local button=P.secureNodes.feed
    button.scripts.OnEnter(button);assert(P.nodes.feed.hover:IsShown() and not P.hud.center.hover:IsShown())
    P.petAction.scripts.OnLeave(P.petAction);assert(P.nodes.feed.hover:IsShown())
    button.scripts.OnLeave(button);assert(not P.nodes.feed.hover:IsShown())
    assert(GameTooltip.owner==globalOwner)
end)
test("tooltip text grows by two pixels without accumulating on refresh",function()
    P.Tooltip("pet",P.petAction)
    local line=PetPulseForeverTooltipTextLeft1
    local _,size=line:GetFont();assert(size==14)
    P.Tooltip("pet",P.petAction);local _,again=line:GetFont();assert(again==size)
end)
test("language selection refreshes menus and tooltips without touching item names",function()
    P.SetLanguage("SK");assert(P.db.language=="SK" and P.T("Diet")=="Strava")
    assert(P.T("Goretusk Liver Pie")=="Goretusk Liver Pie")
    assert(P.T("Nom nom... 8s")=="Ham ham... 8s")
    assert(P.T("Food priority: Lower item level")=="Priorita jedla: Nižšia úroveň")
    P.SetLanguage("CZ");assert(P.T("Ammo")=="Munice")
    P.Tooltip("pet",P.petAction)
    local found=false
    for _,line in ipairs(P.tooltip.lines) do if line[1]=="Strava" then found=true end end
    assert(found)
    P.SetLanguage("invalid");assert(P.db.language=="CZ")
    P.SetLanguage("EN");assert(P.T("Diet")=="Diet")
end)
test("hamburger only appears when expanded and opens settings",function()
    P.db.locked=true;P.Layout(0);assert(not P.hud.menu:IsShown())
    P.Layout(1);assert(P.hud.menu:IsShown())
    P.settings:Hide();P.hud.menu.scripts.OnClick();assert(P.settings:IsShown())
    P.settings:Hide();P.Layout(P.progress)
end)
test("all mood sets can be selected and persist in settings",function()
    for _,family in ipairs(P.moodFamilies) do
        local style=family.key
        P.settings.moodButtons[style].scripts.OnClick()
        assert(P.db.moodStyle==style and P.settings.moodButtons[style].alpha==1)
    end
    P.db.moodStyle="wolf";P.Paint()
end)
test("ammo can be hover-only, has custom color and native Blizzard font",function()
    P.db.ammoBelow=false;P.Layout(0);assert(not P.nodes.ammo:IsShown())
    P.Layout(1);assert(P.nodes.ammo:IsShown())
    P.db.ammoR=.8;P.db.ammoG=.6;P.db.ammoB=.3;P.db.ammoFont="blizzard"
    P.ApplyAmmoStyle(P.nodes.ammo.label,1347,3)
    assert(P.nodes.ammo.label.font[2]==14 and P.nodes.ammo.label.textColor[2]==.6)
    P.ApplyAmmoStyle(P.nodes.ammo.label,5,1);assert(P.nodes.ammo.label.textColor[1]==P.colors[1][1])
    P.db.ammoBelow=true;P.db.ammoFont="classic";P.Layout(P.progress)
end)
test("right click opens food picker without consuming or confirming",function()
    BAG={stack(117,3),stack(3770,5)};P.Refresh(true)
    P.foodMenu:Hide();local action=Click(P.feedAction,"RightButton")
    assert(action==nil and P.foodMenu:IsShown() and not P.confirm:IsShown())
    assert(#P.foodMenu.choices==2)
end)
test("manual safe choice survives bag movement and honors missing food",function()
    assert(P.SelectFood(3770));assert(P.CurrentFood().id==3770)
    local action,slot=Click(P.feedAction);assert(action=="spell" and slot==2)
    BAG={stack(3770,5),stack(117,3)}
    action,slot=Click(P.feedAction);assert(action=="spell" and slot==1)
    BAG={stack(117,3)};assert(Click(P.feedAction)==nil and P.CurrentFood()==nil)
    P.SelectFood(nil);assert(P.CurrentFood().id==117)
end)
test("manual protected food still needs confirmation and rechecks diet",function()
    BAG={stack(117),stack(999,2)};P.Refresh(true);assert(P.SelectFood(999))
    assert(Click(P.feedAction)==nil and P.confirm:IsShown())
    ITEMS[999].diet=false;assert(Click(P.confirm.accept)==nil);ITEMS[999].diet=true
    P.SelectFood(nil)
end)
test("food picker lists protected items as blocked and uses native bag tooltip",function()
    BAG={stack(117),stack(3770)};P.db.protected[117]=true;P.Refresh(true)
    P.RefreshFoodMenu();local blocked
    for _,entry in ipairs(P.foodMenu.choices)do if entry.id==117 then blocked=entry end end
    assert(blocked and not blocked.allowed);assert(P.SelectFood(117)==false)
    local row=P.foodMenu.rows[1];row.scripts.OnEnter(row)
    assert(GameTooltip.bag==row.entry.bag and GameTooltip.slot==row.entry.slot)
    P.db.protected[117]=nil;P.SelectFood(nil)
end)
test("food picker paginates all choices and closes on combat",function()
    BAG={}
    for i=1,18 do ITEMS[80000+i]={name="Food "..i,diet=true,class=0};BAG[i]=stack(80000+i) end
    P.foodMenu:Hide();P.ToggleFoodMenu();assert(#P.foodMenu.choices==18)
    P.foodMenu.page=3;P.RefreshFoodMenu();assert(P.foodMenu.rows[2]:IsShown() and not P.foodMenu.rows[3]:IsShown())
    Combat(true);assert(not P.foodMenu:IsShown());Combat(false)
    BAG={stack(117)};P.SelectFood(nil)
end)
test("pet XP updates the portrait on events without inventory scans",function()
    PETXP=250;PETXPMAX=1000;local scans=BAGSCANS
    Event("UNIT_PET_EXPERIENCE","pet")
    assert(P.pet.xpFraction==.25 and P.hud.xpStep==25 and P.hud.xpFill:IsShown())
    assert(BAGSCANS==scans)
    P.Tooltip("pet",P.petAction);local found=false
    for _,line in ipairs(P.tooltip.lines)do if line[1]=="XP to next level" and line[2]=="750" then found=true end end
    assert(found)
end)
test("XP arc handles empty full and new level without stale progress",function()
    for _,entry in ipairs({{0,1000,0},{1000,1000,100},{12,2000,0},{1200,1000,100}})do
        PETXP=entry[1];PETXPMAX=entry[2];Event("UNIT_PET_EXPERIENCE","pet");assert(P.hud.xpStep==entry[3])
    end
end)
test("invalid unavailable secret dead and absent XP never fabricates a bar",function()
    for _,entry in ipairs({{0,0},{"SECRET",1000},{100,0/0},{-1,1000},{10,math.huge}})do
        PETXP=entry[1];PETXPMAX=entry[2];P.ReadPet();P.Paint();assert(not P.hud.xpFill:IsShown())
    end
    PETXP=100;PETXPMAX=1000;DEAD=true;P.ReadPet();P.Paint();assert(not P.hud.xpFill:IsShown())
    DEAD=false;PET=false;P.ReadPet();P.Paint();assert(not P.hud.xpFill:IsShown())
    PET=true;P.ReadPet();P.Paint();assert(P.hud.xpFill:IsShown())
end)
print("TOTAL "..count.." behavioral tests passed")
