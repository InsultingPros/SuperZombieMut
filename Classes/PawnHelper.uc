// source Skell: https://git.bserved.de/kfpro/kf-kfp/src/branch/master/Classes/PawnHelper.uc
class PawnHelper extends object;


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