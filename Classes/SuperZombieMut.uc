class SuperZombieMut extends Mutator
  dependson(Types)
  config(SuperZombieMut);


// Struct that stores what a specific zombie should be replaced with
struct oldNewZombiePair
{
  var string oldClass;
  var string newClass;
  var bool bReplace;
};

// Struct that stores all the property attributes
struct propertyDescPair
{
  var string property;
  var string longDescription;
  var string shortDescription;
};

// Configuration variables that store whether or not to replace the specimen
var() globalconfig bool bReplaceCrawler, bReplaceStalker, bReplaceClot, bReplaceGorefast, bReplaceBloat, 
                bReplaceSiren, bReplaceHusk, bReplaceScrake, bReplaceFleshpound, bReplaceBoss;
var() globalconfig bool bareMutatorMode;
var() globalconfig bool disableBleeding, disablePoison, disableFpSecret, disableBodyShotResistance;

// Array that stores all the replacement pairs
var array<oldNewZombiePair> replacementArray;
// Array that stores all the properties and their descriptions
var array<propertyDescPair> propDescripArray;
var array<String> replCaps;

// Stores damage types fp has 75% resistance to.
var array<class<DamageType> > fpExtraResistantTypes;
var array<Types.Resistance> fpResistances;


// replaces the zombies in the given squadArray
function replaceSpecialSquad(out array<KFMonstersCollection.SpecialSquad> squadArray)
{
  local int i,j,k;

  for (j = 0; j < squadArray.Length; j++)
  {
    for (i = 0; i < squadArray[j].ZedClass.Length; i++)
    {
      for (k = 0; k < replacementArray.Length; k++)
      {
        if(replacementArray[k].bReplace && InStr(Caps(squadArray[j].ZedClass[i]), replCaps[k]) != -1)
        {
          squadArray[j].ZedClass[i] = replacementArray[k].newClass;
        }
      }
    }
  }
}


function addResistances(array<Types.WeaponDamage> wpnDamages, float maxHp)
{
  local int i, k;

  for (i = 0; i < wpnDamages.Length; i++)
  {
    for (k = 0; k < fpResistances.Length && fpResistances[k].dmgType != wpnDamages[i].dmgType; k++) { }

    if (k >= fpResistances.Length)
    {
      fpResistances.Length = k + 1;
      fpResistances[k].dmgType = wpnDamages[i].dmgType;
      fpResistances[k].scale = 1.0 - (wpnDamages[i].amount / maxHp);
    }
    else
    {
      fpResistances[k].scale = 1.0 - fmin(fpResistances[k].scale + 1 + (wpnDamages[i].amount / maxHp), 1.0);
    }
  }
}


