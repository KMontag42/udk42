//=============================================================================
// UDKRTSCommanderVoiceOver: Object class which plays back "commander" voice
// sounds to the player.
//
// This class is normally archetyped to play back command voice feedback to the
// player.
// 
// Copyright 1998-2011 Epic Games, Inc. All Rights Reserved.
//=============================================================================
class UDKRTSCommanderVoiceOver extends Object
	HideCategories(Object);

// Sound to play when the player builds something
var(VoiceOver) const SoundCue Building;
// Sound to play when the player cancels something
var(VoiceOver) const SoundCue Canceled;
// Sound to play when the player cannot deploy something
var(VoiceOver) const SoundCue CannotDeployHere;
// Sound to play when the rally point is set
var(VoiceOver) const SoundCue CannotSetRallyPointHere;
// Sound to play when the construction is complete
var(VoiceOver) const SoundCue ConstructionComplete;
// Sound to play when an enemy is approaching the player's base
var(VoiceOver) const SoundCue EnemyApproaching;
// Sound to play when the player destroyed an enemy structure
var(VoiceOver) const SoundCue EnemyStructureDestroyed;
// Sound to play when the player destroys an enemy unit
var(VoiceOver) const SoundCue EnemyUnitDestroyed;
// Sound to play when the player has insufficient resources
var(VoiceOver) const SoundCue InsufficientResources;
// Sound to play when the player has insufficient power
var(VoiceOver) const SoundCue InsufficientPower;
// Sound to play when the player's super weapon is charging
var(VoiceOver) const SoundCue SuperWeaponCharging;
// Sound to play when the player's super weapon is ready
var(VoiceOver) const SoundCue SuperWeaponReady;
// Sound to play when the player's mission has been accomplished
var(VoiceOver) const SoundCue MissionAccomplished;
// Sound to play when the player's mission has failed
var(VoiceOver) const SoundCue MissionFailed;
// Sound to play when the player has new construction options
var(VoiceOver) const SoundCue NewConstructionOptions;
// Sound to play when something is not ready
var(VoiceOver) const SoundCue NotReady;
// Sound to play when something is put on hold
var(VoiceOver) const SoundCue OnHold;
// Sound to play when the player's base is under attack
var(VoiceOver) const SoundCue OurBaseIsUnderAttack;
// Sound to play when the player sets a rally point
var(VoiceOver) const SoundCue RallyPointSet;
// Sound to play when the player resets a rally point
var(VoiceOver) const SoundCue RallyPointReset;
// Sound to play when reinforcements have arrived
var(VoiceOver) const SoundCue ReinforcementsHaveArrived;
// Sound to play when someting is being repairs
var(VoiceOver) const SoundCue Repairing;
// Sound to play when research is complete
var(VoiceOver) const SoundCue ResearchComplete;
// Sound to play when the player is researching something
var(VoiceOver) const SoundCue Researching;
// Sound to play when the player should select a target
var(VoiceOver) const SoundCue SelectTarget;
// Sound to play when the player loses a structure
var(VoiceOver) const SoundCue StructureLost;
// Sound to play when the player was unable to build more of something
var(VoiceOver) const SoundCue UnableToBuildMore;
// Sound to play when the player loses a unit
var(VoiceOver) const SoundCue UnitLost;
// Sound to play when a unit is ready for the player to control
var(VoiceOver) const SoundCue UnitReady;
// Constant reference to the archetype
var const UDKRTSCommanderVoiceOver CommanderVoiceOverArchetype;

/**
 * Plays the building sound
 *
 * @param		PlayerReplicationInfo		Who to play the sound for
 */
final static function PlayBuildingSoundCue(PlayerReplicationInfo PlayerReplicationInfo)
{
	PlaySoundCue(PlayerReplicationInfo, default.CommanderVoiceOverArchetype.Building);
}

/**
 * Plays the canceled sound
 *
 * @param		PlayerReplicationInfo		Who to play the sound for
 */
final static function PlayCanceledSoundCue(PlayerReplicationInfo PlayerReplicationInfo)
{
	PlaySoundCue(PlayerReplicationInfo, default.CommanderVoiceOverArchetype.Canceled);
}

/**
 * Plays the cannot deploy here sound
 *
 * @param		PlayerReplicationInfo		Who to play the sound for
 */
final static function PlayCannotDeployHereSoundCue(PlayerReplicationInfo PlayerReplicationInfo)
{
	PlaySoundCue(PlayerReplicationInfo, default.CommanderVoiceOverArchetype.CannotDeployHere);
}

/**
 * Plays the cannot set rally point sound
 *
 * @param		PlayerReplicationInfo		Who to play the sound for
 */
final static function PlayCannotSetRallyPointHere(PlayerReplicationInfo PlayerReplicationInfo)
{
	PlaySoundCue(PlayerReplicationInfo, default.CommanderVoiceOverArchetype.CannotSetRallyPointHere);
}

/**
 * Plays the construction complete sound
 *
 * @param		PlayerReplicationInfo		Who to play the sound for
 */
