//=============================================================================
// UDKRTSResource: Actor in the world where units can harvest from
//
// This class represents an actor placed by level designers that units
// can harvest from.
// 
// Copyright 1998-2011 Epic Games, Inc. All Rights Reserved.
//=============================================================================
class UDKRTSResource extends Actor
	DependsOn(UDKRTSUtility)
	Implements(UDKRTSMinimapInterface, UDKRTSHUDActionInterface)
	Placeable;

// Collision cylinder used for this structure
var(Resource) const editconst CylinderComponent CollisionCylinder;
// Static mesh
var(Resource) editconst const StaticMeshComponent StaticMesh;
// How much resources this resource has
var(Resource) const int MaxAmount;
// How many pawns can harvest from this resource at any given time
var(Resource) const int MaxHarvesters;
// Distance from the resource the pawn needs to be to harvest, this should be larger than harvest radius
var(Resource) const float HarvestRadius;
// Distance that path nodes use, this should be smaller than harvest radius
var(Resource) const float PathHarvestRadius;
// How much to give to the pawn when it harvests it
var(Resource) const int ResourceGivenPerHarvest;

// Minimap icon
var(Minimap) const Texture2D ResourceMinimapIcon;
// Minimap icon U coordinates
var(Minimap) const float ResourceMinimapU;
// Minimap icon V coordinates
var(Minimap) const float ResourceMinimapV;
// Minimap icon width
var(Minimap) const float ResourceMinimapUL;
// Minimap icon height
var(Minimap) const float ResourceMinimapVL;

// HUD Action
var(HUD) const SHUDAction Portrait;

// Debug properties
var(Debug) const Color BoundingBoxColor;

// Amount of resources left
var protectedwrite int Amount;
// Number of harvesters harvesting from this resource
var protectedwrite int Harvesters;

// Mobile only
// Screen bounding box for the resource
var Box ScreenBoundingBox;

// Replication block
replication
{
	if (bNetDirty || bNetInitial)
		Amount;
}

/**
 * Called when this actor is first initialized
 */
simulated event PostBeginPlay()
{
	local UDKRTSGameReplicationInfo UDKRTSGameReplicationInfo;

	Super.PostBeginPlay();

	// Add myself to the game replication info for look up purposes
	UDKRTSGameReplicationInfo = UDKRTSGameReplicationInfo(WorldInfo.GRI);
	if (UDKRTSGameReplicationInfo != None)
	{
		UDKRTSGameReplicationInfo.AddResource(Self);
	}
	else
	{
		// Have not yet received the GRI yet, so keep pinging until we have received it
		SetTimer(0.1f, true, NameOf(RetryAddingResourceToGRI));
	}

	// Set the resource amount
	Amount = MaxAmount;
}

/**
 * Continously retry to add the resource to the game replication info. When this succeeds, we clear the timer
 */
simulated function RetryAddingResourceToGRI()
{
	local UDKRTSGameReplicationInfo UDKRTSGameReplicationInfo;
	
	UDKRTSGameReplicationInfo = UDKRTSGameReplicationInfo(WorldInfo.GRI);
	if (UDKRTSGameReplicationInfo != None)
	{
		UDKRTSGameReplicationInfo.AddResource(Self);
		ClearTimer(NameOf(RetryAddingResourceToGRI));
	}
}

/**
 * Returns true if this actor should render onto the minimap
 *
 * @return		Returns true if this actor should render onto the minimap
 */
simulated function bool ShouldRenderMinimapIcon()
{
	return true;
}

/**
 * Outputs the minimap icon
 *
 * @param		MinimapIcon					Returns the minimap icon texture
 * @param		MinimapU					Returns the U coordinates of the minimap icon
 * @param		MinimapV					Returns the V coordinates of the minimap icon
 * @param		MinimapUL					Returns the UL coordinates of the minimap icon
 * @param		MinimapVL					Returns the VL coordinates of the minimap icon
 * @param		MinimapColor				Retusn the color of the minimap icon
 * @param		RenderBlackBorder			Output 1 if you wish to render a black outline for the minimap icon
 */
simulated function GetMinimapIcon(out Texture2D MinimapIcon, out float MinimapU, out float MinimapV, out float MinimapUL, out float MinimapVL, out Color MinimapColor, out byte RenderBlackBorder)
{
	MinimapIcon = ResourceMinimapIcon;
	MinimapU = ResourceMinimapU;
	MinimapV = ResourceMinimapV;
	MinimapUL = ResourceMinimapUL;
	MinimapVL = ResourceMinimapVL;

	if (Amount > 0)
	{
		MinimapColor = class'HUD'.default.WhiteColor;
	}
	else
	{
		MinimapColor.R = 63;
		MinimapColor.G = 63;
		MinimapColor.B = 63;
		MinimapColor.A = 191;
	}

	RenderBlackBorder = 0;
}

