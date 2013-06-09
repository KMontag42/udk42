//=============================================================================
// UDKRTSPawn: Pawn which represents all units in the game.
//
// This class represents all units in the game. To create new units, you would
// archetype this normally. If your unit requires new game play logic, it would
// be best to extend this class and then archetype that.
// 
// Copyright 1998-2011 Epic Games, Inc. All Rights Reserved.
//=============================================================================
class UDKRTSPawn extends Pawn
	DependsOn(UDKRTSUtility)
	Implements(UDKRTSHUDActionInterface, UDKRTSMinimapInterface, UDKRTSGroupableInterface, UDKRTSHUDInterface, UDKRTSTargetInterface, UDKRTSWeaponOwnerInterface)
	Placeable;

enum ECommandMode
{
	// Perform an automated move. This will auto gather resource, auto attack enemies or move to the desired location
	ECM_AutomatedMove<DisplayName=Automated Move>,
	// Perform a build structure move. This will command the pawn to build a structure at the desired location
	ECM_BuildStructure<DisplayName=Build Structure>,
	// Perform a skill move. This will command the pawn to perform a skill at the desired location
	ECM_UsingSkill<DisplayName=Using Skill>
};

// How much resources this unit costs to build
var(Cost) const int ResourcesCost;
// How much power this unit costs to build
var(Cost) const int PowerCost;
// How much population this unit costs
var(Cost) const int PopulationCost;

// Can this unit move?
var(Ability) const bool CanMove;
// Move HUD action
var(Ability) const SHUDAction MoveHUDAction;
// How quickly this unit can harvest resources. Set to zero if it can't harvest
var(Ability) const float HarvestResourceInterval;
// What kind of structures this unit can build
var(Ability) const archetype array<UDKRTSStructure> BuildableStructureArchetypes;
// Skills that this unit has
var(Ability) const instanced editinline array<UDKRTSSkill> Skills;

// What structures must exist for this unit to be available
var(Dependencies) const archetype array<UDKRTSStructure> RequiredStructures;

// Socket to use when attaching weapons
var(Weapon) const Name WeaponSocketName;
// Weapon archetype to give to the pawn
var(Weapon) const archetype UDKRTSWeapon WeaponArchetype;

// Sound cue to play when the pawn is touched
var(Voice) const SoundCue SelectedSoundCue;
// Sound cue to play when the pawn confirms an order
var(Voice) const SoundCue ConfirmSoundCue;
// Sound cue to play when the pawn is engaging the enemy
var(Voice) const SoundCue EngagingEnemySoundCue;

// Particle effect to spawn when confirming a move command
var(Interface) const ParticleSystem ConfirmMoveCommandEffect;
// Particle effect to spawn when confirming an attack command
var(Interface) const ParticleSystem ConfirmAttackCommandEffect;

// Portrait
var(Pawn) const SHUDAction Portrait;
// Build HUD action
var(Pawn) const SHUDAction BuildHUDAction;
// Light environment for the pawn
var(Pawn) const editconst LightEnvironmentComponent LightEnvironment;
// Command skeletal mesh
var(Pawn) ProtectedWrite editconst SkeletalMeshComponent CommandMesh;
// Time to build this unit
var(Pawn) const float BuildTime;
// Turning speed
var(Pawn) const float TurnSpeed;
// Human friendly name
var(Pawn) /*localized*/ string FriendlyName;
// Used by the AI to determine What military contribution this units adds to the team
var(Pawn) const float MilitaryRating;
// AI priority for targeting reasons
var(Pawn) float AITargetingPriority;
// Should this pawn show the idle icon?
var(Pawn) const bool ShowIdleIcon;
// Must face moving direction before moving
var(Pawn) const bool MustFaceDirectionBeforeMoving;
// Must face moving direction before moving precision, closer to 1.f means more precision
var(Pawn) const float MustFaceDirectionBeforeMovingPrecision;
// Spawn particle effect
var(Pawn) const ParticleSystem SpawnParticleEffect;
// Spawn sound effect
var(Pawn) const SoundCue SpawnSoundCue;

// Debug bounding box color
var(Debug) const Color BoundingBoxColor;

// Shadow plane if required
var(Mobile) const StaticMeshComponent ShadowPlaneComponent;

// All the different team materials
var(Rendering) const array<MaterialInterface> TeamMaterials;

// Current ground speed
var float CurrentGroundSpeed;

