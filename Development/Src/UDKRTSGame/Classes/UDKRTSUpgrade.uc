//=============================================================================
// UDKRTSUpgrade: A base class where all upgrades are archetyped from.
//
// This class should be archetyped in your content packages. In code you
// check against the archetypes in the player's team to see if the player has
// it or not (this allows players in the same team to share upgrades).
// 
// Copyright 1998-2011 Epic Games, Inc. All Rights Reserved.
//=============================================================================
class UDKRTSUpgrade extends Actor
	DependsOn(UDKRTSMobileHUD);

// Upgrade action
var(Upgrade) const SHUDAction UpgradeAction;
// Time to research this upgrade
var(Upgrade) const float BuildTime;
// This upgrade is a weapon upgrade, this will increase the damage by this percentage; values should be between 0.f and 1.f
var(Upgrade) float UnitWeaponBoost;
// This upgrade is an armor boost, this will reduce damage by this percentage; values should be between 0.f and 1.f
var(Upgrade) float UnitArmourBoost;
// This upgrade is a unit speed boost, this will make units move faster
var(Upgrade) float UnitSpeedBoost;
// Friendly upgrade name
var(Upgrade) const /*localized*/ string FriendlyName;
// Can we have multiple instances of this upgrade
var(Upgrade) const bool AllowedMultipleInstances;

// How much resources this upgrade costs to research
var(Cost) const int ResourcesCost;
// How much power this upgrade costs to research
var(Cost) const int PowerCost;

// The team that owns this upgrade
var repnotify UDKRTSTeamInfo OwnerTeamInfo;
// The player that owns this upgrade
var repnotify UDKRTSPlayerReplicationInfo OwnerReplicationInfo;

replication
{
	if ((bNetDirty || bNetInitial) && Role == Role_Authority)
		OwnerTeamInfo, OwnerReplicationInfo;
}

/**
 * Called when a variable with the property flag "RepNotify" is replicated
 *
 * @param		VarName			Name of the variable which was replicated
 */
simulated event ReplicatedEvent(name VarName)
{
	if (VarName == 'OwnerTeamInfo')
	{
		SetOwnerTeamInfo(OwnerTeamInfo);
	}
	else if (VarName == 'OwnerReplicationInfo')
	{
		// Set the owner replication info
		SetOwnerReplicationInfo(OwnerReplicationInfo);
	}

	Super.ReplicatedEvent(VarName);
}

/**
 * Called when the upgrade owner has been set.
 *
 * @param		OwnerReplicationInfo		Player who researched this upgrade
 */
simulated function SetOwnerReplicationInfo(UDKRTSPlayerReplicationInfo NewOwnerReplicationInfo)
{
	// Abort if an invalid owner replication info was sent
	if (NewOwnerReplicationInfo == None)
	{
		return;
	}

	// Set the owner replication info 
	OwnerReplicationInfo = NewOwnerReplicationInfo;

	if (OwnerReplicationInfo != None)
	{
		// Send the player a message to say he has researched this upgrade
		OwnerReplicationInfo.ReceiveWorldMessage(FriendlyName@"researched.", class'HUD'.default.WhiteColor, Location, UpgradeAction.Texture, UpgradeAction.U, UpgradeAction.V, UpgradeAction.UL, UpgradeAction.VL);
		// Play back the research complete sound
		class'UDKRTSCommanderVoiceOver'.static.PlayResearchCompleteSoundCue(OwnerReplicationInfo);
	}
}

/**
 * Called when the upgrade is instanced, to set who owns this upgrade
 *
 * @param		TeamInfo		Team which owns this upgrade
 */
simulated function SetOwnerTeamInfo(UDKRTSTeamInfo TeamInfo)
{
	// Abort if the team info is none
	// Abort if this upgrade is already owned by TeamInfo
	if (TeamInfo == None)
	{
		return;
	}

	// If somebody owned this upgrade before hand, remove the upgrade from this team.
	// This would allow teams to steal upgrades from each other.
	if (OwnerTeamInfo != None)
	{
		OwnerTeamInfo.RemoveUpgrade(Self);
	}

	// Set the team ower, and add it to the team upgrade array
	OwnerTeamInfo = TeamInfo;
	OwnerTeamInfo.AddUpgrade(Self);
}

/**
 * Returns true if this upgrade can be researched by the requesting player
 *
 * @param		TestUpgradeArchetype			UDKRTSUpgrade archetype to test against
 * @param		TestPlayerReplicationInfo		Player to test against
 * @param		SendMessage						If true, send a message to the player replication info as to why he can't research this upgrade
 * @return										Returns true if this upgrade could be researched
 */
simulated static function bool CanResearchUpgrade(UDKRTSUpgrade TestUpgradeArchetype, UDKRTSPlayerReplicationInfo TestPlayerReplicationInfo, bool SendMessage)
{
	local UDKRTSMobilePlayerController UDKRTSMobilePlayerController;
	local UDKRTSTeamInfo UDKRTSTeamInfo;
	local int i;

	// Check incoming objects
	if (TestUpgradeArchetype == None || TestPlayerReplicationInfo == None)
	{
		return false;
	}

	// Check if we have enough resources
	if (TestPlayerReplicationInfo.Resources < TestUpgradeArchetype.ResourcesCost)
	{
		if (SendMessage)
		{
			class'UDKRTSCommanderVoiceOver'.static.PlayInsufficientResourcesSoundCue(TestPlayerReplicationInfo);

			UDKRTSMobilePlayerController = UDKRTSMobilePlayerController(TestPlayerReplicationInfo.Owner);
			if (UDKRTSMobilePlayerController != None)
			{
				UDKRTSMobilePlayerController.ReceiveMessage("You require "$TestUpgradeArchetype.ResourcesCost - TestPlayerReplicationInfo.Resources$" more resources.");
			}
		}

		return false;
	}

	// Check if we have enough power
	if (TestPlayerReplicationInfo.Power < TestUpgradeArchetype.PowerCost)
	{
		if (SendMessage)
		{
			class'UDKRTSCommanderVoiceOver'.static.PlayInsufficientPowerSoundCue(TestPlayerReplicationInfo);

			UDKRTSMobilePlayerController = UDKRTSMobilePlayerController(TestPlayerReplicationInfo.Owner);
			if (UDKRTSMobilePlayerController != None)
			{
				UDKRTSMobilePlayerController.ReceiveMessage("You require "$TestUpgradeArchetype.PowerCost - TestPlayerReplicationInfo.Power$" more power.");
			}
		}

		return false;
	}	

	// Check if the player already has this upgrade
	if (!TestUpgradeArchetype.AllowedMultipleInstances)
	{
		UDKRTSTeamInfo = UDKRTSTeamInfo(TestPlayerReplicationInfo.Team);
		if (UDKRTSTeamInfo != None && UDKRTSTeamInfo.Upgrades.Length > 0)
		{
			for (i = 0; i < UDKRTSTeamInfo.Upgrades.Length; ++i)
			{
				if (UDKRTSTeamInfo.Upgrades[i] != None && UDKRTSTeamInfo.Upgrades[i].ObjectArchetype == TestUpgradeArchetype)
				{
					return false;
				}
			}
		}
	}

	return true;
}

defaultproperties
{
	RemoteRole=ROLE_SimulatedProxy
	NetPriority=2.f
	bAlwaysRelevant=true
	bReplicateMovement=false
	bOnlyDirtyReplication=true
	AllowedMultipleInstances=false
}