//=============================================================================
// UDKRTSStructure: Actor which represents a structure in the RTS game.
//
// This class represents all structures in the RTS game. You should archetype
// it in your content packages if you wish to create new structures. However,
// if a struture requires vastly different logic, extend it first.
// 
// Copyright 1998-2011 Epic Games, Inc. All Rights Reserved.
//=============================================================================
class UDKRTSStructure extends Actor
	HideCategories(Attachment, Physics, Object)
	Implements(UDKRTSHUDActionInterface, UDKRTSMinimapInterface, UDKRTSHUDInterface, UDKRTSGroupableInterface, UDKRTSTargetInterface, UDKRTSWeaponOwnerInterface)
	Placeable;

// Archetype of structure to upgrade to
var(Upgrade) const archetype UDKRTSStructure UpgradableStructureArchetype;
// Upgrades you can purchase from this structure
var(Upgrade) const archetype array<UDKRTSUpgrade> UpgradeArchetypes;

// How much resources this structure costs to build
var(Cost) const int ResourcesCost;
// How much power this structure costs to build
var(Cost) const int PowerCost;

// Portrait
var(Structure) const SHUDAction Portrait;
// Material used to represent that the structure can be built
var(Structure) const MaterialInterface CanBuildMaterial;
// Material used to represent that the structure cannot be built
var(Structure) const MaterialInterface CantBuildMaterial;
// Localized name of the structure
var(Structure) const /*localized*/ String StructureName;
// HUD Action to display to build this structure
var(Structure) const SHUDAction BuildHUDAction;
// HUD Action to display to repair this structure
var(Structure) const SHUDAction RepairHUDAction;
// Time in between repairs
var(Structure) const float RepairTimeInterval;
// How much to repair per interval
var(Structure) const int RepairPerInterval;
// How much resources it costs to repair the building
var(Structure) const int RepairResourcesCost;
// How much power it costs to repair the building
var(Structure) const int RepairPowerCost;
// Repair icon
var(Structure) const Texture2D RepairIcon;
// Preview skeletal mesh to use
var(Structure) const SkeletalMesh PreviewSkeletalMesh;
// Skeletal mesh
var(Structure) const editconst SkeletalMeshComponent Mesh;
// Light environment 
var(Structure) const editconst LightEnvironmentComponent LightEnvironment;
// Pawn archetypes that this structure can build
var(Structure) const archetype array<UDKRTSPawn> BuildablePawnArchetypes;
// Resources can be stored here
var(Structure) const bool IsResourceStorage;
// Health the structure starts with
var(Structure) repnotify int Health;
// Maximum health of the structure
var(Structure) int MaxHealth;
// Team to assign this structure to if it is placed on the map
var(Structure) const int StartingTeamIndex;
// Time that it takes to construct this building
var(Structure) const float ConstructionTime;
// Spawn unit radius
var(Structure) const float UnitSpawnRadius;
// Spawn vehicle radius
var(Structure) const float VehicleSpawnRadius;
// Start building on spawn
var(Structure) const bool BuildOnSpawn;
// Never create a nav mesh obstacle
var(Structure) const bool NeverSpawnNavMeshObstacle;
// Sound to play back when this structure is destroyed
var(Structure) const SoundCue DestroyedStructureSoundCue;
// Particle template to spawn when this structure is destroyed
var(Structure) const ParticleSystem DestroyedStructureParticleTemplate;
// Particle system component to activate when the building is damaged
var(Structure) const ParticleSystemComponent DamagedBuildingParticleSystemComponent;
// How damaged the building should be to activate the building damaged particle system
var(Structure) int DamagedHealth;
// AI priority for targeting reasons
var(Structure) float AITargetingPriority;

// Radius to check if the building can be placed
var(Radius) const float PlacementClearanceRadius;
// Radius a pawn must be in to store resources
var(Radius) const float ResourceStorageRadius;
// Radius a pawn casts out for pathing purposes
var(Radius) const float PathStorageRadius;

// Structure archetypes that need to be build before this building can be
var(Dependencies) const archetype array<UDKRTSStructure> RequiredStructures;
// Minimum number of required structures, -1 to require them all
var(Dependencies) const int MinimumRequiredCount;
// Maximum number of this structures the player can have. Set to -1 to have no limit
var(Dependencies) const int MaximumCount;

// Can the structure set rally points?
var(RallyPoint) const bool CanSetRallyPoint;
// Color to use when rendering the rally point line
var(RallyPoint) const Color RallyPointLineColor;
// Mesh to use which represents the rally point
var(RallyPoint) editconst StaticMeshComponent RallyPointMesh;
// All the different team materials for the rally point flag
var(RallyPoint) const array<MaterialInterface> RallyPointMaterials;

// Minimum power the structure provides per second
var(Power) const int MinPowerProvidedPerSecond;
// Maximum power the structure provides per second
var(Power) const int MaxPowerProvidedPerSecond;

// Color to use when rendering the bounding box
var(Debug) const Color BoundingBoxColor;

// How much to raise the unit population cap
var(PopulationCap) const int AdditionalUnitPopulationCap;
// How much to raise the vehicle population cap
var(PopulationCap) const int AdditionalVehiclePopulationCap;

// All the different team materials
var(Rendering) const array<MaterialInterface> TeamMaterials;

// Structure weaponry
var(Weaponry) const archetype UDKRTSWeapon WeaponArchetype;

// Has an actor reference to use as a rally point
var Actor RallyPointActorReference;
// Where the rally point is right now
var ProtectedWrite vector RallyPointLocation;
// Has the structure finished constructing
var RepNotify ProtectedWrite bool IsConstructed;
// Queued units for building
var ProtectedWrite archetype array<UDKRTSPawn> QueuedUnitArchetypes;
// Queued upgrades for researching
var ProtectedWrite archetype array<UDKRTSUpgrade> QueuedUpgradeArchetypes;
// Collision cylinder used for this structure
var const editconst CylinderComponent CollisionCylinder;
// Player is currently setting the rally point
var bool SettingRallyPoint;
// Rally point has been set and is valid
var bool RallyPointHasBeenSet;
// Waiting for pawn to start construction
var bool WaitingForPawnToStartConstruction;
// Player replication info that owns this structure
var RepNotify ProtectedWrite UDKRTSPlayerReplicationInfo OwnerReplicationInfo;
// Nav Mesh obstacle
var ProtectedWrite UDKRTSNavMeshObstacle UDKRTSNavMeshObstacle;
// Weapon
var ProtectedWrite UDKRTSWeapon Weapon;
// Current target
var ProtectedWrite UDKRTSTargetInterface CurrentTarget;
// Accumulated damage while building
var int AccumulatedDamage;

// Mobile bounding box used for selection purposes
var Box ScreenBoundingBox;

// Replication block
replication
{
	if ((bNetDirty || bNetInitial) && Role == Role_Authority)
		IsConstructed, OwnerReplicationInfo, Health;
}

/**
 * Called when the structure if first instanced
 */
simulated event PostBeginPlay()
{
	Super.PostBeginPlay();

	// If the structure can set rally points, then hide the rally point mesh component initially and set its location to the actor's location
	// Otherwise, detach the rally point mesh component
	if (CanSetRallyPoint)
	{
		RallyPointMesh.SetHidden(true);
		RallyPointMesh.SetTranslation(Location);
		RallyPointLocation = Location;
		RallyPointActorReference = None;
	}
	else
	{
		DetachComponent(RallyPointMesh);
	}

	// Set the health if need be
	if (MaxHealth > 0 && Health == 0)
	{
		Health = MaxHealth;
	}

	// Set the health damage
	if (DamagedHealth == 0)
	{
		DamagedHealth = Health * 0.5f;
	}

	// If the structure was placed in the editor, complete the construction immediately
	if (WorldInfo.bStartup || ConstructionTime == 0.f)
	{
		// Create the navigation mesh obstacle
		CreateNavMeshObstacle();
		CompleteConstruction();
	}
	else
	{
		// Check if this structure starts constructing itself on spawn
		if (BuildOnSpawn)
		{
			// Create the navigation mesh obstacle
			CreateNavMeshObstacle();

			// Start construction
			SetHidden(false);
			WaitingForPawnToStartConstruction = false;
			SetDrawScale3D(Vect(1.f, 1.f, 0.01f));
			SetTimer(ConstructionTime, false, NameOf(CompleteConstruction));
		}
		else
		{
			// Wait for pawns to touch this structure to begin construction
			SetHidden(true);
			WaitingForPawnToStartConstruction = true;
		}
	}
}

/**
 * Called when a variable with the property flag "RepNotify" is replicated
 *
 * @param		VarName			Name of the variable which was replicated
 */
simulated event ReplicatedEvent(name VarName)
{
	if (VarName == 'IsConstructed')
	{
		// Create the navigation mesh obstacle
		CreateNavMeshObstacle();
		CompleteConstruction(true);
	}
	else if (VarName == 'OwnerReplicationInfo')
	{
		// Set the owner replication info
		SetOwnerReplicationInfo(OwnerReplicationInfo);
	}
	else if (VarName == 'Health' && DamagedBuildingParticleSystemComponent != None)
	{
		// Check fire damage particle effect
		if (Health > DamagedHealth)
		{
			DamagedBuildingParticleSystemComponent.DeactivateSystem();
		}
		else
		{
			DamagedBuildingParticleSystemComponent.ActivateSystem();
		}
	}

	Super.ReplicatedEvent(VarName);
}

/**
 * Creates the navigation mesh obstacle to allow pawns to correctly navigate around the world
 */
simulated function CreateNavMeshObstacle()
{
	// Prevent the dedicated server from crashing right now
	if (WorldInfo.NetMode == NM_DedicatedServer)
	{
		return;
	}

	// Abort if the structure should never block
	// Do not allow clients to create the nav mesh obstacle
	if (NeverSpawnNavMeshObstacle || Role < Role_Authority)
	{
		return;
	}

	// Create the navigation mesh obstacle
	if (CollisionCylinder != None && CollisionCylinder.CollisionRadius > 0.f && UDKRTSNavMeshObstacle == None)
	{
		UDKRTSNavMeshObstacle = Spawn(class'UDKRTSNavMeshObstacle',,, Location);
		if (UDKRTSNavMeshObstacle != None)
		{
			UDKRTSNavMeshObstacle.SetAsSquare(CollisionCylinder.CollisionRadius);
			UDKRTSNavMeshObstacle.Register();
		}
	}
}

