//=============================================================================
// UDKRTSAIController: AI controller class that every pawn has
//
// This class controls pawns.
// 
// Copyright 1998-2011 Epic Games, Inc. All Rights Reserved.
//=============================================================================
class UDKRTSAIController extends AIController;

// Enemy target interface
var UDKRTSTargetInterface EnemyTargetInterface;
// Last best attacking destination
var Vector LastBestAttackingDestination;
// Destination to move to
var Vector Destination;
// Current focus spot
var Vector FocusSpot;
// Next move location
var Vector NextMoveLocation;
// Current resources
var UDKRTSResource Resource;
// Current resource storages
var UDKRTSStructure ResourceStorage;

// Debug
var String StateLabel;
// Previous state name
var String CachedPreviousStateName;

/**
 * Called from the HUD class to render debug state
 */
simulated function RenderDebugState(UDKRTSHUD HUD)
{
	local Vector V;
	local string Text;
	local float XL, YL;

	// Display the AI states
	if (HUD.ShouldDisplayDebug('AIStates'))
	{
		V = Pawn.Location + Pawn.CylinderComponent.CollisionHeight * Vect(0.f, 0.f, 1.f);
		V = HUD.Canvas.Project(V);		
		HUD.Canvas.Font = class'Engine'.static.GetTinyFont();

		// Render the state debug
		Text = String(GetStateName())@"-"@StateLabel;
		HUD.Canvas.TextSize(Text, XL, YL);
		HUD.DrawBorderedText(HUD, V.X - (XL * 0.5f), V.Y - (YL * 3.f), Text, class'HUD'.default.WhiteColor, class'UDKRTSPalette'.default.BlackColor);

		HUD.Canvas.TextSize("Previous state - "$CachedPreviousStateName, XL, YL);
		HUD.DrawBorderedText(HUD, V.X - (XL * 0.5f), V.Y - (YL * 2.f), "Previous state - "$CachedPreviousStateName, class'HUD'.default.WhiteColor, class'UDKRTSPalette'.default.BlackColor);

		// Render the enemy debug text
		if (EnemyTargetInterface != None && EnemyTargetInterface.IsValidTarget())
		{
			Text = "Target = "$EnemyTargetInterface.GetActor();
			HUD.Canvas.TextSize(Text, XL, YL);
			HUD.DrawBorderedText(HUD, V.X - (XL * 0.5f), V.Y - YL, Text, class'HUD'.default.WhiteColor, class'UDKRTSPalette'.default.BlackColor);
		}

		if (IsTimerActive(NameOf(HarvestTimer)))
		{
			Text = "Harvesting resource = "$GetRemainingTimeForTimer(NameOf(HarvestTimer));
			HUD.Canvas.TextSize(Text, XL, YL);
			HUD.DrawBorderedText(HUD, V.X - (XL * 0.5f), V.Y, Text, class'HUD'.default.WhiteColor, class'UDKRTSPalette'.default.BlackColor);
		}
	}

	// Display the AI focus
	if (HUD.ShouldDisplayDebug('AIFocus'))
	{
		HUD.Draw3DLine(Pawn.Location, FocusSpot, class'HUD'.default.GreenColor);
	}
}

/**
 * Called when the controller possess's a pawn
 *
 * @param			inPawn						Pawn to possess
 * @param			bVehicleTransition			True if transitioning to a vehicle
 */
event Possess(Pawn inPawn, bool bVehicleTransition)
{
	local UDKRTSPawn UDKRTSPawn;

	Super.Possess(inPawn, bVehicleTransition);

	// Assign the initial focus spot, and start the what to do timer
	UDKRTSPawn = UDKRTSPawn(inPawn);
	if (UDKRTSPawn != None)
	{
		FocusSpot = UDKRTSPawn.Location + Vector(UDKRTSPawn.Rotation) * 64.f;
		SetTimer(0.05f, true, NameOf(WhatToDo));
	}
}

/**
 * Called when the pawn this controller is controling takes damage
 *
 * @param		DamageAmount			Amount of damage to dealt to the pawn
 * @param		EventInstigator			Controller that instigated this event
 * @param		HitLocation				World location where this hit occured
 * @param		Momentum				Momentum to push the pawn
 * @param		DamageType				Damage type that was dealt to the pawn
 * @param		HitInfo					Trace information if any
 * @param		DamageCauser			Actor that caused the damage
 */
function NotifyTakeDamage(int DamageAmount, Controller EventInstigator, vector HitLocation, vector Momentum, class<DamageType> DamageType, optional TraceHitInfo HitInfo, optional Actor DamageCauser)
{
	if (EventInstigator != None)
	{
		EngageTarget(EventInstigator.Pawn);
	}
}

/**
 * Evaluates what the pawn should be doing now
 */
