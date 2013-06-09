//=============================================================================
// UDKRTSWeaponOwnerInterface: Weapon owner interface
//
// Actors that can own weapons should implement this interface.
//
// Copyright 1998-2011 Epic Games, Inc. All Rights Reserved.
//=============================================================================
interface UDKRTSWeaponOwnerInterface;

/**
 * Returns the weapon firing location and rotation in world coordinates
 *
 * @param		FireLocation		Firing Location for the weapon
 * @param		FireRotation		Firing rotation for the weapon
 */
simulated function GetWeaponFireLocationAndRotation(out Vector FireLocation, out Rotator FireRotation);

/**
 * Returns the team info that this actor belongs to
 *
 * @return		Returns the team info for this structure
 */
simulated function UDKRTSTeamInfo GetUDKRTSTeamInfo();