class ZombieSuperBoss extends ZombieBoss_STANDARD;


// Minimum damage the patriarch will take before charging any players within 700uu
var int ChargeDamageThreshold;

// True if the pariarch just spawned. The flag will prevent the patriarch from attacking pipe bombs during the intro scene
var bool bJustSpawned;

// spawnTimer                  track how long the patriarch has spawned
// attackPipeCoolDown          cool down timer so the patriarch will not shoot another 
//                             pile of pipes until his first rocket as exploded
// LastDamageTime2             Serves the same function as LastDamageTime.  Old usage was flawed and would never work
// ChargeDamage2               Serves the same function as ChargeDamage.  Old usage was flawed and never work
var float spawnTimer, attackPipeCoolDown, LastDamageTime2, ChargeDamage2;


// Give the patriarch more to do during each tick
simulated function Tick(float DeltaTime)
{
  local PipeBombProjectile checkProjectile;
  local PipeBombProjectile lastProjectile;
  local KFHumanPawn checkHP, lastHP;
  local int pipeCount,playerCount;
  local bool bBaseState;

  bBaseState = isInState('ZombieSuperBoss');

  super.Tick(DeltaTime);

  // If the patriarch has finished his introduction, the pipe bomb cooldown timer has expire 
  // and is in the base state, checking if a pipe bomb pile is visible
  if (!bJustSpawned && attackPipeCoolDown <= 0.0 && bBaseState)
  {
    // Count how many pipe bombs are visible
    foreach VisibleActors(class'PipeBombProjectile', checkProjectile)
    {
      pipeCount++;
      lastProjectile = checkProjectile;
    }
    if (pipeCount >= 2)
    {
      // Count how many players are visible within its blast radius
      foreach lastProjectile.VisibleActors(class'KFHumanPawn', checkHP)
      {
        playerCount++;
        lastHP = checkHP;
      }
      if (playerCount == 0 || VSize(lastHP.Location - lastProjectile.Location) <= class'BossLAWProj'.default.DamageRadius)
      {
        Controller.Target = lastProjectile;
        Controller.Focus = lastProjectile;
        GotoState('AttackPipes');

        // Calculate how long the LAW rocket will travel so the patriarch doesn't fire another one 
        // at the same pile until the first one detonates
        attackPipeCoolDown= VSize(Location - lastProjectile.Location)/(class'BossLAWProj'.default.MaxSpeed)+GetAnimDuration('PreFireMissile');
      }
      else
      {
        SetAnimAction('transition');
        LastForceChargeTime = Level.TimeSeconds;
        GoToState('ChargePipes');
      }
    }
  }
  spawnTimer += DeltaTime;
  attackPipeCoolDown = FMax(0,attackPipeCoolDown-DeltaTime);
  bJustSpawned = (spawnTimer <= GetAnimDuration('Entrance'));
}


//=============================================================================
//                              ammo class == none fix
//=============================================================================

state FireMissile
{
  function AnimEnd(int Channel)
  {
    local vector Start;
    local Rotator R;

    Start = GetBoneCoords('tip').Origin;

    // at least shoot at someone, not walls
    if (Controller.Target == none)
      Controller.Target = Controller.Enemy;

    // fix MyAmmo none logs
    if (!SavedFireProperties.bInitialized)
    {
      SavedFireProperties.AmmoClass = class'SkaarjAmmo';
      SavedFireProperties.ProjectileClass = class'BossLAWProj';
      SavedFireProperties.WarnTargetPct = 0.15;
      SavedFireProperties.MaxRange = 10000;
      SavedFireProperties.bTossed = false;
      SavedFireProperties.bTrySplash = false;
      SavedFireProperties.bLeadTarget = true;
      SavedFireProperties.bInstantHit = true;
      SavedFireProperties.bInitialized = true;
    }

    R = AdjustAim(SavedFireProperties,Start,100);
    PlaySound(RocketFireSound,SLOT_Interact,2.0,,TransientSoundRadius,,false);
    // add proper projectile owner...
    spawn(class'BossLAWProj', self,, Start, R);

    bShotAnim = true;
    Acceleration = vect(0,0,0);
    SetAnimAction('FireEndMissile');
    HandleWaitForAnim('FireEndMissile');

    // Randomly send out a message about Patriarch shooting a rocket(5% chance)
    if ( FRand() < 0.05 && Controller.Enemy != none && PlayerController(Controller.Enemy.Controller) != none )
    {
      PlayerController(Controller.Enemy.Controller).Speech('AUTO', 10, "");
    }

    GoToState('');
  }
}


