//=============================================================================
// UDKRTSHUDInterface: HUD interface
//
// This interface allows actors to perform rendering calls to the HUD.
// 
// Copyright 1998-2011 Epic Games, Inc. All Rights Reserved.
//=============================================================================
interface UDKRTSHUDInterface;

/**
 * Called from the HUD to perform any post rendering onto the HUD
 *
 * @param		HUD			HUD to perform post rendering onto
 */
simulated function PostRender(HUD HUD);