function WhatToDo()
{
	local UDKRTSPawn MyUDKRTSPawn;
	local float ResourceSearchDistance, Distance, ClosestDistance;
	local UDKRTSTargetInterface UDKRTSTargetInterface;
	local Actor Actor, ClosestActor;
	local UDKRTSResource UDKRTSResource, ClosestUDKRTSResource;

	// Attack the nearest enemy pawn if I don't have an enemy of my own
	MyUDKRTSPawn = UDKRTSPawn(Pawn);
	if (MyUDKRTSPawn != None)
	{
		if (MyUDKRTSPawn.OwnerReplicationInfo == None)
		{
			return;
		}

		// I do not currently have a valid target
		if (EnemyTargetInterface == None || !EnemyTargetInterface.IsValidTarget())
		{
			// I have a weapon
			if (MyUDKRTSPawn.UDKRTSWeapon != None)
			{
				ForEach VisibleCollidingActors(class'Actor', Actor, MyUDKRTSPawn.UDKRTSWeapon.GetRange(), Pawn.Location, true,, true, class'UDKRTSTargetInterface')
				{
					if (Actor != MyUDKRTSPawn)
					{
						UDKRTSTargetInterface = UDKRTSTargetInterface(Actor);
						if (UDKRTSTargetInterface != None && UDKRTSTargetInterface.IsValidTarget(UDKRTSTeamInfo(MyUDKRTSPawn.OwnerReplicationInfo.Team)))
						{
							Distance = VSizeSq(Actor.Location - MyUDKRTSPawn.Location);
							if (ClosestActor == None || Distance < ClosestDistance)
							{
								ClosestDistance = Distance;
								ClosestActor = Actor;
							}
						}
					}
				}

				// There is an enemy near me that I should attack
				if (ClosestActor != None)
				{			
					EngageTarget(ClosestActor);
					return;
				}
			}

			// I can harvest
			if (MyUDKRTSPawn.HarvestResourceInterval > 0.f)
			{
				ResourceSearchDistance = 0.f;
				if ((CachedPreviousStateName ~= "HarvestingResource" && !IsInState('HarvestingResource')) || (CachedPreviousStateName ~= "StoreResource" && !IsInState('StoreResource')))
				{
					ResourceSearchDistance = 1024.f;
				}
				else
				{
					ResourceSearchDistance = 256.f;
				}

				if (ResourceSearchDistance > 0.f)
				{
					// Find the nearest resource to harvest
					ClosestUDKRTSResource = None;
					ForEach VisibleCollidingActors(class'UDKRTSResource', UDKRTSResource, ResourceSearchDistance, Pawn.Location, true,, true)
					{
						if (IsValidResource(UDKRTSResource))
						{
							Distance = VSizeSq(UDKRTSResource.Location - Pawn.Location);
							if (ClosestUDKRTSResource == None || Distance < ClosestDistance)
							{
								ClosestDistance = Distance;
								ClosestUDKRTSResource = UDKRTSResource;
							}
						}
					}

					// There is a resource near me that I should harvest from
					if (ClosestUDKRTSResource != None)
					{
						HarvestResource(ClosestUDKRTSResource);
						return;
					}
				}
			}
		}
	}
}

/**
 * Called every frame updated
 *
 * @param			DeltaTime			Time since the last update
 */
function Tick(float DeltaTime)
{
	local Rotator DesiredRotation;
	local UDKRTSPawn UDKRTSPawn;
	local UDKRTSPlayerController UDKRTSPlayerController;
	local int Index;	
	local Vector TargetLocation, UDKRTSPawnLocation;

	Super.Tick(DeltaTime);

	UDKRTSPawn = UDKRTSPawn(Pawn);
	if (UDKRTSPawn != None && UDKRTSPawn.OwnerReplicationInfo != None)
	{
		// Handle rotation
		TargetLocation = FocusSpot;
		TargetLocation.Z = 0.f;

		UDKRTSPawnLocation = UDKRTSPawn.Location;
		UDKRTSPawnLocation.Z = 0.f;

		DesiredRotation = Rotator(TargetLocation - UDKRTSPawnLocation);
		DesiredRotation.Pitch = 0;
		DesiredRotation.Roll = 0;

		UDKRTSPawn.FaceRotation(RLerp(UDKRTSPawn.Rotation, DesiredRotation, FClamp(UDKRTSPawn.TurnSpeed * DeltaTime, 0.01f, 1.f), true), DeltaTime);
		UDKRTSPlayerController = UDKRTSPlayerController(UDKRTSPawn.OwnerReplicationInfo.Owner);
		if (UDKRTSPlayerController != None && UDKRTSPawn.ShowIdleIcon)
		{
			// If the unit is idle, then inform the player controller that they are
			// @TODO Not replicated at this stage
			if (IsIdle())
			{
				if (UDKRTSPlayerController.IdleUnits.Find(UDKRTSPawn) == INDEX_NONE)
				{
					UDKRTSPlayerController.IdleUnits.AddItem(UDKRTSPawn);
					UDKRTSPlayerController.CurrentIdleUnitIndex = 0;
				}
			}
			else
			{
				Index = UDKRTSPlayerController.IdleUnits.Find(UDKRTSPawn);
				if (Index != INDEX_NONE)
				{
					UDKRTSPlayerController.IdleUnits.Remove(Index, 1);
					UDKRTSPlayerController.CurrentIdleUnitIndex = 0;
				}
			}
		}
	}
}

/**
 * Returns true if the unit is idle
 *
 * @return		Returns true if the unit is idle
 */
simulated function bool IsIdle()
{
	return true;
}

/**
 * Returns true if the pawn is valid
 *
 * @return		Returns true if the pawn is valid
 */
function bool IsValidPawn(Pawn PawnToCheck)
{
	// Check if the pawn is none or about to be deleted
	if (PawnToCheck == None || PawnToCheck.bDeleteMe)
	{
		return false;
	}

	// Check if the pawn has any health
	if (PawnToCheck.Health <= 0)
	{
		return false;
	}

	// Pawn is valid
	return true;
}

/**
 * Returns true if the resource is valid
 *
 * @return		Returns true if the pawn is valid
 */
function bool IsValidResource(UDKRTSResource ResourceToCheck)
{
	// Check if the resource is none
	if (ResourceToCheck == None)
	{
		return false;
	}

	// Check if the resource can be harvested
	if (!ResourceToCheck.CanHarvest())
	{
		return false;
	}

	return true;
}

