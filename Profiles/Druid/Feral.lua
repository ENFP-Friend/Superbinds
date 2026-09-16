-- Feral. Same family strip as Guardian:
-- E attack  Q disrupt  M5 heal  T forms/wheel  M4 move  C protect  R empower  X travel  BUF  +
-- Wheel: up bear, down cat, shift-up moonkin, shift-down travel. Ctrl-wheel stays camera.
-- Cat Attack is Blizzard SBA (Feral native form). Known() hides unlearned IDs.
-- Shapeshifts are never next-cast.
SuperBinds.RegisterProfile({
  name="Feral", class="DRUID", familyMode="feral", spec=103, default=false,
  useBlizzardSBA=false, form="caster", nativeForm="cat",
  appliedNote="Feral: E SBA in cat  Q prowl  M5 heal  wheel forms (up bear / down cat / shift-up moonkin / shift-down travel)  M4 dash  C barkskin  R tiger's fury. Ctrl-wheel zooms.",
  forms={
    cat={spells={768}},
    bear={spells={5487}},
    travel={spells={783,33943,40120,1066}},
    moonkin={spells={24858,197625}},
  },
  actionBars={
    caster={page=1},
    cat={bonus=1},
    bear={bonus=3},
    moonkin={bonus=4},
    travel={page=1,use="caster"},
  },
  neverSuggest={
    "Cat Form","Bear Form","Travel Form","Moonkin Form","Treant Form","Stag Form",
    768,5487,783,24858,197625,33891,114282,33943,40120,1066,
    1850,77761,77764,106898,
  },
  neverBind={}, exclude={}, sculptures={},
  rotation={
    caster={
      {spell={8921,1253582},auraMissing=true,dot=8,ranged=true},
      {spell={5176,190984},fallback=true},
    },
    cat={
      {spell={1822},auraMissing=true,dot=12},
      {spell={1079},auraMissing=true,dot=16,powerType=4,minPower=5},
      {spell={22568},powerType=4,minPower=5},
      {spell={5221},fallback=true},
    },
    bear={
      {spell={77758,106832}},
      {spell={33917}},
      {spell={8921,1253582},auraMissing=true,dot=16,ranged=true},
      {spell={6807,400254},powerType=1,minPower=40},
      {spell={213771,106785},fallback=true},
    },
    moonkin={
      {spell={8921,1253582},auraMissing=true,dot=8,ranged=true},
      {spell={5176,190984},fallback=true},
    },
    travel={},
  },
  families={
    {tag="E",title="Attack · E",caption="ATTACK",
      bars={
        caster={slot=1,key="E",spell={8921},label="Moonfire",target="harm"},
        cat={slot=1,key="E",sba=true,label="Assisted Rotation"},
        bear={slot=1,key="E",spell={33917},label="Mangle",target="harm"},
        moonkin={slot=1,key="E",spell={8921},label="Moonfire",target="harm"},
      },
      items={
        {spell={1822},label="Rake",bindKey="SHIFT-E",target="harm",note="bleed"},
        {spell={5221},label="Shred",target="harm",note="builder · click"},
        {spell={1079},label="Rip",target="harm",note="finisher bleed · click"},
        {spell={22568},label="Ferocious Bite",target="harm",note="finisher · click"},
        {spell={106785,213764,213771},label="Swipe",target="harm",note="aoe · click"},
        {spell={106830,77758},label="Thrash",target="harm",note="aoe bleed · click"},
        {spell={8921,1253582},label="Moonfire",bindKey="CTRL-E",target="harm",note="ranged / LI"},
      }},
    {tag="Q",title="Disrupt · Q",caption="DISRUPT",
      bars={
        caster={slot=2,key="Q",spell={339},label="Entangling Roots",target="harm"},
        cat={slot=2,key="Q",spell={5215},label="Prowl"},
        bear={slot=2,key="Q",spell={6795},label="Growl"},
        moonkin={slot=2,key="Q",spell={339},label="Entangling Roots",target="harm"},
      },
      items={
        {spell={106839},label="Skull Bash",bindKey="SHIFT-Q",target="harm",note="interrupt when talented"},
        {spell={22570},label="Maim",target="harm",note="stun finisher · click"},
        {spell={339},label="Entangling Roots",target="harm",note="click"},
      }},
    {tag="M5",title="Heal · M5",caption="HEAL",
      bars={
        caster={slot=8,key="M5",bindKey="BUTTON5",spell={8936},label="Regrowth",target="help"},
        cat={slot=8,key="M5",bindKey="BUTTON5",spell={8936},label="Regrowth",target="help"},
        bear={slot=8,key="M5",bindKey="BUTTON5",spell={22842},label="Frenzied Regeneration"},
        moonkin={slot=8,key="M5",bindKey="BUTTON5",spell={8936},label="Regrowth",target="help"},
      },
      items={
        {spell={774},label="Rejuvenation",target="help",note="hot · click"},
        {spell={22842},label="Frenzied Regeneration",note="bear heal · click"},
      }},
    {tag="T",title="Forms · wheel",caption="FORMS",
      bar={slot=3,key="WheelUp",bindKey="MOUSEWHEELUP",spell={5487},label="Bear Form",allBars=true},
      items={
        {slot=4,key="WheelDown",bindKey="MOUSEWHEELDOWN",spell={768},label="Cat Form",allBars=true},
        {slot=5,key="Shift-WheelUp",bindKey="SHIFT-MOUSEWHEELUP",spell={24858,197625},label="Moonkin Form",allBars=true},
        {slot=6,key="Shift-WheelDown",bindKey="SHIFT-MOUSEWHEELDOWN",spell={783},label="Travel Form",allBars=true},
      }},
    {tag="M4",title="Move · M4",caption="MOVE",
      bar={slot=10,key="M4",bindKey="BUTTON4",spell={1850},label="Dash",allBars=true},
      items={
        {spell={77761,77764,106898},label="Stampeding Roar",note="group speed · click"},
      }},
    {tag="C",title="Protect · C",caption="PROTECT",
      bars={
        caster={slot=7,key="C",spell={22812},label="Barkskin"},
        cat={slot=7,key="C",spell={22812},label="Barkskin"},
        bear={slot=7,key="C",spell={192081},label="Ironfur"},
        moonkin={slot=7,key="C",spell={22812},label="Barkskin"},
      },
      items={
        {spell={61336},label="Survival Instincts",note="big wall · click"},
        {spell={22812},label="Barkskin",note="wall · click"},
      }},
    {tag="R",title="Empower · R",caption="EMPOWER",
      bars={
        caster={slot=9,key="R",spell={5176},label="Wrath",target="harm"},
        cat={slot=9,key="R",spell={5217},label="Tiger's Fury"},
        bear={slot=9,key="R",spell={6807,400254},label="Maul",target="harm"},
        moonkin={slot=9,key="R",spell={5176},label="Wrath",target="harm"},
      },
      items={
        {spell={106951,50334},label="Berserk",note="burst · click"},
        {spell={274837},label="Feral Frenzy",target="harm",note="builder · click"},
        {spell={285381},label="Primal Wrath",target="harm",note="aoe rip · click"},
      }},
    {tag="X",title="Travel · X",caption="TRAVEL",
      items={
        {bindKey="X",key="X",macrotext="/dismount [mounted]\n/run if not IsMounted() and not InCombatLockdown() then C_MountJournal.SummonByID(0) end",label="Favorite mount",iconFile=132250},
      }},
    {tag="BUF",title="Buffs · click",caption="BUFFS",
      items={
        {spell={1126},label="Mark of the Wild",note="raid buff · click"},
      }},
    {tag="+",title="Recover · click",caption="RECOVER",
      items={
        {spell={50769},label="Revive",note="out of combat"},
        {itemID=6948,label="Hearthstone"},
      }},
  },
  hardware={
    BUTTON5={slot=8}, BUTTON4={slot=10},
    MOUSEWHEELUP={slot=3, spell=5487}, MOUSEWHEELDOWN={slot=4, spell=768},
    ["SHIFT-MOUSEWHEELUP"]={slot=5, spell={24858,197625}},
    ["SHIFT-MOUSEWHEELDOWN"]={slot=6, spell=783},
  },
  reserved={
    ["CTRL-MOUSEWHEELUP"]="camera zoom in",["CTRL-MOUSEWHEELDOWN"]="camera zoom out",
    NUMPADPLUS="camera zoom in",NUMPADMINUS="camera zoom out",
  },
  camera={
    ["CTRL-MOUSEWHEELUP"]="CAMERAZOOMIN",["CTRL-MOUSEWHEELDOWN"]="CAMERAZOOMOUT",
    NUMPADPLUS="CAMERAZOOMIN",NUMPADMINUS="CAMERAZOOMOUT",
  },
  macros={},
  barBinds={
    E="ACTIONBUTTON1",Q="ACTIONBUTTON2",C="ACTIONBUTTON7",R="ACTIONBUTTON9",
    BUTTON5="ACTIONBUTTON8",BUTTON4="ACTIONBUTTON10",
    MOUSEWHEELUP="ACTIONBUTTON3",MOUSEWHEELDOWN="ACTIONBUTTON4",
    ["SHIFT-MOUSEWHEELUP"]="ACTIONBUTTON5",["SHIFT-MOUSEWHEELDOWN"]="ACTIONBUTTON6",
  },
  theme={brass={.65,.51,.28},accent={.35,.65,.9},
    endcap="Interface\\AddOns\\SuperBinds\\Media\\ShamanEndcap.tga",
    endcapWidth=70,endcapHeight=120,
    endcapHorde="Interface\\AddOns\\SuperBinds\\Media\\DruidEndcap_horde.tga",
    endcapHordeWidth=90,endcapHordeHeight=120,
    endcaps={
      bear={path="Interface\\AddOns\\SuperBinds\\Media\\DruidEndcap_bear.tga",width=80,height=120,leftIn=26},
      cat={path="Interface\\AddOns\\SuperBinds\\Media\\DruidEndcap_cat.tga",width=80,height=120,leftIn=26},
      travel={path="Interface\\AddOns\\SuperBinds\\Media\\DruidEndcap_travel.tga",width=80,height=120,leftIn=26},
    }},
})
