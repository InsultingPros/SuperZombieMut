class ZombieSuperCrawler extends ZombieCrawler_STANDARD;


simulated function PostBeginPlay()
{
  super.PostBeginPlay();

  // fix laser sights
  class'PawnHelper'.static.SpawnClientExtendedZCollision(self);

  PounceSpeed = Rand(221) + 330;
  MeleeRange = Rand(41) + 50;
}


// Copied from ZombieCrawler.Bump() but changed damage type
// to be the new poison damage type
event Bump(actor Other)
{
  if (bPouncing && KFHumanPawn(Other) != none)
  {
    class'SZReplicationInfo'.static.findSZri(KFHumanPawn(Other).PlayerReplicationInfo).setPoison();
  }
  super.Bump(Other);
}


function bool MeleeDamageTarget(int hitdamage, vector pushdir)
{
  local bool result;

  result = super.MeleeDamageTarget(hitdamage, pushdir);
  if (result && KFHumanPawn(Controller.Target) != none)
  {
    class'SZReplicationInfo'.static.findSZri(KFHumanPawn(Controller.Target).PlayerReplicationInfo).setPoison();
  }
  return result;
}


// disable collision on death, so it won't alter player movement
simulated function PlayDying(class<DamageType> DamageType, vector HitLoc)
{
  super.PlayDying(DamageType, HitLoc);

  class'PawnHelper'.static.DisablePawnCollision(self);
}


state ZombieDying
{
ignores AnimEnd, Trigger, Bump, HitWall, HeadVolumeChange, PhysicsVolumeChange, Falling, BreathTimer, Died, RangedAttack;

  simulated function BeginState()
  {
    class'PawnHelper'.static.DisablePawnCollision(self);

    super.BeginState();
  }
}


defaultproperties
{
  MenuName="Super Crawler"
  GroundSpeed=190.00000
  WaterSpeed=175.00000
  // Crawler does not have "Jump" animation
  // source: https://github.com/poosh/KF-ScrnZedPack/blob/master/Classes/ZedBaseCrawler.uc
  TakeoffAnims(0)="ZombieSpring"
  TakeoffAnims(1)="ZombieSpring"
  TakeoffAnims(2)="ZombieSpring"
  TakeoffAnims(3)="ZombieSpring"
  AirAnims(0)="ZombieLeapIdle"
  AirAnims(1)="ZombieLeapIdle"
  AirAnims(2)="ZombieLeapIdle"
  AirAnims(3)="ZombieLeapIdle"
  LandAnims(0)="Landed"
  LandAnims(1)="Landed"
  LandAnims(2)="Landed"
  LandAnims(3)="Landed"
  AirStillAnim="Jump2"
  TakeoffStillAnim="ZombieSpring"

  // these should not use but just in case
  DoubleJumpAnims(0)="ZombieSpring"
  DoubleJumpAnims(1)="ZombieSpring"
  DoubleJumpAnims(2)="ZombieSpring"
  DoubleJumpAnims(3)="ZombieSpring"
  DodgeAnims(0)="ZombieSpring"
  DodgeAnims(1)="ZombieSpring"
  DodgeAnims(2)="ZombieSpring"
  DodgeAnims(3)="ZombieSpring"
}