// Defensive bonus
var float DefensiveBonus;

// Weapon instance
var RepNotify UDKRTSWeapon UDKRTSWeapon;
// Player replication info that owns this pawn
var RepNotify ProtectedWrite UDKRTSPlayerReplicationInfo OwnerReplicationInfo;
// Current command mode
var ProtectedWrite ECommandMode CommandMode;
// Current command index
var ProtectedWrite int CommandIndex;

// Mobile only
// Screen bounding box for the pawn
var Box ScreenBoundingBox;
// Pending command location, in screen coordinates
var Vector2D PendingScreenCommandLocation;
// Does this controller have a pending command it needs to take care of?
var bool HasPendingCommand;

// Replication block
replication
{
	if ((bNetDirty || bNetInitial) && Role == Role_Authority)
		OwnerReplicationInfo, UDKRTSWeapon;
}

/**
 * Called when the pawn is instanced in the world
 */
simulated function PostBeginPlay()
{
	Super.PostBeginPlay();	

	CurrentGroundSpeed = default.GroundSpeed;
	LockDesiredRotation(true);
}

/**
 * Called when a variable with the property flag "RepNotify" is replicated
 *
 * @param		VarName			Name of the variable which was replicated
 */
simulated event ReplicatedEvent(name VarName)
{
	if (VarName == 'OwnerReplicationInfo')
	{
		// Set the owner replication info
		SetOwnerReplicationInfo(OwnerReplicationInfo);
	}
	else if (VarName == 'UDKRTSWeapon')
	{
		// Initialize the weapon and attach to the skeletal mesh component
		UDKRTSWeapon.SetOwner(Self);
		UDKRTSWeapon.UDKRTSWeaponOwnerInterface = UDKRTSWeaponOwnerInterface(Self);
		UDKRTSWeapon.Initialize();
		UDKRTSWeapon.AttachToSkeletalMeshComponent(Mesh, LightEnvironment, WeaponSocketName);
	}

	Super.ReplicatedEvent(VarName);
}

/**
 * Returns true if the pawn is considered to be in god mode
 *
 * @return			Returns true if the pawn is considered to be in god mode.
 */
function bool InGodMode()
{
	local PlayerController PlayerController;

	// Defer check to the player controller
	if (OwnerReplicationInfo != None)
	{
		PlayerController = PlayerController(OwnerReplicationInfo.Owner);
		if (PlayerController != None)
		{
			return PlayerController.bGodMode;
		}
	}

	return Super.InGodMode();
}

/**
 * Stubbed function to stop things from pushing the pawn
 *
 * @param		Momentum			Vector force to push the pawn
 * @param		HitLocation			World location to apply the force
 * @param		DamageType			Damage type which caused this push
 * @param		HitInfo				Trace information
 */
function HandleMomentum(Vector Momentum, Vector HitLocation, class<DamageType> DamageType, optional TraceHitInfo HitInfo);

/**
 * Apply upgrades to this pawn
 */
simulated function ApplyUpgrades()
{
	local UDKRTSTeamInfo UDKRTSTeamInfo;
	local int i;

	if (OwnerReplicationInfo != None)
	{
		CurrentGroundSpeed = default.GroundSpeed;
		UDKRTSTeamInfo = UDKRTSTeamInfo(OwnerReplicationInfo.Team);
		if (UDKRTSTeamInfo != None && UDKRTSTeamInfo.Upgrades.Length > 0)
		{
			for (i = 0; i < UDKRTSTeamInfo.Upgrades.Length; ++i)
			{
				// Handle any upgrades which modify ground speed
				if (UDKRTSTeamInfo.Upgrades[i] != None && UDKRTSTeamInfo.Upgrades[i].UnitSpeedBoost > 0.f)
				{
					CurrentGroundSpeed += (CurrentGroundSpeed * UDKRTSTeamInfo.Upgrades[i].UnitSpeedBoost);
				}
			}
		}

		GroundSpeed = CurrentGroundSpeed;
	}
}

/**
 * Called to allow adjustments to the damage applied to this pawn
 *
 * @param		InDamage			Damage to modify
 * @param		Momentum			Momentum to apply
 * @param		InstigatedBy		Controller that instigated this event
 * @param		HitLocation			Where in the world the hit occured
 * @param		DamageType			Damage type used
 * @param		HitInfo				Trace hit information
 * @param		DamageCauser		Actor that caused this damage
 */