// Temp state for when the Patriarch attacks a pipe pile
state AttackPipes
{
Ignores RangedAttack;

  function BeginState()
  {
    bShotAnim = true;
    Acceleration = vect(0,0,0);
    SetAnimAction('PreFireMissile');
    HandleWaitForAnim('PreFireMissile');
    GoToState('FireMissile');
  }
}


//=============================================================================
//                              ctrl == none fixes
//=============================================================================

function bool MeleeDamageTarget(int hitdamage, vector pushdir)
{
  if (Controller != none && Controller.Target != none && Controller.Target.IsA('NetKActor'))
    pushdir = Normal(Controller.Target.Location - Location) * 100000;

  return super(KFMonster).MeleeDamageTarget(hitdamage, pushdir);
}


// non-state one
function ClawDamageTarget()
{
  local vector PushDir;
  local name Anim;
  local float frame,rate;
  local float UsedMeleeDamage;
  local bool bDamagedSomeone;
  local KFHumanPawn P;
  local Actor OldTarget;

  // check this from the very start to prevent any log spam
  if (Controller == none || IsInState('ZombieDying'))
    return;

  if (MeleeDamage > 1)
    UsedMeleeDamage = (MeleeDamage - (MeleeDamage * 0.05)) + (MeleeDamage * (FRand() * 0.1));
  else
    UsedMeleeDamage = MeleeDamage;

  GetAnimParams(1, Anim,frame,rate);

  if (Controller.Target != none)
    PushDir = (damageForce * Normal(Controller.Target.Location - Location));
  else
    PushDir = damageForce * vector(Rotation);

  // merging 2 similar checks
  // dick animation
  if (Anim == 'MeleeImpale')
  {
    MeleeRange = ImpaleMeleeDamageRange;
    bDamagedSomeone = MeleeDamageTarget(UsedMeleeDamage, PushDir);
  }
  // the hand animation
  else
  {
    MeleeRange = ClawMeleeDamageRange;
    OldTarget = Controller.Target;

    foreach DynamicActors(class'KFHumanPawn', P)
    {
      if ( (P.Location - Location) dot PushDir > 0.0 ) // Added dot Product check in Balance Round 3
      {
        Controller.Target = P;
        bDamagedSomeone = bDamagedSomeone || MeleeDamageTarget(UsedMeleeDamage, damageForce * Normal(P.Location - Location)); // Always pushing players away added in Balance Round 3
      }
    }

    Controller.Target = OldTarget;
  }

  MeleeRange = default.MeleeRange;

  if (bDamagedSomeone)
  {
    if (Anim == 'MeleeImpale')
      PlaySound(MeleeImpaleHitSound, SLOT_Interact, 2.0);
    else
      PlaySound(MeleeAttackHitSound, SLOT_Interact, 2.0);
  }
}


state Charging
{
  function BeginState()
  {
    super.BeginState();
    // Randomly make the patriach want to land 2 consecutive melee strikes
    NumChargeAttacks = 1 + round(FRand());
  }

  function bool MeleeDamageTarget(int hitdamage, vector pushdir)
  {
    local bool RetVal;

    RetVal = Global.MeleeDamageTarget(hitdamage, pushdir*1.5);

    // only subtract is the target was hit
    if (RetVal)
      NumChargeAttacks--;
    return RetVal;
  }
}