final static function PlayConstructionCompleteSoundCue(PlayerReplicationInfo PlayerReplicationInfo)
{
	PlaySoundCue(PlayerReplicationInfo, default.CommanderVoiceOverArchetype.ConstructionComplete);
}

/**
 * Plays the enemy approaching sound
 *
 * @param		PlayerReplicationInfo		Who to play the sound for
 */
final static function PlayEnemyApproachingSoundCue(PlayerReplicationInfo PlayerReplicationInfo)
{
	PlaySoundCue(PlayerReplicationInfo, default.CommanderVoiceOverArchetype.EnemyApproaching);
}

/**
 * Plays the enemy structure destroyed sound
 *
 * @param		PlayerReplicationInfo		Who to play the sound for
 */
final static function PlayEnemyStructureDestroyedSoundCue(PlayerReplicationInfo PlayerReplicationInfo)
{
	PlaySoundCue(PlayerReplicationInfo, default.CommanderVoiceOverArchetype.EnemyStructureDestroyed);
}

/**
 * Plays the enemy unit destroyed sound
 *
 * @param		PlayerReplicationInfo		Who to play the sound for
 */
final static function PlayEnemyUnitDestroyedSoundCue(PlayerReplicationInfo PlayerReplicationInfo)
{
	PlaySoundCue(PlayerReplicationInfo, default.CommanderVoiceOverArchetype.EnemyUnitDestroyed);
}

/**
 * Plays the insufficient resources sound
 *
 * @param		PlayerReplicationInfo		Who to play the sound for
 */
final static function PlayInsufficientResourcesSoundCue(PlayerReplicationInfo PlayerReplicationInfo)
{
	PlaySoundCue(PlayerReplicationInfo, default.CommanderVoiceOverArchetype.InsufficientResources);
}

/**
 * Plays the insufficient power sound
 *
 * @param		PlayerReplicationInfo		Who to play the sound for
 */
final static function PlayInsufficientPowerSoundCue(PlayerReplicationInfo PlayerReplicationInfo)
{
	PlaySoundCue(PlayerReplicationInfo, default.CommanderVoiceOverArchetype.InsufficientPower);
}

/**
 * Plays the super weapon charging sound
 *
 * @param		PlayerReplicationInfo		Who to play the sound for
 */
final static function PlaySuperWeaponChargingSoundCue(PlayerReplicationInfo PlayerReplicationInfo)
{
	PlaySoundCue(PlayerReplicationInfo, default.CommanderVoiceOverArchetype.SuperWeaponCharging);
}

/**
 * Plays the super weapon ready sound
 *
 * @param		PlayerReplicationInfo		Who to play the sound for
 */
final static function PlaySuperWeaponReadySoundCue(PlayerReplicationInfo PlayerReplicationInfo)
{
	PlaySoundCue(PlayerReplicationInfo, default.CommanderVoiceOverArchetype.SuperWeaponReady);
}

/**
 * Plays the mission accomplished sound
 *
 * @param		PlayerReplicationInfo		Who to play the sound for
 */
final static function PlayMissionAccomplishedSoundCue(PlayerReplicationInfo PlayerReplicationInfo)
{
	PlaySoundCue(PlayerReplicationInfo, default.CommanderVoiceOverArchetype.MissionAccomplished);
}

/**
 * Plays the mission failed sound
 *
 * @param		PlayerReplicationInfo		Who to play the sound for
 */
final static function PlayMissionFailedSoundCue(PlayerReplicationInfo PlayerReplicationInfo)
{
	PlaySoundCue(PlayerReplicationInfo, default.CommanderVoiceOverArchetype.MissionFailed);
}

/**
 * Plays the new construction options sound
 *
 * @param		PlayerReplicationInfo		Who to play the sound for
 */
final static function PlayNewConstructionOptionsSoundCue(PlayerReplicationInfo PlayerReplicationInfo)
{
	PlaySoundCue(PlayerReplicationInfo, default.CommanderVoiceOverArchetype.NewConstructionOptions);
}

/**
 * Plays the not ready sound
 *
 * @param		PlayerReplicationInfo		Who to play the sound for
 */
final static function PlayNotReadySoundCue(PlayerReplicationInfo PlayerReplicationInfo)
{
	PlaySoundCue(PlayerReplicationInfo, default.CommanderVoiceOverArchetype.NotReady);
}

/**
 * Plays the on hold sound
 *
 * @param		PlayerReplicationInfo		Who to play the sound for
 */
final static function PlayOnHoldSoundCue(PlayerReplicationInfo PlayerReplicationInfo)
{
	PlaySoundCue(PlayerReplicationInfo, default.CommanderVoiceOverArchetype.OnHold);
}

/**
 * Plays the our base is under attack sound
 *
 * @param		PlayerReplicationInfo		Who to play the sound for
 */
final static function PlayOurBaseIsUnderAttack(PlayerReplicationInfo PlayerReplicationInfo)
{
	PlaySoundCue(PlayerReplicationInfo, default.CommanderVoiceOverArchetype.OurBaseIsUnderAttack);
}

