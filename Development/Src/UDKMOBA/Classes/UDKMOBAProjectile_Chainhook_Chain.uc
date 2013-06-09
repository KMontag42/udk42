//=============================================================================
// UDKMOBAProjectile_Chainhook_Chain
//
// These are spawned from the Chainhook spell. It is a chain that flies straight at the target
// and then pulls the caster to the target's location upon Touching
//
// Copyright 1998-2012 Epic Games, Inc. All Rights Reserved.
//=============================================================================
class UDKMOBAProjectile_Chainhook_Chain extends UDKMOBAProjectile;

// Damage per level
var(Missile) const array<float> DamageLevel;
// Radius per level
var(Missile) const array<float> RadiusLevel;

// Replicated time to shoot the chain
var RepNotify float ChainTime;
// Desired target location
var RepNotify Vector TargetLocation;
// Calculated location to place the caster
var RepNotify Vector CasterTargetLocation;
// Spell that launched this projectile
var UDKMOBASpell SpellOwner;
// Actor that owns this projectile
var Actor ActorOwner;

// Replication block
replication
{
	if (bNetInitial)
		ChainTime, TargetLocation, CasterTargetLocation;
}

/**
 * Called when the missile is first initialized
 *
 * @network		Server and client
 */
simulated function PostBeginPlay()
{
	Super.PostBeginPlay();

	if (Role == Role_Authority)
	{
		// Play the spawn sound
		if (SpawnSound != None)
		{
			PlaySound(SpawnSound, true);
		}

		ChainTime = 1;
		StartChainTimer();
	}
}

/**
 * Called when a variable flagged with a RepNotify has finished replicated
 *
 * @network		Client
 */
simulated event ReplicatedEvent(Name VarName)
{
	// Homing in time was replicated, start the timer
	if (VarName == NameOf(ChainTime))
	{
		StartChainTimer();
	}
	else
	{
		Super.ReplicatedEvent(VarName);
	}
}

/**
 * Called the Projectile version of Init only
 *
 * @param		Direction		Direction to set the velocity of the projectile
 * @network						Server and client
 */
simulated function Init(Vector Direction)
{
	Super(Projectile).Init(Direction);
}

/**
 * Starts the homing timer
 *
 * @network		Server and client
 */
simulated function StartChainTimer()
{
	WorldInfo.Game.Broadcast(Self, "Hit Ground");
	SetTimer(0.05f, true, NameOf(ChainTimer));
}

/**
 * Called via timer, checks to see if the chain hit its max range, if so, it sends the chain back
 *
 * @network		Server and client
 */
simulated function ChainTimer()
{
	if (VSizeSq(Location - TargetLocation) < 8196.f)
	{
		Explode(Location, vect(0.f, 0.f, 1.f));
		SetPullTimer();
		ClearTimer(NameOf(ChainTimer));
	}
}

/**
 * Called via timer, used to start the timer to pull the caster to the target
 * 
 * @network     Server and client
 */
simulated function SetPullTimer()
{
	SetTimer(0.05f, true, NameOf(PullTimer));
}

/**
 * Called via timer, used to move the caster of the chain to the target of the chain
 * 
 * @network     Server and client
 */
simulated function PullTimer()
{
	
	if (VSizeSq(Location - TargetLocation) < 4096.f)
	{
		ClearTimer(NameOf(PullTimer));
	}
}

/**
 * Stubbed as this functionality is not required for the missile
 *
 * @param		Other			Unused
 * @param		OtherComp		Unused
 * @param		HitLocation		Unused
 * @param		HitNormal		Unused
 * @network						Server and client
 */
simulated event Touch(Actor Other, PrimitiveComponent OtherComp, vector HitLocation, vector HitNormal)
{
	Super.Touch(Other, OtherComp, HitLocation, HitNormal);
	WorldInfo.Game.Broadcast(Self, "Chain touched");
}

/**
 * Stubbed as this functionality is not required for the missile
 *
 * @param		Other			Unused
 * @param		HitLocation		Unused
 * @param		HitNormal		Unused
 * @network						Server and client
 */
simulated function ProcessTouch(Actor Other, Vector HitLocation, Vector HitNormal);

/**
 * Stubbed as this functionality is not required for the missile
 *
 * @param		HitNormal		Unused
 * @param		Wall			Unused
 * @param		WallComp		Unused
 * @network						Server and client
 */
simulated singular event HitWall(vector HitNormal, actor Wall, PrimitiveComponent WallComp);

/**
 * Stubbed as this functionality is not required for the missile
 *
 * @network						Server and client
 */
simulated function DealEnemyDamage();

/**
 * Explodes the projectile
 *
 * @param		HitLocation		World location where the touch occurred
 * @param		HitNormal		Surface normal of the touch
 * @network						Server and client
 */
simulated function Explode(vector HitLocation, vector HitNormal)
{
	local Controller AttackingController;
	local int DamageDone;
	local UDKMOBAPawn Pawn;
	local UDKMOBASpell_Chainhook Chainhook;

	if (Role == Role_Authority && OwnerAttackInterface != None)
	{
		Chainhook = UDKMOBASpell_Chainhook(SpellOwner);
		if (Chainhook != None)
		{
			// at first its the attack owner, then it is each of the targets for the attack during the foreach
			Pawn = UDKMOBAPawn(OwnerAttackInterface);
			if (Pawn != None)
			{
				AttackingController = Pawn.Controller;
				if (AttackingController != None)
				{
					ForEach CollidingActors(class'UDKMOBAPawn', Pawn, RadiusLevel[Chainhook.Level], HitLocation, true)
					{
						if (Pawn.GetTeamNum() != OwnerAttackInterface.GetTeamNum())
						{
							WorldInfo.Game.Broadcast(Self, "Hit Target");
							DamageDone = DamageLevel[Chainhook.Level] * Pawn.GetArmorTypeMultiplier(AttackType);
							Pawn.TakeDamage(DamageDone, AttackingController, Pawn.Location, Vect(0.f, 0.f, 0.f), class'DamageType',, Self);
							ActorOwner.Move(Location - ActorOwner.Location);
						}
					}
				}
			}
		}
	}

	Super.Explode(HitLocation, HitNormal);
}

// Default properties block
defaultproperties
{
	DamageLevel(0) = 100.f;
	DamageLevel(1) = 100.f;
	DamageLevel(2) = 100.f;
	DamageLevel(3) = 100.f;
	RadiusLevel(0) = 5.f;
	RadiusLevel(1) = 5.f;
	RadiusLevel(2) = 5.f;
	RadiusLevel(3) = 5.f;
	bBlockActors = false;
	bCollideActors = true;

	Begin Object Class=CylinderComponent Name=CylinderComp
        CollisionRadius=32
        CollisionHeight=48
        CollideActors=true        
        BlockActors=false
    End Object
    
    Components.Add( CylinderComp )
    CollisionComponent=CylinderComp 
}