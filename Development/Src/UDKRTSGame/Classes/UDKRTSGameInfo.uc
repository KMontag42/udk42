//=============================================================================
// UDKRTSGameInfo: GameInfo class which represents the game for the strategy
// game.
//
// This class represents the game for the strategy game.
// 
// Copyright 1998-2011 Epic Games, Inc. All Rights Reserved.
//=============================================================================
class UDKRTSGameInfo extends GameInfo;

// Player controller classes for the different platforms
var const class<PlayerController> MobilePlayerControllerClass;
var const class<PlayerController> ConsolePlayerControllerClass;
var const class<PlayerController> PCPlayerControllerClass;
// HUD classes for the different platforms
var const class<HUD> MobileHUDClass;
var const class<HUD> ConsoleHUDClass;
var const class<HUD> PCHUDClass;

// Enum platform
enum EPlatform
{
	P_Mobile,
	P_Console,
	P_PC
};

/**
 * Generic player initialization for all controllers
 *
 * @param		C		Controller to initialize for
 */
function GenericPlayerInitialization(Controller C)
{
	local PlayerController PC;
	local EPlatform Platform;

	PC = PlayerController(C);
	if (PC != None)
	{
		// Keep track of the best host to migrate to in case of a disconnect
		UpdateBestNextHosts();

		// Notify the game that we can now be muted and mute others
		UpdateGameplayMuteList(PC);

		// Tell client what hud class to use
		Platform = GetPlatform();
		switch (Platform)
		{
		// Set the mobile HUD
		case P_Mobile:
			PC.ClientSetHUD(MobileHUDClass);
			break;

		// Return the console player controller
		case P_Console:
			PC.ClientSetHUD(ConsoleHUDClass);
			break;

		// Return the PC player controller
		case P_PC:
			PC.ClientSetHUD(PCHUDClass);
			break;

		// Return the "core" default player controller
		default:
			PC.ClientSetHUD(HudType);
			break;
		}

		// Replicate the streaming status of the client
		ReplicateStreamingStatus(PC);

		// Set the rich presence strings on the client (has to be done there)
		PC.ClientSetOnlineStatus();
	}

	if (BaseMutator != None)
	{
		BaseMutator.NotifyLogin(C);
	}
}

/**
 * Spawns a player controller
 *
 * @param		SpawnLocation		Location to spawn the controller
 * @param		SpawnRotation		Rotation to spawn the controller
 */
function PlayerController SpawnPlayerController(vector SpawnLocation, rotator SpawnRotation)
{
	local EPlatform Platform;

	Platform = GetPlatform();
	switch (Platform)
	{
	// Return the mobile player controller
	case P_Mobile:
		return Spawn(MobilePlayerControllerClass,,, SpawnLocation, SpawnRotation);

	// Return the console player controller
	case P_Console:
		return Spawn(ConsolePlayerControllerClass,,, SpawnLocation, SpawnRotation);

	// Return the PC player controller
	case P_PC:
		return Spawn(PCPlayerControllerClass,,, SpawnLocation, SpawnRotation);

	// Return the "core" default player controller
	default:
		return Spawn(PlayerControllerClass,,, SpawnLocation, SpawnRotation);
	}

	// If all else fails, return the "core" default player controller
	return Spawn(PlayerControllerClass,,, SpawnLocation, SpawnRotation);
}

/**
 * Returns the platform that this game is running as
 */
