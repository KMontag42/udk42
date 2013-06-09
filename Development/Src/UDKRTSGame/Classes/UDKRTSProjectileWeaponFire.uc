//=============================================================================
// UDKRTSProjectileWeaponFire: Weapon that shoots a projectile
//
// Weapon fire that shoots a projectile
// 
// Copyright 1998-2011 Epic Games, Inc. All Rights Reserved.
//=============================================================================
class UDKRTSProjectileWeaponFire extends UDKRTSWeaponFire;

// True if we want to use the projectile range value defined in the archetype
var const bool OverrideProjectileRange;
// Projectile archetype
var(Projectile) const archetype UDKRTSProjectile ProjectileArchetype;
// User defined range of the projectile 
var(Projectile) const float ProjectileRange<EditCondition=OverrideProjectileRange>;

/**
 * Called to fire the weapon
 *
 * @param		FireLocation		Location to fire from
 * @param		FireRotation		Rotation to fire from
 * @param		TeamInfo			Team that "owns" this fire, to prevent friendly fire
 */
protected function Fire(Vector FireLocation, Rotator FireRotation, UDKRTSTeamInfo TeamInfo)
{
	local UDKRTSProjectile Projectile;
	local int i;

	// Check object references
	if (ProjectileArchetype == None || WeaponOwner == None || TeamInfo == None)
	{
		return;
	}

	// Spawn the projectile, set the color and fire it
	Projectile = WeaponOwner.Spawn(ProjectileArchetype.Class, WeaponOwner.Instigator,, FireLocation, FireRotation, ProjectileArchetype);
	if (Projectile != None)
	{
		Projectile.SetTeamInfo(TeamInfo);

		// Apply any team upgrades to it
		if (TeamInfo.Upgrades.Length > 0)
		{
			for (i = 0; i < TeamInfo.Upgrades.Length; ++i)
			{
				if (TeamInfo.Upgrades[i] != None && TeamInfo.Upgrades[i].UnitWeaponBoost > 0.f)
				{
					Projectile.Damage += (Projectile.Damage * TeamInfo.Upgrades[i].UnitWeaponBoost);
				}
			}
		}

		Projectile.Init(Vector(FireRotation));
	}
}

/**
 * Returns the range of the trace
 *
 * @return		Returns the range of the trace
 */
function float GetRange()
{
	// Return the user defined projectile range
	if (OverrideProjectileRange)
	{
		return ProjectileRange;
	}

	// Calculate the ranged based on the archetype
	if (ProjectileArchetype != None)
	{
		if (ProjectileArchetype.MaximumTravelDistance <= 0.f)
		{
			return ProjectileArchetype.Speed * ProjectileArchetype.LifeSpan;
		}
		else
		{
			return ProjectileArchetype.MaximumTravelDistance;
		}
	}

	return 0.f;
}

/**
 * Returns the damage that this weapon does
 *
 * @return		Returns the damage that this weapon does
 */
static function float GetDamage()
{	
	// Check if we have a valid projectile archetype
	if (default.ProjectileArchetype == None)
	{
		return 0.f;
	}

	// Return the archetypes damage
	return default.ProjectileArchetype.Damage;
}

defaultproperties
{
}