/**
 * Returns true if the unit is harvesting resources
 *
 * @return		Returns true if the unit is harvesting resources
 */
function bool IsHarvestingResources()
{
	return false;
}

/**
 * Commands the unit to harvest the resource
 *
 * @param		PotentialResource		Potential resource to harvest
 */
function HarvestResource(UDKRTSResource PotentialResource)
{
	local UDKRTSResourceInventory UDKRTSResourceInventory;

	// Check if we can harvest the resource
	if (!IsValidResource(PotentialResource))
	{
		return;
	}

	// Assign variables to start harvesting it
	Resource = PotentialResource;
	FocusSpot = Resource.Location;

	// Check if we already have a resource in my inventory
	UDKRTSResourceInventory = UDKRTSResourceInventory(Pawn.InvManager.FindInventoryType(class'UDKRTSResourceInventory', true));
	GotoState((UDKRTSResourceInventory != None) ? 'StoreResource' : 'HarvestingResource');
}

/**
 * Evaluates the best attacking location against the enemy
 */
function GetBestAttackingLocation()
{
	local UDKRTSPawn UDKRTSPawn;
	
	// Check that the enemy is still valid
	if (EnemyTargetInterface != None && EnemyTargetInterface.IsValidTarget())
	{	
		// Check that the pawn can still attack the enemy
		UDKRTSPawn = UDKRTSPawn(Pawn);
		if (UDKRTSPawn != None && UDKRTSPawn.UDKRTSWeapon != None)
		{
			// Evaluate if the last best attacking destination is still valid
			if (UDKRTSPawn.UDKRTSWeapon.InRange(EnemyTargetInterface.GetActor(), LastBestAttackingDestination) && !IsZero(LastBestAttackingDestination))
			{
				Destination = LastBestAttackingDestination;
			}
			else
			{
				// The last best attacking destination is no longer valid, so reevaluate it			
				Destination = EnemyTargetInterface.BestAttackingLocation(UDKRTSPawn, UDKRTSPawn.UDKRTSWeapon.GetRange() * 0.9f);
				LastBestAttackingDestination = Destination;
			}

			// Set the destination position
			SetDestinationPosition(Destination);
		}
	}
}

/**
 * Commands the unit to engage a target (running into the best attacking location and firing its weapon at it)
 *
 * @param			PotentialTarget			Potential target to attack
 */
function EngageTarget(Actor PotentialTarget)
{
	local UDKRTSPawn MyUDKRTSPawn;
	local UDKRTSTargetInterface UDKRTSTargetInterface;

	// If potential target is none, then abort
	if (PotentialTarget == None)
	{
		return;
	}

	// RTS target interface
	UDKRTSTargetInterface = UDKRTSTargetInterface(PotentialTarget);

	// Check that the potential target is valid
	if (UDKRTSTargetInterface == None || !UDKRTSTargetInterface.IsValidTarget())
	{
		return;
	}

	// I already have a target, and the potential target can't attack me anyways, so cancel
	if (EnemyTargetInterface != None && !UDKRTSTargetInterface.HasWeapon())
	{
		return;
	}

	// Check if the potential target is on the same team
	MyUDKRTSPawn = UDKRTSPawn(Pawn);
	if (MyUDKRTSPawn == None || MyUDKRTSPawn.OwnerReplicationInfo == None || !UDKRTSTargetInterface.IsValidTarget(UDKRTSTeamInfo(MyUDKRTSPawn.OwnerReplicationInfo.Team)))
	{
		return;
	}

	// Assign the variables for engaging the enemy
	EnemyTargetInterface = UDKRTSTargetInterface;
	GetBestAttackingLocation();
	FocusSpot = GetDestinationPosition();

	GotoState('EngagingEnemy');
}

/**
 * Commands the unit to move to a point in the world
 *
 * @param		MovePoint				World location to move the unit to
 * @param		DisableAutomation		True if you want to disable automation while executing this command
 */
function MoveToPoint(Vector MovePoint, optional bool DisableAutomation)
{
	// If disabling automation, clear the WhatToDo timer
	if (DisableAutomation && IsTimerActive(NameOf(WhatToDo)))
	{
		ClearTimer(NameOf(WhatToDo));
	}

	// Move to a point in the world
	Destination = MovePoint;	
	FocusSpot = MovePoint;
	SetDestinationPosition(Destination);
	Resource = None;

	if (!HasReachedPoint(Destination))
	{
		GotoState('MovingToPoint');
	}
}

/**
 * Returns true if the pawn has reached a point in the world
 *
 * @return		Returns true if the pawn has reached a point in the world
 */
function bool HasReachedPoint(Vector Point, optional float Range = -1.f)
{
	if (Pawn == None)
	{
		return false;
	}

	return (VSize2D(Pawn.Location - Point) <= ((Range == -1.f) ? Pawn.GetCollisionRadius() : Range));
}

/**
 * Generates a path in the navigation mesh to an actor
 *
 * @param		Goal					Actor to path find to
 * @param		WithinDistance			How accurate the path finding needs to be
 * @param		bAllowPartialPath		Returns true even though the path finder only finds part of the path?
 * @return								Returns true if a path was found
 */
function bool GeneratePathToward(Actor Goal, optional float WithinDistance, optional bool bAllowPartialPath)
{
	if (NavigationHandle == None)
	{
         return false;
	}

	// Set up the path finding
	class'NavMeshPath_Toward'.static.TowardGoal(NavigationHandle, Goal);
	class'NavMeshGoal_At'.static.AtActor(NavigationHandle, Goal, WithinDistance, bAllowPartialPath);
	// Set the path finding final destination
	NavigationHandle.SetFinalDestination(Goal.Location);
	// Perform the path finding
	return NavigationHandle.FindPath();
}

