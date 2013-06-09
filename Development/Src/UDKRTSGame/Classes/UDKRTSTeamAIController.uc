//=============================================================================
// UDKRTSTeamAIController: AI controller which is used for controlling an
// entire team of units.
//
// This class controls a collection of units as if it was another player. While
// units themselves have their own AI, they need an over arching AI which forms
// strategies to defeat human players.
// 
// Copyright 1998-2011 Epic Games, Inc. All Rights Reserved.
//=============================================================================
class UDKRTSTeamAIController extends AIController;

// Time intervals to rethink strategy. Decrease time intervals to make the AI more responsive to what other players are doing
var PrivateWrite float RethinkStrategyTime;
// Resources that the AI can access
var PrivateWrite array<UDKRTSResource> Resources;
// Enemy team to focus against
var PrivateWrite UDKRTSTeamInfo FocusedEnemyTeamInfo;
// Cached player replication info to reduce type casting calls
var PrivateWrite UDKRTSPlayerReplicationInfo CachedUDKRTSPlayerReplicationInfo;
// Cached team info to reduce type casting calls
var PrivateWrite UDKRTSTeamInfo CachedUDKRTSTeamInfo;
// All the build points that the AI can use. This is where the AI can build its structures
var PrivateWrite array<UDKRTSAIBuildPoint> BuildPoints;
// Archetype reference to the AI properties that the AI uses to formulate strategies
var const archetype UDKRTSAIProperties AIProperties;
// Next build order index which is an index within the build order array stored in the AI properties. This just points to what the AI needs to build next
var Private int NextBuildOrderIndex;
// Cache to the last structure the AI constructed
var Private UDKRTSStructure LastConstructedBuilding;

/**
 * Called when this actor is first spawned into the world
 */
function PostBeginPlay()
{
	local UDKRTSResource Resource;
	local UDKRTSAIBuildPoint UDKRTSAIBuildPoint;

	Super.PostBeginPlay();

	// Start the looping timer where the AI rethinks its strategy
	SetTimer(RethinkStrategyTime, true, NameOf(RethinkStrategy));

	// Find all of the resources
	ForEach DynamicActors(class'UDKRTSResource', Resource)
	{
		if (Resource != None)
		{
			Resources.AddItem(Resource);
		}
	}

	// Find all of the build points
	ForEach WorldInfo.AllNavigationPoints(class'UDKRTSAIBuildPoint', UDKRTSAIBuildPoint)
	{
		BuildPoints.AddItem(UDKRTSAIBuildPoint);
	}
}

/**
 * Called when this AI should initialize itself
 */
function Initialize()
{
	CachedUDKRTSPlayerReplicationInfo = UDKRTSPlayerReplicationInfo(PlayerReplicationInfo);
	if (CachedUDKRTSPlayerReplicationInfo != None)
	{
		CachedUDKRTSTeamInfo = UDKRTSTeamInfo(CachedUDKRTSPlayerReplicationInfo.Team);
	}
}

/**
 * Called from the GameInfo to inform the AI that the game has ended
 */
function NotifyEndGame()
{
	if (IsTimerActive(NameOf(RethinkStrategy)))
	{
		ClearTimer(NameOf(RethinkStrategy));
	}
}

/**
 * Called from a UDKRTSStructure to inform the AI that one of its structures is being damaged by another player
 *
 * @param		EventInstigator			Controller which caused this notification to be sent
 * @param		Structure				Structure which was damaged
 */
function NotifyStructureDamage(Controller EventInstigator, UDKRTSStructure Structure)
{
	local int i;
	local float Distance;
	local UDKRTSAIController UDKRTSAIController;
	local UDKRTSTargetInterface PotentialTarget;

	// Check parameters
	if (CachedUDKRTSTeamInfo == None || EventInstigator == None || EventInstigator.Pawn == None)
	{
		return;
	}

	if (CachedUDKRTSTeamInfo.Pawns.Length > 0)
	{
		// Find the potential target
		PotentialTarget = UDKRTSTargetInterface(EventInstigator.Pawn);
		if (PotentialTarget != None)
		{
			for (i = 0; i < CachedUDKRTSTeamInfo.Pawns.Length; ++i)
			{
				// For all healthy pawns under my control within a range of 1024 uu's away, engage the attacker!
				if (CachedUDKRTSTeamInfo.Pawns[i] != None && CachedUDKRTSTeamInfo.Pawns[i].Health > 0)
				{
					Distance = VSize(CachedUDKRTSTeamInfo.Pawns[i].Location - Structure.Location);
					if (Distance <= 1024.f)
					{
						UDKRTSAIController = UDKRTSAIController(CachedUDKRTSTeamInfo.Pawns[i].Controller);
						if (UDKRTSAIController != None && UDKRTSAIController.EnemyTargetInterface == None)
						{
							UDKRTSAIController.EngageTarget(EventInstigator.Pawn);
						}
					}
				}
			}
		}
	}
}

