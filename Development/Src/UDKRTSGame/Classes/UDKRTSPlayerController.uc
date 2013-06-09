//=============================================================================
// UDKRTSPlayerController: Base RTS player controller which does the core
// functionality for RTS games.
//
// Base class, extend this for specific platforms.
// 
// Copyright 1998-2011 Epic Games, Inc. All Rights Reserved.
//=============================================================================
class UDKRTSPlayerController extends GamePlayerController
	DependsOn(UDKRTSUtility);

// Array of idle units
var array<UDKRTSPawn> IdleUnits;
// Current idle unit index
var int CurrentIdleUnitIndex;
// Enemy approaching time interval
var float NextEnemyApproachingInterval;
// No enemies in the base
var bool HasEnemiesInTheBase;
// Our base is under attack time interval
var float NextOurBaseIsUnderAttack;

/**
 * Set a rally point on the structure
 *
 * @param		RallyPointLocation		Rally point location
 * @param		Structure				Structure to set the rally point on
 */
simulated function StartSetRallyPoint(Vector RallyPointLocation, UDKRTSStructure Structure)
{
	if (Structure == None)
	{
		return;
	}

	// Replicate the new rally point location to the server
	if (Role < Role_Authority)
	{
		ServerSetRallyPoint(RallyPointLocation, Structure);
	}

	// Set on the client
	Structure.SetRallyPointLocation(RallyPointLocation);
}

/**
 * Set a rally point on the structure
 *
 * @param		RallyPointLocation		Rally point location
 * @param		Structure				Structure to set the rally point on
 */
reliable server function ServerSetRallyPoint(Vector RallyPointLocation, UDKRTSStructure Structure)
{
	if (Role == Role_Authority && Structure != None)
	{
		Structure.SetRallyPointLocation(RallyPointLocation);
	}
}

/**
 * Set a rally point actor on the structure
 *
 * @param		RallyPointActor			Rally point actor
 * @param		Structure				Structure to set the rally point on
 */
simulated function StartSetRallyPointActor(Actor RallyPointActor, UDKRTSStructure Structure)
{
	if (Structure == None || RallyPointActor == None)
	{
		return;
	}

	// Replicate the new rally point actor to the server
	if (Role < Role_Authority)
	{
		ServerSetRallyPointActor(RallyPointActor, Structure);
	}

	// Set on the client
	Structure.SetRallyPointActor(RallyPointActor);
}

/**
 * Set a rally point actor on the structure
 *
 * @param		RallyPointActor			Rally point actor
 * @param		Structure				Structure to set the rally point on
 */
reliable server function ServerSetRallyPointActor(Actor RallyPointActor, UDKRTSStructure Structure)
{
	if (Role == Role_Authority && RallyPointActor != None && Structure != None)
	{
		Structure.SetRallyPointActor(RallyPointActor);
	}
}

/**
 * Send an action command to an actor
 *
 * @param		Reference		HUD action reference
 * @param		Index			HUD action index
 * @param		Actor			Associated actor
 */
simulated function StartHUDAction(EHUDActionReference Reference, int Index, Actor Actor)
{
	// Sync with the server
	if (Role < Role_Authority && class'UDKRTSUtility'.static.HUDActionNeedsToSyncWithServer(Reference) && UDKRTSHUDActionInterface(Actor) != None)
	{
		ServerHUDAction(Reference, Index, Actor);
	}

	BeginHUDAction(Reference, Index, Actor);
}

/**
 * Sync the action command for an actor
 *
 * @param		Reference		HUD action reference
 * @param		Index			HUD action index
 * @param		Actor			Associated actor
 */
reliable server function ServerHUDAction(EHUDActionReference Reference, int Index, Actor Actor)
{
	BeginHUDAction(Reference, Index, Actor);
}

/**
 * Begin an action command to an actor
 */
simulated function BeginHUDAction(EHUDActionReference Reference, int Index, Actor Actor)
{
	local UDKRTSHUDActionInterface UDKRTSHUDActionInterface;

	UDKRTSHUDActionInterface = UDKRTSHUDActionInterface(Actor);
	if (UDKRTSHUDActionInterface != None)
	{
		UDKRTSHUDActionInterface.HandleHUDAction(Reference, Index);
	}
}