function EPlatform GetPlatform()
{
	local UDKRTSMapInfo UDKRTSMapInfo;

	if (WorldInfo != None)
	{
		UDKRTSMapInfo = UDKRTSMapInfo(WorldInfo.GetMapInfo());
		if (UDKRTSMapInfo != None)
		{
			// Check to see if the map info overrides this
			switch (UDKRTSMapInfo.DebugConsoleType)
			{
			case CONSOLE_Any:
				// Auto detect the platform
				if (WorldInfo.IsConsoleBuild(CONSOLE_Mobile) || WorldInfo.IsConsoleBuild(CONSOLE_IPhone) || WorldInfo.IsConsoleBuild(CONSOLE_Android))
				{
					return P_Mobile;
				}
				else if (WorldInfo.IsConsoleBuild(CONSOLE_Xbox360) || WorldInfo.IsConsoleBuild(CONSOLE_PS3))
				{
					return P_Console;
				}
				else 
				{
					return P_PC;
				}
				break;

			// Force the mobile platform
			case CONSOLE_Mobile:
			case CONSOLE_IPhone:
			case CONSOLE_Android:
				return P_Mobile;

			// Force the console platform
			case CONSOLE_Xbox360:
			case CONSOLE_PS3:
				return P_Console;

			// Everything else is considered to be the PC platform
			default:
				return P_PC;
			}
		}
	}

	// Auto detect the platform
	if (WorldInfo.IsConsoleBuild(CONSOLE_Mobile) || WorldInfo.IsConsoleBuild(CONSOLE_IPhone) || WorldInfo.IsConsoleBuild(CONSOLE_Android))
	{
		return P_Mobile;
	}
	else if (WorldInfo.IsConsoleBuild(CONSOLE_Xbox360) || WorldInfo.IsConsoleBuild(CONSOLE_PS3))
	{
		return P_Console;
	}
	else 
	{
		return P_PC;
	}

	// In case all else fails
	return P_Mobile;
}

/**
 * Change a controller to another team
 *
 * @param		Other						Controller requesting the team switch
 * @param		RequestedTeamIndex			Team index being requested
 * @param		bNewTeam					True to create a new team
 */
function bool ChangeTeam(Controller Other, int RequestedTeamIndex, bool bNewTeam)
{
	local UDKRTSTeamInfo UDKRTSTeamInfo;
	local int i;

	// Check object references
	if (Other == None || Other.PlayerReplicationInfo == None)
	{
		return false;
	}

	// Find the team info index, and add the controller to the team
	for (i = 0; i < GameReplicationInfo.Teams.Length; ++i)
	{
		if (GameReplicationInfo.Teams[i].TeamIndex == RequestedTeamIndex)
		{
			GameReplicationInfo.Teams[i].AddToTeam(Other);
			return true;
		}
	}

	// If controllers request a team that has a team index of 6, then abort
	if (RequestedTeamIndex >= 6)
	{
		return false;
	}

	// Create a new team
	UDKRTSTeamInfo = Spawn(class'UDKRTSTeamInfo');
	if (UDKRTSTeamInfo != None)
	{
		if (GameReplicationInfo != None)
		{
			UDKRTSTeamInfo.SetTeamIndex(RequestedTeamIndex);
			GameReplicationInfo.Teams.AddItem(UDKRTSTeamInfo);
		}

		UDKRTSTeamInfo.AddToTeam(Other);
		return true;
	}

	return false;
}

/**
 * Picks a team for the controller
 *
 * @param			Current			Not used
 * @param			C				Not used
 * @return							Returns a team for the controller
 */
function byte PickTeam(byte Current, Controller C)
{
	local array<byte> UnusedTeamIndexes;
	local int i, Index;

	for (i = 0; i < 6; ++i)
	{
		UnusedTeamIndexes.AddItem(i);
	}

	// Give all players a starting pawn
	for (i = 0; i < GameReplicationInfo.Teams.Length; ++i)
	{
		if (GameReplicationInfo.Teams[i] != None)
		{
			Index = UnusedTeamIndexes.Find(GameReplicationInfo.Teams[i].TeamIndex);
			if (Index != INDEX_NONE)
			{
				UnusedTeamIndexes.Remove(Index, 1);
			}
		}
	}

	return (UnusedTeamIndexes.Length > 0) ? UnusedTeamIndexes[0] : 255;
}

/**
 * Starts the match
 */