/**
 * Generates a path in the navigation mesh to a point in the world
 *
 * @param		Goal					Point in the world to path find to
 * @param		WithinDistance			How accurate the path finding needs to be
 * @param		bAllowPartialPath		Returns true even though the path finder only finds part of the path?
 * @return								Returns true if a path was found
 */
function bool GeneratePathTo(Vector Goal, optional float WithinDistance, optional bool bAllowPartialPath)
{
	if (NavigationHandle == None)
	{
         return false;
	}

    // Set up the path finding
	class'NavMeshPath_Toward'.static.TowardPoint(NavigationHandle, Goal);
	class'NavMeshGoal_At'.static.AtLocation(NavigationHandle, Goal, WithinDistance, bAllowPartialPath);
	// Set the path finding final destination
	NavigationHandle.SetFinalDestination(Goal);
	// Perform the path finding
	return NavigationHandle.FindPath();
}

/**
 * Returns true if an actor is reachable
 *
 * @param		Actor					Actor to test if it is reachable
 * @param		IgnoreStructure			Ignore structure trace check
 * @param		IgnoreResource			Ignore resource trace check
 * @return								Returns true if an actor is reachable
 */
simulated function bool IsActorReachable(Actor Actor, optional bool IgnoreStructure, optional bool IgnoreResource)
{
	if (Actor == None)
	{
		return false;
	}

	return IsPointReachable(Actor.Location, IgnoreStructure, IgnoreResource);
}

/**
 * Returns true if a point in the world is reachable
 * 
 * @param		Point					Point in the world to test if it is reachable
 * @param		IgnoreStructure			Ignore structure trace check
 * @param		IgnoreResource			Ignore resource trace check
 * @return								Returns true if the point in the world is reachable
 */
simulated function bool IsPointReachable(Vector Point, optional bool IgnoreStructure, optional bool IgnoreResource)
{
	local Actor HitActor;
	local Vector HitLocation, HitNormal, TraceEnd;

	if (Pawn == None)
	{
		return false;
	}

	// Perform a trace to see if that point is directly reachable or not
	TraceEnd = Point;
	TraceEnd.Z = Pawn.Location.Z;

	ForEach TraceActors(class'Actor', HitActor, HitLocation, HitNormal, TraceEnd, Pawn.Location, Pawn.GetCollisionExtent())
	{
		if (HitActor.bWorldGeometry || (!IgnoreStructure && HitActor.ClassIsChildOf(HitActor.Class, Class'UDKRTSStructure')) || (!IgnoreResource && HitActor.ClassIsChildOf(HitActor.Class, Class'UDKRTSResource')))
		{
			return false;
		}
	}

	return true;
}

/**
 * Checks the rotation of a pawn and adjusts movement speed accordingly. If a pawn needs to turn to face a direction before moving, it sets the ground speed to zero
 * This is mostly used by vehicles
 */
simulated function CheckRotation()
{
	local UDKRTSPawn UDKRTSPawn;

	UDKRTSPawn = UDKRTSPawn(Pawn);
	if (UDKRTSPawn != None)
	{
		UDKRTSPawn.GroundSpeed = (UDKRTSPawn.NeedsToTurnWithPrecision(GetDestinationPosition(), UDKRTSPawn.MustFaceDirectionBeforeMovingPrecision)) ? 0.f : UDKRTSPawn.CurrentGroundSpeed;
	}
}

/**
 * This state represents the pawn moving some where
 */