/**
 * Returns true if the structure is in god mode or not
 *
 * @return		Returns true if the player controller who owns this structure is in god mode or not
 */
function bool InGodMode()
{
	local PlayerController PlayerController;

	if (OwnerReplicationInfo != None)
	{
		PlayerController = PlayerController(OwnerReplicationInfo.Owner);
		if (PlayerController != None)
		{
			return PlayerController.bGodMode;
		}
	}

	return false;
}

/**
 * Called when the structure gives the power resource to its owner
 */
function GivePowerTimer()
{
	local float Percentage;

	// Check if we have an owner
	// Abort if this function is executed on the client
	if (OwnerReplicationInfo == None || Role < Role_Authority)
	{
		return;
	}

	// Give power based on the health of the structure
	Percentage = float(Health) / float(MaxHealth);
	OwnerReplicationInfo.Power += Lerp(MinPowerProvidedPerSecond, MaxPowerProvidedPerSecond, Percentage);
}

/**
 * Called when the structure is destroyed
 */
simulated event Destroyed()
{
	local UDKRTSPlayerController UDKRTSPlayerController;

	Super.Destroyed();

	// If the owner is a player, then inform the player controller that this structure was destroyed
	if (OwnerReplicationInfo != None)
	{		
		UDKRTSPlayerController = UDKRTSPlayerController(OwnerReplicationInfo.Owner);
		if (UDKRTSPlayerController != None)
		{
			UDKRTSPlayerController.NotifyActorDestroyed(Self);
		}
	}

	// Remove the navigation mesh obstacle
	if (Role == Role_Authority && UDKRTSNavMeshObstacle != None)
	{
		UDKRTSNavMeshObstacle.Unregister();
		UDKRTSNavMeshObstacle.Destroy();
	}
}

/**
 * Called when this actor is updated
 *
 * @param		DeltaTime			Time since the last update
 */
simulated function Tick(float DeltaTime)
{
	local Vector V;
	local UDKRTSPawn UDKRTSPawn;
	local Actor Actor;
	local UDKRTSTargetInterface UDKRTSTargetInterface;
	local float Percentage, TargetPriority, HighestTargetPriority;

	Super.Tick(DeltaTime);

	// If the structure isn't constructed
	if (!IsConstructed)
	{
		// If the construction timer is active, then simulate the construction process
		if (IsTimerActive(NameOf(CompleteConstruction)))
		{
			Percentage = GetTimerCount(NameOf(CompleteConstruction)) / GetTimerRate(NameOf(CompleteConstruction));

			// Scale the structure to look like it's growing
			if (WorldInfo.NetMode != NM_DedicatedServer)
			{
				V.X = 1.f;
				V.Y = 1.f;
				V.Z = FClamp(Percentage, 0.01f, 1.f);		
				SetDrawScale3D(V);
			}

			// Set the health
			Health = Lerp(1, MaxHealth, Percentage);
		}
		// Check if the building is waiting for a pawn to start construction
		else if (WaitingForPawnToStartConstruction)
		{
			// Scan for near by pawns
			ForEach VisibleCollidingActors(class'UDKRTSPawn', UDKRTSPawn, CollisionCylinder.CollisionRadius * 1.5f, Location, true,, true)
			{
				// Check that the pawn is on our team
				if (UDKRTSPawn != None && OwnerReplicationInfo != None && UDKRTSPawn.OwnerReplicationInfo != None && UDKRTSPawn.OwnerReplicationInfo.Team == OwnerReplicationInfo.Team)
				{
					// Start building the structure
					CreateNavMeshObstacle();
					SetHidden(false);
					WaitingForPawnToStartConstruction = false;
					SetDrawScale3D(Vect(1.f, 1.f, 0.01f));
					SetTimer(ConstructionTime, false, NameOf(CompleteConstruction));
					break;
				}
			}
		}
	}
	else
	{
		// Check if we're setting the rally point at an actor reference
		if (!SettingRallyPoint && !RallyPointMesh.HiddenGame && RallyPointActorReference != None && RallyPointMesh.Translation != RallyPointActorReference.Location)
		{
			RallyPointMesh.SetTranslation(RallyPointActorReference.Location);
			RallyPointLocation = RallyPointActorReference.Location;
		}

		// If the structure has a weapon and can fire, pick a suitable target and fire at it!
		if (Weapon != None && OwnerReplicationInfo != None && Weapon.CanFire())
		{
			// Reevaluate current target
			ForEach VisibleCollidingActors(class'Actor', Actor, Weapon.GetRange(), Location, true,, true, class'UDKRTSTargetInterface')
			{
				UDKRTSTargetInterface = UDKRTSTargetInterface(Actor);
				if (UDKRTSTargetInterface != None && UDKRTSTargetInterface.IsValidTarget(UDKRTSTeamInfo(OwnerReplicationInfo.Team)) && Weapon.InRange(UDKRTSTargetInterface.GetActor(), Location))
				{
					// Calculate the target priority and attack the pawn with the highest target priority
					TargetPriority = UDKRTSTargetInterface.GetAITargetingPriority() + ((UDKRTSTargetInterface.HasWeapon()) ? 100 : 0);
					if (CurrentTarget == None || TargetPriority > HighestTargetPriority)
					{
						HighestTargetPriority = TargetPriority;
						CurrentTarget = UDKRTSTargetInterface;
					}
				}
			}

			// If I have a current target the fire my weapon
			if (CurrentTarget != None)
			{
				Weapon.Fire(CurrentTarget.GetActor());
			}
		}
	}
}

/**
 * Called when the structure has finished construction
 *
 * @param		ViaReplication		Called via replication
 */
simulated function CompleteConstruction(optional bool ViaReplication)
{
	// Play construction complete feed back cue
	if (!WorldInfo.bStartup && !ViaReplication && OwnerReplicationInfo != None)
	{
		OwnerReplicationInfo.ReceiveWorldMessage(StructureName@"built.", class'HUD'.default.WhiteColor, Location, Portrait.Texture, Portrait.U, Portrait.V, Portrait.UL, Portrait.VL);
		class'UDKRTSCommanderVoiceOver'.static.PlayConstructionCompleteSoundCue(OwnerReplicationInfo);
	}
	
	// If running on the server...
	if (Role == Role_Authority)
	{
		IsConstructed = true;
		// Structure gives power to the player
		if (MinPowerProvidedPerSecond > 0 && MaxPowerProvidedPerSecond > 0)
		{
			SetTimer(1.f, true, NameOf(GivePowerTimer));
		}
	}

	// Unhide the actor
	SetHidden(false);
	// Structure is no longer waiting for the pawn to start construction
	WaitingForPawnToStartConstruction = false;
	// Set the health
	Health = MaxHealth;

	// If the structure has accumulated damage during it construction, handle that now
	if (AccumulatedDamage > 0)
	{
		TakeDamage(AccumulatedDamage, None, Location, Vect(0.f, 0.f, 0.f), class'DamageType');
		AccumulatedDamage = 0;
	}

	// Set the draw scale to normal
	SetDrawScale3D(Vect(1.f, 1.f, 1.f));

	// If the structure has a weapon archetype, create it now	
	if (WeaponArchetype != None)
	{
		Weapon = Spawn(WeaponArchetype.Class, Self,, Location, Rotation, WeaponArchetype);
		if (Weapon != None)
		{
			Weapon.UDKRTSWeaponOwnerInterface = UDKRTSWeaponOwnerInterface(Self);
			Weapon.Initialize();
		}
	}
}

/**
 * Returns true if this actor should render onto the minimap
 *
 * @return		Returns true if this actor should render onto the minimap
 */
simulated function bool ShouldRenderMinimapIcon()
{
	return (Health > 0);
}

/**
 * Returns the mini map icon
 *
 * @param		MinimapIcon			Returns the minimap texture to use
 * @param		MinimapU			Returns the U coordinate within the texture to use
 * @param		MinimapV			Returns the V coordinate within the texture to use
 * @param		MinimapUL			Returns the UL coordinate within the texture to use
 * @param		MinimapVL			Returns the VL coordinate within the texture to use
 * @param		MinimapColor		Returns the color of the minimap icon to use
 * @param		RenderBlackBorder	Returns whether the minimap icon should render with a black border or not
 */
simulated function GetMinimapIcon(out Texture2D MinimapIcon, out float MinimapU, out float MinimapV, out float MinimapUL, out float MinimapVL, out Color MinimapColor, out byte RenderBlackBorder)
{
	MinimapIcon = Texture2D'EngineResources.WhiteSquareTexture';
	MinimapU = 0.f;
	MinimapV = 0.f;
	MinimapUL = 4.f;
	MinimapVL = 4.f;
	MinimapColor = (OwnerReplicationInfo != None && OwnerReplicationInfo.Team != None) ? OwnerReplicationInfo.Team.TeamColor : class'HUD'.default.WhiteColor;
	RenderBlackBorder = 1;
}

/**
 * Sets the owner of this structure
 *
 * @param		NewOwnerReplicationInfo			New owner of this structure
 */
simulated function SetOwnerReplicationInfo(UDKRTSPlayerReplicationInfo NewOwnerReplicationInfo)
{
	local UDKRTSTeamInfo UDKRTSTeamInfo;

	// Abort if NewOwnerReplicationInfo is null
	if (NewOwnerReplicationInfo == None)
	{
		return;
	}

	// Possibly the structure is being stolen
	if (OwnerReplicationInfo != None && OwnerReplicationInfo != NewOwnerReplicationInfo)
	{
		UDKRTSTeamInfo = UDKRTSTeamInfo(OwnerReplicationInfo.Team);
		if (UDKRTSTeamInfo != None)
		{
			UDKRTSTeamInfo.RemoveStructure(Self);
		}
	}

	// Assign the new owner
	OwnerReplicationInfo = NewOwnerReplicationInfo;
	if (!UpdateTeamMaterials())
	{
		// Set a looping timer to check the UDKRTSTeamInfo for the new OwnerReplicationInfo
		SetTimer(0.1f, true, NameOf(CheckTeamInfoForOwnerReplicationInfo));
	}
}