/**
 * Send a move order to a unit
 *
 * @param		WorldLocation			Where in the world the unit should go
 * @param		UDKRTSPawn				Pawn that should move
 * @network								Server and client
 */
simulated function GiveMoveOrder(Vector WorldLocation, UDKRTSPawn UDKRTSPawn)
{
	if (UDKRTSPawn == None)
	{
		return;
	}

	UDKRTSPawn.HasPendingCommand = false;
	
	// If on the client, sync with the server
	if (Role < Role_Authority)
	{
		ServerMoveOrder(WorldLocation, UDKRTSPawn);
	}
	else
	{
		SendMoveOrder(WorldLocation, UDKRTSPawn);
	}

	// Spawn the move confirm particle effect
	if (UDKRTSPawn.ConfirmMoveCommandEffect != None && WorldInfo != None && WorldInfo.MyEmitterPool != None)
	{
		WorldInfo.MyEmitterPool.SpawnEmitter(UDKRTSPawn.ConfirmMoveCommandEffect, WorldLocation);
	}
}

/**
 * Send a move order to a unit
 *
 * @param		WorldLocation			Where in the world the unit should go
 * @param		UDKRTSPawn				Pawn that should move
 * @network								Server and client
 */
reliable server function ServerMoveOrder(Vector WorldLocation, UDKRTSPawn UDKRTSPawn)
{
	SendMoveOrder(WorldLocation, UDKRTSPawn);
}

/**
 * Send a move order to a unit
 *
 * @param		WorldLocation			Where in the world the unit should go
 * @param		UDKRTSPawn				Pawn that should move
 * @network								Server and client
 */
simulated function SendMoveOrder(Vector WorldLocation, UDKRTSPawn UDKRTSPawn)
{
	local UDKRTSAIController UDKRTSAIController;

	if (UDKRTSPawn == None)
	{
		return;
	}

	UDKRTSPawn.HasPendingCommand = false;
	UDKRTSAIController = UDKRTSAIController(UDKRTSPawn.Controller);
	if (UDKRTSAIController != None)
	{
		UDKRTSAIController.MoveToPoint(WorldLocation, true);
	}
}

/**
 * Send a harvest order to a unit
 * 
 * @param			Resource			Resource to harvest
 * @param			UDKRTSPawn			Pawn that should harvest
 * @network								Server and client
 */
simulated function GiveHarvestResourceOrder(UDKRTSResource Resource, UDKRTSPawn UDKRTSPawn)
{
	if (UDKRTSPawn == None)
	{
		return;
	}

	UDKRTSPawn.HasPendingCommand = false;

	// If this is the client sync with the server
	if (Role < Role_Authority)
	{
		ServerHarvestResourceOrder(Resource, UDKRTSPawn);
	}
	else
	{
		SendHarvestResourceOrder(Resource, UDKRTSPawn);
	}
}

/**
 * Send a harvest order to a unit
 * 
 * @param			Resource			Resource to harvest
 * @param			UDKRTSPawn			Pawn that should harvest
 * @network								Server
 */
reliable server function ServerHarvestResourceOrder(UDKRTSResource Resource, UDKRTSPawn UDKRTSPawn)
{
	SendHarvestResourceOrder(Resource, UDKRTSPawn);
}

/**
 * Send a harvest order to a unit
 * 
 * @param			Resource			Resource to harvest
 * @param			UDKRTSPawn			Pawn that should harvest
 * @network								Server and client
 */
simulated function SendHarvestResourceOrder(UDKRTSResource Resource, UDKRTSPawn UDKRTSPawn)
{
	local UDKRTSAIController UDKRTSAIController;

	if (UDKRTSPawn == None)
	{
		return;
	}

	UDKRTSPawn.HasPendingCommand = false;
	UDKRTSAIController = UDKRTSAIController(UDKRTSPawn.Controller);
	if (UDKRTSAIController != None)
	{
		UDKRTSAIController.HarvestResource(Resource);
	}
}

/**
 * Send a engage order to a unit
 *
 * @param			UDKRTSTargetInterface		Target interface to engage
 * @param			UDKRTSPawn					Pawn that should engage
 * @network										Server and client
 */
