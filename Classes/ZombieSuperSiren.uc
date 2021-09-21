class ZombieSuperSiren extends ZombieSiren_STANDARD;


// ADDITION!!! let users to decide what pull effect they want
var bool bPullThroughWalls;


simulated function PostBeginPlay()
{
  super.PostBeginPlay();

  // fix laser sights
  class'PawnHelper'.static.SpawnClientExtendedZCollision(self);
}


// Modified the function so the screams hit through doors as well as damaging them
simulated function SpawnTwoShots()
{
  // ADDITION!!! headless chickens can't cry
  if (bDecapitated)
    return;

  DoShakeEffect();

  if (Level.NetMode != NM_Client)
  {
    // Deal Actual Damage.
    if (Controller != none && KFDoorMover(Controller.Target) != none)
    {
      Controller.Target.TakeDamage(ScreamDamage * 0.6, self, Location, vect(0,0,0), ScreamDamageType);
      if (bPullThroughWalls)
        HurtRadiusThroughDoor(ScreamDamage * 0.6, ScreamRadius, ScreamDamageType, ScreamForce, Location);
    }
    else if (bPullThroughWalls)
    {
      HurtRadiusThroughDoor(ScreamDamage, ScreamRadius, ScreamDamageType, ScreamForce, Location);
      return;
    }
    else
    {
      HurtRadius(ScreamDamage, ScreamRadius, ScreamDamageType, ScreamForce, Location);
    }
  }
}


// Changed the Super Siren's screen to hit through all objects
// TODO: Make the scream do less damage per non human hit?
simulated function HurtRadiusThroughDoor(float DamageAmount, float DamageRadius, class<DamageType> DamageType, float Momentum, vector HitLocation)
{
  local actor Victims;
  local float damageScale, dist;
  local vector dir;
  local float UsedDamageAmount, usedMomentum;

  if (bHurtEntry)
    return;

  bHurtEntry = true;
  // Changed to CollidingActors
  foreach CollidingActors(class 'Actor', Victims, DamageRadius, HitLocation)
  {
    if (Victims != self && !Victims.IsA('FluidSurfaceInfo') && !Victims.IsA('KFMonster') && !Victims.IsA('ExtendedZCollision'))
    {
      dir = Victims.Location - HitLocation;
      dist = FMax(1,VSize(dir));
      dir = dir/dist;
      damageScale = 1 - FMax(0,(dist - Victims.CollisionRadius)/DamageRadius);

      // If it aint human, don't pull the vortex crap on it.
      if (!Victims.IsA('KFHumanPawn'))
      {
        UsedMomentum = 0;
      }
      else
      {
        UsedMomentum = Momentum;
      }

      // Hack for shattering in interesting ways.
      // Siren always shatters glass
      if (Victims.IsA('KFGlassMover'))
      {
        UsedDamageAmount = 100000;
      }
      else
      {
        UsedDamageAmount = DamageAmount;
      }

      // fixed instigator not set to self!
      Victims.TakeDamage(damageScale * UsedDamageAmount, self, Victims.Location - 0.5 * (Victims.CollisionHeight + Victims.CollisionRadius) * dir,
                (damageScale * UsedMomentum * dir),DamageType);

      if (Instigator != none && Vehicle(Victims) != none && Vehicle(Victims).Health > 0)
        Vehicle(Victims).DriverRadiusDamage(UsedDamageAmount, DamageRadius, Instigator.Controller, DamageType, UsedMomentum, HitLocation);
    }
  }
  bHurtEntry = false;
}


// fixed, original pull effect
simulated function HurtRadius(float DamageAmount, float DamageRadius, class<DamageType> DamageType, float Momentum, vector HitLocation)
{
  local actor Victims;
  local float damageScale, dist;
  local vector dir;
  local float UsedDamageAmount;

  if (bHurtEntry)
    return;

  bHurtEntry = true;
  foreach VisibleCollidingActors(class'Actor', Victims, DamageRadius, HitLocation)
  {
    // don't let blast damage affect fluid - VisibleCollisingActors doesn't really work for them - jag
    // Or Karma actors in this case. Self inflicted Death due to flying chairs is uncool for a zombie of your stature.
    if ((Victims != self) && !Victims.IsA('FluidSurfaceInfo') && !Victims.IsA('KFMonster') && !Victims.IsA('ExtendedZCollision'))
    {
      // bugfix, when pull wasn't applied always  -- PooSH
      Momentum = ScreamForce; 
      dir = Victims.Location - HitLocation;
      dist = FMax(1, VSize(dir));
      dir = dir / dist;
      damageScale = 1 - FMax(0, (dist - Victims.CollisionRadius) / DamageRadius);

      if (!Victims.IsA('KFHumanPawn')) // If it aint human, don't pull the vortex crap on it.
        Momentum = 0;

      if (Victims.IsA('KFGlassMover'))   // Hack for shattering in interesting ways.
      {
        UsedDamageAmount = 100000; // Siren always shatters glass
      }
      else
      {
        UsedDamageAmount = DamageAmount;
      }

      // fixed instigator not set to self!
      Victims.TakeDamage(damageScale * UsedDamageAmount, self, Victims.Location - 0.5 * (Victims.CollisionHeight + Victims.CollisionRadius) * dir,(damageScale * Momentum * dir),DamageType);

      if (Instigator != none && Vehicle(Victims) != none && Vehicle(Victims).Health > 0)
        Vehicle(Victims).DriverRadiusDamage(UsedDamageAmount, DamageRadius, Instigator.Controller, DamageType, Momentum, HitLocation);
    }
  }
  bHurtEntry = false;
}


defaultproperties
{
  MenuName="Super Siren"
  ScreamRadius=700
  ScreamForce=-200000
  bPullThroughWalls=false
}