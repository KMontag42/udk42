//=============================================================================
// UDKRTSHUDActionInterface: HUD action interface
//
// This interface allows actors to implement HUD actions for themselves. HUD 
// actions are like buttons on the HUD which perform an action for the actor.
// 
// Copyright 1998-2011 Epic Games, Inc. All Rights Reserved.
//=============================================================================
interface UDKRTSHUDActionInterface
	DependsOn(UDKRTSUtility);

/**
 * Handles the HUD action
 *
 * @param			Reference			HUD action command reference
 * @param			Index				HUD action command index
 */
simulated function HandleHUDAction(EHUDActionReference Reference, int Index);

/**
 * Post renders a HUD action
 *
 * @param		HUD				HUD to render to
 * @param		Reference		HUD action reference
 * @param		Index			HUD action index
 * @param		PosX			X position of the HUD action
 * @param		PosY			Y position of the HUD action
 * @param		SizeX			X size of the HUD action
 * @param		SizeY			Y size of the HUD action
 */
simulated function PostRenderHUDAction(HUD HUD, EHUDActionReference Reference, int Index, int PosX, int PosY, int SizeX, int SizeY);