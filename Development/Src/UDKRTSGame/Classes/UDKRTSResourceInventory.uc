//=============================================================================
// UDKRTSResourceInventory: Inventory which represents resource harvested
// by a unit.
//
// This class represents resources harvested by a unit. This is added as 
// resources can be dropped by units that died.
// 
// Copyright 1998-2011 Epic Games, Inc. All Rights Reserved.
//=============================================================================
class UDKRTSResourceInventory extends Inventory;

// Resource amount
var int Resource;

defaultproperties
{
}