/**
 * Plays the rally point set sound
 *
 * @param		PlayerReplicationInfo		Who to play the sound for
 */
final static function PlayRallyPointSet(PlayerReplicationInfo PlayerReplicationInfo)
{
	PlaySoundCue(PlayerReplicationInfo, default.CommanderVoiceOverArchetype.RallyPointSet);
}

/**
 * Plays the rally point reset sound
 *
 * @param		PlayerReplicationInfo		Who to play the sound for
 */
final static function PlayRallyPointReset(PlayerReplicationInfo PlayerReplicationInfo)
{
	PlaySoundCue(PlayerReplicationInfo, default.CommanderVoiceOverArchetype.RallyPointReset);
}

/**
 * Plays the reinforcements have arrived sound
 *
 * @param		PlayerReplicationInfo		Who to play the sound for
 */
final static function PlayReinforcementsHaveArrivedSoundCue(PlayerReplicationInfo PlayerReplicationInfo)
{
	PlaySoundCue(PlayerReplicationInfo, default.CommanderVoiceOverArchetype.ReinforcementsHaveArrived);
}

/**
 * Plays the repairing sound
 *
 * @param		PlayerReplicationInfo		Who to play the sound for
 */
final static function PlayRepairingSoundCue(PlayerReplicationInfo PlayerReplicationInfo)
{
	PlaySoundCue(PlayerReplicationInfo, default.CommanderVoiceOverArchetype.Repairing);
}

/**
 * Plays the research complete sound
 *
 * @param		PlayerReplicationInfo		Who to play the sound for
 */
final static function PlayResearchCompleteSoundCue(PlayerReplicationInfo PlayerReplicationInfo)
{
	PlaySoundCue(PlayerReplicationInfo, default.CommanderVoiceOverArchetype.ResearchComplete);
}

/**
 * Plays the researching sound
 *
 * @param		PlayerReplicationInfo		Who to play the sound for
 */
final static function PlayResearchingSoundCue(PlayerReplicationInfo PlayerReplicationInfo)
{
	PlaySoundCue(PlayerReplicationInfo, default.CommanderVoiceOverArchetype.Researching);
}

/**
 * Plays the select target sound
 *
 * @param		PlayerReplicationInfo		Who to play the sound for
 */
final static function PlaySelectTargetSoundCue(PlayerReplicationInfo PlayerReplicationInfo)
{
	PlaySoundCue(PlayerReplicationInfo, default.CommanderVoiceOverArchetype.SelectTarget);
}

/**
 * Plays the structure lost sound
 *
 * @param		PlayerReplicationInfo		Who to play the sound for
 */
final static function PlayStructureLostSoundCue(PlayerReplicationInfo PlayerReplicationInfo)
{
	PlaySoundCue(PlayerReplicationInfo, default.CommanderVoiceOverArchetype.StructureLost);
}

/**
 * Plays the unable to build more sound
 *
 * @param		PlayerReplicationInfo		Who to play the sound for
 */
final static function PlayUnableToBuildMoreSoundCue(PlayerReplicationInfo PlayerReplicationInfo)
{
	PlaySoundCue(PlayerReplicationInfo, default.CommanderVoiceOverArchetype.UnableToBuildMore);
}

/**
 * Plays the unit lost sound
 *
 * @param		PlayerReplicationInfo		Who to play the sound for
 */
final static function PlayUnitLostSoundCue(PlayerReplicationInfo PlayerReplicationInfo)
{
	PlaySoundCue(PlayerReplicationInfo, default.CommanderVoiceOverArchetype.UnitLost);
}

/**
 * Plays the unit ready sound
 *
 * @param		PlayerReplicationInfo		Who to play the sound for
 */
final static function PlayUnitReadySoundCue(PlayerReplicationInfo PlayerReplicationInfo)
{
	PlaySoundCue(PlayerReplicationInfo, default.CommanderVoiceOverArchetype.UnitReady);
}

/**
 * Plays thea sound cue
 *
 * @param		PlayerReplicationInfo		Who to play the sound for
 * @param		SoundCue					Sound cue to play
 */
final static function PlaySoundCue(PlayerReplicationInfo PlayerReplicationInfo, SoundCue SoundCue)
{
	local AIController AIController;
	local WorldInfo WorldInfo;

	// Check if we're on the dedicated server
	WorldInfo = class'WorldInfo'.static.GetWorldInfo();
	if (WorldInfo != None && WorldInfo.NetMode == NM_DedicatedServer)
	{
		return;
	}

	// Check object references
	if (PlayerReplicationInfo == None || SoundCue == None || PlayerReplicationInfo.Owner == None)
	{
		return;
	}

	// If the player replication info belongs to an AI controller, then abort
	AIController = AIController(PlayerReplicationInfo.Owner);
	if (AIController != None)
	{
		return;
	}

	PlayerReplicationInfo.Owner.PlaySound(SoundCue, true, true, true,, true);
}

defaultproperties
{
	CommanderVoiceOverArchetype=UDKRTSCommanderVoiceOver'UDKRTSGameContent.Archetypes.CommanderVoiceOver'
}