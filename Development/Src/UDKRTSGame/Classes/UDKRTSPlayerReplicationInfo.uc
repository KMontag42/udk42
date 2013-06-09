//=============================================================================
// UDKRTSPlayerReplicationInfo: Player replication info used by all players.
//
// This class represents the replication info used by players to keep track
// of things for the player.
// 
// Copyright 1998-2011 Epic Games, Inc. All Rights Reserved.
//=============================================================================
class UDKRTSPlayerReplicationInfo extends PlayerReplicationInfo;

// How much resources the player has
var RepNotify int Resources;
// How much power the player has
var RepNotify int Power;
// Players current population cap
var RepNotify int PopulationCap;

// Replication block
replication
{
	if (bNetDirty && Role == Role_Authority)
		Resources, Power, PopulationCap;
}

/**
 * Sends a world message to the client
 *
 * @param		MessageText			Message text
 * @param		MessageColor		Message color
 * @param		WorldLocation		Location in the world where this event happened
 * @param		MessageIcon			Icon of the message
 * @param		MessageU			Icon coordinate U of the message icon
 * @param		MessageV			Icon coordinate V of the message icon
 * @param		MessageUL			Icon coordinate UL of the message icon
 * @param		MessageVL			Icon coordinate VL of the message icon
 */
unreliable client function ClientWorldMessage(String MessageText, Color MessageColor, Vector WorldLocation, Texture2D MessageIcon, float MessageIconU, float MessageIconV, float MessageIconUL, float MessageIconVL)
{
	ReceiveWorldMessage(MessageText, MessageColor, WorldLocation, MessageIcon, MessageIconU, MessageIconV, MessageIconUL, MessageIconVL);
}

/**
 * Shows a world message which is associated with world location
 *
 * @param		MessageText			Message text
 * @param		MessageColor		Message color
 * @param		WorldLocation		Location in the world where this event happened
 * @param		MessageIcon			Icon of the message
 * @param		MessageU			Icon coordinate U of the message icon
 * @param		MessageV			Icon coordinate V of the message icon
 * @param		MessageUL			Icon coordinate UL of the message icon
 * @param		MessageVL			Icon coordinate VL of the message icon
 */
simulated function ReceiveWorldMessage(String MessageText, Color MessageColor, Vector WorldLocation, Texture2D MessageIcon, float MessageIconU, float MessageIconV, float MessageIconUL, float MessageIconVL)
{
	local PlayerController PlayerController;
	local UDKRTSMobileHUD UDKRTSMobileHUD;
	
	// Get the player controller
	PlayerController = PlayerController(Owner);
	if (PlayerController != None)
	{
		// Get the mobile RTS HUD
		UDKRTSMobileHUD = UDKRTSMobileHUD(PlayerController.MyHUD);
		if (UDKRTSMobileHUD != None)
		{
			UDKRTSMobileHUD.RegisterWorldMessage(MessageText, MessageColor, WorldLocation, MessageIcon, MessageIconU, MessageIconV, MessageIconUL, MessageIconVL);
		}
	}
}

defaultproperties
{
	PopulationCap=15
}