/**
 * This timer loops until the owner replication info has a valid team info in order to perform the team update
 */
simulated function CheckTeamInfoForOwnerReplicationInfo()
{
	// If the update for the team materials was successful then stop the timer
	if (UpdateTeamMaterials())
	{
		ClearTimer(NameOf(CheckTeamInfoForOwnerReplicationInfo));
	}
}

/**
 * Updates the materials based on the team info
 */
simulated function bool UpdateTeamMaterials()
{
	local UDKRTSTeamInfo UDKRTSTeamInfo;

	if (OwnerReplicationInfo == None)
	{
		return false;
	}

	UDKRTSTeamInfo = UDKRTSTeamInfo(OwnerReplicationInfo.Team);
	if (UDKRTSTeamInfo != None)
	{
		// Add the structure to the team
		UDKRTSTeamInfo.AddStructure(Self);

		if (WorldInfo.NetMode != NM_DedicatedServer)
		{			
			// Change the mesh materials if required
			if (UDKRTSTeamInfo.TeamIndex >= 0 && UDKRTSTeamInfo.TeamIndex < TeamMaterials.Length && TeamMaterials[UDKRTSTeamInfo.TeamIndex] != None)
			{
				Mesh.SetMaterial(0, TeamMaterials[UDKRTSTeamInfo.TeamIndex]);
			}

			// Change the rally point mesh materials if required
			if (CanSetRallyPoint && UDKRTSTeamInfo.TeamIndex >= 0 && UDKRTSTeamInfo.TeamIndex < RallyPointMaterials.Length && RallyPointMaterials[UDKRTSTeamInfo.TeamIndex] != None)
			{
				RallyPointMesh.SetMaterial(1, RallyPointMaterials[UDKRTSTeamInfo.TeamIndex]);
			}
		}

		return true;
	}

	return false;
}

/**
 * Sets the rally point somewhere within the world. If the new rally point is invalid, it will inform the player
 */
simulated function Vector SetRallyPoint()
{
	local Vector FinalRallyPoint;
	
	// Early exit if the structure can't set the rally point
	if (!CanSetRallyPoint)
	{
		return Location;
	}

	// If it is inside the navigation mesh obstacle, then it is invalid and moved back to the structure's location
	if (SettingRallyPoint)
	{
		if (UDKRTSNavMeshObstacle != None && UDKRTSNavMeshObstacle.IsPointInside(RallyPointMesh.Translation))
		{
			if (RallyPointHasBeenSet)
			{
				class'UDKRTSCommanderVoiceOver'.static.PlayRallyPointReset(OwnerReplicationInfo);
			}
			else
			{
				class'UDKRTSCommanderVoiceOver'.static.PlayCannotSetRallyPointHere(OwnerReplicationInfo);
			}

			FinalRallyPoint = Location;
		}
		else
		{
			class'UDKRTSCommanderVoiceOver'.static.PlayRallyPointSet(OwnerReplicationInfo);
			FinalRallyPoint = RallyPointMesh.Translation;
		}
	}
	else
	{
		FinalRallyPoint = Location;
	}

	// Hide the rally point, and turn off the rally point setting mode	
	RallyPointMesh.SetHidden(true);
	SettingRallyPoint = false;	
	return FinalRallyPoint;
}

/**
 * Sets the rally point
 *
 * @param		NewRallyPointLocation		New rally point location
 */
simulated function SetRallyPointLocation(Vector NewRallyPointLocation)
{
	// Early exit if the structure cannot have a rally point
	if (!CanSetRallyPoint)
	{
		return;
	}

	// Clear the rally point actor
	RallyPointActorReference = None;
	// Set the rally point location
	RallyPointLocation = NewRallyPointLocation;
	RallyPointLocation.Z = Location.Z;
	// True if the rally point has been set
	RallyPointHasBeenSet = (RallyPointLocation != Location);
}

/**
 * Sets the rally point actor
 *
 * @param		NewRallyPointActor		New rally point actor
 */
simulated function SetRallyPointActor(Actor NewRallyPointActor)
{
	// Early exit if the structure cannot have a rally point
	if (!CanSetRallyPoint)
	{
		return;
	}

	// Clear the rally point
	RallyPointLocation = Location;
	// Set the rally point actor	
	RallyPointActorReference = NewRallyPointActor;
	// True if the rally point has been set
	RallyPointHasBeenSet = (RallyPointActorReference != None);
}

/**
 * Called when the structure is selected
 */
simulated function Selected()
{
}

/**
 * Called when the structure is asked to register its HUD actions onto the HUD
 *
 * @param		HUD			HUD to register its HUD actions too
 */
simulated function RegisterHUDActions(UDKRTSMobileHUD HUD)
{
	local int i;
	local SHUDAction SendHUDAction;

	// Check variable references
	if (HUD == None || HUD.AssociatedHUDActions.Find('AssociatedActor', Self) != INDEX_NONE || OwnerReplicationInfo == None)
	{
		return;
	}

	// If the portrait is valid, then register a center command
	if (Portrait.Texture != None)
	{
		SendHUDAction = Portrait;
		SendHUDAction.Reference = EHAR_Center;
		SendHUDAction.Index = -1;
		SendHUDAction.PostRender = true;

		HUD.RegisterHUDAction(Self, SendHUDAction);
	}

	// If the structure has not been constructed then abort
	if (!IsConstructed)
	{
		return;
	}

	// Register all pawn building HUD actions
	if (BuildablePawnArchetypes.Length > 0)
	{
		for (i = 0; i < BuildablePawnArchetypes.Length; ++i)
		{
			if (BuildablePawnArchetypes[i] != None)
			{
				SendHUDAction = BuildablePawnArchetypes[i].BuildHUDAction;
				SendHUDAction.Reference = EHAR_Build;
				SendHUDAction.Index = i;
				SendHUDAction.IsHUDActionActiveDelegate = IsHUDActionActive;

				HUD.RegisterHUDAction(Self, SendHUDAction);
			}
		}
	}

	// Register the structure upgrade HUD action
	if (UpgradableStructureArchetype != None)
	{
		SendHUDAction = UpgradableStructureArchetype.BuildHUDAction;
		SendHUDAction.Reference = EHAR_Upgrade;
		SendHUDAction.Index = -1;
		SendHUDAction.IsHUDActionActiveDelegate = IsHUDActionActive;

		HUD.RegisterHUDAction(Self, SendHUDAction);
	}

	// Register upgrade HUD actions
	if (UpgradeArchetypes.Length > 0)
	{
		for (i = 0; i < UpgradeArchetypes.Length; ++i)
		{
			if (UpgradeArchetypes[i] != None && class'UDKRTSUpgrade'.static.CanResearchUpgrade(UpgradeArchetypes[i], OwnerReplicationInfo, false))
			{
				if (QueuedUpgradeArchetypes.Length > 0 && QueuedUpgradeArchetypes.Find(UpgradeArchetypes[i]) != INDEX_NONE)
				{
					continue;
				}

				SendHUDAction = UpgradeArchetypes[i].UpgradeAction;
				SendHUDAction.Reference = EHAR_Research;
				SendHUDAction.Index = i;
				SendHUDAction.IsHUDActionActiveDelegate = IsHUDActionActive;

				HUD.RegisterHUDAction(Self, SendHUDAction);
			}
		}
	}

	// If the structure has been damaged, then register the repair HUD action
	if (RepairHUDAction.Texture != None && Health < MaxHealth)
	{
		SendHUDAction = RepairHUDAction;
		SendHUDAction.Reference = EHAR_Repair;
		SendHUDAction.Index = -1;

		HUD.RegisterHUDAction(Self, SendHUDAction);
	}

	// If the structure has any queued units, then register their progress/cancel HUD actions
	if (QueuedUnitArchetypes.Length > 0)
	{
		for (i = 0; i < QueuedUnitArchetypes.Length; ++i)
		{
			if (QueuedUnitArchetypes[i] != None)
			{
				SendHUDAction = QueuedUnitArchetypes[i].BuildHUDAction;
				SendHUDAction.Reference = EHAR_Building;
				SendHUDAction.Index = i;
				SendHUDAction.PostRender = true;

				HUD.RegisterHUDAction(Self, SendHUDAction);
			}
		}
	}

	// If the structure has any queued upgrades, then register their progress/cancel HUD actions
	if (QueuedUpgradeArchetypes.Length > 0)
	{
		for (i = 0; i < QueuedUpgradeArchetypes.Length; ++i)
		{
			if (QueuedUpgradeArchetypes[i] != None)
			{
				SendHUDAction = QueuedUpgradeArchetypes[i].UpgradeAction;
				SendHUDAction.Reference = EHAR_Researching;
				SendHUDAction.Index = i;
				SendHUDAction.PostRender = true;

				HUD.RegisterHUDAction(Self, SendHUDAction);
			}
		}
	}
}

/**
 * Called when the structure should handle a HUD action it has registered earlier
 * 
 * @param		Reference		Reference of the HUD action (usually used to identify what kind of HUD action this was)
 * @param		Index			Index of the HUD action (usually to reference inside an array)
 */
