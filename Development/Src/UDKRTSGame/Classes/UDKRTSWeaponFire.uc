//=============================================================================
// UDKRTSWeaponFire: Simplistic weapon fire object used by weapons.
//
// This class is instanced by UDKRTSWeapon to perform the actual firing.
// 
// Copyright 1998-2011 Epic Games, Inc. All Rights Reserved.
//=============================================================================
class UDKRTSWeaponFire extends Object
	HideCategories(Object)
	EditInlineNew
	abstract;

// Time between each weapon fire
var(WeaponFire) const float FireInterval;
// Sound to make for each weapon fire
var(WeaponFire) const SoundCue FireSound;
// How many shots are fired per weapon fire (use more than one to simulate a shotgun for example)
var(WeaponFire) const int ShotsPerFire;
// Fire delay
var(WeaponFire) const float FireDelay;
// Muzzle flash particle system component
var(WeaponFire) const ParticleSystemComponent MuzzleFlashParticleSystemComponent;
// The owner of this weapon
var UDKRTSWeapon WeaponOwner;
// Waiting to set the color of the muzzle flash
var PrivateWrite bool PendingToSetColorOfTheMuzzleFlash;

/**
 * Called when the weapon fire is initialized
 */
simulated function Initialize()
{
	if (WeaponOwner != None && WeaponOwner.WorldInfo.NetMode != NM_DedicatedServer)
	{
		if (!WeaponOwner.UsePawnMeshSocket)
		{
			if (WeaponOwner.AttachmentMesh != None && WeaponOwner.AttachmentMesh.GetSocketByName(WeaponOwner.FireSocketName) != None)
			{
				WeaponOwner.AttachmentMesh.AttachComponentToSocket(MuzzleFlashParticleSystemComponent, WeaponOwner.FireSocketName);
			}
		}
		else
		{
			if (WeaponOwner.Instigator != None && WeaponOwner.Instigator.Mesh != None && WeaponOwner.Instigator.Mesh.GetSocketByName(WeaponOwner.FireSocketName) != None)
			{
				WeaponOwner.Instigator.Mesh.AttachComponentToSocket(MuzzleFlashParticleSystemComponent, WeaponOwner.FireSocketName);
			}
		}
	}
}

/**
 * Sets the team colors of the muzzle flash
 */
simulated function SetTeamColor()
{
	local Vector TeamColor;
	local UDKRTSTeamInfo UDKRTSTeamInfo;
	local UDKRTSWeaponOwnerInterface UDKRTSWeaponOwnerInterface;

	if (PendingToSetColorOfTheMuzzleFlash || MuzzleFlashParticleSystemComponent == None)
	{
		return;
	}

	// Assign the team colors
	UDKRTSWeaponOwnerInterface = UDKRTSWeaponOwnerInterface(WeaponOwner.Owner);
	if (UDKRTSWeaponOwnerInterface != None)
	{
		UDKRTSTeamInfo = UDKRTSWeaponOwnerInterface.GetUDKRTSTeamInfo();
		if (UDKRTSTeamInfo != None)
		{
			TeamColor.X = float(UDKRTSTeamInfo.TeamColor.R) / 255.f;
			TeamColor.Y = float(UDKRTSTeamInfo.TeamColor.G) / 255.f;
			TeamColor.Z = float(UDKRTSTeamInfo.TeamColor.B) / 255.f;

			PendingToSetColorOfTheMuzzleFlash = true;
		}
		else
		{
			TeamColor = Vect(1.f, 1.f, 1.f);
		}

		MuzzleFlashParticleSystemComponent.SetVectorParameter('TeamColor', TeamColor);
	}
}

/**
 * Called when this weapon fire gets destroyed
 */
simulated function Destroyed();

/**
 * Performs the actual firing
 *
 * @param		Target			Actor to target
 */