/**
 * Registers the resource's HUD action
 *
 * @param		HUD			HUD to register the HUD action
 */
simulated function RegisterHUDAction(UDKRTSMobileHUD HUD)
{
	local SHUDAction SendHUDAction;
	
	// Register the portrait
	if (Portrait.Texture != None)
	{
		SendHUDAction = Portrait;
		SendHUDAction.Reference = EHAR_Center;
		SendHUDAction.Index = -1;
		SendHUDAction.PostRender = true;

		HUD.RegisterHUDAction(Self, SendHUDAction);
	}
}

/**
 * Post renders a HUD action
 *
 * @param		HUD				HUD to render to
 * @param		Reference		HUD action reference
 * @param		Index			HUD action index
 * @param		PosX			X position of the HUD action
 * @param		PosY			Y position of the HUD action
 * @param		SizeX			X size of the HUD action
 * @param		SizeY			Y size of the HUD action
 */
simulated function PostRenderHUDAction(HUD HUD, EHUDActionReference Reference, int Index, int PosX, int PosY, int SizeX, int SizeY)
{
	local float XL, YL;
	local String Text;

	if (HUD == None || class'UDKRTSMobileHUD'.default.HUDProperties == None || HUD.Canvas == None)
	{
		return;
	}

	Text = "$"$Amount;

	HUD.Canvas.Font = class'UDKRTSMobileHUD'.default.HUDProperties.MessagesFont;
	HUD.Canvas.StrLen(Text, XL, YL);
	HUD.Canvas.DrawColor = (Amount > 0) ? class'HUD'.default.WhiteColor : class'HUD'.default.RedColor;	
	HUD.Canvas.SetPos(PosX + SizeX + 4, PosY + (SizeY * 0.5f) - (YL * 0.5f));
	HUD.Canvas.DrawText(Text);
}

/**
 * Called when the structure should handle a HUD action it has registered earlier
 * 
 * @param		Reference		Reference of the HUD action (usually used to identify what kind of HUD action this was)
 * @param		Index			Index of the HUD action (usually to reference inside an array)
 */
simulated function HandleHUDAction(EHUDActionReference Reference, int Index);

/**
 * Returns if the resource can be harvested or not
 */
simulated function bool CanHarvest()
{
	return ((Harvesters < MaxHarvesters || MaxHarvesters == -1) && Amount > 0);
}

/**
 * Called when a pawn is requesting a resources from this resource
 *
 * @param		Pawn		Pawn that is requesting resources
 */
simulated function RequestResource(UDKRTSPawn Pawn)
{
	local int ActualResourceGivenPerHarvest;
	local UDKRTSResourceInventory UDKRTSResourceInventory;

	if (Pawn == None)
	{
		return;
	}

	// Get the actual resource to be given
	ActualResourceGivenPerHarvest = (Amount > ResourceGivenPerHarvest) ? ResourceGivenPerHarvest : Amount;
	Amount -= ActualResourceGivenPerHarvest;

	// Spawn and give the resource inventory to the requesting pawn
	UDKRTSResourceInventory = Spawn(class'UDKRTSResourceInventory');
	if (UDKRTSResourceInventory != None)
	{
		UDKRTSResourceInventory.Resource = ActualResourceGivenPerHarvest;
		UDKRTSResourceInventory.GiveTo(Pawn);
	}
}

defaultproperties
{
	Begin Object Class=CylinderComponent Name=MyCylinderComponent
		CollisionRadius=48.f
		CollisionHeight=144.f
	End Object
	CollisionCylinder=MyCylinderComponent
	Components.Add(MyCylinderComponent)

	Begin Object Class=StaticMeshComponent Name=MyStaticMeshComponent
		bAllowApproximateOcclusion=true
		bForceDirectLightMap=true
		bUsePrecomputedShadows=true
	End Object
	StaticMesh=MyStaticMeshComponent
	CollisionComponent=MyStaticMeshComponent
	Components.Add(MyStaticMeshComponent)

	bNoDelete=true
	bStatic=false
	RemoteRole=ROLE_SimulatedProxy
	NetPriority=4.f
	bUpdateSimulatedPosition=false
	MaxHarvesters=-1
	CollisionType=COLLIDE_TouchAll
	ResourceGivenPerHarvest=5
	BoundingBoxColor=(R=255,G=191,B=0,A=255)
}