function AdjustDamage(out int InDamage, out vector Momentum, Controller InstigatedBy, vector HitLocation, class<DamageType> DamageType, TraceHitInfo HitInfo, Actor DamageCauser)
{
	local UDKRTSTeamInfo UDKRTSTeamInfo;
	local int i;

	Super.AdjustDamage(InDamage, Momentum, InstigatedBy, HitLocation, DamageType, HitInfo, DamageCauser);

	// Check if the unit has any defensive bonuses
	if (DefensiveBonus > 0.f)
	{
		InDamage = FClamp(1.f - DefensiveBonus, 0.f, 1.f) * InDamage;
	}

	// Check if the owning team has any unit armor bonuses
	if (OwnerReplicationInfo != None)
	{
		UDKRTSTeamInfo = UDKRTSTeamInfo(OwnerReplicationInfo.Team);
		if (UDKRTSTeamInfo != None)
		{
			for (i = 0; i < UDKRTSTeamInfo.Upgrades.Length; ++i)
			{
				if (UDKRTSTeamInfo.Upgrades[i] != None && UDKRTSTeamInfo.Upgrades[i].UnitArmourBoost > 0.f)
				{
					InDamage = InDamage * (1.f - UDKRTSTeamInfo.Upgrades[i].UnitArmourBoost);
				}
			}
		}
	}
}

/**
 * Called when this pawn takes damage
 *
 * @param		DamageAmount		Damage to modify
 * @param		EventInstigator		Controller that caused this event
 * @param		HitLocation			Where in the world the hit occured
 * @param		Momentum			Momentum to apply
 * @param		DamageType			Damage type used
 * @param		HitInfo				Trace hit information
 * @param		DamageCauser		Actor that caused this damage
 */
function TakeDamage(int DamageAmount, Controller EventInstigator, vector HitLocation, vector Momentum, class<DamageType> DamageType, optional TraceHitInfo HitInfo, optional Actor DamageCauser)
{
	local UDKRTSAIController UDKRTSAIController;

	Super.TakeDamage(DamageAmount, EventInstigator, HitLocation, Momentum, DamageType, HitInfo, DamageCauser);

	// Notify the ai controller that its pawn was damaged
	UDKRTSAIController = UDKRTSAIController(Controller);
	if (UDKRTSAIController != None)
	{
		UDKRTSAIController.NotifyTakeDamage(DamageAmount, EventInstigator, HitLocation, Momentum, DamageType, HitInfo, DamageCauser);
	}
}

/**
 * Sets the command mesh translation. This is used on mobile platforms.
 *
 * @param		NewTranslation			New world location to place the command mesh
 * @param		NewHide					If true, hide the command mesh
 */
simulated function SetCommandMeshTranslation(Vector NewTranslation, bool NewHide)
{
	local Actor Actor;
	local bool CanBuildStructure;
	local MaterialInterface Material;
	local int i;

	if (CommandMesh == None)
	{
		return;
	}
	
	// Move the command mesh to the current touch location
	CommandMesh.SetTranslation(NewTranslation);

	// Get the material that is designated by the command mode
	switch (CommandMode)
	{
	case ECM_AutomatedMove:
		Material = Material'UDKRTSGameContent.Materials.WhiteMaterial';
		break;

	case ECM_BuildStructure:
		// Check if any buildings are within radius, if so, turn it red to signify that we cannot build here
		if (CommandIndex >= 0 && CommandIndex < BuildableStructureArchetypes.Length)
		{
			CanBuildStructure = true;

			ForEach VisibleCollidingActors(class'Actor', Actor, BuildableStructureArchetypes[CommandIndex].PlacementClearanceRadius, NewTranslation, true,, true)
			{
				CanBuildStructure = false;
				break;
			}
 
			Material = (CanBuildStructure) ? BuildableStructureArchetypes[CommandIndex].CanBuildMaterial : BuildableStructureArchetypes[CommandIndex].CantBuildMaterial;
		}
		break;

	default:
		break;
	}
	
	// Set the material that is designated by the command mode
	if (Material != None && CommandMesh.GetNumElements() > 0)
	{
		for (i = 0; i < CommandMesh.GetNumElements(); ++i)
		{
			if (CommandMesh.GetMaterial(i) != Material)
			{
				CommandMesh.SetMaterial(i, Material);
			}
		}
	}

	// If the command mesh is hidden, unhide it
	if (CommandMesh.HiddenGame != NewHide)
	{
		CommandMesh.SetHidden(NewHide);
	}
}

