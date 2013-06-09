//=============================================================================
// UDKRTSAIProperties: An object class used to control the AI in general.
//
// This class contains data which the AI uses to control the overall strategy
// it employs.
// 
// Copyright 1998-2011 Epic Games, Inc. All Rights Reserved.
//=============================================================================
class UDKRTSAIProperties extends Object
	HideCategories(Object);

struct SBuildOrder
{
	// How many harvesters the AI needs before it builds this structure
	var() const int RequiredHarvesters;
	// How strong the military needs to be before it build this structure
	var() const float RequiredMilitaryRating;
	// How much resources in reserve the AI needs to have before it builds this structure
	var() const int RequiredResources;
	// How much power in reserve the AI needs to have before it builds this structure
	var() const int RequiredPower;
	// Structure archetype
	var() const archetype UDKRTSStructure Structure;
};

// Structure build order for the AI
var(AI) const archetype array<SBuildOrder> StructureBuildOrder;

defaultproperties
{
}