/**
 * Called from within a looping timer to make the AI rethink its strategy
 */
function RethinkStrategy()
{
	local int i, j, k;
	local UDKRTSTeamInfo OtherUDKRTSTeamInfo;
	local UDKRTSAIController UDKRTSAIController;
	local UDKRTSResource UDKRTSResource;
	local UDKRTSGameReplicationInfo UDKRTSGameReplicationInfo;
	local bool bHasEnoughMilitary, IsStructureUpgrade, BuildStructureOrderAssigned, CanBuildStructure;
	local UDKRTSTargetInterface UDKRTSTargetInterface;
	local array<UDKRTSTargetInterface> ValidTargets;	
	local UDKRTSAIBuildPoint UDKRTSAIBuildPoint;
	local UDKRTSGameInfo UDKRTSGameInfo;

	// Check cached references
	if (CachedUDKRTSPlayerReplicationInfo == None || CachedUDKRTSTeamInfo == None)
	{
		return;
	}

	// Check the AI properties
	if (AIProperties != None)
	{
		// Check the build order, this controls when and what structures the AI needs to build in order to progress
		if (AIProperties.StructureBuildOrder.Length > 0)
		{
			if (LastConstructedBuilding == None)
			{
				// Iterate over the buid order and reset the NextBuildOrderIndex if required
				if (NextBuildOrderIndex != INDEX_NONE && HasStructure(AIProperties.StructureBuildOrder[NextBuildOrderIndex].Structure))
				{
					NextBuildOrderIndex = INDEX_NONE;
				}

				// If the next build order index is not valid, get the next build order index
				if (NextBuildOrderIndex == INDEX_NONE)
				{
					for (i = 0; i < AIProperties.StructureBuildOrder.Length; ++i)
					{
						if (!HasStructure(AIProperties.StructureBuildOrder[i].Structure))
						{
							NextBuildOrderIndex = i;
							break;
						}
					}
				}

				// Check if we can build this structure
				if (BuildPoints.Length > 0 && NextBuildOrderIndex != INDEX_NONE && class'UDKRTSStructure'.static.CanBuildStructure(AIProperties.StructureBuildOrder[NextBuildOrderIndex].Structure, CachedUDKRTSPlayerReplicationInfo, false) && CachedUDKRTSTeamInfo.Pawns.Length > 0)
				{
					CanBuildStructure = true;
					// Check if we have the required number of harvesters
					if (!HasEnoughHarvesters(AIProperties.StructureBuildOrder[NextBuildOrderIndex].RequiredHarvesters))
					{
						CanBuildStructure = false;
					}

					// Check if we have the required number of military rating
					if (!HasEnoughMilitary(AIProperties.StructureBuildOrder[NextBuildOrderIndex].RequiredMilitaryRating))
					{
						CanBuildStructure = false;
					}

					// Check if we have the required resources
					if (CachedUDKRTSPlayerReplicationInfo.Resources < AIProperties.StructureBuildOrder[NextBuildOrderIndex].RequiredResources)
					{
						CanBuildStructure = false;
					}

					// Check if we have the required power
					if (CachedUDKRTSPlayerReplicationInfo.Power < AIProperties.StructureBuildOrder[NextBuildOrderIndex].RequiredPower)
					{
						CanBuildStructure = false;
					}

					if (CanBuildStructure)
					{
						// Check the other parts
						IsStructureUpgrade = false;
						// Is the building an upgrade
						for (j = 0; j < CachedUDKRTSTeamInfo.Structures.Length; ++j)
						{
							if (CachedUDKRTSTeamInfo.Structures[j] != None && CachedUDKRTSTeamInfo.Structures[j].UpgradableStructureArchetype == AIProperties.StructureBuildOrder[NextBuildOrderIndex].Structure)
							{
								CachedUDKRTSTeamInfo.Structures[j].UpgradeStructure();
								IsStructureUpgrade = true;
							}
						}

						if (!IsStructureUpgrade)
						{
							// Check who can build this
							BuildStructureOrderAssigned = false;
							for (j = 0; j < CachedUDKRTSTeamInfo.Pawns.Length; ++j)
							{
								if (CachedUDKRTSTeamInfo.Pawns[j] != None && CachedUDKRTSTeamInfo.Pawns[j].BuildableStructureArchetypes.Find(AIProperties.StructureBuildOrder[NextBuildOrderIndex].Structure) != INDEX_NONE)
								{
									k = Rand(BuildPoints.Length);
									UDKRTSAIBuildPoint = BuildPoints[k];
									BuildPoints.Remove(k, 1);

									if (UDKRTSAIBuildPoint != None)
									{
										UDKRTSGameInfo = UDKRTSGameInfo(WorldInfo.Game);
										if (UDKRTSGameInfo != None)
										{
											LastConstructedBuilding = UDKRTSGameInfo.RequestStructure(AIProperties.StructureBuildOrder[NextBuildOrderIndex].Structure, CachedUDKRTSPlayerReplicationInfo, UDKRTSAIBuildPoint.Location - (Vect(0.f, 0.f, 1.f) * UDKRTSAIBuildPoint.CylinderComponent.CollisionHeight));							
											if (LastConstructedBuilding != None)
											{
												// Send the pawn to go build this
												UDKRTSAIController = UDKRTSAIController(CachedUDKRTSTeamInfo.Pawns[j].Controller);
												if (UDKRTSAIController != None)
												{
													UDKRTSAIController.MoveToPoint(UDKRTSAIBuildPoint.Location - (Normal(UDKRTSAIBuildPoint.Location - CachedUDKRTSTeamInfo.Pawns[j].Location) * AIProperties.StructureBuildOrder[NextBuildOrderIndex].Structure.CollisionCylinder.CollisionRadius), true);
													BuildStructureOrderAssigned = true;
												}
											}
										}
									}
								}

								if (BuildStructureOrderAssigned)
								{
									break;
								}
							}
						}
					}
				}
			}
			else if (LastConstructedBuilding.IsTimerActive('CompleteConstruction'))
			{
				LastConstructedBuilding = None;
			}
		}
	}

	// Check if the current focused enemy has lost everything or not
	if (FocusedEnemyTeamInfo != None && FocusedEnemyTeamInfo.HasLostEverything())
	{
		FocusedEnemyTeamInfo = None;		
	}

	// If we aren't focusing on an enemy right now, find an enemy team that I should focus on
	if (FocusedEnemyTeamInfo == None)
	{
		UDKRTSGameReplicationInfo = UDKRTSGameReplicationInfo(WorldInfo.GRI);

		if (UDKRTSGameReplicationInfo != None && UDKRTSGameReplicationInfo.Teams.Length > 0)
		{
			for (i = 0; i < UDKRTSGameReplicationInfo.Teams.Length; ++i)
			{
				OtherUDKRTSTeamInfo = UDKRTSTeamInfo(UDKRTSGameReplicationInfo.Teams[i]);
				if (OtherUDKRTSTeamInfo != None && OtherUDKRTSTeamInfo != CachedUDKRTSTeamInfo && !OtherUDKRTSTeamInfo.HasLostEverything())
				{
					FocusedEnemyTeamInfo = OtherUDKRTSTeamInfo;
					break;
				}
			}
		}
	}

	if (FocusedEnemyTeamInfo != None)
	{		
		// Check if we have enough military
		bHasEnoughMilitary = HasEnoughMilitary();

		// If we have units, figure out what to do with them
		if (CachedUDKRTSTeamInfo.Pawns.Length > 0)
		{
			for (i = 0; i < CachedUDKRTSTeamInfo.Pawns.Length; ++i)
			{
				// Ensure that the pawn can move
				if (CachedUDKRTSTeamInfo.Pawns[i] != None)
				{
					UDKRTSAIController = UDKRTSAIController(CachedUDKRTSTeamInfo.Pawns[i].Controller);
					if (UDKRTSAIController != None && UDKRTSAIController.IsTimerActive('WhatToDo'))
					{
						// Unit can harvest...
						if (CachedUDKRTSTeamInfo.Pawns[i].HarvestResourceInterval > 0.f)
						{
							// If the unit is currently attacking, then abort
							if (UDKRTSAIController.IsInState('EngagingEnemy') && UDKRTSAIController.EnemyTargetInterface != None && UDKRTSAIController.EnemyTargetInterface.GetActor() != None)
							{
								continue;
							}

							// Check if unit is harvest, if not, then get him to harvest the nearest resource
							if (!UDKRTSAIController.IsHarvestingResources())
							{
								UDKRTSResource = GetNearestResource(CachedUDKRTSTeamInfo.Pawns[i].Location);

								if (UDKRTSResource != None)
								{
									UDKRTSAIController.HarvestResource(UDKRTSResource);
								}
							}
						}
						else if (bHasEnoughMilitary)
						{
							if (UDKRTSAIController.EnemyTargetInterface == None)
							{
								// Get all the pawn targets
								if (FocusedEnemyTeamInfo.Pawns.Length > 0)
								{
									for (i = 0; i < FocusedEnemyTeamInfo.Pawns.Length; ++i)
									{
										// Build a list of valid pawns to attack
										UDKRTSTargetInterface = UDKRTSTargetInterface(FocusedEnemyTeamInfo.Pawns[i]);
										if (UDKRTSTargetInterface != None && UDKRTSTargetInterface.IsValidTarget(CachedUDKRTSTeamInfo))
										{
											ValidTargets.AddItem(UDKRTSTargetInterface);
										}
									}
								}

								// Get all of the structure targets
								if (FocusedEnemyTeamInfo.Structures.Length > 0)
								{
									// Check if we have any valid targets that are structures
									for (i = 0; i < FocusedEnemyTeamInfo.Structures.Length; ++i)
									{
										// Build a list of valid structures to attack
										UDKRTSTargetInterface = UDKRTSTargetInterface(FocusedEnemyTeamInfo.Structures[i]);
										if (UDKRTSTargetInterface != None && UDKRTSTargetInterface.IsValidTarget(CachedUDKRTSTeamInfo))
										{
											ValidTargets.AddItem(UDKRTSTargetInterface);
										}
									}
								}

								// Sort targets, and choose the best one to attack
								if (ValidTargets.Length > 0)
								{									
									// Pick random target for now
									UDKRTSAIController.EngageTarget(ValidTargets[Rand(ValidTargets.Length)].GetActor());
								}
							}
						}
					}
				}
			}
		}
	}

	// If we have resources left over, and no harvesters then we need to build harvesters
	if (CachedUDKRTSPlayerReplicationInfo.Resources > 0 && CachedUDKRTSPlayerReplicationInfo.Power > 0 && !HasHarvesters())
	{
		BuildHarvester();
	}

	// If we have resources left over, then expand our military
	if (CachedUDKRTSPlayerReplicationInfo.Resources > 0 && CachedUDKRTSPlayerReplicationInfo.Power > 0)
	{
		BuildMilitary();
	}

	// If we have any more resources left over, then build more harvesters if we don't have enough
	if (CachedUDKRTSPlayerReplicationInfo.Resources > 0 && CachedUDKRTSPlayerReplicationInfo.Power > 0 && !HasEnoughHarvesters())
	{
		BuildHarvester();
	}
}

