//=============================================================================
// UDKRTSUtility: An abstract utility object which exposes handy functions
// to all classes.
//
// Copyright 1998-2011 Epic Games, Inc. All Rights Reserved.
//=============================================================================
class UDKRTSUtility extends Object
	abstract;

enum EHUDActionReference
{
	EHAR_Center,
	EHAR_Move,
	EHAR_Build,
	EHAR_Building,
	EHAR_Skill,
	EHAR_Upgrade,
	EHAR_Research,
	EHAR_Researching,
	EHAR_Repair,
};

var const Box NullBoundingBox;

/**
 * Returns true if the HUD action needs to sync with the server
 *
 * @param		Reference		HUD action reference
 * @return						Returns true if the HUD action needs to sync with the server
 */
static function bool HUDActionNeedsToSyncWithServer(EHUDActionReference Reference)
{
	switch (Reference)
	{
	case EHAR_Center:
		return false;

	case EHAR_Move:
	case EHAR_Build:
	case EHAR_Building:
	case EHAR_Skill:
	case EHAR_Upgrade:
	case EHAR_Research:
	case EHAR_Researching:
	case EHAR_Repair:
		return true;

	default:
		return false;
	}
}

/**
 * Returns the length between two vectors
 *
 * @param		A		Vector A
 * @param		B		Vector B
 * @return				Returns the length between two vectors
 */
final static function float VSizeVector2D(Vector2D A, Vector2D B)
{
	return Sqrt(Square(A.X - B.X) + Square(A.Y - B.Y));
}

/**
 * Returns the squared length between two vectors
 *
 * @param		A		Vector A
 * @param		B		Vector B
 * @return				Returns the length between two vectors
 */
final static function float VSizeVector2DSq(Vector2D A, Vector2D B)
{
	return Square(A.X - B.X) + Square(A.Y - B.Y);
}

defaultproperties
{
	NullBoundingBox=(Min=(X=-1.f,Y=-1.f),Max=(X=-1.f,Y=-1.f))
}