function PostBeginPlay()
{
  local int i,k;
  local KFGameType KF;
  local array<String> mcCaps;

  KF = KFGameType(Level.Game);
  if (KF == none)
  {
    Destroy();
    return;
  }

  AddToPackageMap();

  // If we are in bare mutator mode, don't do anything except add to package map
  // do setup work in CheckReplacement, and setup custom HUD
  if (bareMutatorMode)
  {
    return;
  }

  if (KF.MonsterCollection == class'KFGameType'.default.MonsterCollection)
  {
    KF.MonsterCollection = class'SZMonstersCollection';
  }

  replacementArray[0].bReplace = bReplaceFleshpound;
  replacementArray[1].bReplace = bReplaceGorefast;
  replacementArray[2].bReplace = bReplaceStalker;
  replacementArray[3].bReplace = bReplaceSiren;
  replacementArray[4].bReplace = bReplaceScrake;
  replacementArray[5].bReplace = bReplaceHusk;
  replacementArray[6].bReplace = bReplaceCrawler;
  replacementArray[7].bReplace = bReplaceBloat;
  replacementArray[8].bReplace = bReplaceClot;

  for (i = 0; i < KF.MonsterCollection.default.MonsterClasses.Length; i++)
  {
    mcCaps[mcCaps.Length] = Caps(KF.MonsterCollection.default.MonsterClasses[i].MClassName);
  }

  for (i = 0; i < replacementArray.Length; i++)
  {
    replCaps[replCaps.Length] = Caps(replacementArray[i].oldClass);
  }

  // Replace all instances of the old specimens with the new ones 
  for (i = 0; i < mcCaps.Length; i++)
  {
    for (k = 0; k < replCaps.Length; k++)
    {
      if (replacementArray[k].bReplace && InStr(mcCaps[i], replCaps[k]) != -1)
      {
        log("SuperZombies - Replacing" @ KF.MonsterCollection.default.MonsterClasses[i].MClassName @ "with" @ replacementArray[k].newClass);
        KF.MonsterCollection.default.MonsterClasses[i].MClassName = replacementArray[k].newClass;
      }
    }
  }

  // Replace the special squad arrays
  replaceSpecialSquad(KF.MonsterCollection.default.ShortSpecialSquads);
  replaceSpecialSquad(KF.MonsterCollection.default.NormalSpecialSquads);
  replaceSpecialSquad(KF.MonsterCollection.default.LongSpecialSquads);
  replaceSpecialSquad(KF.MonsterCollection.default.FinalSquads);

  // no more hardcoded strings
  if (bReplaceBoss)
  {
    KF.MonsterCollection.default.EndGameBossClass = string(class'ZombieSuperBoss');
  }

  if (bReplaceStalker)
  {
    KF.MonsterCollection.default.FallbackMonsterClass = string(class'ZombieSuperStalker');
  }

  // reset KF events to our SZMonstersCollection
  for (i = 0; i < KF.SpecialEventMonsterCollections.Length; i++)
  {
    KF.SpecialEventMonsterCollections[i] = KF.MonsterCollection;
  }
}


function bool CheckReplacement(Actor Other, out byte bSuperRelevant)
{
  local PlayerReplicationInfo pri;
  local SZReplicationInfo szRI;
  local int i;

  if (PlayerReplicationInfo(Other) != none && PlayerReplicationInfo(Other).Owner != none)
  {
    pri = PlayerReplicationInfo(Other);
    szRI = spawn(class'SZReplicationInfo', pri.Owner);
    szRI.ownerPRI = pri;
    szRI.NextReplicationInfo = pri.CustomReplicationInfo;
    pri.CustomReplicationInfo = szRI;
  }
  else if (ZombieSuperClot(Other) != none)
  {
    ZombieSuperClot(Other).ignoreBodyShotResistance = disableBodyShotResistance;
    return true;
  }
  else if (ZombieSuperStalker(Other) != none && disableBleeding)
  {
    ZombieSuperStalker(Other).MeleeDamage = class'ZombieStalkerBase'.default.MeleeDamage;
    return true;
  }
  else if ((ZombieSuperCrawler(Other) != none && disablePoison))
  {
    return true;
  }
  else if (ZombieSuperFP(Other) != none && !disableFpSecret)
  {
    ZombieSuperFP(Other).resistances.Length = fpResistances.Length;
    for (i = 0; i < fpResistances.Length; i++)
    {
      ZombieSuperFP(Other).resistances[i].dmgType = fpResistances[i].dmgType;
      ZombieSuperFP(Other).resistances[i].scale = fpResistances[i].scale;
    }
    ZombieSuperFP(Other).mutRef = self;
  }
  return true;
}


static function FillPlayInfo(PlayInfo PlayInfo)
{
  local string mutConfigGroup;
  local int i;

  super.FillPlayInfo(PlayInfo);

  mutConfigGroup = "Super Zombie Config"; 
  for (i = 0; i < default.propDescripArray.Length; i++)
  {
    PlayInfo.AddSetting(mutConfigGroup, default.propDescripArray[i].property, default.propDescripArray[i].shortDescription, 0, 0, "Check");
  }
  PlayInfo.AddSetting(mutConfigGroup, "bareMutatorMode", "Enable bare mutator mode", 0, 0, "Check",,,,true);
}


static event string GetDescriptionText(string property)
{
  local int i;

  for (i = 0; i < default.propDescripArray.Length; i++)
  {
    if (default.propDescripArray[i].property == property)
    {
      return default.propDescripArray[i].longDescription;
    }
  }

  switch (property)
  {
    case "bareMutatorMode":
      return "Mutator only adds self to package map, manages bleed, poison, and evolution abilities, and sets up HUD effects";
  }
  return super.GetDescriptionText(property);
}