/**
 * Checks if we already have this structure or not
 *
 * @param		StructureArchetype			Structure archetype to test against
 * @return									Returns true if we have this structure
 */
function bool HasStructure(UDKRTSStructure StructureArchetype)
{
	local int i;

	if (CachedUDKRTSTeamInfo.Structures.Length > 0)
	{
		for (i = 0; i < CachedUDKRTSTeamInfo.Structures.Length; ++i)
		{
			if (CachedUDKRTSTeamInfo.Structures[i] != None && CachedUDKRTSTeamInfo.Structures[i].ObjectArchetype == StructureArchetype)
			{
				return true;
			}
		}
	}

	return false;
}
/**
 * Checks if we have a large enough army to start attacking
 *
 * @param		RequiredMilitaryRating			Military rating the controller has to have in order to return true
 * @return										Returns true if the AI's army is above or equal RequiredMilitaryRating
 */
function bool HasEnoughMilitary(optional float RequiredMilitaryRating = 30.f)
{
	local int i;
	local float MilitaryRating;
	
	// Check object references
	if (CachedUDKRTSPlayerReplicationInfo == None || CachedUDKRTSTeamInfo == None)
	{
		return false;
	}

	// We don't have any units, so we can't have any harvesters
	if (CachedUDKRTSTeamInfo.Pawns.Length <= 0)
	{
		return false;
	}

	// Return true if we have harvesters
	for (i = 0; i < CachedUDKRTSTeamInfo.Pawns.Length; ++i)
	{
		if (CachedUDKRTSTeamInfo.Pawns[i] != None)
		{
			MilitaryRating += CachedUDKRTSTeamInfo.Pawns[i].MilitaryRating;
		}
	}

	// Return true if there is more than or equal to RequiredMilitaryRating
	return (MilitaryRating >= RequiredMilitaryRating);
}

