//=============================================================================
// UDKRTSTeamInfo: Custom TeamInfo which contains relevant information about
// teams used in a RTS game.
//
// This class stores relevant information about teams that are participating
// in a RTS game.
// 
// Copyright 1998-2011 Epic Games, Inc. All Rights Reserved.
//=============================================================================
class UDKRTSTeamInfo extends TeamInfo;

// Array of all pawns that this team owns
var ProtectedWrite array<UDKRTSPawn> Pawns;
// Array of all structures that this team owns
var ProtectedWrite array<UDKRTSStructure> Structures;
// Array of all upgrades that this team owns
var ProtectedWrite array<UDKRTSUpgrade> Upgrades;
// Cached evaluation of the population of all of the pawns
var ProtectedWrite int Population;
// Palette of team colors
var const array<Color> DefaultPalette;

/**
 * Called when a variable with the property flag "RepNotify" is replicated
 *
 * @param		VarName			Name of the variable which was replicated
 */
simulated event ReplicatedEvent(name VarName)
{
	if (VarName == 'TeamIndex')
	{
		// Set the team index
		SetTeamIndex(TeamIndex);
	}

	Super.ReplicatedEvent(VarName);
}

/**
 * Called when the team receives its team index
 *
 * @param		NewTeamIndex		Team index to assign to this team
 */
simulated function SetTeamIndex(int NewTeamIndex)
{
	TeamIndex = NewTeamIndex;
	// Assign the team color according to the team index
	if (NewTeamIndex >= 0 && NewTeamIndex < DefaultPalette.Length)
	{
		TeamColor = DefaultPalette[NewTeamIndex];
	}
}

/**
 * Adds an upgrade to the team and notifies everything
 *
 * @param		Upgrade		Upgrade to add
 */
simulated function AddUpgrade(UDKRTSUpgrade Upgrade)
{
	local int i;

	// Check that this upgrade hasn't been added already...
	if (Upgrades.Find(Upgrade) == INDEX_NONE)
	{
		// Check if the upgrade allows multiple instances
		if (!Upgrade.AllowedMultipleInstances && Upgrades.Length > 0)
		{
			for (i = 0; i < Upgrades.Length; ++i)
			{
				// Check the archetype parameters, if they are the same then destroy the instanced upgrade
				if (Upgrades[i] != None && Upgrades[i].ObjectArchetype == Upgrade.ObjectArchetype)
				{
					Upgrade.Destroy();
					return;
				}
			}
		}

		Upgrades.AddItem(Upgrade);

		// Notify pawns to update themselves based on upgrades
		if (Pawns.Length > 0)
		{
			for (i = 0; i < Pawns.Length; ++i)
			{
				if (Pawns[i] != None && Pawns[i].Health > 0)
				{
					Pawns[i].ApplyUpgrades();
				}
			}
		}
	}
}

/**
 * Removes this upgrade from the upgrades array
 *
 * @param		Upgrade		Upgrade to remove
 */
simulated function RemoveUpgrade(UDKRTSUpgrade Upgrade)
{
	local int i;

	Upgrades.RemoveItem(Upgrade);

	// Notify pawns to update themselves based on upgrades
	if (Pawns.Length > 0)
	{
		for (i = 0; i < Pawns.Length; ++i)
		{
			if (Pawns[i] != None && Pawns[i].Health > 0)
			{
				Pawns[i].ApplyUpgrades();
			}
		}
	}
}

/**
 * Adds a pawn to the pawn array
 *
 * @param		Pawn		Pawn to add
 */
simulated function AddPawn(UDKRTSPawn Pawn)
{
	// Check if the pawn is within the pawn array already
	if (Pawns.Find(Pawn) == INDEX_NONE)
	{
		Pawns.AddItem(Pawn);
		// Update the population
		Population += Pawn.PopulationCost;
	}
}

/**
 * Removes a pawn from the pawn array
 *
 * @param		Pawn		Pawn to remove
 */
simulated function RemovePawn(UDKRTSPawn Pawn)
{
	local int Index;
	local UDKRTSGameInfo UDKRTSGameInfo;

	Index = Pawns.Find(Pawn);
	if (Index != INDEX_NONE)
	{
		// Remove from the pawn array
		Pawns.Remove(Index, 1);
		// Update the population
		Population -= Pawn.PopulationCost;
	}

	// Check if this team has lost everything, if it has then it needs to notify the game info
	if (Role == ROLE_Authority && HasLostEverything())
	{
		UDKRTSGameInfo = UDKRTSGameInfo(WorldInfo.Game);
		if (UDKRTSGameInfo != None)
		{
			UDKRTSGameInfo.CheckForGameEnd();
		}
	}
}

/**
 * Adds a structure to the structure array
 *
 * @param		Structure		Structure to add
 */
simulated function AddStructure(UDKRTSStructure Structure)
{
	// Check if the structure already exists in the structure array
	if (Structures.Find(Structure) == INDEX_NONE)
	{
		Structures.AddItem(Structure);
	}
}

/**
 * Removes a structure from the structure array
 *
 * @param		Structure		Structure to remove
 */
simulated function RemoveStructure(UDKRTSStructure Structure)
{
	local UDKRTSGameInfo UDKRTSGameInfo;

	// Remove structure
	Structures.RemoveItem(Structure);

	// Check if this team has lost everything, if it has then it needs to notify the game info
	if (Role == ROLE_Authority && HasLostEverything())
	{
		UDKRTSGameInfo = UDKRTSGameInfo(WorldInfo.Game);
		if (UDKRTSGameInfo != None)
		{
			UDKRTSGameInfo.CheckForGameEnd();
		}
	}
}

/**
 * Returns true if the team has lost everything that it needs to stay "alive" in this game
 *
 * @return		Returns true if the pawn array is empty and the structure array is empty
 */
function bool HasLostEverything()
{
	return (Pawns.Length <= 0 && Structures.Length <= 0);
}

defaultproperties
{
	DefaultPalette(0)=(R=255,G=0,B=0,A=255)
	DefaultPalette(1)=(R=0,G=0,B=255,A=255)
	DefaultPalette(2)=(R=0,G=255,B=0,A=255)
	DefaultPalette(3)=(R=255,G=255,B=0,A=255)
	DefaultPalette(4)=(R=0,G=255,B=255,A=255)
	DefaultPalette(5)=(R=255,G=0,B=255,A=255)
}