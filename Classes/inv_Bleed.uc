class inv_Bleed extends Inventory;


const dmtype_bleed=class'DamTypeStalkerBleed';
var int maxBleedCount;
var private float fBleedPeriod;

var ZombieSuperStalker stalker;


event PostBeginPlay()
{
  super.PostBeginPlay();

  // suicide, HOE
  if (Level.Game.GameDifficulty >= 5.0)
    maxBleedCount = 7;
  // normal, hard
  else if (Level.Game.GameDifficulty >= 2.0)
    maxBleedCount = 5;
  // beginner and everything else
  else
    maxBleedCount = 3;

  // start the timer
  SetTimer(fBleedPeriod, true);
}


event Timer()
{
  local pawn locpawn;
  local bool amAlive;

  locpawn = Pawn(Owner);
  amAlive = locpawn != none && locpawn.Health > 0;

  // if pawn owner is dead or bleed count is done - destroy
  if (!amAlive || maxBleedCount < 0)
  {
    Destroy();
    return;
  }

  maxBleedCount--;

  if (stalker != none)
    locpawn.TakeDamage(2, stalker, locpawn.Location, 
           vect(0, 0, 0), dmtype_bleed);
  else
    locpawn.TakeDamage(2, locpawn, locpawn.Location, 
           vect(0, 0, 0), dmtype_bleed);

  if (locpawn.isA('KFPawn'))
  {
    KFPawn(locpawn).HealthToGive -= 5;
  }
}


// cleanup
function Destroyed()
{
  if (stalker != none)
    stalker = none;

  super.Destroyed();
}


defaultproperties
{
  fBleedPeriod=1.500000
}