/**
 * Checks if we have any harvesters
 *
 * @return		Returns true if we have any units that can harvest resources
 */
function bool HasHarvesters()
{
	local int i;

	// Checks object references
	if (CachedUDKRTSPlayerReplicationInfo == None || CachedUDKRTSTeamInfo == None)
	{
		return false;
	}

	// We don't have any units, so we can't have any harvesters
	if (CachedUDKRTSTeamInfo.Pawns.Length <= 0)
	{
		return false;
	}

	// Return true if we have harvesters
	for (i = 0; i < CachedUDKRTSTeamInfo.Pawns.Length; ++i)
	{
		if (CachedUDKRTSTeamInfo.Pawns[i] != None && CachedUDKRTSTeamInfo.Pawns[i].HarvestResourceInterval > 0.f)
		{
			return true;
		}
	}

	// We don't have any harvesters
	return false;
}

/**
 * Checks if we have enough harvesters
 *
 * @param		Returns true if we have enough harvesters
 */
function bool HasEnoughHarvesters(optional int RequiredHarvesterCount = 4)
{
	local int i, HarvesterCount;
	
	if (CachedUDKRTSPlayerReplicationInfo == None || CachedUDKRTSTeamInfo == None)
	{
		return false;
	}

	// We don't have any units, so we can't have any harvesters
	if (CachedUDKRTSTeamInfo.Pawns.Length <= 0)
	{
		return false;
	}

	// Return true if we have harvesters
	for (i = 0; i < CachedUDKRTSTeamInfo.Pawns.Length; ++i)
	{
		if (CachedUDKRTSTeamInfo.Pawns[i] != None && CachedUDKRTSTeamInfo.Pawns[i].HarvestResourceInterval > 0.f)
		{
			HarvesterCount++;
		}
	}

	// Return true if there is more than or equal to RequiredHarvesterCount
	return (HarvesterCount >= RequiredHarvesterCount);
}