state MovingToPoint
{
	/**
	 * Returns if the unit is considered to be idle or not
	 *
	 * @return			Returns if the unit is considered to be idle or not
	 */
	simulated function bool IsIdle()
	{
		return false;
	}

	/**
	 * Renders any debug information required for this AI controller
	 *
	 * @param			HUD			HUD to render the debug information to
	 */
	simulated function RenderDebugState(UDKRTSHUD HUD)
	{
		Global.RenderDebugState(HUD);

		// Do we need to render the movement lines or not?
		if (HUD.ShouldDisplayDebug('AIMovementLines'))
		{
			// Draw the current move location
			HUD.Draw3DLine(Pawn.Location, GetDestinationPosition(), class'HUD'.default.GreenColor);
			// Draw the final destination location
			HUD.Draw3DLine(Pawn.Location, Destination, class'UDKRTSPalette'.default.YellowColor);
		}
	}

	/**
	 * Called when this state is first started
	 *
	 * @param			PreviousStateName			Name of the previous state
	 */
	event BeginState(Name PreviousStateName)
	{
		local UDKRTSPawn UDKRTSPawn;

		// Check the rotation
		UDKRTSPawn = UDKRTSPawn(Pawn);
		if (UDKRTSPawn != None && UDKRTSPawn.MustFaceDirectionBeforeMoving)
		{
			CheckRotation();
			SetTimer(0.05f, true, NameOf(CheckRotation));
		}
	}

	/**
	 * Called when this state is about to end
	 *
	 * @param			NextStateName				Name of the next state
	 */
	event EndState(Name NextStateName)
	{
		CachedPreviousStateName = "MovingToPoint";
		
		// Restart the WhatToDo timer
		if (!IsTimerActive(NameOf(WhatToDo)))
		{
			SetTimer(0.05f, true, NameOf(WhatToDo));
		}
	}

Begin:
	StateLabel = "Begin";
	// If the pawn is no longer valid then go to the Dead state
	if (!IsValidPawn(Pawn))
	{
		GotoState('Dead');
	}
	// Wait until we are walking again
	if (Pawn.Physics != Pawn.WalkingPhysics)
	{
		Sleep(0.f);
		Goto('Begin');
	}
	//Set the focus spot
	FocusSpot = GetDestinationPosition();
MoveDirect:
	StateLabel = "MoveDirect";
	// Check if the point is directly reachable or not
	if (IsPointReachable(GetDestinationPosition()))
	{
		// Adjust if we need to
		if (bAdjusting)
		{
			SetDestinationPosition(GetAdjustLocation());
		}

		// Move to the destination position
		bPreciseDestination = true;
		FocusSpot = GetDestinationPosition();
		Sleep(0.f);
		Goto('HasReachedDestination');
	}
MoveViaPathFinding:
	StateLabel = "MoveViaPathFinding";
	// Generate the path and get the next move location
	if (GeneratePathTo(GetDestinationPosition(), Pawn.GetCollisionRadius(), true) && NavigationHandle.GetNextMoveLocation(NextMoveLocation, Pawn.GetCollisionRadius()))
	{
		if (bAdjusting)
		{
			// Adjust if we need to
			SetDestinationPosition(GetAdjustLocation());
		}
		else
		{
			// Set the destination to the next move location
			SetDestinationPosition(NextMoveLocation);
		}
		
		// Move towards the destination
		bPreciseDestination = true;
		FocusSpot = GetDestinationPosition();
	}
	else
	{
		Goto('End');
	}
HasReachedDestination:
	// Check if the unit has reached the destination
	StateLabel = "HasReachedDestination";
	if (!HasReachedPoint(GetDestinationPosition()))
	{
		// Reached current destination 
		Sleep(0.f);
		Goto('Begin');
	}
	else if (!HasReachedPoint(Destination))
	{		
		SetDestinationPosition(Destination);
		Sleep(0.f);
		Goto('Begin');
	}
End:
	StateLabel = "End";
	GotoState('');
}

/**
 * This state represents the pawn engaging the enemy
 */
