local _, P = ...
P.version = "1.6.7"
P.revision = "20261127.1"
P.releaseDate = "2026-11-27"
P.targetInterface = 16001
P.media = "Interface\\AddOns\\PetPulseForever\\Media\\"
P.defaults = {minimap=true,minimapAngle=225,ammoBelow=true, ammoFont="classic", ammoR=1, ammoG=.94, ammoB=.78, language="EN", moodStyle="wolf", scale=1, opacity=1, x=0, y=-140, locked=true, animation=.18,
    hover=true, pinnedOpen=false, delay=.28, happiness=true, training=true, ammo=true, sound=true, petDeath=true, petHealth=true,
    warning=300, critical=200, price=1000, priority="lowlevel", confirmation=true,
    modules={happiness=true, feed=true, training=true, ammo=true}, protected={}}
P.colors = { [1]={.98,.29,.34}, [2]={.95,.68,.26}, [3]={.34,.85,.66},
    neutral={.44,.64,.72} }
function P.Plain(v)
    if issecretvalue and issecretvalue(v) then return nil end
    return v
end
function P.Call(path, ...)
    local f = _G
    for part in path:gmatch("[^.]+") do
        if type(f) ~= "table" then return end
        f = f[part]
    end
    if type(f) ~= "function" then return end
    local function clean(ok, ...)
        if not ok then return end
        local n, values = select("#", ...), {...}
        for i=1,n do values[i] = P.Plain(values[i]) end
        return unpack(values,1,n)
    end
    return clean(pcall(f,...))
end
function P.Copy(t)
    local out={}
    for k,v in pairs(t) do out[k]=type(v)=="table" and P.Copy(v) or v end
    return out
end
function P.Merge(t,d)
    for k,v in pairs(d) do
        if type(t[k])~=type(v) then t[k]=type(v)=="table" and P.Copy(v) or v
        elseif type(v)=="table" then P.Merge(t[k],v) end
    end
end
function P.Clamp(v,lo,hi) return math.max(lo,math.min(hi,v)) end
function P.Message(s) DEFAULT_CHAT_FRAME:AddMessage("|cff70d9c1PetPulse|r "..P.T(s)) end
P.alertTimes={}
function P.Alert(key,text,critical)
    local now=GetTime()
    if now-(P.alertTimes[key] or -100)>8 then
        P.alertTimes[key]=now
        if P.hud then P.hud.alert:SetText(P.T(text)); P.alertUntil=now+4 end
        if P.db.sound and critical and SOUNDKIT then
            PlaySound(SOUNDKIT.RAID_WARNING,"Master")
        end
    end
end
function P.AmmoTier(count,warning,critical)
    if count==nil then return nil end
    if count<=critical then return 1 elseif count<=warning then return 2 else return 3 end
end
function P.Inside(x,y,r,expanded)
    if not expanded then return x*x+y*y<=r*r end
    -- A diamond containing all four satellites and their connecting gaps.
    return math.abs(x)+math.abs(y)<=r
end

-- Shared native dialog treatment; opaque backing prevents world/UI bleed-through.
function P.StyleDialog(frame)
    frame.opaqueBackground=frame:CreateTexture(nil,"BACKGROUND",nil,-8)
    frame.opaqueBackground:SetPoint("TOPLEFT",8,-8)
    frame.opaqueBackground:SetPoint("BOTTOMRIGHT",-8,8)
    frame.opaqueBackground:SetTexture("Interface\\Buttons\\WHITE8X8")
    frame.opaqueBackground:SetVertexColor(0,0,0,1)
    frame:SetBackdrop({bgFile="Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile="Interface\\DialogFrame\\UI-DialogBox-Border",tile=true,tileSize=32,edgeSize=32,
        insets={left=8,right=8,top=8,bottom=8}})
    frame:SetBackdropColor(1,1,1,1)
    frame:SetBackdropBorderColor(1,1,1,1)
end
