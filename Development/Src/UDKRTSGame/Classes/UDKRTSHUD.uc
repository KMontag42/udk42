//=============================================================================
// UDKRTSHUD: Base HUD class which has most of the core logic for handling an
// RTS game.
//
// Base class, extend this for specific platforms.
// 
// Copyright 1998-2011 Epic Games, Inc. All Rights Reserved.
//=============================================================================
class UDKRTSHUD extends HUD
	DependsOn(UDKRTSUtility);

// HUD actions on the HUD
struct SHUDAction
{
	var() Texture2D Texture;
	var() float U;
	var() float V;
	var() float UL;
	var() float VL;
	var EHUDActionReference Reference;
	var int Index;	
	var bool PostRender;
	var delegate<IsHUDActionActive> IsHUDActionActiveDelegate;
};

// HUD actions that are associated to an actor on the HUD
struct SAssociatedHUDAction
{
	var Actor AssociatedActor;
	var array<SHUDAction> HUDActions;
};

// HUD location message. These are messages that players can touch to shift the camera to 
// somewhere in the world.
struct SHUDLocationMessage
{
	var float Life;
	var Texture2D Icon;
	var float U;
	var float V;
	var float UL;
	var float VL;
	var String Message;
	var Color Color;
	var Vector WorldLocation;
	var Box BoundingBox;
};

// HUD messages
struct SHUDMessage
{
	var String Message;
	var Color Color;
	var float Life;
};

// HUD actions
var array<SAssociatedHUDAction> AssociatedHUDActions;
// Stores all of the HUD messages
var array<SHUDMessage> HUDMessages;
// Currently rendered resources
var int CurrentlyRenderedResources;
// Currently rendered power
var int CurrentlyRenderedPower;
// World location related HUD messages
var array<SHUDLocationMessage> WorldMessages;

/**
 * Returns true if a point is within a bounding box
 *
 * @param		Point				Point (usually in screen space) to test
 * @param		BoundingBox			Bounding box (usually in screen space) to test
 * @return							Returns true if the point is within the bounding box
 */
final static function bool IsPointWithinBox(Vector2D Point, Box BoundingBox)
{
	if (BoundingBox.Min.X == -1.f || BoundingBox.Min.Y == -1.f || BoundingBox.Max.X == -1.f || BoundingBox.Max.Y == -1.f)
	{
		return false;
	}

	return (Point.X >= BoundingBox.Min.X && Point.X <= BoundingBox.Max.X && Point.Y >= BoundingBox.Min.Y && Point.Y <= BoundingBox.Max.Y);
}

/**
 * Draw a text with a border. Useful for drawing white text with a black background to make it stand out all the time. This function
 * is quite expensive on mobile hardware such as the iOS, so you use sparingly.
 *
 * @param		HUD				HUD to draw the text on
 * @param		PositionX		X position on the canvas to draw the text
 * @param		PositionY		Y position on the canvas to draw the text
 * @param		TextColor		Color to draw the text in
 * @param		BorderColor		Color to draw the border in
 */
final static function DrawBorderedText(HUD HUD, int PositionX, int PositionY, String Text, Color TextColor, Color BorderColor)
{
	local FontRenderInfo FontRenderInfo;

	if (HUD == None || HUD.Canvas == None || Text ~= "")
	{
		return;
	}

	FontRenderInfo.bClipText = true;
	HUD.Canvas.DrawColor = BorderColor;
	// Top border
	HUD.Canvas.SetPos(PositionX - 1, PositionY - 1);
	HUD.Canvas.DrawText(Text,,,, FontRenderInfo);
	HUD.Canvas.SetPos(PositionX, PositionY - 1);
	HUD.Canvas.DrawText(Text,,,, FontRenderInfo);
	HUD.Canvas.SetPos(PositionX + 1, PositionY - 1);
	HUD.Canvas.DrawText(Text,,,, FontRenderInfo);
	// Middle border
	HUD.Canvas.SetPos(PositionX - 1, PositionY);
	HUD.Canvas.DrawText(Text,,,, FontRenderInfo);
	HUD.Canvas.SetPos(PositionX + 1, PositionY);
	HUD.Canvas.DrawText(Text,,,, FontRenderInfo);
	// Bottom border
	HUD.Canvas.SetPos(PositionX - 1, PositionY + 1);
	HUD.Canvas.DrawText(Text,,,, FontRenderInfo);
	HUD.Canvas.SetPos(PositionX, PositionY + 1);
	HUD.Canvas.DrawText(Text,,,, FontRenderInfo);
	HUD.Canvas.SetPos(PositionX + 1, PositionY + 1);
	HUD.Canvas.DrawText(Text,,,, FontRenderInfo);
	// Render the text
	HUD.Canvas.SetPos(PositionX, PositionY);
	HUD.Canvas.DrawColor = TextColor;
	HUD.Canvas.DrawText(Text,,,, FontRenderInfo);
}

