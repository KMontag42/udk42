//=============================================================================
// UDKRTSMobilePlayerController: Mobile RTS player controller which uses the
// touch pad to control the RTS game.
//
// Mobile player controller which integrates that touch pad as the main control
// device for controlling this game.
// 
// Copyright 1998-2011 Epic Games, Inc. All Rights Reserved.
//=============================================================================
class UDKRTSMobilePlayerController extends UDKRTSPlayerController;

// Touch response of the touch pad
enum ETouchResponse 
{
	ETR_None,
	ETR_Camera,
	ETR_CameraZoomA,
	ETR_CameraZoomB,
	ETR_CameraPanning,
	ETR_Pawn,
	ETR_Vehicle,
	ETR_Resource,
	ETR_Structure,
	ETR_HUDAction,
	ETR_MinimapExpand,
	ETR_Minimap,
	ETR_SelectionGroup_0,
	ETR_SelectionGroup_1,
	ETR_SelectionGroup_2,
	ETR_SelectionGroup_3,
	ETR_SelectionGroup_4,
	ETR_SelectionGroup_5,
	ETR_SelectionGroup_6,
	ETR_SelectionGroup_7,
	ETR_SelectionGroup_8,
	ETR_SelectionGroup_9,
	ETR_DeferTouch
};

// Data about the touch event
struct STouchEvent
{
	// Handle which identifies this touch event
	var int Handle;
	// Which touch pad this event originated from
	var byte TouchpadIndex;
	// Game's response to this touch
	var ETouchResponse Response;
	// Screen location where this touch data originated from
	var Vector2D OriginScreenLocation;
	// Current screen location of the touch
	var Vector2D CurrentScreenLocation;
	// Device time stamp when this touch event occurred
	var float DeviceTimeStamp;
	// Has this touch event been processed?
	var bool Processed;
	// Associated actor with this touch event
	var Actor AssociatedActor;
	// This handle is unique
	var bool HandleIsUnique;
};

// Selection group
struct SSelectionGroup
{
	var array<Actor> GroupedActors;
};

// All of the current touch events
var array<STouchEvent> TouchEvents;
// All of the selection groups
var SSelectionGroup SelectionGroup[10];
// Zoom sensitivity
var float ZoomSensitivity;
// Base camera zoom distance
var float CurrentCameraZoomDistance;

/**
 * Called when the player controller initializes its input system
 */
event InitInputSystem()
{
	local MobilePlayerInput MobilePlayerInput;

	Super.InitInputSystem();

	if (PlayerInput != None)
	{		
		MobilePlayerInput = MobilePlayerInput(PlayerInput);
		if (MobilePlayerInput != None)
		{
			MobilePlayerInput.OnInputTouch = InternalOnInputTouch;
		}
	}
}

/**
 * Calling this simulates a HUD action command
 *
 * @param		HUDActionIndex			HUD action command index
 */
exec function PressButton(byte HUDActionIndex)
{
	local UDKRTSMobileHUD UDKRTSMobileHUD;

	// Ensure that we have a valid Mobile HUD and the HUDActionIndex is valid
	UDKRTSMobileHUD = UDKRTSMobileHUD(MyHUD);
	if (UDKRTSMobileHUD != None && UDKRTSMobileHUD.AssociatedHUDActions.Length > 0 && UDKRTSMobileHUD.AssociatedHUDActions[0].HUDActions.Length > 0 && HUDActionIndex >= 0 && HUDActionIndex < UDKRTSMobileHUD.AssociatedHUDActions[0].HUDActions.Length)
	{
		if (UDKRTSMobileHUD.AssociatedHUDActions[0].HUDActions[HUDActionIndex].IsHUDActionActiveDelegate != None)
		{
			UDKRTSMobileHUD.IsHUDActionActive = UDKRTSMobileHUD.AssociatedHUDActions[0].HUDActions[HUDActionIndex].IsHUDActionActiveDelegate;
			if (!UDKRTSMobileHUD.IsHUDActionActive(UDKRTSMobileHUD.AssociatedHUDActions[0].HUDActions[HUDActionIndex].Reference, UDKRTSMobileHUD.AssociatedHUDActions[0].HUDActions[HUDActionIndex].Index, true))
			{
				// Null the delegate
				UDKRTSMobileHUD.IsHUDActionActive = None;
				return;
			}
			else
			{
				// Null the delegate
				UDKRTSMobileHUD.IsHUDActionActive = None;
			}
		}

		StartHUDAction(UDKRTSMobileHUD.AssociatedHUDActions[0].HUDActions[HUDActionIndex].Reference, UDKRTSMobileHUD.AssociatedHUDActions[0].HUDActions[HUDActionIndex].Index, UDKRTSMobileHUD.AssociatedHUDActions[0].AssociatedActor);
	}
}