// add our interaction
simulated function Tick(float DeltaTime)
{
  local PlayerController PC;

  PC = Level.GetLocalPlayerController();
  if (PC != None)
  {
    // no more hardcoded strings
    PC.Player.InteractionMaster.AddInteraction(string(class'SZInteraction'), PC.Player);
  }
  Disable('Tick');
}


defaultproperties
{
  GroupName="KFSuperZombieMut"
  FriendlyName="Super Zombies v2.4.0"
  Description="Gives specimens new abilities and behaviors."

  RemoteRole=ROLE_SimulatedProxy
  bAlwaysRelevant=true

  replacementArray(0)=(oldClass="KFChar.ZombieFleshPound",newClass="SuperZombieMut.ZombieSuperFP")
  replacementArray(1)=(oldClass="KFChar.ZombieGorefast",newClass="SuperZombieMut.ZombieSuperGorefast")
  replacementArray(2)=(oldClass="KFChar.ZombieStalker",newClass="SuperZombieMut.ZombieSuperStalker")
  replacementArray(3)=(oldClass="KFChar.ZombieSiren",newClass="SuperZombieMut.ZombieSuperSiren")
  replacementArray(4)=(oldClass="KFChar.ZombieScrake",newClass="SuperZombieMut.ZombieSuperScrake")
  replacementArray(5)=(oldClass="KFChar.ZombieHusk",newClass="SuperZombieMut.ZombieSuperHusk")
  replacementArray(6)=(oldClass="KFChar.ZombieCrawler",newClass="SuperZombieMut.ZombieSuperCrawler")
  replacementArray(7)=(oldClass="KFChar.ZombieBloat",newClass="SuperZombieMut.ZombieSuperBloat")
  replacementArray(8)=(oldClass="KFChar.ZombieClot",newClass="SuperZombieMut.ZombieSuperClot")

  propDescripArray(00)=(property="bReplaceCrawler",longDescription="Replace Crawlers with Super Crawlers",shortDescription="Replace Crawlers")
  propDescripArray(01)=(property="bReplaceStalker",longDescription="Replace Stalkers with Super Stalkers",shortDescription="Replace Stalkers")
  propDescripArray(02)=(property="bReplaceClot",longDescription="Replace Clots with Super Clots",shortDescription="Replace Clots")
  propDescripArray(03)=(property="bReplaceGorefast",longDescription="Replace Gorefasts with Super Gorefasts",shortDescription="Replace Gorefasts")
  propDescripArray(04)=(property="bReplaceBloat",longDescription="Replace Bloats with Super Bloats",shortDescription="Replace Bloats")
  propDescripArray(05)=(property="bReplaceSiren",longDescription="Replace Sirens with Super Sirens",shortDescription="Replace Sirens")
  propDescripArray(06)=(property="bReplaceHusk",longDescription="Replace Husks with Super Husks",shortDescription="Replace Husks")
  propDescripArray(07)=(property="bReplaceScrake",longDescription="Replace Scrakes with Super Scrakes",shortDescription="Replace Scrakes")
  propDescripArray(08)=(property="bReplaceFleshpound",longDescription="Replace Fleshpounds with Super Fleshpounds",shortDescription="Replace Fleshpounds")
  propDescripArray(09)=(property="bReplaceBoss",longDescription="Replace the Patriarch with the Super Patriarch",shortDescription="Replace Patriarch")
  propDescripArray(10)=(Property="disableBleeding",longDescription="Disables bleed effect from stalker attacks and restores their melee damage to normal",shortDescription="I don't have bandages")
  propDescripArray(11)=(Property="disablePoison",longDescription="Disables poison effect from crawler attacks",shortDescription="I don't have antidotes")
  propDescripArray(12)=(Property="disableFpSecret",longDescription="Master override to disable fleshpound evolution",shortDescription="I can't adapt")
  propDescripArray(13)=(Property="disableBodyShotResistance",longDescription="Disables clot resistance to body shots",shortDescription="I can't aim")
}