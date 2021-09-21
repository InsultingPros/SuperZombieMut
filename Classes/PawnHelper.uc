// Poosh (c) https://github.com/poosh/KF-ScrnZedPack/blob/master/Classes/ScrnZedFunc.uc
// Skell (c) https://git.bserved.de/kfpro/kf-kfp/src/branch/master/Classes/PawnHelper.uc
class PawnHelper extends object
  abstract;


// spawn extended zed collision on client side for projector tracing (e.g., laser sights)
// NOTE: No special destroy code is needed. EZCollision is already destroyed on any zed that has it (not role-dependent).
final static function SpawnClientExtendedZCollision(KFMonster M)
{
  if (M.Role < ROLE_Authority)
  {
    if (M.bUseExtendedCollision && M.MyExtCollision == none)
    {
      M.MyExtCollision = M.spawn(class'ClientExtendedZCollision', M);
      // slightly smaller version for non auth clients
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


defaultproperties{}