final function FireWeapon(optional Actor Target)
{
	local Vector FireLocation;
	local Rotator FireRotation;
	local int i;
	local UDKRTSTeamInfo UDKRTSTeamInfo;
	local UDKRTSWeaponOwnerInterface UDKRTSWeaponOwnerInterface;

	// Check variables for early outs
	if (ShotsPerFire <= 0 || WeaponOwner == None || WeaponOwner.UDKRTSWeaponOwnerInterface == None || WeaponOwner.Role < Role_Authority)
	{
		return;
	}

	// Turn on the muzzle flash
	WeaponOwner.FlashCount++;
	TurnOnMuzzleFlashEffects();

	UDKRTSWeaponOwnerInterface = UDKRTSWeaponOwnerInterface(WeaponOwner.Owner);
	if (UDKRTSWeaponOwnerInterface != None)
	{
		UDKRTSTeamInfo = UDKRTSWeaponOwnerInterface.GetUDKRTSTeamInfo();
	}

	if (UDKRTSTeamInfo != None)
	{
		if (WeaponOwner.Instigator != None)
		{
			if (!WeaponOwner.UsePawnMeshSocket)
			{
				if (WeaponOwner.AttachmentMesh != None && WeaponOwner.AttachmentMesh.GetSocketByName(WeaponOwner.FireSocketName) != None)
				{
					WeaponOwner.UDKRTSWeaponOwnerInterface.GetWeaponFireLocationAndRotation(FireLocation, FireRotation);	

					if (ShotsPerFire == 1)
					{
						Fire(FireLocation, FireRotation, UDKRTSTeamInfo);
					}
					else if (ShotsPerFire > 1)
					{
						for (i = 0; i < ShotsPerFire; ++i)
						{
							Fire(FireLocation, FireRotation, UDKRTSTeamInfo);
						}
					}
				}
			}
			else if (WeaponOwner.Instigator.Mesh != None && WeaponOwner.Instigator.Mesh.SkeletalMesh != None && WeaponOwner.Instigator.Mesh.GetSocketByName(WeaponOwner.FireSocketName) != None)
			{
				WeaponOwner.Instigator.Mesh.GetSocketWorldLocationAndRotation(WeaponOwner.FireSocketName, FireLocation, FireRotation);

				if (ShotsPerFire == 1)
				{
					Fire(FireLocation, FireRotation, UDKRTSTeamInfo);
				}
				else if (ShotsPerFire > 1)
				{
					for (i = 0; i < ShotsPerFire; ++i)
					{
						Fire(FireLocation, FireRotation, UDKRTSTeamInfo);
					}
				}
			}
		}
		else if (WeaponOwner.Owner != None && Target != None)
		{
			if (ShotsPerFire == 1)
			{
				Fire(WeaponOwner.Owner.Location, Rotator(Target.Location - WeaponOwner.Owner.Location), UDKRTSTeamInfo);
			}
			else if (ShotsPerFire > 1)
			{
				for (i = 0; i < ShotsPerFire; ++i)
				{
					Fire(WeaponOwner.Owner.Location, Rotator(Target.Location - WeaponOwner.Owner.Location), UDKRTSTeamInfo);
				}
			}
		}
	}
}

/**
 * Called to fire the weapon
 *
 * @param		FireLocation		Location to fire from
 * @param		FireRotation		Rotation to fire from
 * @param		TeamInfo			Team that "owns" this fire, to prevent friendly fire
 */
protected function Fire(Vector FireLocation, Rotator FireRotation, UDKRTSTeamInfo TeamInfo);

/**
 * Returns the range of the trace
 *
 * @return		Returns the range of the trace
 */
function float GetRange()
{
	return 16.f;
}

/**
 * Returns the damage that this weapon does
 *
 * @return		Returns the damage that this weapon does
 */
static function float GetDamage()
{
	return 0.f;
}

/**
 * Turns on the muzzle flash effect
 */
simulated function TurnOnMuzzleFlashEffects()
{
	if (WeaponOwner == None || WeaponOwner.WorldInfo.NetMode == NM_DedicatedServer || WeaponOwner.Owner == None)
	{
		return;
	}

	// Set the team colors if we're waiting to set the muzzle flash color
	if (!PendingToSetColorOfTheMuzzleFlash)
	{
		SetTeamColor();
	}

	// Play the fire sound
	if (FireSound != None)
	{
		WeaponOwner.Owner.PlaySound(FireSound);
	}

	// Activate the muzzle flash
	if (MuzzleFlashParticleSystemComponent != None)
	{		
		MuzzleFlashParticleSystemComponent.ActivateSystem();

		// Clear the TurnOffMuzzleFlashEffects if it is already active
		if (WeaponOwner.IsTimerActive(NameOf(TurnOffMuzzleFlashEffects), Self))
		{
			WeaponOwner.ClearTimer(NameOf(TurnOffMuzzleFlashEffects), Self);
		}

		// Start the TurnOffMuzzleFlashEffects timer again
		WeaponOwner.SetTimer(0.3f, false, NameOf(TurnOffMuzzleFlashEffects), Self);
	}
}

/**
 * Turns off the muzzle flash effect
 */
simulated function TurnOffMuzzleFlashEffects()
{
	if (WeaponOwner == None || WeaponOwner.WorldInfo.NetMode == NM_DedicatedServer)
	{
		return;
	}

	if (MuzzleFlashParticleSystemComponent != None)
	{
		MuzzleFlashParticleSystemComponent.DeactivateSystem();
	}
}

defaultproperties
{
	Begin Object Class=ParticleSystemComponent Name=MyParticleSystemComponent
		bAutoActivate=false
		SecondsBeforeInactive=1
	End Object
	MuzzleFlashParticleSystemComponent=MyParticleSystemComponent

	FireInterval=0.1f
	ShotsPerFire=1
	PendingToSetColorOfTheMuzzleFlash=false
}