simulated function HandleHUDAction(EHUDActionReference Reference, int Index)
{
	local PlayerController PlayerController;
	local UDKRTSCamera UDKRTSCamera;
	local SHUDAction SendHUDAction;
	local UDKRTSMobileHUD UDKRTSMobileHUD;
	local int i;

	// Handle the centering HUD action command
	if (Reference ~= EHAR_Center)
	{
		// Center the camera
		if (OwnerReplicationInfo != None)
		{
			PlayerController = PlayerController(OwnerReplicationInfo.Owner);
			if (PlayerController != None)
			{
				UDKRTSCamera = UDKRTSCamera(PlayerController.PlayerCamera);

				if (UDKRTSCamera != None)
				{
					UDKRTSCamera.CurrentLocation = Location;
					UDKRTSCamera.AdjustLocation(Location);
				}
			}
		}
	}
	// All other HUD action commands only work when the structure has been built
	else if (IsConstructed)
	{
		// Handle the build HUD action command
		switch (Reference)
		{
		case EHAR_Build:
			// Check that the index is valid
			// Check that the player can build what he has requested
			if (Index >= 0 && Index < BuildablePawnArchetypes.Length && class'UDKRTSPawn'.static.CanBuildPawn(BuildablePawnArchetypes[Index], OwnerReplicationInfo, false))
			{
				// Play the building sound 
				class'UDKRTSCommanderVoiceOver'.static.PlayBuildingSoundCue(OwnerReplicationInfo);

				// Take resources away
				OwnerReplicationInfo.Resources -= BuildablePawnArchetypes[Index].ResourcesCost;
				OwnerReplicationInfo.Power -= BuildablePawnArchetypes[Index].PowerCost;

				// Update the player controller's HUD actions
				PlayerController = PlayerController(OwnerReplicationInfo.Owner);
				if (PlayerController != None)
				{
					UDKRTSMobileHUD = UDKRTSMobileHUD(PlayerController.MyHUD);
					if (UDKRTSMobileHUD != None)
					{
						SendHUDAction = BuildablePawnArchetypes[Index].BuildHUDAction;
						SendHUDAction.Reference = EHAR_Building;
						SendHUDAction.Index = QueuedUnitArchetypes.Length;
						SendHUDAction.PostRender = true;

						UDKRTSMobileHUD.RegisterHUDAction(Self, SendHUDAction);
					}
				}

				// Add the unit to the queue
				QueuedUnitArchetypes.AddItem(BuildablePawnArchetypes[Index]);

				// Start the building unit timer if it isn't activated
				if (!IsTimerActive(NameOf(BuildingUnit)))
				{
					SetTimer(BuildablePawnArchetypes[Index].BuildTime, false, NameOf(BuildingUnit));
				}
			}
			break;

		// Handle the building HUD action command
		case EHAR_Building:
			// Check that the index is valid
			if (Index >= 0 && Index < QueuedUnitArchetypes.Length)
			{
				// Play back the cancel command
				class'UDKRTSCommanderVoiceOver'.static.PlayCanceledSoundCue(OwnerReplicationInfo);

				// Give the resources back
				OwnerReplicationInfo.Resources += QueuedUnitArchetypes[Index].ResourcesCost;
				OwnerReplicationInfo.Power += QueuedUnitArchetypes[Index].PowerCost;

				// Remove the unit from the queue
				QueuedUnitArchetypes.Remove(Index, 1);

				// Update the researching queue
				if (QueuedUnitArchetypes.Length > 0)
				{
					if (Index == 0)
					{
						ClearTimer(NameOf(BuildingUnit));
						SetTimer(QueuedUnitArchetypes[0].BuildTime, false, NameOf(BuildingUnit));
					}
				}
				else
				{
					ClearTimer(NameOf(BuildingUnit));
				}

				// Update the player controller HUD Actions
				PlayerController = PlayerController(OwnerReplicationInfo.Owner);
				if (PlayerController != None)
				{
					UDKRTSMobileHUD = UDKRTSMobileHUD(PlayerController.MyHUD);
					if (UDKRTSMobileHUD != None)
					{
						// Refresh the research HUD actions
						UDKRTSMobileHUD.UnregisterHUDAction(Self);
						RegisterHUDActions(UDKRTSMobileHUD);
					}
				}
			}
			break;

		// Handle the upgrade action command
		case EHAR_Upgrade:
			// Cancel all units that are currently being built
			if (QueuedUnitArchetypes.Length > 0)
			{
				// Clear the building unit timer
				if (IsTimerActive(NameOf(BuildingUnit)))
				{
					ClearTimer(NameOf(BuildingUnit));
				}

				// Give back the resources
				for (i = 0; i < QueuedUnitArchetypes.Length; ++i)
				{
					OwnerReplicationInfo.Resources += QueuedUnitArchetypes[i].ResourcesCost;
					OwnerReplicationInfo.Power += QueuedUnitArchetypes[i].PowerCost;
				}

				QueuedUnitArchetypes.Remove(0, QueuedUnitArchetypes.Length);
			}

			// Cancel all upgrades that are currently being researched
			if (QueuedUpgradeArchetypes.Length > 0)
			{
				if (IsTimerActive(NameOf(ResearchingUpgrade)))
				{
					ClearTimer(NameOf(ResearchingUpgrade));
				}

				for (i = 0; i < QueuedUpgradeArchetypes.Length; ++i)
				{
					OwnerReplicationInfo.Resources += QueuedUpgradeArchetypes[i].ResourcesCost;
					OwnerReplicationInfo.Power += QueuedUpgradeArchetypes[i].PowerCost;
				}

				QueuedUpgradeArchetypes.Remove(0, QueuedUpgradeArchetypes.Length);
			}

			// Unregister the HUD action for this structure on the HUD
			PlayerController = PlayerController(OwnerReplicationInfo.Owner);
			if (PlayerController != None)
			{
				UDKRTSMobileHUD = UDKRTSMobileHUD(PlayerController.MyHUD);
				if (UDKRTSMobileHUD != None)
				{
					UDKRTSMobileHUD.UnregisterHUDAction(Self);
				}
			}

			class'UDKRTSCommanderVoiceOver'.static.PlayBuildingSoundCue(OwnerReplicationInfo);
			UpgradeStructure();
			break;

		// Handle the research HUD action command
		case EHAR_Research:
			// Check that the index is valid
			// Check that the player can rsearch this upgrade
			if (Index >= 0 && Index < UpgradeArchetypes.Length && class'UDKRTSUpgrade'.static.CanResearchUpgrade(UpgradeArchetypes[Index], OwnerReplicationInfo, false))
			{
				// Play back the research sound
				class'UDKRTSCommanderVoiceOver'.static.PlayResearchingSoundCue(OwnerReplicationInfo);

				// Handle the resource cost
				OwnerReplicationInfo.Resources -= UpgradeArchetypes[Index].ResourcesCost;
				OwnerReplicationInfo.Power -= UpgradeArchetypes[Index].PowerCost;

				// Add the upgrade to the queue
				QueuedUpgradeArchetypes.AddItem(UpgradeArchetypes[Index]);

				// Start the researching timer is it isn't active
				if (!IsTimerActive(NameOf(ResearchingUpgrade)))
				{
					SetTimer(UpgradeArchetypes[Index].BuildTime, false, NameOf(ResearchingUpgrade));
				}

				// Update the player's HUD action list
				PlayerController = PlayerController(OwnerReplicationInfo.Owner);
				if (PlayerController != None)
				{
					UDKRTSMobileHUD = UDKRTSMobileHUD(PlayerController.MyHUD);
					if (UDKRTSMobileHUD != None)
					{
						// Refresh the research HUD actions
						UDKRTSMobileHUD.UnregisterHUDAction(Self);
						RegisterHUDActions(UDKRTSMobileHUD);
					}
				}
			}
			break;

		// Handle the researching HUD action command
		case EHAR_Researching:
			// Check that the index is valid
			if (Index >= 0 && Index < QueuedUpgradeArchetypes.Length)
			{
				// Play the canceled sound cue
				class'UDKRTSCommanderVoiceOver'.static.PlayCanceledSoundCue(OwnerReplicationInfo);

				// Give back the resources spent
				OwnerReplicationInfo.Resources += QueuedUpgradeArchetypes[Index].ResourcesCost;
				OwnerReplicationInfo.Power += QueuedUpgradeArchetypes[Index].PowerCost;

				// Remove it from the upgrade queue
				QueuedUpgradeArchetypes.Remove(Index, 1);

				// Update the researching queue
				if (QueuedUpgradeArchetypes.Length > 0)
				{
					if (Index == 0)
					{
						ClearTimer(NameOf(ResearchingUpgrade));
						SetTimer(QueuedUpgradeArchetypes[0].BuildTime, false, NameOf(ResearchingUpgrade));
					}
				}
				else
				{
					ClearTimer(NameOf(ResearchingUpgrade));
				}

				// Update the player controller HUD Actions
				PlayerController = PlayerController(OwnerReplicationInfo.Owner);
				if (PlayerController != None)
				{
					UDKRTSMobileHUD = UDKRTSMobileHUD(PlayerController.MyHUD);
					if (UDKRTSMobileHUD != None)
					{
						// Refresh the research HUD actions
						UDKRTSMobileHUD.UnregisterHUDAction(Self);
						RegisterHUDActions(UDKRTSMobileHUD);
					}
				}
			}
			break;

		// Handle the repair HUD action command
		case EHAR_Repair:
			ToggleRepair();
			break;

		default:
			break;
		}
	}
}

/**
 * Called when the structure is upgrading itself
 */
simulated function UpgradeStructure()
{
	// Hide this structure
	SetHidden(true);
	SetCollision(false, false, false);
	// Request this structure
	RequestStructure(UpgradableStructureArchetype, Location - Vect(0.f, 0.f, 1.f) * CollisionCylinder.CollisionHeight);
}

/**
 * Toggles repairing of the structure
 */
simulated function ToggleRepair()
{
	// If the client called this function, then sync with the server
	if (Role < Role_Authority)
	{
		ServerToggleRepair();
	}

	BeginToggleRepair();
}

/**
 * Called when the structure is wanting to repair itself
 */
reliable server function ServerToggleRepair()
{
	BeginToggleRepair();
}

/**
 * Called when the structure is wanting to repair itself
 */
simulated function BeginToggleRepair()
{
	// If the timer is already active, then clear it
	if (IsTimerActive(NameOf(DoRepairs)))
	{
		ClearTimer(NameOf(DoRepairs));
	}
	else
	{
		// If the timer isn't active, then activate it
		class'UDKRTSCommanderVoiceOver'.static.PlayRepairingSoundCue(OwnerReplicationInfo);
		SetTimer(RepairTimeInterval, true, NameOf(DoRepairs));
	}
}

/**
 * Called periodically to perform repairs
 */
