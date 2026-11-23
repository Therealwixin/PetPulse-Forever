local _,P=...
local PAGE=14
local function word(key)return P.T(key)end
local function label(parent,text,x,y,width,font)
    local f=parent:CreateFontString(nil,"OVERLAY",font or "GameFontHighlight")
    f:SetPoint("TOPLEFT",parent,"TOPLEFT",x,y);f:SetWidth(width or 350);f:SetJustifyH("LEFT");f:SetText(text)
    return f
end
local function button(parent,text,x,y,width,fn)
    local b=CreateFrame("Button",nil,parent,"UIPanelButtonTemplate");b:SetSize(width,26);b:SetPoint("TOPLEFT",parent,"TOPLEFT",x,y)
    P.BindLabel(b,text);b:SetScript("OnClick",fn);return b
end
local function checked(parent,text,x,y,fn)
    local b=CreateFrame("CheckButton",nil,parent,"UICheckButtonTemplate");b:SetSize(22,22);b:SetPoint("TOPLEFT",parent,"TOPLEFT",x,y)
    P.BindLabel(label(parent,"",x+26,y-5,165,"GameFontHighlightSmall"),text);b:SetScript("OnClick",fn);return b
end
local function color(status)
    if status=="Ready for Beast Training" or status=="Level requirement met" then return .4,1,.4 end
    if status=="Higher level required" then return 1,.35,.3 end
    return 1,.82,.35
