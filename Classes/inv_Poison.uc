class inv_Poison extends Inventory;


var float poisonStartTime, maxSpeedPenaltyTime;


simulated function Tick(float DeltaTime)
{
  if (Level.TimeSeconds - poisonStartTime > maxSpeedPenaltyTime)
    Destroy();
}


simulated function float GetMovementModifierFor(Pawn InPawn)
{
  return 0.5f;
}


defaultproperties
{
  maxSpeedPenaltyTime=5.000000
}