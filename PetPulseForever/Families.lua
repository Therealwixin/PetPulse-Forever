local _,P=...
-- Families from the bundled Blizzard CreatureFamily export (build 71037).
P.moodFamilies={
    {key="bat", name="Bat", id=24},
    {key="bear", name="Bear", id=4},
    {key="birdofprey", name="Bird of Prey", id=26},
    {key="boar", name="Boar", id=5},
    {key="carrionbird", name="Carrion Bird", id=7},
    {key="cat", name="Cat", id=2},
    {key="corehound", name="Core Hound", id=312},
    {key="crab", name="Crab", id=8},
    {key="crocolisk", name="Crocolisk", id=6},
    {key="fox", name="Fox", id=319},
    {key="gorilla", name="Gorilla", id=9},
    {key="hyena", name="Hyena", id=25},
    {key="raptor", name="Raptor", id=11},
    {key="scorpid", name="Scorpid", id=20},
    {key="spider", name="Spider", id=3},
    {key="tallstrider", name="Tallstrider", id=12},
    {key="turtle", name="Turtle", id=21},
    {key="windserpent", name="Wind Serpent", id=27},
    {key="wolf", name="Wolf", id=1},
    {key="classic",name="Classic"},
}
P.moodStyles={}
for _,family in ipairs(P.moodFamilies) do P.moodStyles[family.key]=true end
function P.MoodTexture(style,mood)
    if not P.moodStyles[style] then style="wolf" end
    return P.media..(style=="classic" and mood or "mood-"..style.."-"..mood)..".tga"
end
