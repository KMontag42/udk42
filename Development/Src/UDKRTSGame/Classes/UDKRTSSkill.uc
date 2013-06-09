//=============================================================================
// UDKRTSSkill: Object which represents skills that units can perform.
//
// This class represents all skills that units can perform.
// 
// Copyright 1998-2011 Epic Games, Inc. All Rights Reserved.
//=============================================================================
class UDKRTSSkill extends Object
	DependsOn(UDKRTSMobileHUD)
	HideCategories(Object)
	EditInlineNew
	abstract;

// Icon to display on the HUD
var(Skill) const SHUDAction Icon;
// Is the skill a toggle or a one off skill that gets used
var(Skill) const bool IsToggle;
// Used to tell if an icon is active or not for toggles
var ProtectedWrite bool IsActive;

/**
 * Calling this activates the skill
 *
 * @param		Pawn				Pawn that activated this skill
 * @param		AimLocation			World location the skill is targeted at
 */
final simulated function Activate(UDKRTSPawn Pawn, Vector AimLocation)
{
	// If this skill is a toggle, then deactivate it
	if (IsToggle)
	{
		if (IsActive)
		{
			Deactivate(Pawn, AimLocation);
			return;
		}
		else
		{
			IsActive = true;
		}
	}

	// Activate the sign
	OnActivate(Pawn, AimLocation);
}

/**
 * Calling this deactivates the skill
 *
 * @param		Pawn			Pawn that deactivated this skill
 * @param		AimLocation		World location the skill is targeted at
 */
protected final simulated function Deactivate(UDKRTSPawn Pawn, Vector AimLocation)
{
	IsActive = false;
	OnDeactivate(Pawn, AimLocation);
}

/**
 * Stub which subclasses will extend for custom skill activation code
 *
 * @param		Pawn			Pawn that activated this skill
 * @param		AimLocation		World location the skill is targeted at
 */
protected simulated function OnActivate(UDKRTSPawn Pawn, Vector AimLocation);

/**
 * Stub which subclasses will extend for custom skill deactivation code
 *
 * @param		Pawn			Pawn that deactivated this skill
 * @param		AimLocation		World location the skill is targeted at
 */
protected simulated function OnDeactivate(UDKRTSPawn Pawn, Vector AimLocation);

/**
 * Returns true if the skill requires a post render event call
 *
 * @param		Pawn			Pawn that owns this skill
 */
simulated function bool RequiresPostRender(UDKRTSPawn Pawn)
{
	return false;
}

/**
 * Sub which subclasses will extend to perform custom rendering onto the HUD
 *
 * @param		HUD				HUD to render to
 * @param		Pawn			Pawn that owns this skill
 */
simulated function PostRender(HUD HUD, UDKRTSPawn Pawn);

defaultproperties
{
}