/**
 * Stub for drawing the clock on the HUD. On the iOS this shows individual textures to drive the animation, on the PC and other shader supported platforms, this would use 
 * the material system for handling the animation.
 *
 * @param		HUD					HUD to draw the clock onto
 * @param		Percentage			Percentage of time left
 * @param		TimeLeft			Actual time left
 * @param		ClockPosX			X position of the clock 
 * @param		ClockPosY			Y position of the clock
 * @param		ClockSizeX			X size of the clock
 * @param		ClockSizeY			Y size of the clock
 */
static simulated function DrawClock(HUD HUD, float Percentage, float TimeLeft, float ClockPosX, float ClockPosY, float ClockSizeX, float ClockSizeY);

/**
 * Calculates the screen bounding box given an actor and a primitive component
 *
 * @param		HUD						HUD providing a valid Canvas so that Project could be used
 * @param		Actor					Actor to find the screen bounding box for
 * @param		PrimitiveComponent		Primitive component to find the screen bounding box for
 * @return								Returns the screen bounding box
 */
function Box CalculateScreenBoundingBox(HUD HUD, Actor Actor, PrimitiveComponent PrimitiveComponent)
{
	local Box ComponentsBoundingBox, OutBox;
	local Vector BoundingBoxCoordinates[8];
	local int i;

	if (HUD == None || PrimitiveComponent == None || Actor == None || WorldInfo.TimeSeconds - Actor.LastRenderTime >= 0.1f)
	{
		OutBox.Min.X = -1.f;
		OutBox.Min.Y = -1.f;
		OutBox.Max.X = -1.f;
		OutBox.Max.Y = -1.f;

		return OutBox;
	}

	ComponentsBoundingBox.Min = PrimitiveComponent.Bounds.Origin - PrimitiveComponent.Bounds.BoxExtent;
	ComponentsBoundingBox.Max = PrimitiveComponent.Bounds.Origin + PrimitiveComponent.Bounds.BoxExtent;

	// Z1
	// X1, Y1
	BoundingBoxCoordinates[0].X = ComponentsBoundingBox.Min.X;
	BoundingBoxCoordinates[0].Y = ComponentsBoundingBox.Min.Y;
	BoundingBoxCoordinates[0].Z = ComponentsBoundingBox.Min.Z;
	BoundingBoxCoordinates[0] = HUD.Canvas.Project(BoundingBoxCoordinates[0]);
	// X2, Y1
	BoundingBoxCoordinates[1].X = ComponentsBoundingBox.Max.X;
	BoundingBoxCoordinates[1].Y = ComponentsBoundingBox.Min.Y;
	BoundingBoxCoordinates[1].Z = ComponentsBoundingBox.Min.Z;
	BoundingBoxCoordinates[1] = HUD.Canvas.Project(BoundingBoxCoordinates[1]);
	// X1, Y2
	BoundingBoxCoordinates[2].X = ComponentsBoundingBox.Min.X;
	BoundingBoxCoordinates[2].Y = ComponentsBoundingBox.Max.Y;
	BoundingBoxCoordinates[2].Z = ComponentsBoundingBox.Min.Z;
	BoundingBoxCoordinates[2] = HUD.Canvas.Project(BoundingBoxCoordinates[2]);
	// X2, Y2
	BoundingBoxCoordinates[3].X = ComponentsBoundingBox.Max.X;
	BoundingBoxCoordinates[3].Y = ComponentsBoundingBox.Max.Y;
	BoundingBoxCoordinates[3].Z = ComponentsBoundingBox.Min.Z;
	BoundingBoxCoordinates[3] = HUD.Canvas.Project(BoundingBoxCoordinates[3]);

	// Z2
	// X1, Y1
	BoundingBoxCoordinates[4].X = ComponentsBoundingBox.Min.X;
	BoundingBoxCoordinates[4].Y = ComponentsBoundingBox.Min.Y;
	BoundingBoxCoordinates[4].Z = ComponentsBoundingBox.Max.Z;
	BoundingBoxCoordinates[4] = HUD.Canvas.Project(BoundingBoxCoordinates[4]);
	// X2, Y1
	BoundingBoxCoordinates[5].X = ComponentsBoundingBox.Max.X;
	BoundingBoxCoordinates[5].Y = ComponentsBoundingBox.Min.Y;
	BoundingBoxCoordinates[5].Z = ComponentsBoundingBox.Max.Z;
	BoundingBoxCoordinates[5] = HUD.Canvas.Project(BoundingBoxCoordinates[5]);
	// X1, Y2
	BoundingBoxCoordinates[6].X = ComponentsBoundingBox.Min.X;
	BoundingBoxCoordinates[6].Y = ComponentsBoundingBox.Max.Y;
	BoundingBoxCoordinates[6].Z = ComponentsBoundingBox.Max.Z;
	BoundingBoxCoordinates[6] = HUD.Canvas.Project(BoundingBoxCoordinates[6]);
	// X2, Y2
	BoundingBoxCoordinates[7].X = ComponentsBoundingBox.Max.X;
	BoundingBoxCoordinates[7].Y = ComponentsBoundingBox.Max.Y;
	BoundingBoxCoordinates[7].Z = ComponentsBoundingBox.Max.Z;
	BoundingBoxCoordinates[7] = HUD.Canvas.Project(BoundingBoxCoordinates[7]);

	// Find the left, top, right and bottom coordinates
	OutBox.Min.X = HUD.Canvas.ClipX;
	OutBox.Min.Y = HUD.Canvas.ClipY;
	OutBox.Max.X = 0;
	OutBox.Max.Y = 0;

	// Iterate though the bounding box coordinates
	for (i = 0; i < ArrayCount(BoundingBoxCoordinates); ++i)
	{
		// Detect the smallest X coordinate
		if (OutBox.Min.X > BoundingBoxCoordinates[i].X)
		{
			OutBox.Min.X = BoundingBoxCoordinates[i].X;
		}

		// Detect the smallest Y coordinate
		if (OutBox.Min.Y > BoundingBoxCoordinates[i].Y)
		{
			OutBox.Min.Y = BoundingBoxCoordinates[i].Y;
		}

		// Detect the largest X coordinate
		if (OutBox.Max.X < BoundingBoxCoordinates[i].X)
		{
			OutBox.Max.X = BoundingBoxCoordinates[i].X;
		}

		// Detect the largest Y coordinate
		if (OutBox.Max.Y < BoundingBoxCoordinates[i].Y)
		{
			OutBox.Max.Y = BoundingBoxCoordinates[i].Y;
		}
	}

	// Check if the bounding box is within the screen
	if ((OutBox.Min.X < 0 && OutBox.Max.X < 0) || (OutBox.Min.X > HUD.Canvas.ClipX && OutBox.Max.X > HUD.Canvas.ClipX) || (OutBox.Min.Y < 0 && OutBox.Max.Y < 0) || (OutBox.Min.Y > HUD.Canvas.ClipY && OutBox.Max.Y > HUD.Canvas.ClipY))
	{
		OutBox.Min.X = -1.f;
		OutBox.Min.Y = -1.f;
		OutBox.Max.X = -1.f;
		OutBox.Max.Y = -1.f;
	}
	else
	{
		// Clamp the bounding box coordinates
		OutBox.Min.X = FClamp(OutBox.Min.X, 0.f, HUD.Canvas.ClipX);
		OutBox.Max.X = FClamp(OutBox.Max.X, 0.f, HUD.Canvas.ClipX);
		OutBox.Min.Y = FClamp(OutBox.Min.Y, 0.f, HUD.Canvas.ClipY);
		OutBox.Max.Y = FClamp(OutBox.Max.Y, 0.f, HUD.Canvas.ClipY);
	}

	return OutBox;
}

/**
 * IsHUDActionActive delegate
 *
 * @param		Reference			HUD action reference
 * @param		Index				HUD action index
 * @param		PlaySound			Set true to play back sounds
 * @return							Returns true if the HUD action is active
 */
simulated delegate bool IsHUDActionActive(EHUDActionReference Reference, int Index, bool PlaySound)
{
	return true;
}

defaultproperties
{
}