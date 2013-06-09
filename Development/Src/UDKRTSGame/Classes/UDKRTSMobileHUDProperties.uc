//=============================================================================
// UDKRTSMobileHUDProperties: Mobile HUD properties class which has mobile
// specific properties required for rendering things onto the HUD.
//
// Mobile HUD properties for handling scroll bars and selection groups.
// 
// Copyright 1998-2011 Epic Games, Inc. All Rights Reserved.
//=============================================================================
class UDKRTSMobileHUDProperties extends UDKRTSHUDProperties;

// Scroll bar width in pixels
var(Scrollbars) const int ScrollWidth;
// Scroll bar color for vertical camera panning
var(Scrollbars) const Color ScrollVerticalColor;
// Scroll bar color for horizontal camera panning
var(Scrollbars) const Color ScrollHorizontalColor;
// Scroll bar color for diagonal camera panning
var(Scrollbars) const Color ScrollDiagonalColor;

// Selection group icon
var(SelectionGroup) const Texture2D SelectionGroupIcon;
// Selection group icon coordinates
var(SelectionGroup) const SUVCoordinates SelectionGroupIconCoordinates;
// Selection group icon colors
var(SelectionGroup) const Color SelectionGroupColor;

defaultproperties
{
}