simulated function DoRepairs()
{
	local PlayerController PlayerController;
	local UDKRTSMobileHUD UDKRTSMobileHUD;

	// Check if the structure can repair itself
	if (OwnerReplicationInfo == None || !IsConstructed)
	{
		return;
	}

	// Handle resource cost of repairing itself
	if (OwnerReplicationInfo.Resources >= RepairResourcesCost)
	{
		OwnerReplicationInfo.Resources -= RepairResourcesCost;
	}

	// Handle power cost of repairing itself
	if (OwnerReplicationInfo.Power >= RepairPowerCost)
	{
		OwnerReplicationInfo.Power -= RepairPowerCost;
	}

	// Health the structure
	Health = Min(Health + RepairPerInterval, MaxHealth);

	// If the building was on fire, and the health is now above the threshold, deactivate the particle system
	if (Health > DamagedHealth)
	{
		DamagedBuildingParticleSystemComponent.DeactivateSystem();
	}

	// If the structure is at full health, clear the repair timer
	if (Health == MaxHealth)
	{
		// Check if the HUD action is visible
		PlayerController = PlayerController(OwnerReplicationInfo.Owner);
		if (PlayerController != None)
		{
			UDKRTSMobileHUD = UDKRTSMobileHUD(PlayerController.MyHUD);
			if (UDKRTSMobileHUD != None)
			{
				UDKRTSMobileHUD.UnregisterHUDActionByReference(Self, EHAR_Repair);
			}
		}

		ClearTimer(NameOf(DoRepairs));
	}
}

/**
 * Called when the structure has finished building a unit
 */
simulated function BuildingUnit()
{
	local Vector SpawnLocation;
	local Rotator R;
	local UDKRTSMobileHUD UDKRTSMobileHUD;
	local PlayerController PlayerController;
	local int i;
	local SHUDAction SendHUDAction;

	// Check if the structure is able to build a unit
	if (!IsConstructed || QueuedUnitArchetypes.Length <= 0)
	{
		return;
	}

	// Update the HUD action list
	PlayerController = PlayerController(OwnerReplicationInfo.Owner);
	if (PlayerController != None)
	{
		UDKRTSMobileHUD = UDKRTSMobileHUD(PlayerController.MyHUD);
		if (UDKRTSMobileHUD != None && UDKRTSMobileHUD.AssociatedHUDActions.Find('AssociatedActor', Self) != INDEX_NONE)
		{
			UDKRTSMobileHUD.UnregisterHUDActionByReference(Self, EHAR_Building);

			if (QueuedUnitArchetypes.Length > 0)
			{
				for (i = 0; i < QueuedUnitArchetypes.Length; ++i)
				{
					if (QueuedUnitArchetypes[i] != None)
					{
						SendHUDAction = QueuedUnitArchetypes[i].BuildHUDAction;
						SendHUDAction.Reference = EHAR_Building;
						SendHUDAction.Index = i;
						SendHUDAction.PostRender = true;

						UDKRTSMobileHUD.RegisterHUDAction(Self, SendHUDAction);
					}
				}
			}
		}
	}

	// Get the appropriate spawn location
	if (Role == Role_Authority)
	{
		if (RallyPointLocation == Location)
		{
			R.Yaw = Rand(65536);
			SpawnLocation = Location + Vector(R) * (QueuedUnitArchetypes[0].CylinderComponent.CollisionRadius + UnitSpawnRadius);
		}
		else
		{
			SpawnLocation = Location + Normal(RallyPointLocation - Location) * (QueuedUnitArchetypes[0].CylinderComponent.CollisionRadius + UnitSpawnRadius);
		}
	
		SpawnLocation.Z -= CollisionCylinder.CollisionHeight;
		// Request the pawn
		RequestPawn(QueuedUnitArchetypes[0], SpawnLocation);
	}

	// Remove the unit from the queue
	QueuedUnitArchetypes.Remove(0, 1);

	// If there are still units left in the queue then start the building unit timer again
	if (QueuedUnitArchetypes.Length > 0)
	{
		SetTimer(QueuedUnitArchetypes[0].BuildTime, false, NameOf(BuildingUnit));
	}
}

/**
 * Called when researching an upgrade has been completed
 */
simulated function ResearchingUpgrade()
{
	local PlayerController PlayerController;
	local UDKRTSMobileHUD UDKRTSMobileHUD;
	local int i;
	local SHUDAction SendHUDAction;

	// Check if the upgrade could have been researched
	if (!IsConstructed || QueuedUpgradeArchetypes.Length <= 0)
	{
		return;
	}

	// Request the upgrade
	RequestUpgrade(QueuedUpgradeArchetypes[0]);
	// Remove the upgrade from the queue
	QueuedUpgradeArchetypes.Remove(0, 1);

	// Update the HUD action command list
	PlayerController = PlayerController(OwnerReplicationInfo.Owner);
	if (PlayerController != None)
	{
		UDKRTSMobileHUD = UDKRTSMobileHUD(PlayerController.MyHUD);
		if (UDKRTSMobileHUD != None && UDKRTSMobileHUD.AssociatedHUDActions.Find('AssociatedActor', Self) != INDEX_NONE)
		{
			UDKRTSMobileHUD.UnregisterHUDActionByReference(Self, EHAR_Researching);

			if (QueuedUpgradeArchetypes.Length > 0)
			{
				for (i = 0; i < QueuedUpgradeArchetypes.Length; ++i)
				{
					if (QueuedUpgradeArchetypes[i] != None)
					{
						SendHUDAction = QueuedUpgradeArchetypes[i].UpgradeAction;
						SendHUDAction.Reference = EHAR_Researching;
						SendHUDAction.Index = i;
						SendHUDAction.PostRender = true;

						UDKRTSMobileHUD.RegisterHUDAction(Self, SendHUDAction);
					}
				}
			}
		}
	}

	// If there are still upgrades in the queue, then restart the researching upgrade timer
	if (QueuedUpgradeArchetypes.Length > 0)
	{
		SetTimer(QueuedUpgradeArchetypes[0].BuildTime, false, NameOf(ResearchingUpgrade));
	}
}

/**
 * Requests an upgrade
 *
 * @param		UpgradeArchetype		Archetype of the upgrade requested
 * @network		Client
 */
simulated function RequestUpgrade(UDKRTSUpgrade UpgradeArchetype)
{
	// If this is on the client, the sync it with the server
	if (Role < Role_Authority)
	{
		ServerRequestForUpgrade(UpgradeArchetype);
	}

	HandleRequestForUpgrade(UpgradeArchetype);
}

/**
 * Requests an upgrade
 *
 * @param		UpgradeArchetype		Archetype of the upgrade requested
 * @network		Server
 */
reliable server function ServerRequestForUpgrade(UDKRTSUpgrade UpgradeArchetype)
{
	if (Role == Role_Authority)
	{
		HandleRequestForUpgrade(UpgradeArchetype);
	}
}

/**
 * Requests an upgrade
 *
 * @param		UpgradeArchetype		Archetype of the upgrade requested
 * @network		Server and client
 */
simulated function HandleRequestForUpgrade(UDKRTSUpgrade UpgradeArchetype)
{
	local UDKRTSGameInfo UDKRTSGameInfo;

	if (OwnerReplicationInfo == None)
	{
		return;
	}

	// Ask the game info for the upgrade
	UDKRTSGameInfo = UDKRTSGameInfo(WorldInfo.Game);
	if (UDKRTSGameInfo != None)
	{
		UDKRTSGameInfo.RequestUpgrade(UpgradeArchetype, OwnerReplicationInfo, Location);
	}
}

/**
 * Requests a structure
 *
 * @param		StructureArchetype			Archetype of the structure requested
 * @param		SpawnLocation				World location to spawn the structure
 */
simulated function RequestStructure(UDKRTSStructure StructureArchetype, Vector SpawnLocation)
{
	// Check that we're on the client
	if (Role < Role_Authority)
	{
		ServerRequestForStructure(StructureArchetype, SpawnLocation);
	}

	HandleRequestForStructure(StructureArchetype, SpawnLocation);
}

/**
 * Requests a structure
 *
 * @param		StructureArchetype			Archetype of the structure requested
 * @param		SpawnLocation				World location to spawn the structure
 * @network		Server
 */
reliable server function ServerRequestForStructure(UDKRTSStructure StructureArchetype, Vector SpawnLocation)
{
	HandleRequestForStructure(StructureArchetype, SpawnLocation);
}

/**
 * Requests a structure
 *
 * @param		StructureArchetype			Archetype of the structure requested
 * @param		SpawnLocation				World location to spawn the structure
 * @network		Server
 */
simulated function HandleRequestForStructure(UDKRTSStructure StructureArchetype, Vector SpawnLocation)
{
	local UDKRTSGameInfo UDKRTSGameInfo;

	if (OwnerReplicationInfo == None)
	{
		return;
	}

	// Request the structure from the game info
	UDKRTSGameInfo = UDKRTSGameInfo(WorldInfo.Game);
	if (UDKRTSGameInfo != None)
	{
		UDKRTSGameInfo.RequestStructure(StructureArchetype, OwnerReplicationInfo, SpawnLocation);
	}
}

/**
 * Requests a pawn 
 *
 * @param		PawnArchetype		Archetype of the pawn requested
 * @param		SpawnLocation		World location to spawn the pawn
 * @network		Client
 */
simulated function RequestPawn(UDKRTSPawn PawnArchetype, Vector SpawnLocation)
{
	// Abort if the building has not been constructed
	if (!IsConstructed)
	{
		return;
	}

	// Sync with the server
	if (Role < Role_Authority)
	{
		ServerRequestForPawn(PawnArchetype, SpawnLocation, RallyPointHasBeenSet, RallyPointLocation, RallyPointActorReference);
	}

	HandleRequestForPawn(PawnArchetype, SpawnLocation, RallyPointHasBeenSet, RallyPointLocation, RallyPointActorReference);
}

/**
 * Requests a pawn
 *
 * @param		PawnArchetype					Archetype of the pawn requested
 * @param		SpawnLocation					World location to spawn the pawn
 * @param		InRallyPointValid				Is true if the rally point is valid
 * @param		InRallyPoint					World location of the rally point the pawn should run to
 * @param		InRallyPointActorReference		Actor the pawn should run to
 * @network		Server
 */