/**
 * Sets the owning player replication info
 *
 * @param		NewOwnerReplicationInfo			New owner
 */
simulated function SetOwnerReplicationInfo(UDKRTSPlayerReplicationInfo NewOwnerReplicationInfo)
{
	local UDKRTSTeamInfo UDKRTSTeamInfo;

	if (NewOwnerReplicationInfo == None)
	{
		return;
	}

	// Unit is possibly being converted to another team
	if (OwnerReplicationInfo != None && OwnerReplicationInfo != NewOwnerReplicationInfo)
	{
		UDKRTSTeamInfo = UDKRTSTeamInfo(OwnerReplicationInfo.Team);
		if (UDKRTSTeamInfo != None)
		{
			UDKRTSTeamInfo.RemovePawn(Self);
		}
	}

	// Assign the team
	OwnerReplicationInfo = NewOwnerReplicationInfo;
	if (!UpdateTeamMaterials())
	{
		SetTimer(0.1f, true, NameOf(CheckTeamInfoForOwnerReplicationInfo));
	}

	// Give the pawn its default weapon, if it doesn't have one right now
	if (Role == Role_Authority && WeaponArchetype != None && UDKRTSWeapon == None)
	{
		UDKRTSWeapon = Spawn(WeaponArchetype.Class, Self,, Location, Rotation, WeaponArchetype);		
		if (UDKRTSWeapon != None)
		{
			UDKRTSWeapon.SetOwner(Self);
			UDKRTSWeapon.UDKRTSWeaponOwnerInterface = UDKRTSWeaponOwnerInterface(Self);
			UDKRTSWeapon.Initialize();
			UDKRTSWeapon.AttachToSkeletalMeshComponent(Mesh, LightEnvironment, WeaponSocketName);
		}
	}

	// Send the client a world message that the pawn was trained
	OwnerReplicationInfo.ReceiveWorldMessage(FriendlyName@"trained.", class'HUD'.default.WhiteColor, Location, Portrait.Texture, Portrait.U, Portrait.V, Portrait.UL, Portrait.VL);
	class'UDKRTSCommanderVoiceOver'.static.PlayUnitReadySoundCue(OwnerReplicationInfo);
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
	local ParticleSystemComponent ParticleSystemComponent;
	local Vector TeamLinearColor;

	if (OwnerReplicationInfo == None)
	{
		return false;
	}

	UDKRTSTeamInfo = UDKRTSTeamInfo(OwnerReplicationInfo.Team);
	if (UDKRTSTeamInfo != None)
	{
		UDKRTSTeamInfo.AddPawn(Self);

		if (WorldInfo.NetMode != NM_DedicatedServer)
		{
			// Set the team material
			if (UDKRTSTeamInfo.TeamIndex >= 0 && UDKRTSTeamInfo.TeamIndex < TeamMaterials.Length && TeamMaterials[UDKRTSTeamInfo.TeamIndex] != None)
			{
				Mesh.SetMaterial(0, TeamMaterials[UDKRTSTeamInfo.TeamIndex]);
			}

			if (EffectIsRelevant(Location, false))
			{
				// Play the spawn effect
				if (SpawnParticleEffect != None && WorldInfo != None && WorldInfo.MyEmitterPool != None)
				{
					ParticleSystemComponent = WorldInfo.MyEmitterPool.SpawnEmitter(SpawnParticleEffect, Location);
					if (ParticleSystemComponent != None)
					{
						TeamLinearColor.X = float(class'UDKRTSTeamInfo'.default.DefaultPalette[UDKRTSTeamInfo.TeamIndex].R) / 255.f;
						TeamLinearColor.Y = float(class'UDKRTSTeamInfo'.default.DefaultPalette[UDKRTSTeamInfo.TeamIndex].G) / 255.f;
						TeamLinearColor.Z = float(class'UDKRTSTeamInfo'.default.DefaultPalette[UDKRTSTeamInfo.TeamIndex].B) / 255.f;
						ParticleSystemComponent.SetVectorParameter('Color', TeamLinearColor);
					}
				}

				// Play the spawn sound
				if (SpawnSoundCue != None)
				{
					PlaySound(SpawnSoundCue);
				}
			}
		}

		return true;
	}

	return false;
}

