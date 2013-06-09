//=============================================================================
// UDKRTSSkill_FragGrenade: Frag grenades that units can throw.
//
// This skill allows units to throw frag grenades at a location.
// 
// Copyright 1998-2011 Epic Games, Inc. All Rights Reserved.
//=============================================================================
class UDKRTSSkill_FragGrenade extends UDKRTSSkill;

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

defaultproperties
{
}