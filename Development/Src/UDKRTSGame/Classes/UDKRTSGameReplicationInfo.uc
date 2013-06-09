//=============================================================================
// UDKRTSGameReplicationInfo: Custom game replication info which holds data
// for the RTS game.
//
// This class is instanced by the GameInfo automatically and stores game data
// which is important for clients as well.
// 
// Copyright 1998-2011 Epic Games, Inc. All Rights Reserved.
//=============================================================================
class UDKRTSGameReplicationInfo extends GameReplicationInfo;

// Cache of all the resources in the game
var array<UDKRTSResource> Resources;

/**
 * Adds a team to the teams array
 *
 * @param		Index			Index to insert the team into
 * @param		TeamInfo		Team info to insert
 */
simulated function SetTeam(int Index, TeamInfo TeamInfo)
{
	if (Index >= 0)
	{
		if (Index >= Teams.Length)
		{
			Teams.Length = Index + 1;
		}

		Teams[Index] = TeamInfo;
	}
}

/**
 * Adds a resource to the resources array
 *
 * @param			UDKRTSResource			Resource to insert
 */
simulated function AddResource(UDKRTSResource UDKRTSResource)
{
	if (Resources.Find(UDKRTSResource) == INDEX_NONE)
	{
		Resources.AddItem(UDKRTSResource);
	}
}

/**
 * Removes a resource from the resources array
 *
 * @param			UDKRTSResource			Resource to remove
 */
simulated function RemoveResource(UDKRTSResource UDKRTSResource)
{
	Resources.RemoveItem(UDKRTSResource);
}

defaultproperties
{
}