// State to have the patriarch charge right through the pipe bombs.
state ChargePipes extends Charging
{
  function RangedAttack(Actor A)
  {
    if (VSize(A.Location-Location) > 700 && Level.TimeSeconds - LastForceChargeTime > 3.0)
      GoToState('');
    if (bShotAnim)
      return;
    else if (IsCloseEnuf(A))
    {
      if (bCloaked)
        UnCloakBoss();
      bShotAnim = true;
      Acceleration = vect(0,0,0);
      Acceleration = (A.Location-Location);
      SetAnimAction('MeleeClaw');
      // PlaySound(sound'Claw2s', SLOT_None); Claw2s
    }
  }
}


// Allow the patriarch to automatically destroy any welded door in his path
state Escaping
{ 
  function DoorAttack(Actor A)
  {
    local vector hitLocation;
    local vector momentum;

    if (bShotAnim)
      return;
    else if (KFDoorMover(A) != none)
    {
      hitLocation = vect(0.0,0.0,0.0);
      momentum = vect(0.0,0.0,0.0);
      KFDoorMover(A).Health = 0;
      KFDoorMover(A).GoBang(self, hitLocation, momentum, class'BossLAWProj'.default.MyDamageType);
    }
  }
}


// Slightly change the conditions for charging from damage
function bool ShouldChargeFromDamage()
{
  // If we don't want to heal, charge whoever damaged us!!!
  if ((SyringeCount == 0 && Health < HealingLevels[0]) || (SyringeCount == 1 && Health < HealingLevels[1]) || (SyringeCount == 2 && Health < HealingLevels[2]))
  {
    return false;
  }
  return !bChargingPlayer;
}


// Give the patriarch new responses when he takes damage
function TakeDamage(int Damage, Pawn InstigatedBy, Vector Hitlocation, Vector Momentum, class<DamageType> damageType, optional int HitIndex)
{  
  local float DamagerDistSq;
  local float oldHealth;

  OldHealth = Health;
  super.TakeDamage(Damage,instigatedBy,hitlocation,Momentum,damageType);

  // Reset the charge accumulator if 10 seconds have passed since the patriarch last took damage.  
  // Old Patriarch code had this wrong and never incremented the accumulator
  if (LastDamageTime2 != 0.0 && Level.TimeSeconds - LastDamageTime2 > 10)
  {
    ChargeDamage2 = 0;
  }

  ChargeDamage2 += (OldHealth-Health);
  LastDamageTime2 = Level.TimeSeconds;
  if (ShouldChargeFromDamage() && ChargeDamage2 > ChargeDamageThreshold)
  {
    if (InstigatedBy != none)
    {
      DamagerDistSq = VSizeSquared(Location - InstigatedBy.Location);
      if (DamagerDistSq < (700 * 700))
      {
        ChargeDamage2 = 0;
        LastForceChargeTime = Level.TimeSeconds;
        GoToState('Charging');
        return;
      }
    }
  }
}