/**
 * Called every time this player controller should be updated
 *
 * @param		DeltaTime		Time since the last update
 */
simulated function PlayerTick(float DeltaTime)
{
	local bool FoundEnemiesInTheBase;
	local Actor Actor;
	local UDKRTSTargetInterface UDKRTSTargetInterface;
	local UDKRTSTeamInfo UDKRTSTeamInfo;
	local int i;

	// Check to see if any enemies are entering the players base
	UDKRTSTeamInfo = UDKRTSTeamInfo(PlayerReplicationInfo.Team);
	if (UDKRTSTeamInfo != None)
	{
		FoundEnemiesInTheBase = false;
		for (i = 0; i < UDKRTSTeamInfo.Structures.Length; ++i)
		{
			if (UDKRTSTeamInfo.Structures[i] != None)
			{
				ForEach VisibleCollidingActors(class'Actor', Actor, 512.f, UDKRTSTeamInfo.Structures[i].Location, true,, true, class'UDKRTSTargetInterface')
				{
					UDKRTSTargetInterface = UDKRTSTargetInterface(Actor);
					if (UDKRTSTargetInterface != None && UDKRTSTargetInterface.IsValidTarget(UDKRTSTeamInfo))
					{
						if (!HasEnemiesInTheBase && WorldInfo.TimeSeconds >= NextEnemyApproachingInterval)
						{
							class'UDKRTSCommanderVoiceOver'.static.PlayEnemyApproachingSoundCue(PlayerReplicationInfo);
							NextEnemyApproachingInterval = WorldInfo.TimeSeconds + 15.f;
						}

						HasEnemiesInTheBase = true;
						FoundEnemiesInTheBase = true;
						break;
					}
				}
			}

			if (FoundEnemiesInTheBase)
			{
				break;
			}
		}

		if (!FoundEnemiesInTheBase)
		{
			HasEnemiesInTheBase = false;
			NextEnemyApproachingInterval = 0.f;
		}
	}
}

/**
 * Called when an actor is destroyed
 *
 * @param		Actor		Actor that was destroyed
 */
simulated function NotifyActorDestroyed(Actor Actor)
{
	local int i, j;

	Super.NotifyActorDestroyed(Actor);

	// Remove the actor from the group actor array's.
	for (i = 0; i < ArrayCount(SelectionGroup); ++i)
	{
		if (SelectionGroup[i].GroupedActors.Length > 0)
		{
			for (j = 0; j < SelectionGroup[i].GroupedActors.Length; ++j)
			{
				if (SelectionGroup[i].GroupedActors[j] == Actor)
				{
					SelectionGroup[i].GroupedActors.Remove(j, 1);
					--j;
				}
			}
		}
	}
}

/**
 * Handles input touches
 *
 * @param		Handle					Touch input handle
 * @param		Type					Input input type
 * @param		TouchLocation			Location in screen space where the touch occured
 * @param		DeviceTimestamp			When the touch event occured
 * @param		TouchpadIndex			Index of the touch pad if there are multiple touchpads
 */