function StartMatch()
{
	local UDKRTSStructure UDKRTSStructure;
	local PlayerController PlayerController;
	local Controller Controller;
	local UDKRTSTeamAIController UDKRTSTeamAIController;
	local UDKRTSPlayerReplicationInfo UDKRTSPlayerReplicationInfo;
	local array<byte> UnusedTeamIndexes;
	local int i, Index;
	
	Super.StartMatch();

	// Add all of the necessary teams
	ForEach AllActors(class'UDKRTSStructure', UDKRTSStructure)
	{
		if (UnusedTeamIndexes.Find(UDKRTSStructure.StartingTeamIndex) == INDEX_NONE && UDKRTSStructure.StartingTeamIndex < class'UDKRTSTeamInfo'.default.DefaultPalette.Length)
		{
			UnusedTeamIndexes.AddItem(UDKRTSStructure.StartingTeamIndex);
		}
	}

	// Give all players a starting pawn
	ForEach WorldInfo.AllControllers(class'PlayerController', PlayerController)
	{
		if (PlayerController.PlayerReplicationInfo != None && PlayerController.PlayerReplicationInfo.Team != None)
		{
			Index = UnusedTeamIndexes.Find(PlayerController.PlayerReplicationInfo.Team.TeamIndex);
			if (Index != INDEX_NONE)
			{
				UnusedTeamIndexes.Remove(Index, 1);
			}
		}
	}

	// Create enemy teams that fill the rest of the player slots
	for (i = 0; i < UnusedTeamIndexes.Length; ++i)
	{
		UDKRTSTeamAIController = Spawn(class'UDKRTSTeamAIController');
		if (UDKRTSTeamAIController != None)
		{
			ChangeTeam(UDKRTSTeamAIController, UnusedTeamIndexes[i], true);
			UDKRTSTeamAIController.Initialize();
		}
	}

	// For every team, set all of their starting buildings
	ForEach WorldInfo.AllControllers(class'Controller', Controller)
	{
		UDKRTSPlayerReplicationInfo = UDKRTSPlayerReplicationInfo(Controller.PlayerReplicationInfo);
		if (UDKRTSPlayerReplicationInfo != None && UDKRTSPlayerReplicationInfo.Team != None)
		{
			ForEach DynamicActors(class'UDKRTSStructure', UDKRTSStructure)
			{
				if (UDKRTSStructure.StartingTeamIndex == UDKRTSPlayerReplicationInfo.Team.TeamIndex)
				{
					UDKRTSStructure.SetOwnerReplicationInfo(UDKRTSPlayerReplicationInfo);
				}
			}

			UDKRTSPlayerReplicationInfo.Resources += class'UDKRTSMapInfo'.static.GetStartingResources();
			UDKRTSPlayerReplicationInfo.Power += class'UDKRTSMapInfo'.static.GetStartingPower();
		}
	}
}

/**
 * Requests an upgrade for the player
 *
 * @param		RequestedUpgradeArchetype				Requesting upgrade archetype
 * @param		RequestingPlayerReplicationInfo			Player who is requesting the upgrade
 * @param		UpgradeLocation							Location where the upgrade was performed
 */
function RequestUpgrade(UDKRTSUpgrade RequestedUpgradeArchetype, UDKRTSPlayerReplicationInfo ReqestingReplicationInfo, Vector UpgradeLocation)
{
	local UDKRTSUpgrade UDKRTSUpgrade;
	local UDKRTSTeamInfo UDKRTSTeamInfo;

	// Check object variables
	if (RequestedUpgradeArchetype == None || ReqestingReplicationInfo == None)
	{
		return;
	}

	UDKRTSTeamInfo = UDKRTSTeamInfo(ReqestingReplicationInfo.Team);
	if (UDKRTSTeamInfo == None)
	{
		return;
	}

	// Check that the player can research this upgrade
	if (!class'UDKRTSUpgrade'.static.CanResearchUpgrade(RequestedUpgradeArchetype, ReqestingReplicationInfo, true))
	{
		return;
	}

	// Spawn the upgrade
	UDKRTSUpgrade = Spawn(RequestedUpgradeArchetype.Class,,, UpgradeLocation,, RequestedUpgradeArchetype, false);
	if (UDKRTSUpgrade != None)
	{
		ReqestingReplicationInfo.Resources -= RequestedUpgradeArchetype.ResourcesCost;
		ReqestingReplicationInfo.Power -= RequestedUpgradeArchetype.PowerCost;

		UDKRTSUpgrade.SetOwnerReplicationInfo(ReqestingReplicationInfo);
		UDKRTSUpgrade.SetOwnerTeamInfo(UDKRTSTeamInfo);
	}
}

