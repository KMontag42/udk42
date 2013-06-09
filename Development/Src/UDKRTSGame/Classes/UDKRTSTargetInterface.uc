//=============================================================================
// UDKRTSTargetInterface: Targetting interface
//
// This interface allows actors to get targetting information from each other
// to determine if an actor should attack this actor or not.
//
// Copyright 1998-2011 Epic Games, Inc. All Rights Reserved.
//=============================================================================
interface UDKRTSTargetInterface;

/**
 * Returns true if the target is valid
 *
 * @param		TeamInfo		Team info to test against, for friendly team checks
 */
simulated function bool IsValidTarget(optional UDKRTSTeamInfo TeamInfo);

/**
 * Returns the best location for the enemy to attack this actor
 *
 * @param		Attacker		Actor that will be attacking this actor
 * @param		WeaponRange		Range of the weapon the attacker will be using
 * @return						Returns the best attacking location for the enemy
 */
simulated function Vector BestAttackingLocation(Actor Attacker, float WeaponRange);

/**
 * Returns true if the actor has a weapon
 *
 * @return		Returns true if the actor has a weapon
 */
simulated function bool HasWeapon();

/**
 * Returns the AI targeting priority
 *
 * @return		Returns the AI targeting priority
 */
simulated function float GetAITargetingPriority();

/**
 * Returns the actor that implements this interface
 *
 * @return		Returns the actor that implements this interface
 */
simulated function Actor GetActor();