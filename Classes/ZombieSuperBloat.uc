class ZombieSuperBloat extends ZombieBloat_STANDARD;


// bAmIBarfing     true if the bloat is in the barf animation
var bool bAmIBarfing;

// bileCoolDownTimer   timer that counts to when the bloat will spawn another set of pile pellets
// bileCoolDownMax     max time in between pellet spawns
var float bileCoolDownTimer, bileCoolDownMax;


// Spawn extra sets of bile pellets here once the bile cool down timer
// has reached the max limit
simulated function Tick(float DeltaTime)
{
  super.Tick(DeltaTime);

  if (!bDecapitated && bAmIBarfing)
  {
    bileCoolDownTimer += DeltaTime;
    if (bileCoolDownTimer >= bileCoolDownMax)
    {
      SpawnTwoShots();
      bileCoolDownTimer = 0.0;
    }
  }
}


// eat all shotgun pellets
function Touch(Actor Other)
{
  super.Touch(Other);
  if (Other.IsA('ShotgunBullet'))
  {
    ShotgunBullet(Other).Damage = 0;
  }
}


function RangedAttack(Actor A)
{
  local int LastFireTime;

  if (bShotAnim)
    return;

  if (Physics == PHYS_Swimming)
  {
    SetAnimAction('Claw');
    bShotAnim = true;
    LastFireTime = Level.TimeSeconds;
  }
  else if (VSize(A.Location - Location) < MeleeRange + CollisionRadius + A.CollisionRadius)
  {
    bShotAnim = true;
    LastFireTime = Level.TimeSeconds;
    SetAnimAction('Claw');
    // PlaySound(sound'Claw2s', SLOT_Interact); KFTODO: Replace this
    Controller.bPreparingMove = true;
    Acceleration = vect(0,0,0);
  }
  else if ((KFDoorMover(A) != none || VSize(A.Location-Location) <= 250) && !bDecapitated)
  {
    bShotAnim = true;
    SetAnimAction('ZombieBarfMoving');
    RunAttackTimeout = GetAnimDuration('ZombieBarf', 1.0);
    bMovingPukeAttack=true;

    // Randomly send out a message about Bloat Vomit burning(3% chance)
    if (FRand() < 0.03 && KFHumanPawn(A) != none && PlayerController(KFHumanPawn(A).Controller) != none)
    {
      PlayerController(KFHumanPawn(A).Controller).Speech('AUTO', 7, "");
    }
  }
}


// ZombieBarf animation triggers this
function SpawnTwoShots()
{
  local vector X,Y,Z, FireStart;
  local rotator FireRotation;

  // check this from the very start to prevent any log spam / dead bloats dont barf!
  if (Controller == none || IsInState('ZombieDying'))
    return;

  if (KFDoorMover(Controller.Target) != none)
  {
    Controller.Target.TakeDamage(22, Self, Location, vect(0,0,0), class'DamTypeVomit');
    return;
  }

  GetAxes(Rotation,X,Y,Z);
  FireStart = Location+(vect(30,0,64) >> Rotation)*DrawScale;
  if (!SavedFireProperties.bInitialized)
  {
    SavedFireProperties.AmmoClass = class'SkaarjAmmo';
    SavedFireProperties.ProjectileClass = class'KFBloatVomit';
    SavedFireProperties.WarnTargetPct = 1;
    SavedFireProperties.MaxRange = 500;
    SavedFireProperties.bTossed = false;
    SavedFireProperties.bTrySplash = false;
    SavedFireProperties.bLeadTarget = true;
    SavedFireProperties.bInstantHit = true;
    SavedFireProperties.bInitialized = true;
  }

  // Turn off extra collision before spawning vomit, otherwise spawn fails
  ToggleAuxCollision(false);
  FireRotation = Controller.AdjustAim(SavedFireProperties,FireStart,600);
  Spawn(class'KFBloatVomit',self,,FireStart,FireRotation);

  FireStart -= (0.5*CollisionRadius*Y);
  FireRotation.Yaw -= 1200;
  spawn(class'KFBloatVomit',self,,FireStart, FireRotation);

  FireStart += (CollisionRadius*Y);
  FireRotation.Yaw += 2400;
  spawn(class'KFBloatVomit', self,, FireStart, FireRotation);
  // Turn extra collision back on
  ToggleAuxCollision(true);

  bAmIBarfing = true;
}


simulated function AnimEnd(int Channel)
{
  local name Sequence;
  local float Frame, Rate;

  GetAnimParams(ExpectingChannel, Sequence, Frame, Rate);

  super.AnimEnd(Channel);

  if (Sequence == 'ZombieBarf')
    bAmIBarfing = false;
}


defaultproperties
{
  MenuName="Super Bloat"
  bileCoolDownMax=0.75
  bAmIBarfing=false
}