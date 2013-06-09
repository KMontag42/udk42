//=============================================================================
// UDKRTSCameraProperties: Object archetype used to hold camera properties
//
// This class is archetyped to be used for storing camera properties that can
// be modified in Unreal Editor.
// 
// Copyright 1998-2011 Epic Games, Inc. All Rights Reserved.
//=============================================================================
class UDKRTSCameraProperties extends Object
	HideCategories(Object);

// Length of the camera offset
var(CameraProperties) float OffsetLength;
// Direction of the camera offset
var(CameraProperties) Rotator OffsetDirection;
// Minimum zoom level of the camera
var(CameraProperties) float MinimumZoomDistance;
// Maximum zoom level of the camera
var(CameraProperties) float MaximumZoomDistance;

defaultproperties
{
}