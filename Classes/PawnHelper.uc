// Poosh (c) https://github.com/poosh/KF-ScrnZedPack/blob/master/Classes/ScrnZedFunc.uc
// Skell (c) https://git.bserved.de/kfpro/kf-kfp/src/branch/master/Classes/PawnHelper.uc
class PawnHelper extends object
  abstract;


// TEST!!! 'fixed' headshots
var private bool bHeadshotSrvAnim;
var private bool bHeadshotSrvDebugAnim;
var private bool bHeadshotSrvTorsoTwist;


// TEST!!! 'fixed' headshots
final static function bool IsHeadShot(KFMonster M, vector HitLoc, vector ray, float AdditionalScale, vector HeadOffset)
{
  local coords C;
  local vector HeadLoc;
  local int look;
  local float sphrad;
  local vector P, HitToSphere;
  local bool bUseAltHeadShotLocation;
  local bool bWasAnimating;

  if (M.HeadBone == '')
    return false;

  // If we are a dedicated server estimate what animation is most likely playing on the client
  if (M.Level.NetMode == NM_DedicatedServer && !M.bShotAnim)
  {
    if (M.Physics == PHYS_Walking)
    {
      bWasAnimating = default.bHeadshotSrvAnim && (M.IsAnimating(0) || M.IsAnimating(1));

      if (!bWasAnimating)
      {
        if (M.bIsCrouched)
          M.PlayAnim(M.IdleCrouchAnim, 1.0, 0.0);
        else
          bUseAltHeadShotLocation=true;
      }
      else if (default.bHeadshotSrvDebugAnim)
      {
        DebugAnim(M);
      }

      if (default.bHeadshotSrvTorsoTwist && M.bDoTorsoTwist && !bUseAltHeadShotLocation)
      {
        M.SmoothViewYaw = M.Rotation.Yaw;
        M.SmoothViewPitch = M.ViewPitch;

        look = (256 * M.ViewPitch) & 65535;
        if (look > 32768)
          look -= 65536;

        M.SetTwistLook(0, look);
      }
    }
    else if (M.Physics == PHYS_Falling || M.Physics == PHYS_Flying)
    {
      M.PlayAnim(M.AirAnims[0], 1.0, 0.0);
    }
    else if (M.Physics == PHYS_Swimming)
    {
      M.PlayAnim(M.SwimAnims[0], 1.0, 0.0);
    }

    if (!bWasAnimating && !bUseAltHeadShotLocation)
    {
      M.SetAnimFrame(0.5);
    }
  }

  if (bUseAltHeadShotLocation)
  {
    HeadLoc = M.Location + (M.OnlineHeadshotOffset >> M.Rotation);
    AdditionalScale *= M.OnlineHeadshotScale;
  }
  else
  {
    C = M.GetBoneCoords(M.HeadBone);

    HeadLoc = C.Origin + (M.HeadHeight * M.HeadScale * C.XAxis) + HeadOffset.X * C.XAxis + HeadOffset.Y * C.YAxis + HeadOffset.Z * c.ZAxis;
  }

  sphrad = m.HeadRadius * m.HeadScale * AdditionalScale;
  sphrad *= sphrad;

  HitToSphere = HeadLoc - HitLoc;
  if (VSizeSquared(HitToSphere) < sphrad)
  {
    return true;
  }

  p = HitLoc + ray * (HitToSphere dot ray);

  return VSizeSquared(P - HeadLoc) < sphrad;
}


final static function DebugAnim(KFMonster M)
{
  local int i;
  local name seq;
  local float frame, rate;
  local vector HeadLoc, SrvLoc, Diff;
  local coords C;

  for (i = 0; i < 2; ++i)
  {
    if (!M.IsAnimating(i))
      continue;
    M.GetAnimParams(i, seq, frame, rate);
    log(M $ " chanel=" $ i $ " anim=" $ seq $ " frame=" $ frame $ " rate=" $ rate);
  }

  C = M.GetboneCoords(M.HeadBone);
  HeadLoc = C.Origin + (M.HeadHeight * M.HeadScale * C.XAxis);
  SrvLoc = M.Location + (M.OnlineHeadshotOffset >> M.Rotation);
  Diff = SrvLoc - HeadLoc;
  log(M $ "server / client head diff: " $ VSize(Diff) $ "u (" $ Diff $ ")");
}


// spawn extended zed collision on client side for projector tracing (e.g., laser sights)
// NOTE: No special destroy code is needed. EZCollision is already destroyed on any zed that has it (not role-dependent).
final static function SpawnClientExtendedZCollision(KFMonster M)
{
  if (M.Role < ROLE_Authority)
  {
    if (M.bUseExtendedCollision && M.MyExtCollision == none)
    {
      M.MyExtCollision = M.spawn(class'ClientExtendedZCollision', M);
      M.MyExtCollision.SetCollisionSize(M.ColRadius, M.ColHeight);

      M.MyExtCollision.bHardAttach = true;
      M.MyExtCollision.SetLocation(M.Location + (M.ColOffset >> M.Rotation));
      M.MyExtCollision.SetPhysics(PHYS_None);
      M.MyExtCollision.SetBase(M);
      M.SavedExtCollision = M.MyExtCollision.bCollideActors;
    }
  }
}


// disable zed collision on death, so it won't alter player movement
final static function DisablePawnCollision(Pawn P)
{
  P.bBlockActors = false;
  P.bBlockPlayers = false;
  P.bBlockProjectiles = false;
  P.bProjTarget = false;
  P.bBlockZeroExtentTraces = false;
  P.bBlockNonZeroExtentTraces = false;
  P.bBlockHitPointTraces = false;
}


defaultproperties
{
  bHeadshotSrvAnim=false
  bHeadshotSrvDebugAnim=true
  bHeadshotSrvTorsoTwist=true
}