function InternalOnInputTouch(int Handle, ETouchType Type, Vector2D TouchLocation, float DeviceTimestamp, int TouchpadIndex)
{
	local STouchEvent TouchEvent;
	local int Index, i;
	local UDKRTSMobileHUD UDKRTSMobileHUD;
	local UDKRTSCamera UDKRTSCamera;
	local UDKRTSPawn UDKRTSPawn;
	local UDKRTSStructure UDKRTSStructure;
	local UDKRTSTeamInfo UDKRTSTeamInfo;
	local UDKRTSGameReplicationInfo UDKRTSGameReplicationInfo;
	local UDKRTSResource UDKRTSResource;
	local bool InsertedActorIntoSelectionGroup;

	// Check to see if this touch event has been handled before hand
	Index = TouchEvents.Find('Handle', Handle);
	if (Index != INDEX_NONE)
	{
		// This touch event was an update, process the update
		if (Type == Touch_Moved)
		{
			// If the touch event is unique the process it first
			if (TouchEvents[Index].HandleIsUnique)
			{
				ProcessInputTouch(Index, Handle, Type, TouchLocation, DeviceTimestamp, TouchpadIndex);
			}
			else
			{
				// For all touch events that have this matching handle, process them
				for (i = 0; i < TouchEvents.Length; ++i)
				{
					if (TouchEvents[i].Handle == Handle)
					{
						ProcessInputTouch(i, Handle, Type, TouchLocation, DeviceTimestamp, TouchpadIndex);
					}
				}
			}
		}
		// This touch event was an untouch or cancelled
		else if (Type == Touch_Ended || Type == Touch_Cancelled)
		{
			// For all touch events process them and then remove them. Continue doing this until no more
			// touch events match this handle.
			while (Index != INDEX_NONE)
			{
				ProcessInputTouch(Index, Handle, Type, TouchLocation, DeviceTimestamp, TouchpadIndex);
				Index = TouchEvents.Find('Handle', Handle);
			}
		}
	}
	// Handle new touch events
	else if (Type == Touch_Began)
	{
		// This touch input is a new touch event; create it and add it to the touch events array
		TouchEvent.Handle = Handle;
		TouchEvent.TouchpadIndex = TouchpadIndex;		
		TouchEvent.OriginScreenLocation = TouchLocation;
		TouchEvent.CurrentScreenLocation = TouchLocation;
		TouchEvent.DeviceTimeStamp = DeviceTimestamp;
		TouchEvent.Processed = false;
		TouchEvent.Response = ETR_None;
		TouchEvent.HandleIsUnique = true;

		// If this touch was for a HUD Action, then just trigger the HUD action
		UDKRTSMobileHUD = UDKRTSMobileHUD(MyHUD);
		if (UDKRTSMobileHUD != None)
		{
			TouchEvent.Response = UDKRTSMobileHUD.InputTouch(TouchLocation);

			if (TouchEvent.Response == ETR_None)
			{
				if (TouchLocation.X > UDKRTSMobileHUD.PlayableSpaceLeft && TouchLocation.X < UDKRTSMobileHUD.PlayableSpaceRight)
				{
					// Check if we touch any game play relevant objects
					if (PlayerReplicationInfo != None)
					{
						UDKRTSTeamInfo = UDKRTSTeamInfo(PlayerReplicationInfo.Team);			
						if (UDKRTSTeamInfo != None)
						{
							UDKRTSMobileHUD = UDKRTSMobileHUD(MyHUD);
							if (UDKRTSMobileHUD != None)
							{
								// Are we touching a pawn?
								if (TouchEvent.Response == ETR_None && UDKRTSTeamInfo.Pawns.Length > 0)
								{
									for (i = 0; i < UDKRTSTeamInfo.Pawns.Length; ++i)
									{
										if (UDKRTSTeamInfo.Pawns[i] != None && class'UDKRTSMobileHUD'.static.IsPointWithinBox(TouchLocation, UDKRTSTeamInfo.Pawns[i].ScreenBoundingBox) && TouchEvents.Find('AssociatedActor', UDKRTSTeamInfo.Pawns[i]) == INDEX_NONE)
										{
											UDKRTSTeamInfo.Pawns[i].Selected();
											UDKRTSTeamInfo.Pawns[i].RegisterHUDActions(UDKRTSMobileHUD);

											TouchEvent.AssociatedActor = UDKRTSTeamInfo.Pawns[i];
											TouchEvent.Response = ETR_Pawn;
											break;
										}
									}
								}

								// Are we touching a structure
								if (TouchEvent.Response == ETR_None && UDKRTSTeamInfo.Structures.Length > 0)
								{
									for (i = 0; i < UDKRTSTeamInfo.Structures.Length; ++i)
									{
										if (class'UDKRTSMobileHUD'.static.IsPointWithinBox(TouchLocation, UDKRTSTeamInfo.Structures[i].ScreenBoundingBox) && TouchEvents.Find('AssociatedActor', UDKRTSTeamInfo.Structures[i]) == INDEX_NONE)
										{
											UDKRTSTeamInfo.Structures[i].Selected();
											UDKRTSTeamInfo.Structures[i].RegisterHUDActions(UDKRTSMobileHUD);

											TouchEvent.AssociatedActor = UDKRTSTeamInfo.Structures[i];
											TouchEvent.Response = ETR_Structure;
											break;
										}
									}
								}
							}
						}
					}

					// Are we touching a resource?
					if (TouchEvent.Response == ETR_None)
					{
						UDKRTSGameReplicationInfo = UDKRTSGameReplicationInfo(WorldInfo.GRI);

						if (UDKRTSGameReplicationInfo != None)
						{
							for (i = 0; i < UDKRTSGameReplicationInfo.Resources.Length; ++i)
							{
								if (class'UDKRTSMobileHUD'.static.IsPointWithinBox(TouchLocation, UDKRTSGameReplicationInfo.Resources[i].ScreenBoundingBox))
								{
									TouchEvent.AssociatedActor = UDKRTSGameReplicationInfo.Resources[i];
									TouchEvent.Response = ETR_Resource;
									break;
								}
							}
						}
					}

					if (TouchEvent.Response == ETR_None)
					{
						// If we're currently panning the camera, then we disable other camera controls
						// If we're currently panning the camera via the minimap, then we disable other camera controls
						if (TouchEvents.Find('Response', ETR_CameraPanning) != INDEX_NONE || TouchEvents.Find('Response', ETR_Minimap) != INDEX_NONE)
						{
							return;
						}
						else
						{
							// If w'ere zooming the camera in and out already, then ignore
							if (TouchEvents.Find('Response', ETR_CameraZoomA) != INDEX_NONE && TouchEvents.Find('Response', ETR_CameraZoomB) != INDEX_NONE)
							{
								return;
							}

							TouchEvent.Response = ETR_Camera;

							// If an existing camera touch event exists, then the player wants to zoom in and out
							Index = TouchEvents.Find('Response', ETR_Camera);
							if (Index != INDEX_NONE)
							{
								// Check if this is a third finger trying to apply zoom
								if (TouchEvents.Find('Response', ETR_CameraZoomB) == INDEX_NONE)
								{
									// Change the touch event response for the previous camera to a camera zoom
									TouchEvents[Index].Response = ETR_CameraZoomA;
									UDKRTSMobileHUD = UDKRTSMobileHUD(MyHUD);
									if (UDKRTSMobileHUD != None)
									{
										UDKRTSMobileHUD.CameraPanningTouchEventIndex = -1;
									}

									UDKRTSCamera = UDKRTSCamera(PlayerCamera);
									if (UDKRTSCamera != None)
									{
										UDKRTSCamera.AdjustLocation(UDKRTSCamera.CurrentLocation);
									}

									// Set the touch event response
									TouchEvent.Response = ETR_CameraZoomB;
									// Set the base camera distance zoom
									CurrentCameraZoomDistance = class'UDKRTSUtility'.static.VSizeVector2D(TouchEvents[Index].CurrentScreenLocation, TouchLocation);
								}
								else
								{
									return;
								}
							}
						}
					}

					TouchEvents.AddItem(TouchEvent);

					switch (TouchEvent.Response)
					{
					case ETR_Camera:
						UDKRTSMobileHUD.CameraPanningTouchEventIndex = TouchEvents.Length - 1;
						break;

					case ETR_Resource:
						UDKRTSMobileHUD = UDKRTSMobileHUD(MyHUD);
						if (UDKRTSMobileHUD != None)
						{
							UDKRTSResource = UDKRTSResource(TouchEvent.AssociatedActor);
							if (UDKRTSResource != None)
							{
								UDKRTSResource.RegisterHUDAction(UDKRTSMobileHUD);
							}
						}
						break;

					default:
						break;
					}
				}
				else
				{
					// If we're already panning via the minimap, we disable edge panning
					// If we're already panning via the finger panning, we disable edge panning
					if (TouchEvents.Find('Response', ETR_Camera) != INDEX_NONE || TouchEvents.Find('Response', ETR_Minimap) != INDEX_NONE)
					{
						return;
					}
					else if (TouchEvents.Find('Response', ETR_CameraPanning) == INDEX_NONE)
					{
						// Handle camera panning as the user touches the edges
						// Figure out the direction we're panning
						UDKRTSCamera = UDKRTSCamera(PlayerCamera);

						if (UDKRTSCamera != None)
						{
							UDKRTSCamera.UpdateMobileCameraPanningScreenTouchLocation(TouchLocation);
							TouchEvent.Response = ETR_CameraPanning;
							TouchEvents.AddItem(TouchEvent);
						}
					}
				}
			}
			else if (TouchEvent.Response == ETR_HUDAction)
			{
				// Do nothing
			}
			else if (TouchEvent.Response == ETR_MinimapExpand)
			{
				TouchEvents.AddItem(TouchEvent);
			}
			else if (TouchEvent.Response == ETR_Minimap)
			{
				TouchEvents.AddItem(TouchEvent);
			}
			else
			{
				Index = -1;
				switch (TouchEvent.Response)
				{
				case ETR_SelectionGroup_0:
					Index = 0;
					break;

				case ETR_SelectionGroup_1:
					Index = 1;
					break;

				case ETR_SelectionGroup_2:
					Index = 2;
					break;

				case ETR_SelectionGroup_3:
					Index = 3;
					break;

				case ETR_SelectionGroup_4:
					Index = 4;
					break;

				case ETR_SelectionGroup_5:
					Index = 5;
					break;

				case ETR_SelectionGroup_6:
					Index = 6;
					break;

				case ETR_SelectionGroup_7:
					Index = 7;
					break;

				case ETR_SelectionGroup_8:
					Index = 8;
					break;

				case ETR_SelectionGroup_9:
					Index = 9;
					break;

				default:
					break;
				}

				if (Index >= 0 && Index < ArrayCount(SelectionGroup))
				{
					InsertedActorIntoSelectionGroup = false;

					// Check if we're touch any pawns
					for (i = 0; i < TouchEvents.Length; ++i)
					{
						if ((TouchEvents[i].Response == ETR_Pawn || TouchEvents[i].Response == ETR_Structure) && UDKRTSGroupableInterface(TouchEvents[i].AssociatedActor) != None)
						{
							AddActorToSelectionGroup(Index, TouchEvents[i].AssociatedActor);
							InsertedActorIntoSelectionGroup = true;
						}
					}

					// Didn't insert any actors, that means we want to use the selection group
					if (!InsertedActorIntoSelectionGroup)
					{
						UDKRTSMobileHUD = UDKRTSMobileHUD(MyHUD);

						if (UDKRTSMobileHUD != None)
						{
							for (i = 0; i < SelectionGroup[Index].GroupedActors.Length; ++i)
							{
								UDKRTSPawn = UDKRTSPawn(SelectionGroup[Index].GroupedActors[i]);
								if (UDKRTSPawn != None)
								{
									UDKRTSPawn.Selected();
									UDKRTSPawn.RegisterHUDActions(UDKRTSMobileHUD);

									TouchEvent.HandleIsUnique = false;
									TouchEvent.AssociatedActor = UDKRTSPawn;
									TouchEvent.Response = ETR_Pawn;
									TouchEvents.AddItem(TouchEvent);
								}
								else
								{
									UDKRTSStructure = UDKRTSStructure(SelectionGroup[Index].GroupedActors[i]);
									if (UDKRTSStructure != None)
									{
										UDKRTSStructure.Selected();
										UDKRTSStructure.RegisterHUDActions(UDKRTSMobileHUD);

										TouchEvent.HandleIsUnique = false;
										TouchEvent.AssociatedActor = UDKRTSStructure;
										TouchEvent.Response = ETR_Structure;
										TouchEvents.AddItem(TouchEvent);
									}
								}
							}
						}
					}
				}
			}
		}
	}
}

