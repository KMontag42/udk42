//=============================================================================
// UDKRTSWeapon: Simplistic weapon for units.
//
// This class is a simplistic weapon for units. You would normally archetype
// this to create new weapons.
// 
// Copyright 1998-2011 Epic Games, Inc. All Rights Reserved.
//=============================================================================
class UDKRTSWeapon extends Actor
	HideCategories(Movement,Display,Attachment,Collision,Physics,Advanced,Debug,Object);

// Archetype of the upgraded weapon
var(Weapon) const archetype UDKRTSWeapon UpgradedWeaponArchetype;
// Instanced weapon firing object
var(Weapon) const instanced editinline UDKRTSWeaponFire FireMode;
// Weapon attachment mesh
var(Weapon) editconst const SkeletalMeshComponent AttachmentMesh;
// Socket name of the socket where firing starts from
var(Weapon) const Name FireSocketName;
// How precise the aim of the pawn has to be to start firing this weapon?
var(Weapon) const float AimPrecision;
// Use the pawn mesh to find the fire socket using FireSocketName
var(Weapon) const bool UsePawnMeshSocket;
// Name of the animation to play when this weapon is fired
var(Weapon) const Name FireAnimationName;
// Interface to who owns this weapon
var UDKRTSWeaponOwnerInterface UDKRTSWeaponOwnerInterface;
// Flash count for updating the muzzle effects
var RepNotify byte FlashCount;
// Flash location for updating the muzzle effects
var RepNotify Vector FlashHitLocation;
// Delay weapon fire target
var Actor DelayedWeaponFireTarget;

replication 
{
	if (bNetDirty && Role == Role_Authority)
		FlashCount, FlashHitLocation;
}

/**
 * Called when a variable with the property flag "RepNotify" is replicated
 *
 * @param		VarName			Name of the variable that was replicated
 */
simulated event ReplicatedEvent(Name VarName)
{
	if ((VarName == 'FlashCount' || VarName == 'FlashHitLocation') && FireMode != None)
	{
		FireMode.TurnOnMuzzleFlashEffects();
	}

	Super.ReplicatedEvent(VarName);
}

/**
 * Called when the weapon is initialized
 */
simulated function Initialize()
{
	if (FireMode != None)
	{
		FireMode.WeaponOwner = Self;
		FireMode.Initialize();
	}
}

/**
 * Attaches itself to a skeletal mesh component. Weapons are usually attachments as well, as units usually have the same weapon.
 *
 * @param		SkeletalMeshComponent			Skeletal mesh component to attach to
 * @param		LightEnvironment				Light environment for the weapon's mesh to use
 * @param		SocketName						Name of the socket on the skeletal 
 */
simulated function AttachToSkeletalMeshComponent(SkeletalMeshComponent SkeletalMeshComponent, LightEnvironmentComponent LightEnvironment, Name SocketName)
{
	// Check object references
	if (SkeletalMeshComponent == None || AttachmentMesh == None)
	{
		return;
	}

	// Attach the mesh to the pawn's skeletal mesh
	if (SocketName != '' && SocketName != 'None' && SkeletalMeshComponent.GetSocketByName(SocketName) != None)
	{
		// Attach the weapon's mesh to the skeletal mesh component
		SkeletalMeshComponent.AttachComponentToSocket(AttachmentMesh, SocketName);
		AttachmentMesh.SetShadowParent(SkeletalMeshComponent);

		if (LightEnvironment != None)
		{
			AttachmentMesh.SetLightEnvironment(LightEnvironment);
		}

		AttachmentMesh.SetHidden(false);
	}
}

/**
 * Detaches the weapon mesh from any thing it is currently attached to
 */
simulated function DetachFromAny()
{
	AttachmentMesh.DetachFromAny();
	AttachmentMesh.SetShadowParent(None);
	AttachmentMesh.SetLightEnvironment(None);
	AttachmentMesh.SetHidden(true);
}

