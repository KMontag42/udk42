//=============================================================================
// UDKRTSProjectile: Projectile class that can be archetyped
//
// Projectile class that you should archetype to create different kinds of 
// projectiles for units to shoot.
// 
// Copyright 1998-2011 Epic Games, Inc. All Rights Reserved.
//=============================================================================
class UDKRTSProjectile extends Projectile
	HideCategories(Movement,Attachment,Physics,Advanced,Debug,Object);

// Particle system which represents the projectile
var(Projectile) const editconst ParticleSystemComponent ParticleSystem;
// Impact particle template to spawn when the projectiles hits something
var(Projectile) const ParticleSystem ImpactParticleTemplate;
// Maximum distance to travel
var(Projectile) const float MaximumTravelDistance;
// Static mesh which represents the projectile
var(Projectile) const StaticMeshComponent Mesh;
// Mesh team materials to apply
var(Projectile) const array<MaterialInterface> MeshTeamMaterials;

// Team this projectile belongs to
var RepNotify UDKRTSTeamInfo TeamInfo;
// Spawn location of this projectile, used for ensuring that the projectile does not travel too far
var vector SpawnLocation;
// Cached maximum travel distance squared, used for ensuring that the projectile does not travel too far
var float MaximumTravelDistanceSq;

// Replication block
replication
{
	if ((bNetDirty || bNetInitial) && Role == Role_Authority)
		TeamInfo;
}

/**
 * Called when the projectile is first initialized
 */
simulated event PostBeginPlay()
{
	Super.PostBeginPlay();

	// Cache the spawn location
	SpawnLocation = Location;
	// Cache the maximum travel distance squared
	MaximumTravelDistanceSq = Square(MaximumTravelDistance);
	// Attach the mesh if it has been defined
	if (Mesh != None && Mesh.StaticMesh != None)
	{
		AttachComponent(Mesh);
	}
}

/**
 * Called when a variable with the property flag "RepNotify" is replicated
 *
 * @param		VarName			Name of the variable that was replicated
 */
simulated event ReplicatedEvent(Name VarName)
{
	if (VarName == 'TeamInfo')
	{
		SetTeamInfo(TeamInfo);
	}

	Super.ReplicatedEvent(VarName);
}

/**
 * Sets the team info for this projectile; and sets the colors of the projectile
 *
 * @param		NewTeamInfo			NewTeamInfo
 */
simulated function SetTeamInfo(UDKRTSTeamInfo NewTeamInfo)
{
	local Vector TeamColor;

	TeamInfo = NewTeamInfo;
	if (TeamInfo != None)
	{
		// Set the team color of the particle system
		if (ParticleSystem != None)
		{
			TeamColor.X = float(TeamInfo.TeamColor.R) / 255.f;
			TeamColor.Y = float(TeamInfo.TeamColor.G) / 255.f;
			TeamColor.Z = float(TeamInfo.TeamColor.B) / 255.f;

			ParticleSystem.SetVectorParameter('TeamColor', TeamColor);
		}

		// Set the mesh material
		if (Mesh != None && TeamInfo.TeamIndex >= 0 && TeamInfo.TeamIndex < MeshTeamMaterials.Length)
		{
			Mesh.SetMaterial(0, MeshTeamMaterials[TeamInfo.TeamIndex]);
		}
	}
}

/**
 * Called everytime the projectile is updated
 *
 * @param		DeltaTime		Time since the last tick was called
 */
simulated function Tick(float DeltaTime)
{
	local float DistanceTravelledSq;

	// Check if the projectile has travelled to far away or not
	DistanceTravelledSq = VSizeSq(SpawnLocation - Location);
	if (DistanceTravelledSq >= MaximumTravelDistanceSq)
	{
		Destroy();
	}
}

/**
 * Processes when a touch occurs
 *
 * @param		Other				Other actor that was touched
 * @param		HitLocation			World location where the touch occured
 * @param		HitNormal			Direction of the touch
 */
simulated function ProcessTouch(Actor Other, Vector HitLocation, Vector HitNormal)
{
	local UDKRTSTargetInterface UDKRTSTargetInterface;
	local Vector TeamColor;
	local ParticleSystemComponent ImpactParticleSystemComponent;

	// Projectiles do not hit the instigator
	if (Other == Instigator || TeamInfo == None)
	{
		return;
	}

	UDKRTSTargetInterface = UDKRTSTargetInterface(Other);
	if (UDKRTSTargetInterface != None && UDKRTSTargetInterface.IsValidTarget(TeamInfo) && DamageRadius == 0.f)
	{
		// Handle effects
		if (WorldInfo != None && WorldInfo.NetMode != NM_DedicatedServer)
		{
			// Play back the impact sound
			if (ImpactSound != None)
			{
				PlaySound(ImpactSound);
			}

			// Spawn the particle effect
			if (ImpactParticleTemplate != None && WorldInfo.MyEmitterPool != None)
			{
				ImpactParticleSystemComponent = WorldInfo.MyEmitterPool.SpawnEmitter(ImpactParticleTemplate, HitLocation, Rotator(HitNormal));
				if (ImpactParticleSystemComponent != None)
				{
					// Set the particle effect to the team color
					TeamColor.X = float(TeamInfo.TeamColor.R) / 255.f;
					TeamColor.Y = float(TeamInfo.TeamColor.G) / 255.f;
					TeamColor.Z = float(TeamInfo.TeamColor.B) / 255.f;
					ImpactParticleSystemComponent.SetVectorParameter('TeamColor', TeamColor);
				}
			}
		}

		// Deal damage
		if (Damage > 0.f)
		{
			Other.TakeDamage(Damage, Instigator.Controller, HitLocation, HitNormal * -MomentumTransfer, MyDamageType,, Self);
		}

		// Destroy the projectile
		Destroy();
	}
	else
	{
		// Otherwise explode and cause radial damage
		Explode(HitLocation, HitNormal);
	}
}

/**
 * Called when the projectile explodes
 *
 * @param		HitLocation			Where in the world the projectile exploded
 * @param		HitNormal			Direction of the explosion
 */
simulated function Explode(vector HitLocation, vector HitNormal)
{
	// Handle effects
	if (WorldInfo != None && WorldInfo.NetMode != NM_DedicatedServer)
	{
		// Play back the impact sound
		if (ImpactSound != None)
		{
			PlaySound(ImpactSound);
		}

		// Spawn the particle effect
		if (ImpactParticleTemplate != None && WorldInfo.MyEmitterPool != None)
		{
			WorldInfo.MyEmitterPool.SpawnEmitter(ImpactParticleTemplate, HitLocation, Rotator(HitNormal));
		}
	}

	// Super explode!
	Super.Explode(HitLocation, HitNormal);
}

defaultproperties
{
	Begin Object Class=ParticleSystemComponent Name=MyParticleSystemComponent
		SecondsBeforeInactive=1
	End Object
	ParticleSystem=MyParticleSystemComponent
	Components.Add(MyParticleSystemComponent)
}