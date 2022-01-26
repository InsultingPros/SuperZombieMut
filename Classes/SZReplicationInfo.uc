class SZReplicationInfo extends LinkedReplicationInfo;


var PlayerReplicationInfo ownerPRI;
var int numClotsAttached;


static function SZReplicationInfo findSZri(PlayerReplicationInfo pri)
{
  local LinkedReplicationInfo lriIt;
  local SZReplicationInfo repInfo;

  if (pri == none)
    return none;
    
  lriIt = pri.CustomReplicationInfo;
  while (lriIt != none && lriIt.class != class'SZReplicationInfo')
  {
    lriIt = lriIt.NextReplicationInfo;
  }

  if (lriIt == none)
  {
    foreach pri.DynamicActors(Class'SZReplicationInfo', repInfo)
    {
      if (repInfo.ownerPRI == pri)
        return repInfo;
    }
    return none;
  }

  return SZReplicationInfo(lriIt);
}


defaultproperties{}