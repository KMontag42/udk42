//=============================================================================
// UDKRTSCamera: RTS camera
//
// This class represents the camera in the world.
// 
// Copyright 1998-2011 Epic Games, Inc. All Rights Reserved.
//=============================================================================
class UDKRTSCamera extends Camera;

// Archetyped camera properties
var const archetype UDKRTSCameraProperties Properties;
// Current location of the camera
var Vector CurrentLocation;
// Current zoom distance of the camera
var float CurrentZoom;
// Is camera panning north
var bool IsCameraPanningNorth;
// Is camera panning east
var bool IsCameraPanningEast;
// Is camera panning south
var bool IsCameraPanningSouth;
// Is camera panning west
var bool IsCameraPanningWest;
// Camera panning speed
var /*config*/ float CameraPanningSpeed;

/**
 * Called when the camera is initialized for the PC
 *
 * @param		PC			Player controller that is initializing the camera
 */
function InitializeFor(PlayerController PC)
{
	Super.InitializeFor(PC);
	CurrentLocation = PC.Location;
}

/**
 * Updates the camera panning based on the screen touch location
 *
 * @param		ScreenTouchLocation			Touch location in screen space
 */
function UpdateMobileCameraPanningScreenTouchLocation(Vector2D ScreenTouchLocation)
{
	local UDKRTSMobileHUD UDKRTSMobileHUD;

	UDKRTSMobileHUD = UDKRTSMobileHUD(PCOwner.MyHUD);

	if (UDKRTSMobileHUD != None)
	{
		IsCameraPanningNorth = false;
		IsCameraPanningEast = false;
		IsCameraPanningSouth = false;
		IsCameraPanningWest = false;

		if (ScreenTouchLocation.X <= UDKRTSMobileHUD.PlayableSpaceLeft)
		{
			// Handle north, north west, west, south west and south
			if (ScreenTouchLocation.Y >= UDKRTSMobileHUD.FifthScrollSpace.X)
			{
				IsCameraPanningSouth = true;
			}
			else if (ScreenTouchLocation.Y >= UDKRTSMobileHUD.FourthScrollSpace.X)
			{
				IsCameraPanningSouth = true;
				IsCameraPanningWest = true;
			}
			else if (ScreenTouchLocation.Y >= UDKRTSMobileHUD.ThirdScrollSpace.X)
			{
				IsCameraPanningWest = true;
			}
			else if (ScreenTouchLocation.Y >= UDKRTSMobileHUD.SecondScrollSpace.X)
			{
				IsCameraPanningWest = true;
				IsCameraPanningNorth = true;
			}
			else
			{
				IsCameraPanningNorth = true;
			}
		}
		else if (ScreenTouchLocation.X >= UDKRTSMobileHUD.PlayableSpaceRight)
		{
			// Handle north, north east, east, south east and south
			// Handle north, north west, west, south west and south
			if (ScreenTouchLocation.Y >= UDKRTSMobileHUD.FifthScrollSpace.X)
			{
				IsCameraPanningSouth = true;
			}
			else if (ScreenTouchLocation.Y >= UDKRTSMobileHUD.FourthScrollSpace.X)
			{
				IsCameraPanningSouth = true;
				IsCameraPanningEast = true;
			}
			else if (ScreenTouchLocation.Y >= UDKRTSMobileHUD.ThirdScrollSpace.X)
			{
				IsCameraPanningEast = true;
			}
			else if (ScreenTouchLocation.Y >= UDKRTSMobileHUD.SecondScrollSpace.X)
			{
				IsCameraPanningEast = true;
				IsCameraPanningNorth = true;
			}
			else
			{
				IsCameraPanningNorth = true;
			}
		}
	}
}

/**
 * Updates the camera location, rotation and FOV.
 *
 * @param		OutVT			Output view target containing the camera location and rotation
 * @param		DeltaTime		Time since the last update time
 */
function UpdateViewTarget(out TViewTarget OutVT, float DeltaTime)
{
	local Vector CameraPanDelta;
	local Rotator R;

	// If the properties archetype is none, then use parent method
	if (Properties == None)
	{
		Super.UpdateViewTarget(OutVT, DeltaTime);
		return;
	}

	// Handle camera panning
	CameraPanDelta = Vect(0.f, 0.f, 0.f);

	if (IsCameraPanningNorth)
	{
		CameraPanDelta.X = 1.f;
	}
	else if (IsCameraPanningSouth)
	{
		CameraPanDelta.X = -1.f;
	}

	if (IsCameraPanningEast)
	{
		CameraPanDelta.Y = 1.f;
	}
	else if (IsCameraPanningWest)
	{
		CameraPanDelta.Y -= 1.f;
	}

	R.Yaw = Properties.OffsetDirection.Yaw;
	CameraPanDelta = Normal(CameraPanDelta >> R) * CameraPanningSpeed * DeltaTime;
	CurrentLocation += CameraPanDelta;

	// Update the camera location and rotation
	OutVT.POV.Location = CurrentLocation - Vector(Properties.OffsetDirection) * (Properties.OffsetLength + CurrentZoom);
	OutVT.POV.Rotation = Properties.OffsetDirection;
}

/**
 * Zoom out based on the zoom factor
 *
 * @param		ZoomFactor		How much to zoom out by
 */
function ZoomOut(float ZoomFactor)
{
	CurrentZoom = FMin(CurrentZoom + ZoomFactor, Properties.MaximumZoomDistance);
}

/**
 * Zoom in based on the zoom factor
 *
 * @param		ZoomFactor		How much to zoom in by
 */
function ZoomIn(float ZoomFactor)
{
	CurrentZoom = FMax(CurrentZoom - ZoomFactor, -Properties.MinimumZoomDistance);
}

/**
 * Adjusts the location of the camera
 *
 * @param		NewLocation		New location to adjust the camera to
 */
function AdjustLocation(Vector NewLocation)
{
	// Set the location of the player controller. This is to make sure the player can hear the sounds that are happening in game.
	if (PCOwner != None)
	{
		PCOwner.SetLocation(NewLocation);
	}

	// Set the location of the camera
	SetLocation(NewLocation);
}

defaultproperties
{
	CameraPanningSpeed=550.f
	Properties=UDKRTSCameraProperties'UDKRTSGameContent.Archetypes.CameraProperties'
}