state EngagingEnemy
{
	/**
	 * Renders any debug information required for this AI controller
	 *
	 * @param			HUD			HUD to render the debug information to
	 */
	simulated function RenderDebugState(UDKRTSHUD HUD)
	{
		Global.RenderDebugState(HUD);

		if (HUD.ShouldDisplayDebug('AIMovementLines'))
		{
			// Draw the current move location
			HUD.Draw3DLine(Pawn.Location, GetDestinationPosition(), class'HUD'.default.GreenColor);
			// Draw the destination location
			HUD.Draw3DLine(Pawn.Location, Destination, class'UDKRTSPalette'.default.YellowColor);

			if (EnemyTargetInterface != None && EnemyTargetInterface.IsValidTarget())
			{
				// Draw the enemy line
				HUD.Draw3DLine(Pawn.Location, EnemyTargetInterface.GetActor().Location, class'HUD'.default.RedColor);
			}
		}
	}

	/**
	 * Returns if the unit is considered to be idle or not
	 *
	 * @return			Returns if the unit is considered to be idle or not
	 */
	simulated function bool IsIdle()
	{
		return false;
	}

	/**
	 * Engages a potential enemy target
	 *
	 * @param		PotentialTarget			Potential target
	 */
	function EngageTarget(Actor PotentialTarget)
	{
		if (EnemyTargetInterface != None && PotentialTarget == EnemyTargetInterface.GetActor())
		{
			return;
		}

		Global.EngageTarget(PotentialTarget);
	}

	/**
	 * Called when the controller's pawn has taken damage
	 *
	 * @param		DamageAmount			Amount of damage to dealt to the pawn
	 * @param		EventInstigator			Controller that instigated this event
	 * @param		HitLocation				World location where this hit occured
	 * @param		Momentum				Momentum to push the pawn
	 * @param		DamageType				Damage type that was dealt to the pawn
	 * @param		HitInfo					Trace information if any
	 * @param		DamageCauser			Actor that caused the damage
	 */
	function NotifyTakeDamage(int DamageAmount, Controller EventInstigator, vector HitLocation, vector Momentum, class<DamageType> DamageType, optional TraceHitInfo HitInfo, optional Actor DamageCauser)
	{
		// Check if the current enemy is still valid
		if (EnemyTargetInterface == None || !EnemyTargetInterface.HasWeapon())
		{
			Global.NotifyTakeDamage(DamageAmount, EventInstigator, HitLocation, Momentum, DamageType, HitInfo, DamageCauser);
		}
	}

	/**
	 * Checks if the unit is within range. If it is, then it will start firing at the enemy
	 *
	 * @return		Returns true if the unit is within range of the enemy
	 */
	function bool CheckIfWithinAttackRange()
	{
		local UDKRTSPawn UDKRTSPawn;

		// Check the enemy and the pawn
		if (EnemyTargetInterface == None || !EnemyTargetInterface.IsValidTarget() || !IsValidPawn(Pawn))
		{
			return false;
		}

		// Check the pawn
		UDKRTSPawn = UDKRTSPawn(Pawn);
		if (UDKRTSPawn == None || UDKRTSPawn.UDKRTSWeapon == None)
		{
			return false;
		}

		// Check if the enemy is within range, if so attack the enemy
		if (UDKRTSPawn.UDKRTSWeapon.InRange(EnemyTargetInterface.GetActor(), Pawn.Location))
		{
			if (!UDKRTSPawn.NeedsToTurnForFiring(EnemyTargetInterface.GetActor().Location) && UDKRTSPawn.UDKRTSWeapon.CanFire())
			{
				UDKRTSPawn.UDKRTSWeapon.Fire();
			}

			return true;
		}

		return false;
	}

	/**
	 * Called when this state ends
	 *
	 * @param	NextStateName	Name of the next state
	 */
	function EndState(Name NextStateName)
	{
		Super.EndState(NextStateName);
		
		// Set the enemy to none
		EnemyTargetInterface = None;
	}

Begin:
	StateLabel = "Begin";
	// Check pawn, if is no longer valid then this controller is dead
	if (!IsValidPawn(Pawn))
	{
		GotoState('Dead');
	}
	// Check enemy
	if (EnemyTargetInterface == None || !EnemyTargetInterface.IsValidTarget())
	{
		Goto('End');
	}
	// Wait until we are walking
	if (Pawn.Physics != Pawn.WalkingPhysics)
	{
		Sleep(0.f);
		Goto('Begin');
	}
	// Check if we are within attacking range of the target. If we are then start shooting at the enemy
	if (CheckIfWithinAttackRange())
	{
		Goto('HasReachedTargetDestination');
	}
	else
	{
		// Get the best attacking location
		GetBestAttackingLocation();
	}
MoveDirect:
	StateLabel = "MoveDirect";
	// Check if the destination is reachable
	if (IsPointReachable(GetDestinationPosition()))
	{		
		if (bAdjusting)
		{
			SetDestinationPosition(GetAdjustLocation());
		}

		// Move towards the destination
		bPreciseDestination = true;		
		FocusSpot = (CheckIfWithinAttackRange()) ? EnemyTargetInterface.GetActor().Location : GetDestinationPosition();
		Sleep(0.f);
		Goto('HasReachedDestination');
	}
MoveViaPathFinding:
	StateLabel = "MoveViaPathFinding";
	// Path find towards the destination
	if (GeneratePathTo(GetDestinationPosition(), Pawn.GetCollisionRadius(), true) && NavigationHandle.GetNextMoveLocation(NextMoveLocation, Pawn.GetCollisionRadius()))
	{
		if (bAdjusting)
		{
			SetDestinationPosition(GetAdjustLocation());
		}
		else
		{
			SetDestinationPosition(NextMoveLocation);
		}
		
		// Move towards the destination
		bPreciseDestination = true;
		FocusSpot = (CheckIfWithinAttackRange()) ? EnemyTargetInterface.GetActor().Location : GetDestinationPosition();
		Goto('HasReachedDestination');
	}
	else
	{
		// Couldn't path find, go to the end
		Goto('End');
	}
HasReachedDestination:
	StateLabel = "HasReachedDestination";
	// Check if we've reached the destination position
	if (!HasReachedPoint(GetDestinationPosition()))
	{
		FocusSpot = (CheckIfWithinAttackRange()) ? EnemyTargetInterface.GetActor().Location : GetDestinationPosition();
		Sleep(0.f);
		Goto('Begin');
	}
	else if (!HasReachedPoint(Destination))
	{		
		// Check if we've reached the destination
		SetDestinationPosition(Destination);
		FocusSpot = (CheckIfWithinAttackRange()) ? EnemyTargetInterface.GetActor().Location : GetDestinationPosition();
		Sleep(0.f);
		Goto('Begin');
	}
HasReachedTargetDestination:
	StateLabel = "HasReachedTargetDestination";
	FocusSpot = EnemyTargetInterface.GetActor().Location;
	Sleep(0.f);
	Goto('Begin');
End:
	Enemy = None;
	StateLabel = "End";
	GotoState('');
}

/**
 * This state represents a pawn that is harvesting a resource
 */
function HarvestTimer();

/**
 * This state represents the controller harvesting resources from a resource point
 */