/**
 * Processes an input touch event
 *
 * @param		Index					Index of the touch event
 * @param		Handle					Touch input handle
 * @param		Type					Input input type
 * @param		TouchLocation			Location in screen space where the touch occured
 * @param		DeviceTimestamp			When the touch event occured
 * @param		TouchpadIndex			Index of the touch pad if there are multiple touchpads
 */
function ProcessInputTouch(int Index, int Handle, ETouchType Type, Vector2D TouchLocation, float DeviceTimestamp, int TouchpadIndex)
{
	local int SecondIndex, i;
	local UDKRTSMobileHUD UDKRTSMobileHUD;
	local UDKRTSCamera UDKRTSCamera;
	local UDKRTSPawn UDKRTSPawn;
	local UDKRTSGameReplicationInfo UDKRTSGameReplicationInfo;
	local UDKRTSStructure UDKRTSStructure;
	local Vector WorldLocation;
	local bool HasSetRallyPoint;

	if (Index >= 0 && Index < TouchEvents.Length)
	{
		// This touch input is updating a touch event
		TouchEvents[Index].DeviceTimestamp = DeviceTimestamp;		

		if (Type == Touch_Moved)
		{
			if (TouchEvents[Index].Response != ETR_Camera)
			{
				UDKRTSCamera = UDKRTSCamera(PlayerCamera);
				if (UDKRTSCamera != None)
				{
					UDKRTSCamera.UpdateMobileCameraPanningScreenTouchLocation(TouchLocation);
				}
			}

			switch (TouchEvents[Index].Response)
			{			
			// Handle a touch update with the camera
			case ETR_Camera:
				TouchEvents[Index].CurrentScreenLocation = TouchLocation;
				TouchEvents[Index].Processed = false;
				break;

			// Handle a touch update with the camera zoom
			case ETR_CameraZoomA:
				SecondIndex = TouchEvents.Find('Response', ETR_CameraZoomB);
				if (SecondIndex != INDEX_NONE)
				{
					HandleCameraZoomTouchEvent(TouchEvents[Index].CurrentScreenLocation, TouchEvents[SecondIndex].CurrentScreenLocation);
				}

				TouchEvents[Index].CurrentScreenLocation = TouchLocation;
				break;

			// Handle a touch update with the camera zoom
			case ETR_CameraZoomB:
				SecondIndex = TouchEvents.Find('Response', ETR_CameraZoomA);
				if (SecondIndex != INDEX_NONE)
				{
					HandleCameraZoomTouchEvent(TouchEvents[Index].CurrentScreenLocation, TouchEvents[SecondIndex].CurrentScreenLocation);
				}

				TouchEvents[Index].CurrentScreenLocation = TouchLocation;
				break;

			// Handle a touch update with the minimap expand
			case ETR_MinimapExpand:
				UDKRTSMobileHUD = UDKRTSMobileHUD(MyHUD);
				if (UDKRTSMobileHUD != None)
				{
					UDKRTSMobileHUD.DesiredMinimapSize = TouchEvents[Index].OriginScreenLocation - TouchLocation;
					TouchEvents[Index].CurrentScreenLocation = TouchLocation;
				}
				break;

			// Handle a touch update with the minimap
			case ETR_Minimap:
				UDKRTSMobileHUD = UDKRTSMobileHUD(MyHUD);
				if (UDKRTSMobileHUD != None)
				{
					UDKRTSCamera = UDKRTSCamera(PlayerCamera);
					if (UDKRTSCamera != None)
					{
						WorldLocation = UDKRTSMobileHUD.ConvertMinimapPositionToWorldLocation(TouchLocation);
						UDKRTSCamera.CurrentLocation.X = WorldLocation.X;
						UDKRTSCamera.CurrentLocation.Y = WorldLocation.Y;
						TouchEvents[Index].CurrentScreenLocation = TouchLocation;
					}
				}
				break;

			default:
				TouchEvents[Index].CurrentScreenLocation = TouchLocation;
				break;
			}			
		}
		else if (Type == Touch_Ended || Type == Touch_Cancelled)
		{
			// Update the camera 
			if (TouchEvents[Index].Response != ETR_Camera)
			{
				UDKRTSCamera = UDKRTSCamera(PlayerCamera);
				if (UDKRTSCamera != None)
				{
					UDKRTSCamera.IsCameraPanningNorth = false;
					UDKRTSCamera.IsCameraPanningEast = false;
					UDKRTSCamera.IsCameraPanningSouth = false;
					UDKRTSCamera.IsCameraPanningWest = false;
					UDKRTSCamera.AdjustLocation(UDKRTSCamera.CurrentLocation);
				}
			}

			switch (TouchEvents[Index].Response)
			{
			// Handle an untouch or cancelled event with the camera
			// Handle an untouch or cancelled event with the camera
			case ETR_CameraZoomA:
			case ETR_CameraZoomB:
				break;

			// Handle an untouch or cancelled event with the camera
			case ETR_Camera:
				UDKRTSMobileHUD = UDKRTSMobileHUD(MyHUD);
				if (UDKRTSMobileHUD != None)
				{					
					UDKRTSMobileHUD.CameraPanningTouchEventIndex = -1;
				}

				UDKRTSCamera = UDKRTSCamera(PlayerCamera);
				if (UDKRTSCamera != None)
				{
					UDKRTSCamera.AdjustLocation(UDKRTSCamera.CurrentLocation);
				}
				break;

			// Handle an untouch or cancelled event with the pawn
			case ETR_Pawn:
				UDKRTSPawn = UDKRTSPawn(TouchEvents[Index].AssociatedActor);
				if (UDKRTSPawn != None)
				{
					UDKRTSMobileHUD = UDKRTSMobileHUD(MyHUD);
					if (UDKRTSMobileHUD != None)
					{
						UDKRTSMobileHUD.UnregisterHUDAction(UDKRTSPawn);
					}

					if (UDKRTSPawn.CommandMesh != None)
					{
						UDKRTSPawn.CommandMesh.SetHidden(true);
					}

					UDKRTSPawn.Deselected();
					UDKRTSPawn.PendingScreenCommandLocation = TouchLocation;
					UDKRTSPawn.HasPendingCommand = true;
				}
				break;

			// Handle an untouch or cancelled event with the structure
			case ETR_Structure:
				UDKRTSStructure = UDKRTSStructure(TouchEvents[Index].AssociatedActor);
				if (UDKRTSStructure != None)
				{
					if (UDKRTSStructure.IsConstructed)
					{
						if (UDKRTSStructure.SettingRallyPoint)
						{
							HasSetRallyPoint = false;

							// If the untouch is over a UDKRTSResource, then units should automatically
							// try to harvest it if they can. Otherwise they just go to the nearest point
							// Check if the player wants to auto rally to resource
							UDKRTSGameReplicationInfo = UDKRTSGameReplicationInfo(WorldInfo.GRI);
							if (UDKRTSGameReplicationInfo != None && UDKRTSGameReplicationInfo.Resources.Length > 0)
							{
								for (i = 0; i < UDKRTSGameReplicationInfo.Resources.Length; ++i)
								{
									if (UDKRTSGameReplicationInfo.Resources[i] != None && class'UDKRTSMobileHUD'.static.IsPointWithinBox(TouchLocation, UDKRTSGameReplicationInfo.Resources[i].ScreenBoundingBox))
									{
										UDKRTSStructure.SetRallyPoint();
										StartSetRallyPointActor(UDKRTSGameReplicationInfo.Resources[i], UDKRTSStructure);
										HasSetRallyPoint = true;
										break;
									}
								}
							}

							// Hasn't set the rally point, so set it, if required
							if (!HasSetRallyPoint)
							{
								// Set the rally point
								StartSetRallyPoint(UDKRTSStructure.SetRallyPoint(), UDKRTSStructure);
							}
						}
						else
						{
							UDKRTSStructure.SetRallyPoint();
						}
					}

					UDKRTSMobileHUD = UDKRTSMobileHUD(MyHUD);
					if (UDKRTSMobileHUD != None)
					{
						UDKRTSMobileHUD.UnregisterHUDAction(UDKRTSStructure);
					}
				}
				break;

			// Handle an untouch or cancelled event with the resource
			case ETR_Resource:
				UDKRTSMobileHUD = UDKRTSMobileHUD(MyHUD);
				if (UDKRTSMobileHUD != None)
				{
					UDKRTSMobileHUD.UnregisterHUDAction(TouchEvents[Index].AssociatedActor);
				}
				break;

			// Handle an untouch or cancelled event with the minimap expand tab
			case ETR_MinimapExpand:
				UDKRTSMobileHUD = UDKRTSMobileHUD(MyHUD);
				if (UDKRTSMobileHUD != None)
				{
					UDKRTSMobileHUD.CurrentMinimapSize.X += UDKRTSMobileHUD.DesiredMinimapSize.X;
					UDKRTSMobileHUD.CurrentMinimapSize.Y -= UDKRTSMobileHUD.DesiredMinimapSize.Y;
					UDKRTSMobileHUD.DesiredMinimapSize.X = 0.f;
					UDKRTSMobileHUD.DesiredMinimapSize.Y = 0.f;
				}
				break;

			// handle an untouch or cancelled event with the minimap
			case ETR_Minimap:
				UDKRTSMobileHUD = UDKRTSMobileHUD(MyHUD);
				if (UDKRTSMobileHUD != None)
				{
					UDKRTSCamera = UDKRTSCamera(PlayerCamera);
					if (UDKRTSCamera != None)
					{
						WorldLocation = UDKRTSMobileHUD.ConvertMinimapPositionToWorldLocation(TouchLocation);
						UDKRTSCamera.CurrentLocation.X = WorldLocation.X;
						UDKRTSCamera.CurrentLocation.Y = WorldLocation.Y;
						UDKRTSCamera.AdjustLocation(UDKRTSCamera.CurrentLocation);
					}
				}

				break;

			default:
				break;
			}

			TouchEvents.Remove(Index, 1);
		}
	}
}

