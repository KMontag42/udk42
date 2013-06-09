//=============================================================================
// UDKRTSMinimapInterface: Minimap interface
//
// This interface allows actors to suggest their own minimap icons on the 
// players minimap.
//
// Copyright 1998-2011 Epic Games, Inc. All Rights Reserved.
//=============================================================================
interface UDKRTSMinimapInterface;

/**
 * Returns true if this actor should render onto the minimap
 *
 * @return		Returns true if this actor should render onto the minimap
 */
simulated function bool ShouldRenderMinimapIcon();

/**
 * Returns the mini map icon
 *
 * @param		MinimapIcon			Returns the minimap texture to use
 * @param		MinimapU			Returns the U coordinate within the texture to use
 * @param		MinimapV			Returns the V coordinate within the texture to use
 * @param		MinimapUL			Returns the UL coordinate within the texture to use
 * @param		MinimapVL			Returns the VL coordinate within the texture to use
 * @param		MinimapColor		Returns the color of the minimap icon to use
 * @param		RenderBlackBorder	Returns whether the minimap icon should render with a black border or not
 */
simulated function GetMinimapIcon(out Texture2D MinimapIcon, out float MinimapU, out float MinimapV, out float MinimapUL, out float MinimapVL, out Color MinimapColor, out byte RenderBlackBorder);