function RangedAttack(Actor A)
{
  local float D;
  local bool bOnlyE;
  local bool bDesireChainGun;

  // Randomly make him want to chaingun more
  if (Controller.LineOfSightTo(A) && FRand() < 0.15 && LastChainGunTime<Level.TimeSeconds)
  {
    bDesireChainGun = true;
  }

  if (bShotAnim)
    return;
  D = VSize(A.Location-Location);
  bOnlyE = (Pawn(A)!=none && OnlyEnemyAround(Pawn(A)));
  if (IsCloseEnuf(A))
  {
    bShotAnim = true;
    if (Health > 1500 && Pawn(A) != none && FRand() < 0.5)
    {
      SetAnimAction('MeleeImpale');
    }
    else
    {
      SetAnimAction('MeleeClaw');
      // PlaySound(sound'Claw2s', SLOT_None); KFTODO: Replace this
    }
  }
  // SZ: Reduce min sneak time interval to 15s
  else if (Level.TimeSeconds - LastSneakedTime > 15.0)
  {
    if (FRand() < 0.3)
    {
      // Wait another 20 to try this again
      LastSneakedTime = Level.TimeSeconds; //+FRand()*120;
      return;
    }
    SetAnimAction('transition');
    GoToState('SneakAround');
  }
  else if (bChargingPlayer && (bOnlyE || D<200))
    return;
  // SZ: Reduce min charge interval to [5,7] seconds
  else if (!bDesireChainGun && !bChargingPlayer && (D<300 || (D<700 && bOnlyE)) &&
        (Level.TimeSeconds - LastChargeTime > (5.0 + 2.0 * FRand())) )
  {
    SetAnimAction('transition');
    GoToState('Charging');
  }
  else if (LastMissileTime < Level.TimeSeconds && D > 500)
  {
    if (!Controller.LineOfSightTo(A) || FRand() > 0.75)
    {
      LastMissileTime = Level.TimeSeconds+FRand() * 5;
      return;
    }

    // SZ: Reduce min missile interval to [10,15] seconds
    LastMissileTime = Level.TimeSeconds + 10 + FRand() * 5;

    bShotAnim = true;
    Acceleration = vect(0,0,0);
    SetAnimAction('PreFireMissile');

    HandleWaitForAnim('PreFireMissile');

    GoToState('FireMissile');
  }
  else if (!bWaitForAnim && !bShotAnim && LastChainGunTime < Level.TimeSeconds)
  {
    if (!Controller.LineOfSightTo(A) || FRand() > 0.85)
    {
      LastChainGunTime = Level.TimeSeconds + FRand() * 4;
      return;
    }

    // SZ: Reduce min chaingun interval to [5,10] seconds
    LastChainGunTime = Level.TimeSeconds + 5 + FRand() * 5;

    bShotAnim = true;
    Acceleration = vect(0,0,0);
    SetAnimAction('PreFireMG');

    HandleWaitForAnim('PreFireMG');
    MGFireCounter =  Rand(60) + 35;

    GoToState('FireChaingun');
  }
}


//=============================================================================
//                   headshot fix while machinegunning
//=============================================================================

state FireChaingun
{
  function TakeDamage( int Damage, Pawn InstigatedBy, Vector Hitlocation, Vector Momentum, class<DamageType> damageType, optional int HitIndex)
  {
    local float EnemyDistSq, DamagerDistSq;

    // changed vect(0,0,0) with Momentum
    global.TakeDamage(Damage,instigatedBy,hitlocation,Momentum,damageType);

    // if someone close up is shooting us, just charge them
    if (InstigatedBy != none)
    {
      DamagerDistSq = VSizeSquared(Location - InstigatedBy.Location);

      if ((ChargeDamage > 200 && DamagerDistSq < (500 * 500)) || DamagerDistSq < (100 * 100))
      {
        SetAnimAction('transition');
        GoToState('Charging');
        return;
      }
    }

    if (Controller.Enemy != none && InstigatedBy != none && InstigatedBy != Controller.Enemy)
    {
      EnemyDistSq = VSizeSquared(Location - Controller.Enemy.Location);
      DamagerDistSq = VSizeSquared(Location - InstigatedBy.Location);
    }

    if (InstigatedBy != none && (DamagerDistSq < EnemyDistSq || Controller.Enemy == none))
    {
      MonsterController(Controller).ChangeEnemy(InstigatedBy,Controller.CanSee(InstigatedBy));
      Controller.Target = InstigatedBy;
      Controller.Focus = InstigatedBy;

      if (DamagerDistSq < (500 * 500))
      {
        SetAnimAction('transition');
        GoToState('Charging');
      }
    }
  }
}


defaultproperties
{
  MenuName="Super Patriarch"
  ChargeDamageThreshold=1000
  bJustSpawned=true
  ControllerClass=class'ZombieSuperBossController'
  ImpaleMeleeDamageRange=75
}