/**
 * Handles the HUD action
 *
 * @param			Reference			HUD action command reference
 * @param			Index				HUD action command index
 */
simulated function HandleHUDAction(EHUDActionReference Reference, int Index)
{
	local PlayerController PlayerController;
	local UDKRTSCamera UDKRTSCamera;

	// Don't handle any hud actions if we're dead
	if (Health <= 0)
	{
		return;
	}

	CommandIndex = Index;

	switch (Reference)
	{
	// Center the camera
	case EHAR_Center:		
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
		break;

	// Move command
	case EHAR_Move:		
		CommandMesh.SetSkeletalMesh(default.CommandMesh.SkeletalMesh);
		CommandMesh.SetMaterial(0, Material'UDKRTSGameContent.Materials.WhiteMaterial');
		CommandMode = ECM_AutomatedMove;
		break;

	// Build commands
	case EHAR_Build:
		if (Index >= 0 && Index < BuildableStructureArchetypes.Length)
		{
			CommandMesh.SetSkeletalMesh(BuildableStructureArchetypes[Index].PreviewSkeletalMesh);
			CommandMode = ECM_BuildStructure;
		}
		break;

	// Skill commands
	case EHAR_Skill:		
		ActivateSkill(Index, CommandMesh.Translation);
		break;

	// Unknown reference
	default:
		break;
	}
}

/**
 * Activates a skill
 *
 * @param		Index				Which skill to activate
 * @param		TargetLocation		Skill target location
 * @network							Client and server
 */
simulated function ActivateSkill(byte Index, Vector TargetLocation)
{
	// If we're dead, don't activate skills
	if (Health <= 0)
	{
		return;
	}

	// Replicate to the server that we are activating a skill
	if (Role < Role_Authority)
	{
		ServerActivateSkill(Index, TargetLocation);
	}

	BeginActivateSkill(Index, TargetLocation);
}

/**
 * Activates a skill on the server
 *
 * @param		Index				Which skill to activate
 * @param		TargetLocation		Skill target location
 * @network							Server
 */
reliable server function ServerActivateSkill(byte Index, Vector TargetLocation)
{
	if (Role == Role_Authority)
	{
		BeginActivateSkill(Index, TargetLocation);
	}
}

/**
 * Activates a skill
 *
 * @param		Index				Which skill to activate
 * @param		TargetLocation		Skill target location
 * @network							Client and server
 */
simulated function BeginActivateSkill(byte Index, Vector TargetLocation)
{
	// If we're dead, don't activate skills
	if (Health <= 0)
	{
		return;
	}

	if (Index >= 0 && Index < Skills.Length && Skills[Index] != None)
	{			
		Skills[Index].Activate(Self, TargetLocation);
	}
}

/**
 * Returns true if the pawn needs to turn to the target location based on the precision value
 *
 * @param		TargetLocation			World target location
 * @param		Precision				Precision that the pawn needs to face that target location (usually from 0.f to 1.f)
 * @return								Returns false if the pawn is looking at the target location
 */
function bool NeedsToTurnWithPrecision(Vector TargetLocation, float Precision)
{
	local Vector LookDir, AimDir;

	LookDir = Vector(Rotation);
	LookDir.Z = 0.f;
	LookDir = Normal(LookDir);

	AimDir = TargetLocation - Location;
	AimDir.Z = 0.f;
	AimDir = Normal(AimDir);

	return ((LookDir Dot AimDir) < Precision);
}

/**
 * Returns true if the pawn needs to turn in order to shoot at that target location
 *
 * @param		TargetLocation			World target location
 * @return								Returns false if the pawn is aiming at the target location
 */
function bool NeedsToTurnForFiring(Vector TargetLocation)
{
	return NeedsToTurnWithPrecision(TargetLocation, (UDKRTSWeapon != None) ? UDKRTSWeapon.AimPrecision : 0.95f);
}

/**
 * Called when the pawn is selected
 */
simulated function Selected()
{
	CommandMode = ECM_AutomatedMove;
	CommandMesh.SetSkeletalMesh(default.CommandMesh.SkeletalMesh);

	if (SelectedSoundCue != None)
	{
		PlaySound(SelectedSoundCue);
	}
}

/**
 * Called when the pawn is deselected
 */
simulated function Deselected();

/**
 * Called when the pawn confirms a command
 */
simulated function ConfirmCommand()
{
	if (ConfirmSoundCue != None)
	{
		PlaySound(ConfirmSoundCue);
	}
}