state HarvestingResource
{
	/**
	 * Called everytime the AIController is updated
	 *
	 * @param			DeltaTime			Time since the last tick
	 */
	simulated function Tick(float DeltaTime)
	{
		Global.Tick(DeltaTime);

		if (Resource != None)
		{
			// Check if the AI is within range of harvesting from the resource
			if (HasReachedPoint(Resource.Location, Resource.HarvestRadius))
			{
				// Start the harvest timer as we've reached the resource
				if (!IsTimerActive(NameOf(HarvestTimer)))
				{
					SetTimer(UDKRTSPawn(Pawn).HarvestResourceInterval, false, NameOf(HarvestTimer));
				}
			}
			else
			{
				// Clear the harvest timer as we haven't reached the resource
				if (IsTimerActive(NameOf(HarvestTimer)))
				{
					ClearTimer(NameOf(HarvestTimer));
				}
			}
		}
	}

	/**
	 * Returns true if the controller is harvesting resources
	 *
	 * @return		Returns true if the controller is harvesting resources
	 */
	function bool IsHarvestingResources()
	{
		return true;
	}

	/**
	 * Returns true if the controller is idle
	 *
	 * @return		Returns true if the controller is idle
	 */
	simulated function bool IsIdle()
	{
		return false;
	}

	/**
	 * Renders any debug information required for this AI controller
	 *
	 * @param			HUD			HUD to render the debug information to
	 */
	simulated function RenderDebugState(UDKRTSHUD HUD)
	{
		Global.RenderDebugState(HUD);

		if (HUD.ShouldDisplayDebug('AIMovementLines'))
		{
			// Draw the current move location
			HUD.Draw3DLine(Pawn.Location, GetDestinationPosition(), class'HUD'.default.GreenColor);
			// Draw the final destination location
			HUD.Draw3DLine(Pawn.Location, Destination, class'UDKRTSPalette'.default.YellowColor);
		}
	}

	/**
	 * Sets the best harvest destination
	 */
	function BestHarvestDestination()
	{
		local Vector U;

		if (Resource == None || Pawn == None)
		{
			return;
		}

		U = Resource.Location;
		U.Z = Pawn.Location.Z;

		Destination = U + (Normal(Pawn.Location - U) * Resource.PathHarvestRadius);
		SetDestinationPosition(Destination);
	}

	/**
	 * Harvests a resource and then stores the resources
	 */
	function HarvestTimer()
	{
		if (Resource == None)
		{
			return;
		}

		Resource.RequestResource(UDKRTSPawn(Pawn));
		GotoState('StoreResource');
	}

	/**
	 * Called when this state 
	 *
	 * @param		PreviousStateName		Name of the previous state
	 */
	event BeginState(Name PreviousStateName)
	{
		Super.BeginState(PreviousStateName);
		
		// Set the best harvest destination
		BestHarvestDestination();

		// Set the enemy to none
		EnemyTargetInterface = None;
	}

	/**
	 * Called when this state ends
	 *
	 * @param		NextStateName			Name of the next state
	 */
	event EndState(Name NextStateName)
	{
		Super.EndState(NextStateName);

		CachedPreviousStateName = "HarvestingResource";

		if (IsTimerActive(NameOF(HarvestTimer)))
		{
			ClearTimer(NameOf(HarvestTimer));
		}
	}

Begin:
	StateLabel = "Begin";
	// Check if the pawn is still valid
	if (!IsValidPawn(Pawn))
	{
		GotoState('Dead');
	}
	// Check to make sure the resource I'm trying to gather from is still valid
	if (!IsValidResource(Resource))
	{
		Goto('End');
	}
	// Check if pawn is walking, if not wait until he is on the ground again
	if (Pawn.Physics != Pawn.WalkingPhysics)
	{
		Sleep(0.f);
		Goto('Begin');
	}
MoveDirect:
	StateLabel = "MoveDirect";
	// Check if the point is reachable or not
	if (IsPointReachable(GetDestinationPosition()))
	{
		if (bAdjusting)
		{
			SetDestinationPosition(GetAdjustLocation());
		}

		bPreciseDestination = true;
		FocusSpot = Resource.Location;
		Sleep(0.f);
		Goto('HasReachedDestination');
	}
MoveViaPathFinding:
	StateLabel = "MoveViaPathFinding";
	// Generate a path to the destination
	if (GeneratePathTo(GetDestinationPosition()) && NavigationHandle.GetNextMoveLocation(NextMoveLocation, 0.f))
	{
		if (bAdjusting)
		{
			SetDestinationPosition(GetAdjustLocation());
		}
		else
		{
			SetDestinationPosition(NextMoveLocation);
		}

		// Move to the current location
		bPreciseDestination = true;
		FocusSpot = GetDestinationPosition();
	}
	else
	{
		Goto('End');
	}
HasReachedDestination:
	StateLabel = "HasReachedDestination";

	// Check if we've reached the destination
	if (HasReachedPoint(GetDestinationPosition()))
	{		
		if (GetDestinationPosition() == Destination)
		{
			bPreciseDestination = false;
			FocusSpot = Resource.Location;
			Sleep(0.f);
			Goto('HasReachedDestination');			
		}
		else
		{
			SetDestinationPosition(Destination);
		}
	}

	Sleep(0.f);
	Goto('Begin');

End:
	StateLabel = "End";
	GotoState('');
}

/**
 * This state is when the controller is storing a resource somewhere
 */