reliable server function ServerRequestForPawn(UDKRTSPawn PawnArchetype, Vector SpawnLocation, bool InRallyPointValid, Vector InRallyPoint, Actor InRallyPointActorReference)
{
	// Abort if the building has not been constructed
	if (!IsConstructed)
	{
		return;
	}

	// Only servers should call this
	if (Role == Role_Authority)
	{
		HandleRequestForPawn(PawnArchetype, SpawnLocation, InRallyPointValid, InRallyPoint, InRallyPointActorReference);
	}
}

/**
 * Requests a pawn
 *
 * @param		PawnArchetype					Archetype of the pawn requested
 * @param		SpawnLocation					World location to spawn the pawn
 * @param		InRallyPointValid				Is true if the rally point is valid
 * @param		InRallyPoint					World location of the rally point the pawn should run to
 * @param		InRallyPointActorReference		Actor the pawn should run to
 * @network		Server and client
 */
simulated function HandleRequestForPawn(UDKRTSPawn PawnArchetype, Vector SpawnLocation, bool InRallyPointValid, Vector InRallyPoint, Actor InRallyPointActorReference)
{
	local UDKRTSGameInfo UDKRTSGameInfo;

	// Abort if no owner replication info or the structure has not been constructed
	if (OwnerReplicationInfo == None || !IsConstructed)
	{
		return;
	}

	// Request a pawn from the game info
	UDKRTSGameInfo = UDKRTSGameInfo(WorldInfo.Game);
	if (UDKRTSGameInfo != None)
	{
		UDKRTSGameInfo.RequestPawn(PawnArchetype, OwnerReplicationInfo, SpawnLocation, InRallyPointValid, InRallyPoint, InRallyPointActorReference);
	}
}

/**
 * Post renders a HUD action
 *
 * @param		HUD				HUD to render to
 * @param		Reference		HUD action reference
 * @param		Index			HUD action index
 * @param		PosX			X position of the HUD action
 * @param		PosY			Y position of the HUD action
 * @param		SizeX			X size of the HUD action
 * @param		SizeY			Y size of the HUD action
 */
simulated function PostRenderHUDAction(HUD HUD, EHUDActionReference Reference, int Index, int PosX, int PosY, int SizeX, int SizeY)
{
	local float HealthPercentage, HealthBarWidth, HealthBarHeight;

	if (HUD == None || HUD.Canvas == None)
	{
		return;
	}

	// Handle post rendering for the center HUD action command
	if (Reference == EHAR_Center)
	{
		// Get the health bar percentage
		if (IsConstructed)
		{
			HealthPercentage = float(Health) / float(MaxHealth);
		}
		else
		{
			HealthPercentage = float(Health - AccumulatedDamage) / float(MaxHealth);
		}
	
		// Render the health bar border
		HealthBarWidth = SizeX - 2;
		HealthBarHeight = 8;
		HUD.Canvas.SetPos(PosX + 1, PosY + SizeY - HealthBarHeight - 1);
		HUD.Canvas.SetDrawColor(0, 0, 0, 191);
		HUD.Canvas.DrawBox(HealthBarWidth, HealthBarHeight);

		HealthBarWidth -= 4;
		HealthBarHeight -= 4;

		// Render the missing health
		HUD.Canvas.SetPos(PosX + 3, PosY + SizeY - HealthBarHeight - 3);
		HUD.Canvas.SetDrawColor(0, 0, 0, 127);
		HUD.Canvas.DrawRect(HealthBarWidth, HealthBarHeight);

		// Render the health bar
		HUD.Canvas.SetPos(PosX + 3, PosY + SizeY - HealthBarHeight - 3);
		HUD.Canvas.SetDrawColor(255 * (1.f - HealthPercentage), 255 * HealthPercentage, 0, 191);
		HUD.Canvas.DrawRect(HealthBarWidth * HealthPercentage, HealthBarHeight);

		// If the structure is not constructed and is being constructed, render the clock
		if (!IsConstructed && IsTimerActive(NameOf(CompleteConstruction)))
		{
			class'UDKRTSMobileHUD'.static.DrawClock(HUD, GetTimerCount(NameOf(CompleteConstruction)) / GetTimerRate(NameOf(CompleteConstruction)), GetRemainingTimeForTimer(NameOf(CompleteConstruction)), PosX, PosY, SizeX, SizeY);
		}
	}
	// Structure must be constructed before handling any other HUD actions
	else if (IsConstructed)
	{
		// Handle the building HUD action
		switch (Reference)
		{
		case EHAR_Building:
			if (Index == 0 && IsTimerActive(NameOf(BuildingUnit)))
			{
				// Draw the clock for the currently building unit
				class'UDKRTSMobileHUD'.static.DrawClock(HUD, GetTimerCount(NameOf(BuildingUnit)) / GetTimerRate(NameOf(BuildingUnit)), GetRemainingTimeForTimer(NameOf(BuildingUnit)), PosX, PosY, SizeX, SizeY);
			}
			else
			{
				// Draw a dark square over queued units
				HUD.Canvas.SetPos(PosX, PosY);
				HUD.Canvas.DrawColor = class'UDKRTSMobileHUD'.default.HUDProperties.ClockColor;
				HUD.Canvas.DrawRect(SizeX, SizeY);
			}
			break;

		case EHAR_Researching:
			if (Index == 0 && IsTimerActive(NameOf(ResearchingUpgrade)))
			{
				// Draw the clock for the currently researching upgrade
				class'UDKRTSMobileHUD'.static.DrawClock(HUD, GetTimerCount(NameOf(ResearchingUpgrade)) / GetTimerRate(NameOf(ResearchingUpgrade)), GetRemainingTimeForTimer(NameOf(ResearchingUpgrade)), PosX, PosY, SizeX, SizeY);
			}
			else
			{
				// Draw a dark square over queued upgrades
				HUD.Canvas.SetPos(PosX, PosY);
				HUD.Canvas.DrawColor = class'UDKRTSMobileHUD'.default.HUDProperties.ClockColor;
				HUD.Canvas.DrawRect(SizeX, SizeY);	
			}
			break;

		default:
			break;
		}
	}
}

/**
 * Returns true if the structure archetype can be built by the requesting player
 *
 * @param		TestStructureArchetype			Archetype of the structure to test
 * @param		TestPlayerReplicationInfo		Player that wants to build the structure
 * @param		SendMessage						True if you wish to inform the player why the building could not be built
 * @return										Returns true if the structure can be built
 */
simulated static function bool CanBuildStructure(UDKRTSStructure TestStructureArchetype, UDKRTSPlayerReplicationInfo TestPlayerReplicationInfo, bool SendMessage)
{
	local int i, Index, StructureCount;
	local UDKRTSTeamInfo UDKRTSTeamInfo;
	local array<UDKRTSStructure> TestRequiredStructures;
	local UDKRTSMobilePlayerController UDKRTSMobilePlayerController;
	local String Text;

	// Check parameters
	if (TestStructureArchetype == None || TestPlayerReplicationInfo == None)
	{
		return false;
	}

	// Check if the player has the resources to build this structure
	if (TestPlayerReplicationInfo.Resources < TestStructureArchetype.ResourcesCost)
	{
		if (SendMessage)
		{
			class'UDKRTSCommanderVoiceOver'.static.PlayInsufficientResourcesSoundCue(TestPlayerReplicationInfo);

			UDKRTSMobilePlayerController = UDKRTSMobilePlayerController(TestPlayerReplicationInfo.Owner);
			if (UDKRTSMobilePlayerController != None)
			{
				UDKRTSMobilePlayerController.ReceiveMessage("You require "$TestStructureArchetype.ResourcesCost - TestPlayerReplicationInfo.Resources$" more resources.");
			}
		}

		return false;
	}

	// Check if the player has the power to build this structure
	if (TestPlayerReplicationInfo.Power < TestStructureArchetype.PowerCost)
	{
		if (SendMessage)
		{
			class'UDKRTSCommanderVoiceOver'.static.PlayInsufficientPowerSoundCue(TestPlayerReplicationInfo);

			UDKRTSMobilePlayerController = UDKRTSMobilePlayerController(TestPlayerReplicationInfo.Owner);
			if (UDKRTSMobilePlayerController != None)
			{
				UDKRTSMobilePlayerController.ReceiveMessage("You require "$TestStructureArchetype.PowerCost - TestPlayerReplicationInfo.Power$" more power.");
			}
		}

		return false;
	}		

	// Check the player has a valid team
	UDKRTSTeamInfo = UDKRTSTeamInfo(TestPlayerReplicationInfo.Team);
	if (UDKRTSTeamInfo == None)
	{
		return false;
	}

	// Check if the player can build this structure due to maximum count
	if (TestStructureArchetype.MaximumCount != -1)
	{		
		StructureCount = 0;

		for (i = 0; i < UDKRTSTeamInfo.Structures.Length; ++i)
		{
			if (UDKRTSTeamInfo.Structures[i] != None && UDKRTSTeamInfo.Structures[i].ObjectArchetype == TestStructureArchetype)
			{
				StructureCount++;

				// Can't build as we have reached the limit of how many structures of this type the player can have
				if (StructureCount >= TestStructureArchetype.MaximumCount)
				{
					if (SendMessage)
					{
						class'UDKRTSCommanderVoiceOver'.static.PlayUnableToBuildMoreSoundCue(TestPlayerReplicationInfo);

						UDKRTSMobilePlayerController = UDKRTSMobilePlayerController(TestPlayerReplicationInfo.Owner);
						if (UDKRTSMobilePlayerController != None)
						{
							UDKRTSMobilePlayerController.ReceiveMessage("Maximum number of "$TestStructureArchetype.StructureName$" built.");
						}
					}

					return false;
				}
			}
		}
	}

	// Check if all of the required structures have been built
	if (TestStructureArchetype.RequiredStructures.Length > 0)
	{					
		TestRequiredStructures = TestStructureArchetype.RequiredStructures;

		for (i = 0; i < UDKRTSTeamInfo.Structures.Length; ++i)
		{
			if (UDKRTSTeamInfo.Structures[i] != None && UDKRTSTeamInfo.Structures[i].IsConstructed)
			{
				Index = TestRequiredStructures.Find(UDKRTSTeamInfo.Structures[i].ObjectArchetype);
				if (Index != INDEX_NONE)
				{
					TestRequiredStructures.Remove(Index, 1);
				}
			}
		}

		// All structures are required
		if (TestStructureArchetype.MinimumRequiredCount == -1)
		{
			if (TestRequiredStructures.Length > 0)
			{
				if (SendMessage)
				{
					Text = "";

					if (TestRequiredStructures.Length == 1)
					{
						Text = TestRequiredStructures[0].StructureName;
					}
					else
					{
						for (i = 0; i < TestRequiredStructures.Length; ++i)
						{
							if (i == TestRequiredStructures.Length - 1)
							{
								Text = Left(Text, Len(Text) - 2);
								Text $= " and "$TestRequiredStructures[i].StructureName;
							}
							else
							{
								Text $= TestRequiredStructures[i].StructureName$", ";
							}
						}
					}

					UDKRTSMobilePlayerController = UDKRTSMobilePlayerController(TestPlayerReplicationInfo.Owner);
					if (UDKRTSMobilePlayerController != None)
					{
						UDKRTSMobilePlayerController.ReceiveMessage("Require "$Text$" to be built.");
					}
				}

				return false;
			}
		}
		else
		{
			if (TestStructureArchetype.RequiredStructures.Length - TestRequiredStructures.Length < TestStructureArchetype.MinimumRequiredCount)
			{
				return false;
			}
		}
	}

	return true;
}