/**
 * Builds a unit that can harvest resources
 *
 * @return		Returns true if we are building harvesters
 */
function bool BuildHarvester()
{
	local int i, j;

	// Check object references
	if (CachedUDKRTSPlayerReplicationInfo == None || CachedUDKRTSTeamInfo == None)
	{
		return false;
	}

	// Find out if we're building any units that can harvest at the moment
	for (i = 0; i < CachedUDKRTSTeamInfo.Structures.Length; ++i)
	{
		if (CachedUDKRTSTeamInfo.Structures[i] != None && CachedUDKRTSTeamInfo.Structures[i].QueuedUnitArchetypes.Length > 0)
		{
			// Check if any of the queued units are capable of harvesting
			for (j = 0; j < CachedUDKRTSTeamInfo.Structures[i].QueuedUnitArchetypes.Length; ++j)
			{
				if (CachedUDKRTSTeamInfo.Structures[i].QueuedUnitArchetypes[j] != None && CachedUDKRTSTeamInfo.Structures[i].QueuedUnitArchetypes[j].HarvestResourceInterval > 0)
				{
					return true;
				}
			}
		}
	}

	// We're not building any units, so build a unit that can harvest resources
	for ( i = 0; i < CachedUDKRTSTeamInfo.Structures.Length; ++i)
	{
		if (CachedUDKRTSTeamInfo.Structures[i] != None && CachedUDKRTSTeamInfo.Structures[i].BuildablePawnArchetypes.Length > 0)
		{
			// Find a unit that can be built that can harvest resources
			for (j = 0; j < CachedUDKRTSTeamInfo.Structures[i].BuildablePawnArchetypes.Length; ++j)
			{
				if (CachedUDKRTSTeamInfo.Structures[i].BuildablePawnArchetypes[j] != None && CachedUDKRTSTeamInfo.Structures[i].BuildablePawnArchetypes[j].HarvestResourceInterval > 0 && class'UDKRTSPawn'.static.CanBuildPawn(CachedUDKRTSTeamInfo.Structures[i].BuildablePawnArchetypes[j], CachedUDKRTSPlayerReplicationInfo, false))
				{
					// Build this unit
					CachedUDKRTSTeamInfo.Structures[i].HandleHUDAction(EHAR_Build, j);
					return true;
				}
			}
		}
	}

	return false;
}