simulated function GiveEngageTargetOrder(Actor EngageTarget, UDKRTSPawn UDKRTSPawn)
{
	if (UDKRTSPawn == None)
	{
		return;
	}

	UDKRTSPawn.HasPendingCommand = false;

	// If client, sync with the server
	if (Role < Role_Authority)
	{
		ServerEngageTargetOrder(EngageTarget, UDKRTSPawn);
	}
	else
	{
		SendEngageTargetOrder(EngageTarget, UDKRTSPawn);
	}

	// Spawn the confirm attack command
	if (UDKRTSPawn.ConfirmAttackCommandEffect != None && WorldInfo != None && WorldInfo.MyEmitterPool != None && EngageTarget != None)
	{
		WorldInfo.MyEmitterPool.SpawnEmitter(UDKRTSPawn.ConfirmAttackCommandEffect, EngageTarget.Location);
	}
}

/**
 * Send a engage order to a unit
 *
 * @param			UDKRTSTargetInterface		Target interface to engage
 * @param			UDKRTSPawn					Pawn that should engage
 * @network										Server
 */
reliable server function ServerEngageTargetOrder(Actor EngageTarget, UDKRTSPawn UDKRTSPawn)
{
	// Only servers should execute this
	if (Role == Role_Authority)
	{
		SendEngageTargetOrder(EngageTarget, UDKRTSPawn);
	}
}

/**
 * Send a engage order to a unit
 *
 * @param			UDKRTSTargetInterface		Target interface to engage
 * @param			UDKRTSPawn					Pawn that should engage
 * @network										Server and client
 */
simulated function SendEngageTargetOrder(Actor EngageTarget, UDKRTSPawn UDKRTSPawn)
{
	local UDKRTSAIController UDKRTSAIController;

	if (UDKRTSPawn == None || EngageTarget == None)
	{
		return;
	}

	UDKRTSPawn.HasPendingCommand = false;
	UDKRTSAIController = UDKRTSAIController(UDKRTSPawn.Controller);
	if (UDKRTSAIController != None)
	{
		UDKRTSAIController.EngageTarget(EngageTarget);
	}
}

/**
 * Requests a structure
 *
 * @param			StructureArchetype			Structure archetype
 * @param			SpawnLocation				Where to spawn it
 * @network										Client
 */
simulated function RequestStructure(UDKRTSStructure StructureArchetype, Vector SpawnLocation)
{
	// If a client, sync on the server
	if (Role < Role_Authority)
	{
		ServerRequestForStructure(StructureArchetype, SpawnLocation);
	}
	else
	{
		SendRequestForStructure(StructureArchetype, SpawnLocation);
	}
}

/**
 * Requests a structure
 *
 * @param			StructureArchetype			Structure archetype
 * @param			SpawnLocation				Where to spawn it
 * @network										Server
 */
reliable server function ServerRequestForStructure(UDKRTSStructure StructureArchetype, Vector SpawnLocation)
{
	SendRequestForStructure(StructureArchetype, SpawnLocation);
}

/**
 * Requests a structure
 *
 * @param			StructureArchetype			Structure archetype
 * @param			SpawnLocation				Where to spawn it
 * @network										Server and client
 */
simulated function SendRequestForStructure(UDKRTSStructure StructureArchetype, Vector SpawnLocation)
{
	local UDKRTSGameInfo UDKRTSGameInfo;

	if (PlayerReplicationInfo == None)
	{
		return;
	}

	UDKRTSGameInfo = UDKRTSGameInfo(WorldInfo.Game);
	if (UDKRTSGameInfo != None)
	{
		UDKRTSGameInfo.RequestStructure(StructureArchetype, UDKRTSPlayerReplicationInfo(PlayerReplicationInfo), SpawnLocation);
	}
}

/**
 * Servers can use this to send a message to clients
 *
 * @param		MessageText		Text to send to the server
 * @param		MessageColor	Color to render the message
 * @network						Client
 */
simulated function ReceiveMessage(string MessageText, optional Color MessageColor = class'HUD'.default.WhiteColor);

/**
 * Notification if an actor is destroyed
 *
 * @param		Actor			Actor that was destroyed
 */
simulated function NotifyActorDestroyed(Actor Actor);

defaultproperties
{
	CheatClass=class'UDKRTSCheatManager'
	CameraClass=class'UDKRTSCamera'
}