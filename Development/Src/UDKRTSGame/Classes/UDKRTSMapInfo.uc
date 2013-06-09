//=============================================================================
// UDKRTSMapInfo: Custom map info used to define various properties for the
// map.
//
// This class is instanced by Unreal Editor, and allows level designers to 
// define various properties.
// 
// Copyright 1998-2011 Epic Games, Inc. All Rights Reserved.
//=============================================================================
class UDKRTSMapInfo extends MapInfo
	HideCategories(Object);

// How much resources to give the player when they first start
var(Map) const int StartingResources;
// How much power to give the player when they first start
var(Map) const int StartingPower;

// Minimap texture
var(Minimap) const Texture2D MinimapTexture;
// Minimap upper bounds
var(Minimap) const Vector MinimapUpperBounds;
// Minimap lower bounds
var(Minimap) const Vector MinimapLowerBounds;

// Set the console type to run the RTS game under, as different platforms have different control schemes
var(Debug) const EConsoleType DebugConsoleType;

/**
 * Returns the UDKRTSMapInfo instance as static function
 *
 * @param		UDKRTSMapInfoInstance		Outputs the UDKRTSMapInfo instance
 * @return									Returns true if a valid UDKRTSMapInfo was grabbed
 */
final static function bool GetUDKRTSMapInfoInstance(out UDKRTSMapInfo UDKRTSMapInfoInstance)
{
	local WorldInfo WorldInfo;

	WorldInfo = class'WorldInfo'.static.GetWorldInfo();
	if (WorldInfo != None)
	{
		UDKRTSMapInfoInstance = UDKRTSMapInfo(WorldInfo.GetMapInfo());
		return (UDKRTSMapInfoInstance != None);
	}

	return false;
}

/**
 * Returns the starting resources defined in UDKRTSMapInfo
 *
 * @return			Returns the starting resources defined in UDKRTSMapInfo
 */
final static function int GetStartingResources()
{
	local UDKRTSMapInfo UDKRTSMapInfo;

	if (class'UDKRTSMapInfo'.static.GetUDKRTSMapInfoInstance(UDKRTSMapInfo))
	{
		return UDKRTSMapInfo.StartingResources;
	}

	return 0;
}

/**
 * Returns the starting power defined in UDKRTSMapInfo
 *
 * @return			Returns the starting power defined in UDKRTSMapInfo
 */
final static function int GetStartingPower()
{
	local UDKRTSMapInfo UDKRTSMapInfo;

	if (class'UDKRTSMapInfo'.static.GetUDKRTSMapInfoInstance(UDKRTSMapInfo))
	{
		return UDKRTSMapInfo.StartingPower;
	}

	return 0;
}

/**
 * Returns the minimap upper bounds defined in the UDKRTSMapInfo
 *
 * @return			Returns the minimap upper bounds defined in UDKRTSMapInfo
 */
final static function Vector GetMinimapUpperBounds()
{
	local UDKRTSMapInfo UDKRTSMapInfo;

	if (class'UDKRTSMapInfo'.static.GetUDKRTSMapInfoInstance(UDKRTSMapInfo))
	{
		return UDKRTSMapInfo.MinimapUpperBounds;
	}

	return Vect(0.f, 0.f, 0.f);
}

/**
 * Returns the minimap lower bounds defined in UDKRTSMapInfo
 *
 * @return			Returns the minimap lower bounds defined in UDKRTSMapInfo
 */
final static function Vector GetMinimapLowerBounds()
{
	local UDKRTSMapInfo UDKRTSMapInfo;

	if (class'UDKRTSMapInfo'.static.GetUDKRTSMapInfoInstance(UDKRTSMapInfo))
	{
		return UDKRTSMapInfo.MinimapLowerBounds;
	}

	return Vect(0.f, 0.f, 0.f);
}

/**
 * Returns the minimap texture defined in UDKRTSMapInfo
 *
 * @return			Returns the minimap texture defined in UDKRTSMapInfo
 */
final static function Texture2D GetMinimapTexture()
{
	local UDKRTSMapInfo UDKRTSMapInfo;

	if (class'UDKRTSMapInfo'.static.GetUDKRTSMapInfoInstance(UDKRTSMapInfo))
	{
		return UDKRTSMapInfo.MinimapTexture;
	}

	return None;
}

defaultproperties
{
}