/**
 * Returns the nearest resource from a location in the world
 *
 * @param		TestLocation		World location to find the nearest resource
 * @return							Returns a reference to a resource that can be harvested
 */
function UDKRTSResource GetNearestResource(Vector TestLocation)
{
	local int i;
	local UDKRTSResource Resource;
	local float ClosestDistanceSq, DistanceSq;

	if (Resources.Length > 0)
	{
		for (i = 0; i < Resources.Length; ++i)
		{
			// Check that this resource still has resources left
			if (Resources[i].Amount > 0)
			{
				// Evaluate if this is the nearest resource or not
				DistanceSq = VSizeSq(TestLocation - Resources[i].Location);
				if (Resource == None || ClosestDistanceSq > DistanceSq)
				{
					Resource = Resources[i];
					ClosestDistanceSq = DistanceSq;
				}
			}
			else
			{
				// This resource has no more resources left in it, remove it
				Resources.Remove(i, 1);
				--i;
			}
		}

		return Resource;
	}

	return None;
}

/**
 * Builds the best military unit
 *
 * @return			Returns true if a military unit is being built
 */
function bool BuildMilitary()
{
	local int i, j, SelectedStructureIndex, SelectedPawnIndex;
	local UDKRTSPawn UDKRTSPawnArchetype, SelectedPawnArchetype;

	// Check object references
	if (CachedUDKRTSPlayerReplicationInfo == None || CachedUDKRTSTeamInfo == None)
	{
		return false;
	}

	// Find a unit which is within our price range and has the best fire power
	if (CachedUDKRTSTeamInfo.Structures.Length > 0)
	{
		for (i = 0; i < CachedUDKRTSTeamInfo.Structures.Length; ++i)
		{
			if (CachedUDKRTSTeamInfo.Structures[i].BuildablePawnArchetypes.Length > 0 && CachedUDKRTSTeamInfo.Structures[i].QueuedUnitArchetypes.Length == 0)
			{
				SelectedStructureIndex = i;

				for (j = 0; j < CachedUDKRTSTeamInfo.Structures[i].BuildablePawnArchetypes.Length; ++j)
				{
					// For each buildable pawn check if it has a weapon and if we can afford it
					UDKRTSPawnArchetype = CachedUDKRTSTeamInfo.Structures[i].BuildablePawnArchetypes[j];

					if (UDKRTSPawnArchetype != None && UDKRTSPawnArchetype.HarvestResourceInterval <= 0.f && UDKRTSPawnArchetype.WeaponArchetype != None && class'UDKRTSPawn'.static.CanBuildPawn(UDKRTSPawnArchetype, CachedUDKRTSPlayerReplicationInfo, false))
					{
						if (SelectedPawnArchetype == None || SelectedPawnArchetype.WeaponArchetype.FireMode.GetDamage() < UDKRTSPawnArchetype.WeaponArchetype.FireMode.GetDamage())
						{
							SelectedPawnArchetype = UDKRTSPawnArchetype;
							SelectedPawnIndex = j;
						}
					}
				}
			}
		}

		// If we've selected a pawn archetype, build it
		if (SelectedPawnArchetype != None)
		{
			CachedUDKRTSTeamInfo.Structures[SelectedStructureIndex].HandleHUDAction(EHAR_Build, SelectedPawnIndex);
			return true;
		}
	}

	return false;
}

defaultproperties
{
	AIProperties=UDKRTSAIProperties'UDKRTSGameContent.Archetypes.AIProperties'
	RethinkStrategyTime=0.05f
	bIsPlayer=true
}