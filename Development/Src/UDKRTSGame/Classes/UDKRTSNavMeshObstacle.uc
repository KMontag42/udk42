//=============================================================================
// UDKRTSNavMeshObstacle: Class which creates an obstacle in the navigation
// mesh.
//
// This class is a helper function which creates a wide variety of shapes for 
// creating an obstacle on the navigation mesh.
// 
// Copyright 1998-2011 Epic Games, Inc. All Rights Reserved.
//=============================================================================
class UDKRTSNavMeshObstacle extends NavMeshObstacle;

// Half the width of the obstacle
var PrivateWrite float HalfWidth;
// Half the height of the obstacle
var PrivateWrite float HalfHeight;   
// Has this obstacle registered itself
var PrivateWrite bool HasRegisteredObstacle;

/**
 * Called when this actor is first instanced in the world
 */
simulated function PostBeginPlay()
{
	// Skip default post begin play function
	Super(Actor).PostBeginPlay();
}

/**
 * Registers this obstacle on the navigation mesh
 */
simulated function Register()
{
	if (!HasRegisteredObstacle)
	{
		RegisterObstacle();
		HasRegisteredObstacle = true;
	}
}

/**
 * Unregister this obstacle on the navigation mesg
 */
simulated function Unregister()
{
	if (HasRegisteredObstacle)
	{
		UnregisterObstacle();
		HasRegisteredObstacle = false;
	}
}

/**
 * Returns true if a point is inside the AABB for this shape
 *
 * @param		TestPoint		Point to test
 * @return						Returns true if a point is inside the AABB for this shape
 */
simulated function bool IsPointInside(Vector TestPoint)
{
	// Check that we have a valid width
	if (HalfWidth == 0.f)
	{
		return false;
	}

	// Shape is a square, so test using half width only
	if (HalfHeight == -1.f)
	{
		return (Location.X - HalfWidth <= TestPoint.X && Location.X + HalfWidth >= TestPoint.X && Location.Y - HalfWidth <= TestPoint.Y && Location.Y + HalfWidth >= TestPoint.Y);
	}
	// Shape is a rectangle, so test using both half width and half height
	else
	{
		return (Location.X - HalfWidth <= TestPoint.X && Location.X + HalfWidth >= TestPoint.X && Location.Y - HalfHeight <= TestPoint.Y && Location.Y + HalfHeight >= TestPoint.Y);
	}

	return false;
}

/**
 * Sets the obstacle as a square
 *
 * @param		NewHalfWidth		New half width to set the square
 */
simulated function SetAsSquare(float NewHalfWidth)
{
	if (NewHalfWidth > 0.f)
	{
	    HalfWidth = NewHalfWidth;
		HalfHeight = -1.f;
	}
}

/**
 * Sets the obstacle as a rectangle
 *
 * @param		NewHalfWidth		New half width to set the rectangle
 * @param		NewHalfHeight		New half height to set the rectangle
 */
simulated function SetAsRectangle(float NewHalfWidth, float NewHalfHeight)
{
	if (NewHalfWidth > 0.f && NewHalfHeight > 0.f)
	{
		HalfWidth = NewHalfWidth;
		HalfHeight = NewHalfHeight;
	}
}

/**
 * Returns the obstacle bounding shape as an array of vectors
 *
 * @param		Shape		Shape output coordinates
 */
event bool GetObstacleBoudingShape(out array<vector> Shape)
{
	local Vector Offset;
	
	// HalfWidth must be larger than zero, otherwise abort
	if (HalfWidth <= 0.f)
	{
		return false;
	}

	// Square obstacle
	if (HalfHeight == -1.f)
	{
		// Square obstacle
		// Top right corner
		Offset.X = HalfWidth;
		Offset.Y = HalfWidth;
		Shape.AddItem(Location + Offset);
		// Bottom right corner
		Offset.X = -HalfWidth;
		Offset.Y = HalfWidth;
		Shape.AddItem(Location + Offset);
		// Bottom left corner
		Offset.X = -HalfWidth;
		Offset.Y = -HalfWidth;
		Shape.AddItem(Location + Offset);
		// Top left corner
		Offset.X = HalfWidth;
		Offset.Y = -HalfWidth;
		Shape.AddItem(Location + Offset);
    }
	// Rectangle obstacle
	else
    {
		// Top right corner
		Offset.X = HalfWidth;
		Offset.Y = HalfHeight;
		Shape.AddItem(Location + Offset);
		// Bottom right corner
		Offset.X = -HalfWidth;
		Offset.Y = HalfHeight;
		Shape.AddItem(Location + Offset);
		// Bottom left corner
		Offset.X = -HalfWidth;
		Offset.Y = -HalfHeight;
		Shape.AddItem(Location + Offset);
		// Top left corner
		Offset.X = HalfWidth;
		Offset.Y = -HalfHeight;
		Shape.AddItem(Location + Offset);
    }

	return true;
}

defaultproperties
{
}