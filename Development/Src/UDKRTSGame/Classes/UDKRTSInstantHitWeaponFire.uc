//=============================================================================
// UDKRTSInstantHitWeaponFire: Weapon fire that uses traces
//
// Weapon that uses traces to perform damage.
// 
// Copyright 1998-2011 Epic Games, Inc. All Rights Reserved.
//=============================================================================
class UDKRTSInstantHitWeaponFire extends UDKRTSWeaponFire;

// How much to damage the victim
var(InstantHit) const int Damage;
// Range of the weapon
var(InstantHit) const float Range;
// Extent of the trace
var(InstantHit) const Vector TraceExtent;
// Damage type of the weapon
var(InstantHit) const class<DamageType> DamageType;
// Momentum to apply to the victim
var(InstantHit) const float Momentum;
// How many victims to pass though (rail gun)
var(InstantHit) const int PassThroughCount;
// Team based beam particle effect
var(InstantHit) const array<ParticleSystem> TeamBeamParticleSystems;
// Impact particle effect
var(InstantHit) const ParticleSystem ImpactParticleSystem;
// Beam particle system component
var ParticleSystemComponent BeamParticleSystemComponent;
// Cached team color
var Vector TeamColor;

/**
 * Initializes the weapon fire
 */
simulated function Initialize()
{
	Super.Initialize();

	if (WeaponOwner.WorldInfo.NetMode != NM_DedicatedServer && WeaponOwner != None)
	{
		if (WeaponOwner.AttachmentMesh != None && WeaponOwner.AttachmentMesh.GetSocketByName(WeaponOwner.FireSocketName) != None)
		{
			// Create the beam particle system and attach it
			BeamParticleSystemComponent = new () class'ParticleSystemComponent';
			if (BeamParticleSystemComponent != None)
			{
				WeaponOwner.AttachmentMesh.AttachComponentToSocket(BeamParticleSystemComponent, WeaponOwner.FireSocketName);
			}
		}
	}
}

/**
 * Sets the team colors of the muzzle flash
 */
simulated function SetTeamColor()
{
	local UDKRTSTeamInfo UDKRTSTeamInfo;
	local UDKRTSWeaponOwnerInterface UDKRTSWeaponOwnerInterface;

	if (PendingToSetColorOfTheMuzzleFlash)
	{
		return;
	}

	// Assign the team colors
	UDKRTSWeaponOwnerInterface = UDKRTSWeaponOwnerInterface(WeaponOwner.Owner);
	if (UDKRTSWeaponOwnerInterface != None)
	{
		UDKRTSTeamInfo = UDKRTSWeaponOwnerInterface.GetUDKRTSTeamInfo();
		if (UDKRTSTeamInfo != None && UDKRTSTeamInfo.TeamIndex >= 0 && UDKRTSTeamInfo.TeamIndex < TeamBeamParticleSystems.Length)
		{
			if (BeamParticleSystemComponent != None)
			{
				BeamParticleSystemComponent.bAutoActivate = false;
				BeamParticleSystemComponent.SetTemplate(TeamBeamParticleSystems[UDKRTSTeamInfo.TeamIndex]);				
			}

			TeamColor.X = float(UDKRTSTeamInfo.TeamColor.R) / 255.f;
			TeamColor.Y = float(UDKRTSTeamInfo.TeamColor.G) / 255.f;
			TeamColor.Z = float(UDKRTSTeamInfo.TeamColor.B) / 255.f;
		}
	}

	Super.SetTeamColor();
}

/**
 * Called when this weapon is destroyed
 */
simulated function Destroyed()
{
	Super.Destroyed();

	// Destroy the beam particle system
	if (BeamParticleSystemComponent != None)
	{
		BeamParticleSystemComponent = None;
	}	
}

/**
 * Called to fire the weapon
 *
 * @param		FireLocation		Location to fire from
 * @param		FireRotation		Rotation to fire from
 * @param		TeamInfo			Team that "owns" this fire, to prevent friendly fire
 */
