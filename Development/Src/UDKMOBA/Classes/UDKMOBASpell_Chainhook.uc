//=============================================================================
// UDKMOBASpell_Chainhook
//
// Launches a chain at the target and then pulls the caster to the target's location
// 
// Copyright 1998-2012 Epic Games, Inc. All Rights Reserved.
//=============================================================================
class UDKMOBASpell_Chainhook extends UDKMOBASpell;

// Archetype to use for the missile projectile
var(ChainhookProjectile) const UDKMOBAProjectile_Chainhook_Chain ChainProjectileArchetype;
// Current target location for the chain
var ProtectedWrite Vector MissionTargetLocation;
// Current number of chains launched
var ProtectedWrite int ChainsLaunched;

/**
 * Launches the chain
 *
 * @network		Server and client
 */
protected simulated function PerformCast()
{
	// Only launch the chain on the server
	if (Role == Role_Authority && !IsTimerActive(NameOf(LaunchChainTimer)))
	{
		MissionTargetLocation = TargetLocation;
		SetTimer(0.05f, true, NameOf(LaunchChainTimer));
	}
}

/**
 * Launches the chain which is usually called via a timer
 */
function LaunchChainTimer()
{
	local UDKMOBAProjectile_Chainhook_Chain lProjectile;
	local Vector DesiredDirection;

	// Spawn the missile
	lProjectile = PawnOwner.Spawn(ChainProjectileArchetype.Class,,, PawnOwner.Location,, ChainProjectileArchetype);
	if (lProjectile != None)
	{
		// Set the spell owner
		lProjectile.SpellOwner = Self;
		// Set the attack owner
		lProjectile.OwnerAttackInterface = UDKMOBAAttackInterface(PawnOwner);
		// Set the actor owner
		lProjectile.ActorOwner = PawnOwner;
		// Set the target location
		lProjectile.TargetLocation = MissionTargetLocation;
		// Set where to move caster
		lProjectile.CasterTargetLocation = TargetLocation;
		// Send the projectile flying
		DesiredDirection = Vector(Rotator(TargetLocation - PawnOwner.Location));
		DesiredDirection.z = 0.f;
		lProjectile.Init(DesiredDirection);
	}

	// Count how many missiles have been launched
	ChainsLaunched++;
	// Clear the timer if the amount of missiles have been launched
	if (ChainsLaunched >= 1)
	{
		ClearTimer(NameOf(LaunchChainTimer));
	}
}

// Default properties block
defaultproperties
{
}