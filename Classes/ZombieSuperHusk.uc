class ZombieSuperHusk extends ZombieHusk_STANDARD;


// consecutiveShots            How many consecutive shots the Super Husk has taken
// maxConsecutiveShots         Max consecutive shots the Super Husk can take before the cool down timer kicks in
var int consecutiveShots, maxConsecutiveShots;


// MyAmmo spawns from AmmunitionClass! just change it!
// var class<Ammunition> AmmunitionClass;
// var Ammunition MyAmmo;


simulated function PostBeginPlay()
{
  super.PostBeginPlay();

  // and why TWI removed this feature...
  if (Controller != none)
		MyAmmo = spawn(AmmunitionClass);

  // fix laser sights
  class'PawnHelper'.static.SpawnClientExtendedZCollision(self);

  maxConsecutiveShots = Rand(5) + 1;
}


function SpawnTwoShots()
{
  local vector X,Y,Z, FireStart;
  local rotator FireRotation;
  local KFMonsterController KFMonstControl;

  // removes lot's of none log spam, and prevent's dead / falling husk shooting projectile and being moved by other husk's shot
  if (Controller == none || IsInState('ZombieDying') || IsInState('GettingOutOfTheWayOfShot') || Physics == PHYS_Falling)
    return;

  if (KFDoorMover(Controller.Target) != none)
  {
    Controller.Target.TakeDamage(22, self, Location, vect(0,0,0), class'DamTypeVomit');
    return;
  }

  GetAxes(Rotation,X,Y,Z);
  FireStart = GetBoneCoords('Barrel').Origin;

  if (!SavedFireProperties.bInitialized)
  {
    SavedFireProperties.AmmoClass = MyAmmo.Class;
    SavedFireProperties.ProjectileClass = MyAmmo.ProjectileClass;
    SavedFireProperties.WarnTargetPct = MyAmmo.WarnTargetPct;
    SavedFireProperties.MaxRange = MyAmmo.MaxRange;
    SavedFireProperties.bTossed = MyAmmo.bTossed;
    SavedFireProperties.bTrySplash = MyAmmo.bTrySplash;
    SavedFireProperties.bLeadTarget = MyAmmo.bLeadTarget;
    SavedFireProperties.bInstantHit = MyAmmo.bInstantHit;
    SavedFireProperties.bInitialized = true;
  }

  // Turn off extra collision before spawning vomit, otherwise spawn fails
  ToggleAuxCollision(false);

  FireRotation = Controller.AdjustAim(SavedFireProperties, FireStart, 600);

  foreach DynamicActors(class'KFMonsterController', KFMonstControl)
  {
    // ignore zeds that the husk can't actually see... and ignore all fleshpounds, they are heavy
    if (KFMonstControl == none || KFMonstControl != Controller || !LineOfSightTo(KFMonstControl) || ClassIsChildOf(KFMonstControl, class'FleshpoundZombieController'))
      continue;

    if (PointDistToLine(KFMonstControl.Pawn.Location, vector(FireRotation), FireStart) < 75)
    {
      KFMonstControl.GetOutOfTheWayOfShot(vector(FireRotation), FireStart);
    }
  }

  Spawn(SavedFireProperties.ProjectileClass, self,, FireStart, FireRotation);

  // Turn extra collision back on
  ToggleAuxCollision(true);
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
  else if ((KFDoorMover(A) != none || (!Region.Zone.bDistanceFog && VSize(A.Location-Location) <= 65535) ||
        (Region.Zone.bDistanceFog && VSizeSquared(A.Location-Location) < (Square(Region.Zone.DistanceFogEnd) * 0.8)))  // Make him come out of the fog a bit
        && !bDecapitated )
  {
    bShotAnim = true;

    SetAnimAction('ShootBurns');
    Controller.bPreparingMove = true;
    Acceleration = vect(0,0,0);

    // Increment the number of consecutive shtos taken and apply the cool down if needed
    consecutiveShots++;
    if (consecutiveShots < maxConsecutiveShots)
    {
      NextFireProjectileTime = Level.TimeSeconds;
    }
    else
    {
      NextFireProjectileTime = Level.TimeSeconds + ProjectileFireInterval + (FRand() * 2.0);
      consecutiveShots = 0;
    }
  }
}


defaultproperties
{
  MenuName="Super Husk"
  AmmunitionClass=class'ammo_Husk'
  ControllerClass=class'ctrl_ZombieSuperHusk'
}