/**
 * Handle a camera zoom touch event
 *
 * @param		ScreenTouchLocationA			One of the touch locations in screen space
 * @param		ScreenTouchLocationB			One of the touch locations in screen space
 */
simulated function HandleCameraZoomTouchEvent(Vector2D ScreenTouchLocationA, Vector2D ScreenTouchLocationB)
{
	local UDKRTSCamera UDKRTSCamera;
	local float Distance, Difference, Multiplier;

	// Check that we have a valid camera
	UDKRTSCamera = UDKRTSCamera(PlayerCamera);
	if (UDKRTSCamera == None)
	{
		return;
	}

	// Find the distance between the two touch locations
	Distance = class'UDKRTSUtility'.static.VSizeVector2D(ScreenTouchLocationA, ScreenTouchLocationB);
	// Find the difference
	Difference = Distance - CurrentCameraZoomDistance;
	Multiplier = Abs(Difference * 0.1f);

	// Zoom in or out based on the difference in distance
	if (Distance > CurrentCameraZoomDistance)
	{
		UDKRTSCamera.ZoomOut(ZoomSensitivity * Multiplier);
	}
	else if (Distance < CurrentCameraZoomDistance)
	{
		UDKRTSCamera.ZoomIn(ZoomSensitivity * Multiplier);
	}

	CurrentCameraZoomDistance = Distance;
}