/**
 * Returns true if a HUD action is active or not
 *
 * @param		Reference			Identifier for what kind of HUD action
 * @param		Index				Array index that is usually used by the HUD action
 * @param		SendMessage			Send a message to the player if a HUD action is active or not?
 * @return							Returns true if a HUD action is active or not
 */
simulated function bool IsHUDActionActive(EHUDActionReference Reference, int Index, bool SendMessage)
{	
	// All HUD actions can only be checked if the structure has been constructed
	if (!IsConstructed)
	{
		return false;
	}
	
	switch (Reference)
	{
	// Handle the build HUD action 
	case EHAR_Build:
		if (Index >= 0 && Index < BuildablePawnArchetypes.Length && BuildablePawnArchetypes[Index] != None)
		{
			return class'UDKRTSPawn'.static.CanBuildPawn(BuildablePawnArchetypes[Index], OwnerReplicationInfo, SendMessage);
		}
		return true;

	// Handle the upgrade HUD action
	case EHAR_Upgrade:
		if (UpgradableStructureArchetype != None)
		{
			return class'UDKRTSStructure'.static.CanBuildStructure(UpgradableStructureArchetype, OwnerReplicationInfo, SendMessage);
		}
		return true;

	// Handle the research HUD action
	case EHAR_Research:
		if (Index >= 0 && Index < UpgradeArchetypes.Length)
		{
			return class'UDKRTSUpgrade'.static.CanResearchUpgrade(UpgradeArchetypes[Index], OwnerReplicationInfo, SendMessage);
		}
		return true;

	default:
		break;
	}

	return false;
}

/**
 * Handle any post rendering onto the HUD for this structure
 *
 * @param		HUD			HUD to render to
 */
simulated function PostRender(HUD HUD)
{
	local Vector ScreenLocation;
	local float Size, Alpha;

	// Check parameters
	if (HUD == None || HUD.PlayerOwner == None || HUD.PlayerOwner.PlayerReplicationInfo == None || OwnerReplicationInfo == None)
	{
		return;
	}

	// Check that the HUD belongs to the player that owns this structure
	if (HUD.PlayerOwner.PlayerReplicationInfo.Team != OwnerReplicationInfo.Team)
	{
		return;
	}

	// Check if the structure has been constructed or not
	if (!IsConstructed)
	{
		if (!WaitingForPawnToStartConstruction)
		{
			// Get the size of the icon
			Size = HUD.SizeX * 0.0625f;

			// Get the screen location
			ScreenLocation = HUD.Canvas.Project(Location);
			ScreenLocation.X -= Size * 0.5f;
			ScreenLocation.Y -= Size * 0.5f;

			// Draw the icon
			HUD.Canvas.SetDrawColor(255, 255, 255);
			HUD.Canvas.SetPos(ScreenLocation.X, ScreenLocation.Y);
			HUD.Canvas.DrawTile(Portrait.Texture, Size, Size, Portrait.U, Portrait.V, Portrait.UL, Portrait.VL);

			// Draw the clock wind down
			class'UDKRTSMobileHUD'.static.DrawClock(HUD, GetTimerCount(NameOf(CompleteConstruction)) / GetTimerRate(NameOf(CompleteConstruction)), GetRemainingTimeForTimer(NameOf(CompleteConstruction)), ScreenLocation.X, ScreenLocation.Y, Size, Size);
		}
	}
	else
	{
		// If we're building a unit, then show it on the HUD on top of the building
		if (IsTimerActive(NameOf(BuildingUnit)) && QueuedUnitArchetypes.Length > 0)
		{
			// Get the size of the icon
			Size = HUD.SizeX * 0.0625f;
			
			// Get the screen location
			ScreenLocation = HUD.Canvas.Project(Location);
			ScreenLocation.X -= Size * 0.5f;
			ScreenLocation.Y -= Size * 0.5f;

			// Draw the icon
			HUD.Canvas.SetDrawColor(255, 255, 255);
			HUD.Canvas.SetPos(ScreenLocation.X, ScreenLocation.Y);
			HUD.Canvas.DrawTile(QueuedUnitArchetypes[0].Portrait.Texture, Size, Size, QueuedUnitArchetypes[0].Portrait.U, QueuedUnitArchetypes[0].Portrait.V, QueuedUnitArchetypes[0].Portrait.UL, QueuedUnitArchetypes[0].Portrait.VL);

			// Draw the clock wind down
			class'UDKRTSMobileHUD'.static.DrawClock(HUD, GetTimerCount(NameOf(BuildingUnit)) / GetTimerRate(NameOf(BuildingUnit)), GetRemainingTimeForTimer(NameOf(BuildingUnit)), ScreenLocation.X, ScreenLocation.Y, Size, Size);
		}
		else if (IsTimerActive(NameOf(ResearchingUpgrade)) && QueuedUpgradeArchetypes.Length > 0)
		{
			// Get the size of the icon
			Size = HUD.SizeX * 0.0625f;
			
			// Get the screen location
			ScreenLocation = HUD.Canvas.Project(Location);
			ScreenLocation.X -= Size * 0.5f;
			ScreenLocation.Y -= Size * 0.5f;

			// Draw the icon
			HUD.Canvas.SetDrawColor(255, 255, 255);
			HUD.Canvas.SetPos(ScreenLocation.X, ScreenLocation.Y);
			HUD.Canvas.DrawTile(QueuedUpgradeArchetypes[0].UpgradeAction.Texture, Size, Size, QueuedUpgradeArchetypes[0].UpgradeAction.U, QueuedUpgradeArchetypes[0].UpgradeAction.V, QueuedUpgradeArchetypes[0].UpgradeAction.UL, QueuedUpgradeArchetypes[0].UpgradeAction.VL);

			// Draw the clock wind down
			class'UDKRTSMobileHUD'.static.DrawClock(HUD, GetTimerCount(NameOf(ResearchingUpgrade)) / GetTimerRate(NameOf(ResearchingUpgrade)), GetRemainingTimeForTimer(NameOf(ResearchingUpgrade)), ScreenLocation.X, ScreenLocation.Y, Size, Size);
		}

		// Render the repair icon
		if (RepairIcon != None && IsTimerActive(NameOf(DoRepairs)))
		{
			Alpha = GetTimerCount(NameOf(DoRepairs)) / GetTimerRate(NameOf(DoRepairs));
			if (Alpha >= 0.5f)
			{
				// Get the size of the icon
				Size = HUD.SizeX * 0.0625f;
			
				// Get the screen location
				ScreenLocation = HUD.Canvas.Project(Location);
				ScreenLocation.X -= Size * 0.5f;
				ScreenLocation.Y -= Size * 0.5f;

				// Draw the icon
				HUD.Canvas.SetDrawColor(255, 255, 255);
				HUD.Canvas.SetPos(ScreenLocation.X, ScreenLocation.Y);
				HUD.Canvas.DrawTile(RepairIcon, Size, Size, 0.f, 0.f, RepairIcon.SizeX, RepairIcon.SizeY);
			}
		}
	}
}

/**
 * Called when the structure takes damage 
 *
 * @param		DamageAmount			Amount of damage to deal
 * @param		EventInstigator			Controller that caused this event
 * @param		HitLocation				World location where the hit occured
 * @param		Momentum				Force to push this structure
 * @param		DamageType				Damage type class to use when dealing damage
 * @param		HitInfo					Information about the trace
 * @param		DamageCauser			Actual actor that caused this damage
 */
event TakeDamage(int DamageAmount, Controller EventInstigator, vector HitLocation, vector Momentum, class<DamageType> DamageType, optional TraceHitInfo HitInfo, optional Actor DamageCauser)
{
	local UDKRTSPlayerController UDKRTSPlayerController;
	local UDKRTSTeamAIController UDKRTSTeamAIController;

	// If the structure is in god mode, don't bother dealing damage
	if (InGodMode())
	{
		return;
	}

	Super.TakeDamage(DamageAmount, EventInstigator, HitLocation, Momentum, DamageType, HitInfo, DamageCauser);

	if (OwnerReplicationInfo != None)
	{
		// Notify to the player that the base is under attack
		UDKRTSPlayerController = UDKRTSPlayerController(OwnerReplicationInfo.Owner);
		if (UDKRTSPlayerController != None)
		{
			if (WorldInfo.TimeSeconds >= UDKRTSPlayerController.NextOurBaseIsUnderAttack)
			{
				class'UDKRTSCommanderVoiceOver'.static.PlayOurBaseIsUnderAttack(OwnerReplicationInfo);
				UDKRTSPlayerController.NextOurBaseIsUnderAttack = WorldInfo.TimeSeconds + 10.f;
			}
		}
		else
		{
			// If the owner is an AI, then notify the AI that its base is under attack
			UDKRTSTeamAIController = UDKRTSTeamAIController(OwnerReplicationInfo.Owner);
			if (UDKRTSTeamAIController != None)
			{
				UDKRTSTeamAIController.NotifyStructureDamage(EventInstigator, Self);
			}
		}
	}

	// If the structure is constructed...
	if (IsConstructed)
	{
		// Damage the structure
		Health -= DamageAmount;

		// If the health is below or equal to the damage threshold then activate the damage building particle system
		if (Health <= DamagedHealth)
		{
			DamagedBuildingParticleSystemComponent.ActivateSystem();
		}

		// If the health is below zero, then the structure is destroyed
		if (Health <= 0)
		{
			Died(EventInstigator);
		}
	}
	else
	{
		// If not constructed, then add to the accumulated damage
		AccumulatedDamage += DamageAmount;
		// If the health is below accumulated damage, then the structure is destroyed
		if (Health - AccumulatedDamage <= 0)
		{
			Died(EventInstigator);
		}
	}
}