protected function Fire(Vector FireLocation, Rotator FireRotation, UDKRTSTeamInfo TeamInfo)
{
	local Actor HitActor;
	local Vector HitLocation, HitNormal, TraceEnd;
	local int HitCount, i;	
	local float ModifiedDamage;
	local UDKRTSTargetInterface UDKRTSTargetInterface;

	// Check object references
	if (WeaponOwner == None || TeamInfo == None)
	{
		return;
	}

	// Check for upgrades
	HitCount = 0;
	ModifiedDamage = Damage;
	if (TeamInfo.Upgrades.Length > 0)
	{
		for (i = 0; i < TeamInfo.Upgrades.Length; ++i)
		{
			if (TeamInfo.Upgrades[i] != None && TeamInfo.Upgrades[i].UnitWeaponBoost > 0.f)
			{
				ModifiedDamage += (ModifiedDamage * TeamInfo.Upgrades[i].UnitWeaponBoost);
			}
		}
	}

	// Perform the trace
	TraceEnd = FireLocation + Vector(FireRotation) * Range;
	ForEach WeaponOwner.TraceActors(class'Actor', HitActor, HitLocation, HitNormal, TraceEnd, FireLocation, TraceExtent)
	{
		UDKRTSTargetInterface = UDKRTSTargetInterface(HitActor);
		if (UDKRTSTargetInterface != None && UDKRTSTargetInterface.IsValidTarget(TeamInfo))
		{
			HitCount++;
			HitActor.TakeDamage(ModifiedDamage, (WeaponOwner.Instigator != None) ? WeaponOwner.Instigator.Controller : None, HitLocation, Vector(FireRotation) * Momentum, DamageType,, WeaponOwner.Instigator);

			if (HitCount == PassThroughCount)
			{
				WeaponOwner.FlashCount++;
				WeaponOwner.FlashHitLocation = HitLocation;

				break;
			}
		}
	}

	if (HitCount == 0)
	{
		WeaponOwner.FlashCount++;
		WeaponOwner.FlashHitLocation = Vect(0, 0, 0);
	}

	// Turn on the muzzle flash anyways
	TurnOnMuzzleFlashEffects();
}

/**
 * Returns the range of the trace
 *
 * @return		Returns the range of the trace
 */
function float GetRange()
{
	return Range;
}

/**
 * Returns the damage that this weapon does
 *
 * @return		Returns the damage that this weapon does
 */
static function float GetDamage()
{
	return default.Damage;
}

/**
 * Turns on the muzzle flash effect
 */
simulated function TurnOnMuzzleFlashEffects()
{
	local ParticleSystemComponent ImpactParticleSystemComponent;

	if (WeaponOwner == None || WeaponOwner.WorldInfo.NetMode == NM_DedicatedServer || WeaponOwner.Owner == None || IsZero(WeaponOwner.FlashHitLocation))
	{
		return;
	}

	// If we have a beam particle system then activate it
	if (BeamParticleSystemComponent != None)
	{
		BeamParticleSystemComponent.ActivateSystem();
		BeamParticleSystemComponent.SetVectorParameter('ShockBeamEnd', WeaponOwner.FlashHitLocation);
	}

	// Spawn the impact particle effect
	if (ImpactParticleSystem != None && WeaponOwner.WorldInfo != None && WeaponOwner.WorldInfo.MyEmitterPool != None)
	{
		ImpactParticleSystemComponent = WeaponOwner.WorldInfo.MyEmitterPool.SpawnEmitter(ImpactParticleSystem, WeaponOwner.FlashHitLocation, Rot(0, 0, 0));
		if (ImpactParticleSystemComponent != None)
		{
			ImpactParticleSystemComponent.SetVectorParameter('TeamColor', TeamColor);
		}
	}

	Super.TurnOnMuzzleFlashEffects();
}

defaultproperties
{
	TraceExtent=(X=8.f,Y=8.f,Z=8.f)
	PassThroughCount=1
}