/**
 * Called when the pawn engages an enemy
 */
simulated function EngageEnemy()
{
	if (EngagingEnemySoundCue != None)
	{
		PlaySound(EngagingEnemySoundCue);
	}
}

/**
 * Called when the pawn is dying and should play a sound
 */
function PlayDyingSound();

/**
 * Called when the pawn is asked to register its HUD actions onto the HUD
 *
 * @param		HUD			HUD to register its HUD actions too
 */
simulated function RegisterHUDActions(UDKRTSMobileHUD HUD)
{
	local int i;
	local SHUDAction SendHUDAction;

	if (HUD == None || OwnerReplicationInfo == None || HUD.AssociatedHUDActions.Find('AssociatedActor', Self) != INDEX_NONE || Health <= 0)
	{
		return;
	}

	// Register the camera center HUD action
	if (Portrait.Texture != None)
	{
		SendHUDAction = Portrait;
		SendHUDAction.Reference = EHAR_Center;
		SendHUDAction.Index = -1;
		SendHUDAction.PostRender = true;

		HUD.RegisterHUDAction(Self, SendHUDAction);
	}

	// Register the move HUD action if the unit can move
	if (CanMove)
	{
		SendHUDAction = MoveHUDAction;
		SendHUDAction.Reference = EHAR_Move;
		SendHUDAction.Index = -1;

		HUD.RegisterHUDAction(Self, SendHUDAction);
	}

	// Add all of the build structure HUD actions, if this unit can build any buildings
	if (BuildableStructureArchetypes.Length > 0)
	{
		for (i = 0; i < BuildableStructureArchetypes.Length; ++i)
		{
			SendHUDAction = BuildableStructureArchetypes[i].BuildHUDAction;
			SendHUDAction.Reference = EHAR_Build;
			SendHUDAction.Index = i;
			SendHUDAction.IsHUDActionActiveDelegate = IsHUDActionActive;

			HUD.RegisterHUDAction(Self, SendHUDAction);
		}
	}

	// Add all of the skill HUD actions, if this unit has any skills
	if (Skills.Length > 0)
	{
		for (i = 0; i < Skills.Length; ++i)
		{
			if (Skills[i] != None)
			{
				SendHUDAction = Skills[i].Icon;
				SendHUDAction.Reference = EHAR_Skill;
				SendHUDAction.Index = i;

				HUD.RegisterHUDAction(Self, SendHUDAction);
			}
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
	local float HealthPercentage;
	local float HealthBarWidth, HealthBarHeight;

	if (HUD == None || HUD.Canvas == None || Health <= 0)
	{
		return;
	}

	if (Reference == EHAR_Center)
	{
		// Get the health bar percentage
		HealthPercentage = float(Health) / float(HealthMax);
	
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
	}
}

/**
 * Returns true if the player can build a pawn
 *
 * @param		TestPawnArchetype				Pawn to test
 * @param		TestPlayerReplicationInfo		Player to test against
 * @param		SendMessage						True if you want to send a message back to the player if he couldn't build this pawn
 * @return										Returns true if the player can build this pawn
 */
simulated static function bool CanBuildPawn(const UDKRTSPawn TestPawnArchetype, UDKRTSPlayerReplicationInfo TestPlayerReplicationInfo, bool SendMessage)
{
	local int i, Index;
	local array<UDKRTSStructure> TestRequiredStructures;
	local UDKRTSTeamInfo UDKRTSTeamInfo;
	local UDKRTSMobilePlayerController UDKRTSMobilePlayerController;
	local String Text;
	
	// Check object references
	if (TestPawnArchetype == None || TestPlayerReplicationInfo == None)
	{
		return false;
	}	

	// Check team info
	UDKRTSTeamInfo = UDKRTSTeamInfo(TestPlayerReplicationInfo.Team);
	if (UDKRTSTeamInfo == None)
	{
		return false;
	}

	// Check to see if the player has not reached the population cap
	if (UDKRTSTeamInfo.Population + TestPawnArchetype.default.PopulationCost > TestPlayerReplicationInfo.PopulationCap)
	{
		return false;
	}

	// Check to see if the player has enough money to build this unit
	if (TestPlayerReplicationInfo.Resources < TestPawnArchetype.ResourcesCost)
	{
		if (SendMessage)
		{
			class'UDKRTSCommanderVoiceOver'.static.PlayInsufficientResourcesSoundCue(TestPlayerReplicationInfo);

			UDKRTSMobilePlayerController = UDKRTSMobilePlayerController(TestPlayerReplicationInfo.Owner);
			if (UDKRTSMobilePlayerController != None)
			{
				UDKRTSMobilePlayerController.ReceiveMessage("You require "$TestPawnArchetype.ResourcesCost - TestPlayerReplicationInfo.Resources$" more resources.");
			}
		}

		return false;
	}

	// Check to see if the player has enough power to build this unit
	if (TestPlayerReplicationInfo.Power < TestPawnArchetype.PowerCost)
	{
		if (SendMessage)
		{
			class'UDKRTSCommanderVoiceOver'.static.PlayInsufficientPowerSoundCue(TestPlayerReplicationInfo);

			UDKRTSMobilePlayerController = UDKRTSMobilePlayerController(TestPlayerReplicationInfo.Owner);
			if (UDKRTSMobilePlayerController != None)
			{
				UDKRTSMobilePlayerController.ReceiveMessage("You require "$TestPawnArchetype.PowerCost - TestPlayerReplicationInfo.Power$" more power.");
			}
		}

		return false;
	}

	// Check to see if the player has built all of the required structures required to build this pawn
	if (TestPawnArchetype.RequiredStructures.Length > 0)
	{
		TestRequiredStructures = TestPawnArchetype.RequiredStructures;

		// Iterate through the team's structure list and remove existing ones from the required list
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

		// Not all of the requirements have been met
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

	// Passed all tests
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
simulated function bool IsHUDActionActive(EHUDActionReference Reference, int Index, bool PlaySound)
{
	if (Reference == EHAR_Build && Index >= 0 && Index < BuildableStructureArchetypes.Length && BuildableStructureArchetypes[Index] != None)
	{
		return class'UDKRTSStructure'.static.CanBuildStructure(BuildableStructureArchetypes[Index], OwnerReplicationInfo, PlaySound);
	}

	return true;
}

/**
 * Called when the pawn dies.
 *
 * @param		DamageType			Damage type class used to perform the damage
 * @param		HitLoc				Where in the world damage was applied
 */
simulated function PlayDying(class<DamageType> DamageType, vector HitLoc)
{
	Super.PlayDying(DamageType, HitLoc);

	// Start the ragdoll
    Mesh.SetRBChannel(RBCC_GameplayPhysics);
    Mesh.SetRBCollidesWithChannel(RBCC_Default, true);
    Mesh.SetRBCollidesWithChannel(RBCC_GameplayPhysics, true);
    Mesh.SetRBCollidesWithChannel(RBCC_BlockingVolume, true);
	Mesh.SetRBCollidesWithChannel(RBCC_EffectPhysics, true);
    Mesh.ForceSkelUpdate();
    Mesh.SetTickGroup(TG_PostAsyncWork);
    CollisionComponent = Mesh;
    CylinderComponent.SetActorCollision(false, false);
    Mesh.SetActorCollision(true, false);
    Mesh.SetTraceBlocking(true, true);
    SetPhysics(PHYS_RigidBody);
    Mesh.PhysicsWeight = 1.f;

    if (Mesh.bNotUpdatingKinematicDueToDistance)
    {
		Mesh.UpdateRBBonesFromSpaceBases(true, true);
    }

    Mesh.PhysicsAssetInstance.SetAllBodiesFixed(false);
    Mesh.bUpdateKinematicBonesFromAnimation = false;
    Mesh.SetRBLinearVelocity(Velocity, false);
    Mesh.WakeRigidBody();

	// Hide the shadow plane
	if (ShadowPlaneComponent != None)
	{
		ShadowPlaneComponent.SetHidden(true);
	}
}

/**
 * Called when the pawn has died
 *
 * @param			Killer				Controller that killed this pawn
 * @param			DamageType			Damage type class which killed this pawn
 * @param			HitLocation			World location where the killing blow occured
 */
simulated function bool Died(Controller Killer, class<DamageType> DamageType, vector HitLocation)
{
	local UDKRTSMobilePlayerController UDKRTSMobilePlayerController;
	local UDKRTSTeamInfo UDKRTSTeamInfo;
	local UDKRTSAIController UDKRTSAIController;
	local UDKRTSPawn UDKRTSPawn;

	if (Super.Died(Killer, DamageType, HitLocation))
	{
		if (OwnerReplicationInfo != None)
		{
			// Inform the player that he has lost a unit
			class'UDKRTSCommanderVoiceOver'.static.PlayUnitLostSoundCue(OwnerReplicationInfo);

			// Notify the mobile player controller that a unit was destroyed
			UDKRTSMobilePlayerController = UDKRTSMobilePlayerController(OwnerReplicationInfo.Owner);
			if (UDKRTSMobilePlayerController != None)
			{
				UDKRTSMobilePlayerController.NotifyActorDestroyed(Self);
			}
			else
			{
				// Notify the killer's owner that he killed a unit
				UDKRTSAIController = UDKRTSAIController(Killer);
				if (UDKRTSAIController != None)
				{
					UDKRTSPawn = UDKRTSPawn(UDKRTSAIController.Pawn);
					if (UDKRTSPawn != None)
					{
						class'UDKRTSCommanderVoiceOver'.static.PlayEnemyUnitDestroyedSoundCue(UDKRTSPawn.OwnerReplicationInfo);
					}
				}
			}

			// Remove the pawn from the team
			UDKRTSTeamInfo = UDKRTSTeamInfo(OwnerReplicationInfo.Team);
			if (UDKRTSTeamInfo != None)
			{
				UDKRTSTeamInfo.RemovePawn(Self);
			}
		}

		// Auto destroy in a second
		LifeSpan = 8.f;
		return true;
  }

  return false;
}

/**
 * Called from the HUD to perform any post rendering onto the HUD
 *
 * @param		HUD			HUD to perform post rendering onto
 */
simulated function PostRender(HUD HUD)
{
	local int i;

	// Early exit if no health
	if (Health <= 0)
	{
		return;
	}

	// Forward post rendering to all skills
	if (Skills.Length > 0)
	{
		for (i = 0; i < Skills.Length; ++i)
		{
			if (Skills[i] != None && Skills[i].RequiresPostRender(Self))
			{
				Skills[i].PostRender(HUD, Self);
			}
		}
	}
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
	// If we're dead, then no weapon
	if (Health <= 0)
	{
		return false;
	}

	return (UDKRTSWeapon != None);
}

/**
 * Returns the AI targeting priority for this structure
 *
 * @return			Returns the AI targeting priority for this structure
 */
simulated function float GetAITargetingPriority()
{
	// If we're dead, then no targeting priority
	if (Health <= 0)
	{
		return 0.f;
	}

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
	if (UDKRTSWeapon != None && UDKRTSWeapon.AttachmentMesh != None && UDKRTSWeapon.AttachmentMesh.SkeletalMesh != None)
	{
		UDKRTSWeapon.AttachmentMesh.GetSocketWorldLocationAndRotation(UDKRTSWeapon.FireSocketName, FireLocation, FireRotation);
	}
	else
	{
		FireLocation = Location;
		FireRotation = Rotation;
	}
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
	Components.Remove(Sprite)
	
	Begin Object Class=StaticMeshComponent Name=MyStaticMeshComponent
	End Object
	Components.Add(MyStaticMeshComponent)
	ShadowPlaneComponent=MyStaticMeshComponent;

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
		CollideActors=true
		BlockRigidBody=true
		bHasPhysicsAssetInstance=true
		bUpdateKinematicBonesFromAnimation=true
		MinDistFactorForKinematicUpdate=0.f
		LightEnvironment=MyLightEnvironment
 	End Object
 	Mesh=MySkeletalMeshComponent
 	Components.Add(MySkeletalMeshComponent)

	Begin Object Class=SkeletalMeshComponent Name=MyOtherSkeletalMeshComponent
		HiddenGame=true
		AbsoluteTranslation=true
		AbsoluteRotation=true
	End Object
	CommandMesh=MyOtherSkeletalMeshComponent
	Components.Add(MyOtherSkeletalMeshComponent);

	PopulationCost=1
	MustFaceDirectionBeforeMovingPrecision=0.99f
	RotationRate=(Yaw=0,Pitch=0,Roll=0)
	BoundingBoxColor=(R=255,G=0,B=255,A=255)
	ControllerClass=class'UDKRTSAIController'
	bCanCrouch=true
	Health=100
	HealthMax=100
	Physics=PHYS_Falling
	WalkingPhysics=PHYS_Walking
	AlwaysRelevantDistanceSquared=1048576.f
	bReplicateHealthToAll=true
}