end
local function resetList(w)w.page=1;w.selected=nil;P.RefreshGuideWindow()end
function P.GuideDetails(entry)
    local w=P.guideWindow;local g=P.guide;w.selected=entry;w.mapEntry=nil;w.stableEntry=nil
    w.track:Hide();w.nextSource:Hide();w.map:Hide();w.stable:Hide()
    if not entry then
        w.detail:SetText(word(w.mode=="pet" and (w.search:GetText() or "")=="" and "No later upgrades are recorded for this pet." or "No matching entries."));return
    end
    local lines={};local function add(s)lines[#lines+1]=s end
    local rank,npc=entry.rank,entry.npc;local pet=g:Focus()
    if rank then
        add("|cffffd100"..g:RankName(rank).."|r");add(word(g:Status(rank)));add(" ")
        add(word("Your pet's rank")..": "..tostring(pet and pet.spells and pet.spells[rank.ability.key] or 0))
        local oldCost=0;for _,r in ipairs(rank.ability.ranks)do if pet and pet.spells and r.rank==pet.spells[rank.ability.key] then oldCost=r.training_cost or 0 end end
        add(word("Training points needed")..": "..math.max(0,(rank.training_cost or 0)-oldCost))
        add(" ")
        local journey,stable
        if entry.future then
            journey=word("Unlocks at pet level").." "..rank.pet_level.." · "..word("Levels to go")..": "..math.max(0,rank.pet_level-(pet and pet.level or 0))
            journey=journey.."\n"..word(g:Known(rank)==true and "Already learned by you. Train your pet when it reaches this level." or "This is a future upgrade, not ready to teach yet.")
        else journey,stable=g:Journey(rank) end
        if stable then
            add(word("Stable your main pet")..": "..g:PlaceText(stable))
            add(word("Tame a source below, use its ability until learned, then return to your main pet."))
        else add(journey) end
        w.stableEntry=stable
        if stable then w.stable:Show() end
        if g:Known(rank)~=true and not rank.ability.trainer then
            local sources=g:Sources(rank);local nearest=g:NearestSource(rank)
            table.sort(sources,function(a,b)
                if nearest and a.id~=b.id and (a.id==nearest.id or b.id==nearest.id) then return a.id==nearest.id end
                return a.npc.name<b.npc.name
            end)
            entry.sourceCount=#sources;entry.sourceIndex=P.Clamp(entry.sourceIndex or 1,1,math.max(1,#sources))
            local source=sources[entry.sourceIndex];npc=source and source.npc
            if #sources>1 then w.nextSource:Show() end
            if not npc then add(word("No documented taming source for this rank.")) end
        end
        w.track:Show()
    end
    if npc then
        add(" ");add("|cffffd100"..npc.name.."|r")
        add(word(npc.family or "").." · "..word("Level").." "..tostring(npc.min or "?")..(npc.max and npc.max~=npc.min and "–"..npc.max or ""))
        if not rank then add(word(entry.status)) end
        local map,point=g:Location(npc);w.mapEntry={map=map,point=point};if map then w.map:Show()end
        add(g:MapName(map)..(point and string.format(" · %.1f, %.1f",point.x,point.y) or ""))
        if npc.class then add(npc.class)end
        if entry.pick then
            add(" ");add("|cffffd100"..word("Why choose this pet?").."|r")
            add(word(entry.pick.role));add(word(entry.pick.reason))
            add(word("Role-based picks, not a universal BiS ranking."));add("Wowhead Forever · 2026-11-19")
        end
        if not rank then
            add(" ");add(word("Abilities recorded on this beast"))
            local taught=g:Taught(entry.id)
            for _,r in ipairs(taught)do add(g:RankName(r))end
            if #taught==0 then add(word("Abilities unverified — use Beast Lore"))end
        end
        add(" ");add(word("Known habitat — not a live spawn guarantee."))
    end
    w.detail:SetText(table.concat(lines,"\n"));w.detailBody:SetHeight(math.max(390,w.detail:GetStringHeight()+20));w.detailScroll:SetVerticalScroll(0)
end
function P.RefreshGuideWindow()
    local w=P.guideWindow;if not w or InCombatLockdown() then return end
    local g=P.guide;local store=g:Store();local pet=g:Focus();local overview,counts,status=g:PetOverview()
    w.focus:SetText(word("Your Main Pet")..": "..(pet and pet.name.." · "..word(pet.family).." · "..word("Level").." "..tostring(pet.level or "?") or word("Choose")))
    g:PaintMainPortrait(w.petIcon)
    w.summary:SetText(word(status)..(counts.ready>0 and " ("..counts.ready..")" or counts.learn>0 and " ("..counts.learn..")" or ""))
    if counts.ready>0 then w.summary:SetTextColor(.4,1,.4)elseif status=="Up to date for this level" then w.summary:SetTextColor(.7,.85,.7)else w.summary:SetTextColor(1,.82,.35)end
    w.hint:SetText(word(counts.ready>0 and "Open Beast Training to teach the green entries." or counts.learn>0 and "Choose an ability below to see where to learn it." or "Only upgrades for your selected pet and current level are listed."))
    w.snapshot:SetText(pet and pet.guid~=P.pet.guid and word("Saved main pet — summon it to verify training.") or "")
    local query=w.search:GetText() or "";local browser=w.mode~="pet"
    w.showingUpcoming=not browser and status=="Up to date for this level"
    if w.showingUpcoming then
        overview=g:Upcoming()
        w.hint:SetText(#overview>0 and word("Next upgrade at pet level").." "..overview[1].rank.pet_level.." — "..g:RankName(overview[1].rank) or word("No later upgrades are recorded for this pet."))
    end
    if browser then w.entries=g:BrowseEntries(w.mode,query,w.family,w.levelOnly,w.zoneOnly)
    else
        w.entries={};for _,e in ipairs(overview)do if query=="" or g:RankName(e.rank):lower():find(query:lower(),1,true)then w.entries[#w.entries+1]=e end end
    end
    w.familyButton:SetShown(browser);w.levelFilter:SetShown(browser);w.zoneFilter:SetShown(browser)
    w.filterLabels:SetShown(browser);w.familyButton:SetText(word(w.family or "All families"))
    w.page=P.Clamp(w.page or 1,1,math.max(1,math.ceil(#w.entries/PAGE)))
    w.pageText:SetText(string.format("%d / %d · %d",w.page,math.max(1,math.ceil(#w.entries/PAGE)),#w.entries))
    w.empty:SetText(#w.entries==0 and word(query~="" and "No matching entries." or w.showingUpcoming and "No later upgrades are recorded for this pet." or w.mode=="pet" and status or "No matching entries.") or "")
    for i,row in ipairs(w.rows)do
        local e=w.entries[(w.page-1)*PAGE+i];row.entry=e;row:SetShown(e~=nil)
        if e then
            row.name:SetText(e.rank and g:RankName(e.rank) or e.npc.name)
            local sub=e.rank and (e.future and word("Unlocks at pet level").." "..e.rank.pet_level or word(e.status)) or word(e.npc.family or "").." · "..word("Level").." "..tostring(e.npc.min or "?")..(e.npc.max and e.npc.max~=e.npc.min and "–"..e.npc.max or "").." · "..word(e.pick and e.pick.role or e.status)
            row.sub:SetText(sub);row.name:SetTextColor(color(e.status))
            row.icon:SetTexture(e.rank and (P.Call("C_Spell.GetSpellTexture",e.rank.spell_id) or "Interface\\Icons\\INV_Misc_Book_09") or g:FamilyIcon(e.npc.family))
        end
    end
    for mode,b in pairs(w.modeButtons)do b:SetAlpha(mode==w.mode and 1 or .6)end
    w.tooltipToggle:SetChecked(store.tooltips);w.alertToggle:SetChecked(store.alerts);w.levelToggle:SetChecked(store.levelAlerts~=false)
    w.levelFilter:SetChecked(w.levelOnly);w.zoneFilter:SetChecked(w.zoneOnly)
    local keep=false;for _,e in ipairs(w.entries)do if w.selected and (e.rank and e.rank==w.selected.rank or e.id and e.id==w.selected.id)then
        e.sourceIndex=w.selected.sourceIndex;w.selected=e;keep=true;break end end
    if not keep then w.selected=w.entries[(w.page-1)*PAGE+1] end
    P.GuideDetails(w.selected)
    local plan=store.plan and g.bySpell[store.plan]
    w.progress:SetText(plan and g:RankName(plan).." — "..word(g:Status(plan)) or "")
    w.clear:SetShown(plan~=nil)
end
local function chooser(w,kind)
    if w.chooser then w.chooser:Hide()end
    local f=CreateFrame("Frame",nil,w,"BackdropTemplate");w.chooser=f
    f:SetSize(470,410);f:SetPoint("TOPRIGHT",w,"TOPRIGHT",-18,-94);f:SetFrameLevel(w:GetFrameLevel()+20);P.StyleDialog(f);f:EnableMouse(true)
    local close=CreateFrame("Button",nil,f,"UIPanelCloseButton");close:SetPoint("TOPRIGHT")
    P.BindLabel(label(f,"",18,-20,400,"GameFontNormalLarge"),kind=="family" and "Pet family" or "Choose your main pet")
    if kind=="family" then
        local options={{name="All families"}};for _,family in ipairs(P.moodFamilies)do if family.id then options[#options+1]=family end end
        for i,family in ipairs(options)do
            local value=family.id and family.name or nil
            button(f,family.name,18+((i-1)%2)*220,-58-math.floor((i-1)/2)*32,212,function()w.family=value;f:Hide();resetList(w)end)
        end
    else
        button(f,"Use my current pet",18,-58,430,function()
            P.ReadPet();local pet=P.guide:Snapshot(false)
            if pet then P.guide:ChooseMain(pet.guid);f:Hide();resetList(w)else P.Message(word("Call your pet first."))end
        end)
        local choices=P.guide:SavedPets()
        local page=1;local rows={}
        local function paint()
            for i,row in ipairs(rows)do local e=choices[(page-1)*7+i];row.entry=e;row:SetShown(e~=nil)
                if e then row:SetText(e.pet.name.." · "..word(e.pet.family).." · "..word("Level").." "..tostring(e.pet.level or "?"))end end
        end
        for i=1,7 do rows[i]=button(f,"",18,-98-(i-1)*34,430,function(self)
            if self.entry then P.guide:ChooseMain(self.entry.guid);f:Hide();resetList(w)end
        end)end
        button(f,"<",18,-353,60,function()page=math.max(1,page-1);paint()end)
        button(f,">",388,-353,60,function()page=math.min(math.max(1,math.ceil(#choices/7)),page+1);paint()end);paint()
    end
end
function P.ToggleGuide()
    if InCombatLockdown()then P.Message(word("Open the training guide after combat."));return end
    if P.settings then P.settings:Hide()end
    if P.guideWindow then
        if P.guideWindow:IsShown()then P.guideWindow:Hide()else P.guide:Refresh();P.RefreshGuideWindow();P.guideWindow:Show()end;return
    end
    local g=P.guide;local w=CreateFrame("Frame","PetPulseForeverTrainingGuide",UIParent,"BackdropTemplate");P.guideWindow=w
    w:SetSize(1040,760);w:SetPoint("CENTER");w:SetFrameStrata("DIALOG");w:SetClampedToScreen(true);w:EnableMouse(true);P.StyleDialog(w)
    if UIParent.GetWidth and UIParent.GetHeight then w:SetScale(math.min(1,(UIParent:GetWidth()-30)/1040,(UIParent:GetHeight()-30)/760))end
    table.insert(UISpecialFrames,"PetPulseForeverTrainingGuide")
    w.back=button(w,"Back to settings",24,-23,175,function()
        if InCombatLockdown()then return end
        w:Hide();P.ToggleSettings()
    end)
    local close=CreateFrame("Button",nil,w,"UIPanelCloseButton");close:SetPoint("TOPRIGHT")
    local logo=w:CreateTexture(nil,"ARTWORK");logo:SetTexture(P.media.."logo.tga");logo:SetSize(200,50);logo:SetPoint("CENTER",w,"TOP",-100,-36)
    local heading=label(w,"",0,0,180,"GameFontNormalLarge")
    heading:ClearAllPoints();heading:SetPoint("LEFT",w,"TOP",20,-36)
    P.BindLabel(heading,"Training guide")
    w.petIcon=w:CreateTexture(nil,"ARTWORK");w.petIcon:SetSize(42,42);w.petIcon:SetPoint("TOPLEFT",w,"TOPLEFT",24,-65)
    w.focus=label(w,"",76,-68,700,"GameFontNormalLarge");w.snapshot=label(w,"",76,-90,700,"GameFontHighlightSmall")
    w.choose=button(w,"Choose",850,-68,160,function()chooser(w,"pet")end)
    w.summary=label(w,"",24,-118,740,"GameFontNormalLarge");w.hint=label(w,"",24,-144,980)
    w.mode="pet";w.modeButtons={}
    for i,v in ipairs({{"pet","My Pet"},{"beasts","Bestiary"},{"picks","Top Picks"}})do
        local mode=v[1];w.modeButtons[mode]=button(w,v[2],24+(i-1)*175,-177,165,function()
            w.mode=mode;w.search:SetText("");if w.chooser then w.chooser:Hide()end;resetList(w)
        end)
    end
    w.options=CreateFrame("Frame",nil,w,"BackdropTemplate");w.options:SetSize(310,145);w.options:SetPoint("TOPRIGHT",w,"TOPRIGHT",-24,-206);w.options:SetFrameLevel(w:GetFrameLevel()+15);w.options:EnableMouse(true);P.StyleDialog(w.options);w.options:Hide()
    button(w,"Alerts",850,-177,160,function()w.options:SetShown(not w.options:IsShown())end)
    for i,v in ipairs({{"tooltips","Mouseover details"},{"alerts","Nearby alerts"},{"levelAlerts","Level-up alerts"}})do
        local key=v[1];local c=checked(w.options,v[2],18,-20-(i-1)*36,function(self)g:Store()[key]=self:GetChecked()==true end)
        if i==1 then w.tooltipToggle=c elseif i==2 then w.alertToggle=c else w.levelToggle=c end
    end
    w.familyButton=button(w,"All families",24,-211,175,function()chooser(w,"family")end)
    w.filterLabels=CreateFrame("Frame",nil,w);w.filterLabels:SetAllPoints(w)
    w.levelFilter=checked(w.filterLabels,"My level",215,-213,function(self)w.levelOnly=self:GetChecked()==true;resetList(w)end)
    w.zoneFilter=checked(w.filterLabels,"This zone",365,-213,function(self)w.zoneOnly=self:GetChecked()==true;resetList(w)end)
    w.search=CreateFrame("EditBox",nil,w,"InputBoxTemplate");w.search:SetSize(260,24);w.search:SetPoint("TOPLEFT",w,"TOPLEFT",750,-211);w.search:SetAutoFocus(false)
    P.BindLabel(label(w,"",650,-216,95),"Search")
    w.search:SetScript("OnEscapePressed",function(self)self:ClearFocus()end);w.search:SetScript("OnTextChanged",function()resetList(w)end)
    w.rows={}
    for i=1,PAGE do
        local row=CreateFrame("Button",nil,w);row:SetSize(580,30);row:SetPoint("TOPLEFT",w,"TOPLEFT",24,-248-(i-1)*30)
        row:SetHighlightTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight","ADD")
        row.icon=row:CreateTexture(nil,"ARTWORK");row.icon:SetSize(28,28);row.icon:SetPoint("LEFT",row,"LEFT",0,0)
        row.name=label(row,"",36,-1,540,"GameFontNormal");row.sub=label(row,"",36,-16,540,"GameFontHighlightSmall")
        row:SetScript("OnClick",function(self)P.GuideDetails(self.entry)end)
        row:SetScript("OnEnter",function(self)if self.entry and self.entry.rank then GameTooltip:SetOwner(self,"ANCHOR_RIGHT");GameTooltip:SetSpellByID(self.entry.rank.spell_id);GameTooltip:Show()end end)
        row:SetScript("OnLeave",function()GameTooltip:Hide()end);w.rows[i]=row
    end
    w.empty=label(w,"",24,-260,560)
    w.detailScroll=CreateFrame("ScrollFrame",nil,w,"UIPanelScrollFrameTemplate");w.detailScroll:SetPoint("TOPLEFT",w,"TOPLEFT",640,-248);w.detailScroll:SetSize(350,390)
    w.detailBody=CreateFrame("Frame",nil,w.detailScroll);w.detailBody:SetSize(340,900);w.detailScroll:SetScrollChild(w.detailBody)
    w.detail=label(w.detailBody,"",0,0,340);w.detail:SetFont("Fonts\\ARIALN.TTF",14,"")
    w.pageText=label(w,"",115,-686,350)
    for _,dir in ipairs({-1,1})do local step=dir;button(w,step<0 and "<" or ">",step<0 and 24 or 550,-680,54,function()w.page=w.page+step;w.selected=nil;P.RefreshGuideWindow()end)end
    w:EnableMouseWheel(true);w:SetScript("OnMouseWheel",function(_,delta)w.page=w.page-delta;w.selected=nil;P.RefreshGuideWindow()end)
    w.map=button(w,"Show on map",640,-648,172,function()if w.mapEntry then g:Pin(w.mapEntry)end end)
    w.nextSource=button(w,"Next source",825,-648,185,function()if w.selected and (w.selected.sourceCount or 0)>1 then w.selected.sourceIndex=(w.selected.sourceIndex or 1)%w.selected.sourceCount+1;P.GuideDetails(w.selected)end end)
    w.track=button(w,"Track this rank",640,-680,172,function()if w.selected and w.selected.rank then g:Store().plan=w.selected.rank.spell_id;P.RefreshGuideWindow()end end)
    w.stable=button(w,"Stable on map",825,-680,185,function()if w.stableEntry then g:Pin(w.stableEntry)end end)
    w.progress=label(w,"",24,-725,780,"GameFontHighlightSmall")
    w.clear=button(w,"Clear tracking",850,-716,160,function()g:Store().plan=nil;P.RefreshGuideWindow()end)
    w.train=CreateFrame("Button",nil,w,"SecureActionButtonTemplate,UIPanelButtonTemplate");w.train:SetSize(160,26);w.train:SetPoint("TOPLEFT",w,"TOPLEFT",850,-114);w.train:RegisterForClicks("LeftButtonUp")
    w.train:SetAttribute("useOnKeyDown",false);w.train:SetAttribute("type","spell");w.train:SetAttribute("spell",5149);P.BindLabel(w.train,"Beast Training")
    RegisterStateDriver(w,"visibility","[combat] hide; ignore");P.RefreshGuideWindow()
end