/**
 * Destroys the weapon
 */
simulated event Destroyed()
{
	// Destroy the fire mode
	if (FireMode != None)
	{
		FireMode.Destroyed();
	}

	// Detach it from anyone
	DetachFromAny();
	Super.Destroyed();
}

/**
 * Returns true if the weapon can be fired
 *
 * @return		Returns true if the weapon can be fired
 */
function bool CanFire()
{
	if (Role < Role_Authority)
	{
		return false;
	}

	if (FireMode == None || IsTimerActive(NameOf(WeaponFireCooldownTimer)) || IsTimerActive(NameOf(DelayedWeaponFire)))
	{
		return false;
	}

	return true;
}

/**
 * Fires the weapon at a target
 *
 * @param		Target		Target to fire the weapon at
 */
function Fire(optional Actor Target)
{
	if (Role < Role_Authority)
	{
		return;
	}

	if (CanFire())
	{
		if (FireMode.FireDelay > 0.f)
		{
			DelayedWeaponFireTarget = Target;
			SetTimer(FireMode.FireDelay, false, NameOf(DelayedWeaponFire));
		}
		else
		{
			FireMode.FireWeapon(Target);
			SetTimer(FireMode.FireInterval, false, NameOf(WeaponFireCooldownTimer));
		}		
	}
}

/**
 * Returns true if a target is within range at the attacking location
 *
 * @param			Target						Target to attack
 * @param			AttackingLocation			Location to attack from
 * @param			IgnoreBlockingActors		If actors are in the way, just ignore them and shoot
 * @return										Returns true if the weapon can attack the target from attacking location
 */
simulated function bool InRange(Actor Target, Vector AttackingLocation, optional bool IgnoreBlockingActors)
{
	local float Distance;
	local Vector HitLocation, HitNormal;
	local Actor HitActor;

	// Check object references
	if (Target == None || UDKRTSWeaponOwnerInterface == None)
	{
		return false;
	}

	// Perform a quick line of sight check
	if (FastTrace(Target.Location, AttackingLocation))
	{		
		// Check the distance
		Distance = VSize(Target.Location - AttackingLocation);
		if (Distance >= (GetRange() * 0.25f) && Distance <= GetRange())
		{
			// If we're not ignoring blocking actors, then just return true
			if (!IgnoreBlockingActors)
			{
				// Perforce a trace to check for actors
				ForEach TraceActors(class'Actor', HitActor, HitLocation, HitNormal, AttackingLocation, Target.Location)
				{
					if (HitActor.IsA('UDKRTSPawn') && HitActor != Owner && HitActor != Target)
					{
						return false;
					}

					if (HitActor.IsA('UDKRTSStructure') && HitActor != Owner && HitActor != Target)
					{
						return false;
					}
				}
			}

			return true;
		}
	}

	return false;
}

/**
 * Returns the range of this weapon
 *
 * @return			Returns the range of this weapon
 */
simulated function float GetRange()
{
	return (FireMode != None) ? FireMode.GetRange() : 16.f;
}

/**
 * Used to keep track if the fire mode is cooling down or not
 */
simulated function WeaponFireCooldownTimer();

/**
 * Fires the weapon with a cool down delay
 */
simulated function DelayedWeaponFire()
{
	FireMode.FireWeapon(DelayedWeaponFireTarget);

	if (Role == Role_Authority)
	{
		SetTimer(FireMode.FireInterval, false, NameOf(WeaponFireCooldownTimer));
	}
}

defaultproperties
{
	AimPrecision=0.995f
	bReplicateInstigator=true
	bOnlyDirtyReplication=false
	RemoteRole=ROLE_SimulatedProxy	

 	Begin Object Class=SkeletalMeshComponent Name=MySkeletalMeshComponent
		HiddenGame=true
 	End Object
 	AttachmentMesh=MySkeletalMeshComponent
 	Components.Add(MySkeletalMeshComponent)	
}