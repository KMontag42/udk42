//=============================================================================
// UDKRTSPalette: Abstract object class which contains colors to use in script.
//
// This class is just a data holding class which contains colors to use.
// 
// Copyright 1998-2011 Epic Games, Inc. All Rights Reserved.
//=============================================================================
class UDKRTSPalette extends Object
	abstract;

// Black color
var const Color BlackColor;
// Yellow color
var const Color YellowColor;
// Magenta color
var const Color MagentaColor;

defaultproperties
{
	BlackColor=(R=0,G=0,B=0,A=255)
	YellowColor=(R=255,G=255,B=0,A=255)
	MagentaColor=(R=255,G=0,B=255,A=255)
}