/**
 * Called when this structure has died
 *
 * @param		EventInstigator			Controller who instigated this event
 */
simulated function Died(Controller EventInstigator)
{
	local UDKRTSAIController UDKRTSAIController;
	local UDKRTSPawn UDKRTSPawn;
	local UDKRTSTeamInfo UDKRTSTeamInfo;

	if (WorldInfo.NetMode != NM_DedicatedServer)
	{
		UDKRTSAIController = UDKRTSAIController(EventInstigator);
		if (UDKRTSAIController != None)
		{
			UDKRTSPawn = UDKRTSPawn(UDKRTSAIController.Pawn);
			if (UDKRTSPawn != None)
			{
				class'UDKRTSCommanderVoiceOver'.static.PlayEnemyStructureDestroyedSoundCue(UDKRTSPawn.OwnerReplicationInfo);
			}
		}

		PlaySound(DestroyedStructureSoundCue);

		if (WorldInfo != None && WorldInfo.MyEmitterPool != None)
		{
			WorldInfo.MyEmitterPool.SpawnEmitter(DestroyedStructureParticleTemplate, Location);
		}
	}

	if (OwnerReplicationInfo != None)
	{
		UDKRTSTeamInfo = UDKRTSTeamInfo(OwnerReplicationInfo.Team);
		if (UDKRTSTeamInfo != None)
		{
			if (WorldInfo.NetMode != NM_DedicatedServer && UDKRTSTeamInfo.Structures.Length > 1 && UDKRTSTeamInfo.Pawns.Length > 0)
			{
				class'UDKRTSCommanderVoiceOver'.static.PlayStructureLostSoundCue(OwnerReplicationInfo);
			}

			UDKRTSTeamInfo.RemoveStructure(Self);
		}			
	}

	Destroy();
}

// ====================================
// UDKRTSTargetInterface implementation
// ====================================
/**
 * Returns true if this actor is a valid target
 *
 * @param		TeamInfo		Team info if you wish to check team relevance
 * @return						Returns true if this actor is a valid target
 */
simulated function bool IsValidTarget(optional UDKRTSTeamInfo TeamInfo)
{
	// Not targetable if health is zero
	if (Health <= 0)
	{
		return false;
	}

	// Not targetable if we're about to be deleted
	if (bDeleteMe)
	{
		return false;
	}

	// Not targetable if we're hidden
	if (bHidden)
	{
		return false;
	}

	// Not targetable if we're on the same team
	if (TeamInfo != None && OwnerReplicationInfo != None && TeamInfo == OwnerReplicationInfo.Team)
	{
		return false;
	}
	
	return true;
}

/**
 * Returns the best attacking location in world coordinates
 *
 * @param		Attacker					Actor that is doing the attacking
 * @param		AttackerWeaponRange			Range of the attacker's weapon
 */
simulated function Vector BestAttackingLocation(Actor Attacker, float AttackerWeaponRange)
{
	local Rotator AimDirection, AttackerWeaponFireRotation;
	local Vector AimLocation, AdjustedLocation, HitLocation, HitNormal, AttackerWeaponFireLocation;
	local Actor HitActor;
	local int i, BestAimLocationIndex;
	local array<Vector> ValidAimLocations;
	local float DistanceSq, ClosestDistanceSq;
	local bool AddAimLocation;
	local UDKRTSWeaponOwnerInterface UDKRTSWeaponOwnerInterface;

	UDKRTSWeaponOwnerInterface = UDKRTSWeaponOwnerInterface(Attacker);
	if (UDKRTSWeaponOwnerInterface == None)
	{
		return Vect(0.f, 0.f, 0.f);
	}

	// Get the weapon's location and rotation
	UDKRTSWeaponOwnerInterface.GetWeaponFireLocationAndRotation(AttackerWeaponFireLocation, AttackerWeaponFireRotation);

	// Set the base aim direction
	AdjustedLocation = Location;
	AdjustedLocation.Z = AttackerWeaponFireLocation.Z;

	AimDirection = Rotator(AttackerWeaponFireLocation - AdjustedLocation);

	// Perform a 11.25 degree search for useable attacking positions
	for (i = 0; i < 32; ++i)
	{		
		AimDirection.Yaw += 2048;
		AimLocation = AdjustedLocation + (Vector(AimDirection) * AttackerWeaponRange);

		// If this aim location is valid, then return it
		if (FastTrace(AdjustedLocation, AimLocation))
		{
			AddAimLocation = true;
			ForEach TraceActors(class'Actor', HitActor, HitLocation, HitNormal, AdjustedLocation, AimLocation, Vect(8.f, 8.f, 8.f))
			{
				if (HitActor != None)
				{
					AddAimLocation = false;
					break;
				}
			}

			if (AddAimLocation)
			{
				ValidAimLocations.AddItem(AimLocation);
			}
		}
	}

	if (ValidAimLocations.Length <= 0)
	{
		return Vect(0.f, 0.f, 0.f);
	}

	// Find the closest aim location to me
	ClosestDistanceSq = -1.f;
	for (i = 0; i < ValidAimLocations.Length; ++i)
	{
		DistanceSq = VSizeSq(ValidAimLocations[i] - Attacker.Location);
		if (ClosestDistanceSq == -1.f || DistanceSq < ClosestDistanceSq)
		{
			BestAimLocationIndex = i;
			ClosestDistanceSq = DistanceSq;
		}
	}

	// Return the best aim location
	if (BestAimLocationIndex >= 0 && BestAimLocationIndex < ValidAimLocations.Length)
	{
		return ValidAimLocations[BestAimLocationIndex];
	}

	return Vect(0.f, 0.f, 0.f);
}

/**
 * Returns true if the structure has a weapon or not
 *
 * @return			Returns true if the structure has a weapon
 */
simulated function bool HasWeapon()
{
	return Weapon != None;
}

/**
 * Returns the AI targeting priority for this structure
 *
 * @return			Returns the AI targeting priority for this structure
 */
simulated function float GetAITargetingPriority()
{
	return AITargetingPriority;
}

/**
 * Returns the actor
 *
 * @return			Returns the actor
 */
simulated function Actor GetActor()
{
	return Self;
}

// =========================================
// UDKRTSWeaponOwnerInterface implementation
// =========================================
/**
 * Returns the weapon firing location and rotation in world coordinates
 *
 * @param		FireLocation		Firing Location for the weapon
 * @param		FireRotation		Firing rotation for the weapon
 */
simulated function GetWeaponFireLocationAndRotation(out Vector FireLocation, out Rotator FireRotation)
{
	FireLocation = Location;
	FireRotation = Rotation;
}

/**
 * Returns the team info of this structure
 *
 * @return		Returns the team info for this structure
 */
simulated function UDKRTSTeamInfo GetUDKRTSTeamInfo()
{
	if (OwnerReplicationInfo != None)
	{
		return UDKRTSTeamInfo(OwnerReplicationInfo.Team);
	}

	return None;
}

defaultproperties
{
 	Begin Object Class=DynamicLightEnvironmentComponent Name=MyLightEnvironment
		bSynthesizeSHLight=true
		bUseBooleanEnvironmentShadowing=false
		ModShadowFadeoutTime=0.75f
		bIsCharacterLightEnvironment=true
		bAllowDynamicShadowsOnTranslucency=true
 	End Object
 	Components.Add(MyLightEnvironment)
	LightEnvironment=MyLightEnvironment

	Begin Object Class=SkeletalMeshComponent Name=MySkeletalMeshComponent
		LightEnvironment=MyLightEnvironment
	End Object
	Mesh=MySkeletalMeshComponent
	Components.Add(MySkeletalMeshComponent)

	Begin Object Class=CylinderComponent Name=MyCylinderComponent
		BlockActors=true
		BlockZeroExtent=true
		BlockNonZeroExtent=true
	End Object
	Components.Add(MyCylinderComponent)
	CollisionCylinder=MyCylinderComponent
	CollisionComponent=MyCylinderComponent

	Begin Object Class=StaticMeshComponent Name=MyStaticMeshComponent
		LightEnvironment=MyLightEnvironment
		HiddenEditor=true
		HiddenGame=true
		AbsoluteTranslation=true
		AbsoluteRotation=true
	End Object
	RallyPointMesh=MyStaticMeshComponent
	Components.Add(MyStaticMeshComponent)

	Begin Object Class=ParticleSystemComponent Name=MyDamagedBuildingParticleSystemComponent
		SecondsBeforeInactive=1
		bAutoActivate=false
	End Object
	DamagedBuildingParticleSystemComponent=MyDamagedBuildingParticleSystemComponent
	Components.Add(MyDamagedBuildingParticleSystemComponent)

	MaxHealth=1000
	MinimumRequiredCount=-1
	MaximumCount=-1
	ResourceStorageRadius=128.f
	BoundingBoxColor=(R=255,G=0,B=0,A=255)
	RallyPointLineColor=(R=255,G=191,B=0,A=255)
	RallyPointHasBeenSet=false
	CollisionType=COLLIDE_BlockAll
	BlockRigidBody=true
	bBlockActors=true
	RepairTimeInterval=0.5f
	RepairPerInterval=10
	RepairResourcesCost=5
	RepairPowerCost=0
	RemoteRole=ROLE_SimulatedProxy
	NetPriority=2.f
	bAlwaysRelevant=true
	bReplicateMovement=false
	bOnlyDirtyReplication=true
}