state StoreResource
{
	/**
	 * Called everytime the AIController is updated
	 *
	 * @param			DeltaTime			Time since the last tick
	 */
	simulated function Tick(float DeltaTime)
	{
		Global.Tick(DeltaTime);

		// Check if the AI is within range of storing the resource
		if (ResourceStorage != None && HasReachedPoint(ResourceStorage.Location, ResourceStorage.ResourceStorageRadius))
		{
			// Reached the destination, and store the resource and go back to harvesting
			StoreResource();
			GotoState('HarvestingResource');
		}
	}

	/**
	 * Renders any debug information required for this AI controller
	 *
	 * @param			HUD			HUD to render the debug information to
	 */
	simulated function RenderDebugState(UDKRTSHUD HUD)
	{
		Global.RenderDebugState(HUD);

		if (HUD.ShouldDisplayDebug('AIMovementLines'))
		{
			// Draw the current move location
			HUD.Draw3DLine(Pawn.Location, GetDestinationPosition(), class'HUD'.default.GreenColor);
			// Draw the final destination location
			HUD.Draw3DLine(Pawn.Location, Destination, class'UDKRTSPalette'.default.YellowColor);
		}
	}

	/**
	 * Returns true if the controller is harvesting resources
	 *
	 * @return		Returns true if the controller is harvesting resources
	 */
	function bool IsHarvestingResources()
	{
		return true;
	}

	/**
	 * Returns true if the controller is idle
	 *
	 * @return		Returns true if the controller is idle
	 */
	simulated function bool IsIdle()
	{
		return false;
	}

	/**
	 * Sets the destination as the best resource storage destination
	 */
	function BestResourceStorageDestination()
	{
		local Vector U;

		if (ResourceStorage == None)
		{
			return;
		}

		U = ResourceStorage.Location;
		U.Z = Pawn.Location.Z;

		Destination = U + Normal(Pawn.Location - U) * ResourceStorage.PathStorageRadius;
	}

	/**
	 * Finds the best storage structure
	 */
	function FindBestStorageStructure()
	{
		local UDKRTSPawn UDKRTSPawn;
		local UDKRTSGameReplicationInfo UDKRTSGameReplicationInfo;
		local UDKRTSTeamInfo UDKRTSTeamInfo;
		local float ShortestDistance, Distance;
		local int i, j;
		
		// Get the team
		ResourceStorage = None;
		UDKRTSPawn = UDKRTSPawn(Pawn);
		if (UDKRTSPawn != None)
		{
			UDKRTSGameReplicationInfo = UDKRTSGameReplicationInfo(WorldInfo.GRI);
			if (UDKRTSGameReplicationInfo != None)
			{
				for (i = 0; i < UDKRTSGameReplicationInfo.Teams.Length; ++i)
				{
					if (UDKRTSPawn.OwnerReplicationInfo != None && UDKRTSGameReplicationInfo.Teams[i] == UDKRTSPawn.OwnerReplicationInfo.Team)
					{
						UDKRTSTeamInfo = UDKRTSTeamInfo(UDKRTSGameReplicationInfo.Teams[i]);
						if (UDKRTSTeamInfo != None)
						{
							for (j = 0; j < UDKRTSTeamInfo.Structures.Length; ++j)
							{
								if (UDKRTSTeamInfo.Structures[j] != None && UDKRTSTeamInfo.Structures[j].IsResourceStorage && UDKRTSTeamInfo.Structures[j].IsConstructed)
								{
									Distance = VSizeSq(Pawn.Location - UDKRTSTeamInfo.Structures[j].Location);
									if (ResourceStorage == None || Distance < ShortestDistance)
									{
										ResourceStorage = UDKRTSTeamInfo.Structures[j];
										ShortestDistance = Distance;
									}
								}
							}

							break;
						}
					}
				}
			}
		}
	}

	/**
	 * Stores the resource, and gives the owning player some resource
	 */
	function StoreResource()
	{
		local UDKRTSResourceInventory UDKRTSResourceInventory;
		local UDKRTSPawn UDKRTSPawn;

		if (Pawn != None && Pawn.InvManager != None)
		{
			UDKRTSResourceInventory = UDKRTSResourceInventory(Pawn.InvManager.FindInventoryType(class'UDKRTSResourceInventory', true));
			if (UDKRTSResourceInventory != None)
			{
				UDKRTSPawn = UDKRTSPawn(Pawn);
				if (UDKRTSPawn != None && UDKRTSPawn.OwnerReplicationInfo != None)
				{
					UDKRTSPawn.OwnerReplicationInfo.Resources += UDKRTSResourceInventory.Resource;					
				}

				Pawn.InvManager.RemoveFromInventory(UDKRTSResourceInventory);
			}
		}
	}

	/**
	 * Called when the state first begins
	 *
	 * @param		PreviousStateName		Previous state name
	 */
	event BeginState(Name PreviousStateName)
	{
		Super.BeginState(PreviousStateName);

		// Set the enemy to none
		EnemyTargetInterface = None;
	}

	/**
	 * Called when the state ends
	 *
	 * @param		NextStateName			Next state name
	 */
	event EndState(Name NextStateName)
	{
		CachedPreviousStateName = "StoreResource";
		Super.EndState(NextStateName);
		ResourceStorage = None;
	}

Begin:
	StateLabel = "Begin";
	// Ensure that the pawn is valid
	if (!IsValidPawn(Pawn))
	{
		Goto('Dead');
	}
	// Find the best storage structure
	if (ResourceStorage == None)
	{
		FindBestStorageStructure();
		// Set the best destination to go to, to store the resource	
		BestResourceStorageDestination();
	}
	// If the AI still doesn't have the best resource storage, then abort
	if (ResourceStorage == None)
	{
		GotoState('');
	}
	// Check to see if we're in store range
	if (VSize2D(ResourceStorage.Location - Pawn.Location) <= ResourceStorage.ResourceStorageRadius)
	{
		Goto('HasReachedDestination');
	}
	// Check if pawn is walking, if not wait until he is on the ground again
	if (Pawn.Physics != Pawn.WalkingPhysics)
	{
		Sleep(0.f);
		Goto('Begin');
	}
MoveDirect:
	StateLabel = "MoveDirect";
	// Check that the point is directly reachable
	if (IsPointReachable(GetDestinationPosition()))
	{
		if (bAdjusting)
		{
			SetDestinationPosition(GetAdjustLocation());
		}

		// Move to the destination
		bPreciseDestination = true;
		FocusSpot = ResourceStorage.Location;
		Sleep(0.f);
		Goto('HasReachedDestination');
	}
MoveViaPathFinding:
	StateLabel = "MoveViaPathFinding";
	// Generate a path
	if (GeneratePathTo(GetDestinationPosition(),, true) && NavigationHandle.GetNextMoveLocation(NextMoveLocation, 0.f))
	{
		if (bAdjusting)
		{
			SetDestinationPosition(GetAdjustLocation());
		}
		else
		{
			SetDestinationPosition(NextMoveLocation);
		}

		// Move to the destination
		bPreciseDestination = true;
		FocusSpot = ResourceStorage.Location;		
	}
	else
	{
		Goto('End');
	}
HasReachedDestination:
	StateLabel = "HasReachedDestination";

	// Check if we have reached the destination position
	if (HasReachedPoint(GetDestinationPosition()) && GetDestinationPosition() != Destination)
	{
		SetDestinationPosition(Destination);
	}

	Sleep(0.f);
	Goto('Begin');
End:
	StateLabel = "End";
	GotoState('');
}

defaultproperties
{	
}