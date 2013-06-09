//=============================================================================
// UDKRTSCameraBlockingVolume: Volume used for blocking the camera
//
// This class blocks all camera traces. Used to define the camera plane
// in the world, but also gives level designers more flexibility with the
// terrain topology.
// 
// Copyright 1998-2011 Epic Games, Inc. All Rights Reserved.
//=============================================================================
class UDKRTSCameraBlockingVolume extends BlockingVolume;

defaultproperties
{
	Begin Object Name=BrushComponent0
		CollideActors=True
		BlockActors=True
		BlockZeroExtent=True
		BlockNonZeroExtent=True
		BlockRigidBody=True
	End Object

	CollisionType=COLLIDE_BlockAll
}