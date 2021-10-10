class Procedure_NoUnauthorizedUseOfDeadlyForce extends SwatGame.Procedure
    implements  IInterested_GameEvent_PawnDied;

var config int PenaltyPerEnemy;

var array<SwatEnemy> KilledEnemies;

function PostInitHook()
{
    Super.PostInitHook();

    //register for notifications that interest me
    GetGame().GameEvents.PawnDied.Register(self);
}

//interface IInterested_GameEvent_PawnDied implementation
function OnPawnDied(Pawn Pawn, Actor Killer, bool WasAThreat)
{
    if (!Pawn.IsA('SwatEnemy')) return;

//    if (WasAThreat)
//    {
//        if (GetGame().DebugLeadership)
//            log("[LEADERSHIP] "$class.name
//                $"::OnPawnDied() did *not* add "$Pawn.name
//                $" to its list of KilledEnemies because the SwatEnemy was a threat (so the deadly force was authorized).");
//
//        return; //the deadly force was authorized
//    }

    if (Pawn.IsA('SwatEnemy') && ISwatEnemy(Pawn).IAmThreat())
    {
        if (GetGame().DebugLeadership)
            log("[LEADERSHIP] "$class.name
                $"::OnPawnDied() did *not* add "$Pawn.name
                $" to its list of KilledEnemies because the SwatEnemy was a threat (so the deadly force was authorized).");

        return; //the deadly force was authorized
    }


    //running close in front of an officer with a gun is considered a threat
	if ( ISwatEnemy(Pawn).GetCurrentState() == EnemyState_Flee  )
    {
		//GetGame().PenaltyTriggeredMessage(Pawn(Killer) , "Enemy flee " $!ISwatEnemy(Pawn).GetEnemyCommanderAction().HasFledWithoutUsableWeapon()$  " " );
		if ( VSize(Pawn.Location - Killer.Location) < 500 && !ISwatEnemy(Pawn).GetEnemyCommanderAction().HasFledWithoutUsableWeapon() )
		{
			//GetGame().PenaltyTriggeredMessage(Pawn(Killer) , "Enemy flee: no penalty");
			return;
		}
	}



    if( !Killer.IsA('SwatPlayer') && Pawn(Killer).GetActiveItem().GetSlot() != Slot_Detonator && !Killer.IsA('SniperPawn'))
    {
        if (GetGame().DebugLeadership)
            log("[LEADERSHIP] "$class.name
                $"::OnPawnDied() did *not* add "$Pawn.name
                $" to its list of KilledEnemies because Killer ("$Killer$") was not the local player.");

        return; //we only penalize the player if they did the Killing
    }

    AssertNotInArray( Pawn, KilledEnemies, 'KilledEnemies' );
    Add( Pawn, KilledEnemies );
	TriggerPenaltyMessage(Pawn(Killer));
    GetGame().CampaignStats_TrackPenaltyIssued();

    if (GetGame().DebugLeadership)
        log("[LEADERSHIP] "$class.name
            $" added "$Pawn.name
            $" to its list of KilledEnemies because PawnDied, Killer="$Killer
            $". KilledEnemies.length="$KilledEnemies.length);
}

function string Status()
{
    return string(KilledEnemies.length);
}

//interface IProcedure implementation
function int GetCurrentValue()
{
    if (GetGame().DebugLeadershipStatus)
        log("[LEADERSHIP] "$class.name
            $" is returning CurrentValue = PenaltyPerEnemy * KilledEnemies.length\n"
            $"                           = "$PenaltyPerEnemy$" * "$KilledEnemies.length$"\n"
            $"                           = "$PenaltyPerEnemy * KilledEnemies.length);

    return PenaltyPerEnemy * KilledEnemies.length;
}