/**
 * Requests a structure for the player
 *
 * @param		RequstedStructureArchetype			Requesting structure archetype
 * @param		RequestingReplicationInfo			Player who is requesting the structure
 * @param		SpawnLocation						Where in the world the player should spawn
 * @return											Returns the structure spawned
 */
function UDKRTSStructure RequestStructure(UDKRTSStructure RequstedStructureArchetype, UDKRTSPlayerReplicationInfo RequestingReplicationInfo, Vector SpawnLocation)
{
	local UDKRTSStructure UDKRTSStructure;
	local Actor Actor;
	local UDKRTSMobilePlayerController UDKRTSMobilePlayerController;

	// Check object variables
	if (RequstedStructureArchetype == None || RequestingReplicationInfo == None)
	{
		return None;
	}
	
	// Check that there are no nearby actors blocking construction
	ForEach VisibleCollidingActors(class'Actor', Actor, RequstedStructureArchetype.PlacementClearanceRadius, SpawnLocation, true,, true)
	{
		class'UDKRTSCommanderVoiceOver'.static.PlayCannotDeployHereSoundCue(RequestingReplicationInfo);

		UDKRTSMobilePlayerController = UDKRTSMobilePlayerController(RequestingReplicationInfo.Owner);
		if (UDKRTSMobilePlayerController != None)
		{
			UDKRTSMobilePlayerController.ReceiveMessage("Cannot deploy here.");
		}
		return None;
	}

	// Check that the player is able to build this structure
	if (!class'UDKRTSStructure'.static.CanBuildStructure(RequstedStructureArchetype, RequestingReplicationInfo, true))
	{
		return None;
	}

	// Spawn the structure
	UDKRTSStructure = Spawn(RequstedStructureArchetype.Class,,, SpawnLocation + Vect(0.f, 0.f, 1.f) * RequstedStructureArchetype.CollisionCylinder.CollisionHeight,, RequstedStructureArchetype, true);
	if (UDKRTSStructure != None)
	{
		RequestingReplicationInfo.Resources -= RequstedStructureArchetype.ResourcesCost;
		RequestingReplicationInfo.Power -= RequstedStructureArchetype.PowerCost;

		UDKRTSStructure.SetOwnerReplicationInfo(RequestingReplicationInfo);
	}

	return UDKRTSStructure;
}

/**
 * Requests a pawn for the player
 *
 * @param		RequestedPawnArchetype				Requesting pawn archetype
 * @param		RequestingReplicationInfo			Player requesting the pawn
 * @param		SpawnLocation						Where in the world to spawn the pawn
 * @param		InRallyPointValid					True if the rally point is valid
 * @param		RallyPoint							Where in the world the pawn should rally to
 * @param		RallyPointActorReference			Actor the pawn should rally to
 */