/**
 * Adds an actor to a selection group
 * 
 * @param		Index		Selection group index
 * @param		Actor		Actor to add
 */
simulated function AddActorToSelectionGroup(int Index, Actor Actor)
{
	local int Idx;

	// Check variables
	if (Index < 0 || Index >= ArrayCount(SelectionGroup) || Actor == None)
	{
		return;
	}

	// Insert the actor into the selection group if it is valid
	Idx = SelectionGroup[Index].GroupedActors.Find(Actor);
	if (Idx == INDEX_NONE)
	{
		SelectionGroup[Index].GroupedActors.AddItem(Actor);
	}
}

/**
 * Receives a message and registers it on the HUD
 *
 * @param		MessageText			Text of the message
 * @param		MessageColor		Color of the message
 */
simulated function ReceiveMessage(string MessageText, optional Color MessageColor = class'HUD'.default.WhiteColor)
{
	local UDKRTSMobileHUD UDKRTSMobileHUD;

	Super.ReceiveMessage(MessageText, MessageColor);

	// Register it on the HUD
	UDKRTSMobileHUD = UDKRTSMobileHUD(MyHUD);
	if (UDKRTSMobileHUD != None)
	{
		UDKRTSMobileHUD.RegisterMessage(MessageText, MessageColor);
	}
}

defaultproperties
{	
	InputClass=class'MobilePlayerInput'	
	ZoomSensitivity=16.f
}