//=============================================================================
// UDKRTSHUDProperties: Base HUD properties class which has most of the core
// properties required for rendering things onto the HUD.
//
// Base class, extend this for specific platforms.
// 
// Copyright 1998-2011 Epic Games, Inc. All Rights Reserved.
//=============================================================================
class UDKRTSHUDProperties extends Object
	HideCategories(Object)
	abstract;

// Coordinate struct
struct SUVCoordinates
{
	var() float U;
	var() float V;
	var() float UL;
	var() float VL;
};

// Time to fade in the game when starting a mission
var(Fade) const float FadeInTime;
// Time to fade out the game when exiting a mission
var(Fade) const float FadeOutTime;

// Minimap border color
var(Minimap) const Color MinimapBorderColor;
// Minimap expand tab color
var(Minimap) const Color MinimapExpandTabColor;
// Minimap color
var(Minimap) const Color MinimapColor;
// Minimap expand tab texture
var(Minimap) const Texture2D MinimapExpandTab;
// Minimap expand tab UV coordinates
var(Minimap) const SUVCoordinates MinimapExpandTabCoordinates;

// Color to use for the resources text
var(Resources) const Color ResourcesTextColor;
// Font to use for the resources font
var(Resources) const Font ResourcesTextFont;
// Color to use for the resources icon
var(Resources) const Color ResourcesIconColor;
// Texture to use for the resources icon
var(Resources) const Texture2D ResourcesIcon;
// Resources icon UV coordinates
var(Resources) const SUVCoordinates ResourcesIconCoordinates;

// Color to use for the power text
var(Power) const Color PowerTextColor;
// Font to use for the power text
var(Power) const Font PowerTextFont;
// Color to use for the power icon
var(Power) const Color PowerIconColor;
// Texture to use for the power icon
var(Power) const Texture2D PowerIcon;
// Power icon UV coordinates
var(Power) const SUVCoordinates PowerIconCoordinates;

// Color to use for the population text
var(Population) const Color PopulationTextColor;
// Font to use for the population text
var(Population) const Font PopulationTextFont;
// Color to use for the population icon
var(Population) const Color PopulationIconColor;
// Texture to use for the population icon
var(Population) const Texture2D PopulationIcon;
// Population icon UV coordinates
var(Population) const SUVCoordinates PopulationIconCoordinates;

// Font to use when showing messages
var(Messages) const Font MessagesFont;
// Life time to use when showing messages
var(Messages) const float MessagesLifeTime;

// Color to display the clock in
var(Clock) const Color ClockColor;
// Clock textures to use when displaying the winding clock
var(Clock) array<Texture2D> ClockTextures;

defaultproperties
{
}