function RequestPawn(UDKRTSPawn RequestedPawnArchetype, UDKRTSPlayerReplicationInfo RequestingReplicationInfo, Vector SpawnLocation, bool InRallyPointValid, Vector RallyPoint, Actor RallyPointActorReference)
{
	local UDKRTSPawn UDKRTSPawn;
	local UDKRTSAIController UDKRTSAIController;
	local UDKRTSResource UDKRTSResource;

	if (RequestedPawnArchetype == None || RequestingReplicationInfo == None)
	{
		return;
	}

	UDKRTSPawn = Spawn(RequestedPawnArchetype.Class,,, SpawnLocation + Vect(0.f, 0.f, 1.f) * RequestedPawnArchetype.CylinderComponent.CollisionHeight,, RequestedPawnArchetype);
	if (UDKRTSPawn != None)
	{
		if (UDKRTSPawn.bDeleteMe)
		{
			`Warn(Self$":: RequestPawn:: Deleted newly spawned pawn, refund player his money?");
		}
		else
		{
			UDKRTSPawn.SetOwnerReplicationInfo(RequestingReplicationInfo);
			UDKRTSPawn.SpawnDefaultController();

			UDKRTSAIController = UDKRTSAIController(UDKRTSPawn.Controller);
			if (UDKRTSAIController != None)
			{
				if (RallyPointActorReference != None)
				{
					UDKRTSResource = UDKRTSResource(RallyPointActorReference);
					if (UDKRTSResource != None && UDKRTSPawn.HarvestResourceInterval > 0)
					{
						UDKRTSAIController.HarvestResource(UDKRTSResource);
					}
				}
				else if (InRallyPointValid)
				{
					UDKRTSAIController.MoveToPoint(RallyPoint);
				}
			}
		}
	}
}

/**
 * Checks if the game has ended or not
 */
function CheckForGameEnd()
{
	local Controller Controller;
	local UDKRTSTeamAIController UDKRTSTeamAIController;
	local UDKRTSTeamInfo UDKRTSTeamInfo;
	local array<UDKRTSTeamInfo> TeamsStillAlive;
	local PlayerReplicationInfo Winner;

	// Finds all of the teams that are still "alive"
	ForEach WorldInfo.AllControllers(class'Controller', Controller)
	{
		if (Controller.PlayerReplicationInfo != None)
		{
			UDKRTSTeamInfo = UDKRTSTeamInfo(Controller.PlayerReplicationInfo.Team);
			if (UDKRTSTeamInfo != None && !UDKRTSTeamInfo.HasLostEverything() && TeamsStillAlive.Find(UDKRTSTeamInfo) == INDEX_NONE)
			{
				TeamsStillAlive.AddItem(UDKRTSTeamInfo);
			}
		}
	}

	// Only one team is alive, thus is the winner
	if (TeamsStillAlive.Length == 1)
	{
		ForEach WorldInfo.AllControllers(class'Controller', Controller)
		{
			if (Controller.PlayerReplicationInfo != None)
			{
				if (Controller.PlayerReplicationInfo.Team == TeamsStillAlive[0])
				{
					class'UDKRTSCommanderVoiceOver'.static.PlayMissionAccomplishedSoundCue(Controller.PlayerReplicationInfo);

					if (Winner == None)
					{
						Winner = Controller.PlayerReplicationInfo;
					}
				}
				else
				{
					class'UDKRTSCommanderVoiceOver'.static.PlayMissionFailedSoundCue(Controller.PlayerReplicationInfo);
				}
			}

			UDKRTSTeamAIController = UDKRTSTeamAIController(Controller);
			if (UDKRTSTeamAIController != None)
			{
				UDKRTSTeamAIController.NotifyEndGame();
			}
		}

		EndGame(Winner, "Annhilation");
	}
}

defaultproperties
{
	bDelayedStart=false
	bWaitingToStartMatch=true
	HUDType=class'UDKRTSMobileHUD'
	PlayerControllerClass=class'UDKRTSMobilePlayerController'
	GameReplicationInfoClass=class'UDKRTSGameReplicationInfo'
	PlayerReplicationInfoClass=class'UDKRTSPlayerReplicationInfo'
	MobilePlayerControllerClass=class'UDKRTSMobilePlayerController'
	ConsolePlayerControllerClass=class'UDKRTSConsolePlayerController'
	PCPlayerControllerClass=class'UDKRTSPCPlayerController'
	MobileHUDClass=class'UDKRTSMobileHUD'
	ConsoleHUDClass=class'UDKRTSConsoleHUD'
	PCHUDClass=class'UDKRTSPCHUD'
}