//=============================================================================
// UDKRTSCheatManager: Cheat Manager subclass to handle cheats for the
// strategy game.
//
// This class handles all the cheat commands used by the strategy games.
// 
// Copyright 1998-2011 Epic Games, Inc. All Rights Reserved.
//=============================================================================
class UDKRTSCheatManager extends CheatManager;

/**
 * Damage all structures owned by this player
 *
 * @param		DamageAmount		Amount to damage all structures
 */
exec function DamageAllStructures(int DamageAmount)
{
	local UDKRTSTeamInfo UDKRTSTeamInfo;
	local int i;

	UDKRTSTeamInfo = UDKRTSTeamInfo(PlayerReplicationInfo.Team);
	if (UDKRTSTeamInfo != None && UDKRTSTeamInfo.Structures.Length > 0)
	{
		for (i = 0; i < UDKRTSTeamInfo.Structures.Length; ++i)
		{
			if (UDKRTSTeamInfo.Structures[i] != None)
			{
				UDKRTSTeamInfo.Structures[i].TakeDamage(DamageAmount, None, UDKRTSTeamInfo.Structures[i].Location, Vect(0.f, 0.f, 0.f), class'DamageType');
			}
		}
	}
}

/**
 * Damage all units owned by this player
 */
exec function KillAllUnits()
{
	local UDKRTSTeamInfo UDKRTSTeamInfo;
	local int i;

	UDKRTSTeamInfo = UDKRTSTeamInfo(PlayerReplicationInfo.Team);
	if (UDKRTSTeamInfo != None && UDKRTSTeamInfo.Pawns.Length > 0)
	{
		for (i = 0; i < UDKRTSTeamInfo.Pawns.Length; ++i)
		{
			if (UDKRTSTeamInfo.Pawns[i] != None)
			{
				UDKRTSTeamInfo.Pawns[i].TakeDamage(16384, None, UDKRTSTeamInfo.Pawns[i].Location, Vect(0.f, 0.f, 0.f), class'DamageType');
			}
		}
	}
}

defaultproperties
{
}