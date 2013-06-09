//=============================================================================
// UDKRTSMobileHUD: Mobile HUD which handles rendering and deferred touch
// logic.
//
// Mobile HUD handles all rendering onto the heads up display, and also handles
// deferred touch logic as project/deproject is usually required.
// 
// Copyright 1998-2011 Epic Games, Inc. All Rights Reserved.
//=============================================================================
class UDKRTSMobileHUD extends UDKRTSHUD
	DependsOn(UDKRTSMobilePlayerController, UDKRTSUtility);

// Stores the archetyped HUD properties
var const archetype UDKRTSMobileHUDProperties HUDProperties;
// Stores the touch event index used for camera panning. Is -1 when the camera is not panning
var int CameraPanningTouchEventIndex;
// Playable space left, if the screen touch location is to the left of this, then scroll
var int PlayableSpaceLeft;
// Playable space right, if the screen touch location is to the right of this, then scroll
var int PlayableSpaceRight;
// Cached scroll space 1/5 (X = vertical position, Y = height)
var IntPoint FirstScrollSpace;
// Cached scroll space 2/5 (X = vertical position, Y = height)
var IntPoint SecondScrollSpace;
// Cached scroll space 3/5 (X = vertical position, Y = height)
var IntPoint ThirdScrollSpace;
// Cached scroll space 4/5 (X = vertical position, Y = height)
var IntPoint FourthScrollSpace;
// Cached scroll space 5/5 (X = vertical position, Y = height)
var IntPoint FifthScrollSpace;
// Stores the current minimap size
var IntPoint CurrentMinimapSize;
// Stores the desired minimap size
var Vector2D DesiredMinimapSize;
// Selection group size
var Vector2D SelectionGroupSize;

/**
 * Called when the HUD is first initialized
 */
simulated function PostBeginPlay()
{
	Super.PostBeginPlay();

	// When this is first initialized, fade out from black
	if (HUDProperties != None)
	{
		SetTimer(HUDProperties.FadeOutTime, false, NameOf(FadeOutTimer));
	}
}

/**
 * Fade out timer
 */
simulated function FadeOutTimer();

/**
 * Registers a world message onto the HUD
 *
 * @param		MessageText			Text of the message
 * @param		MessageColor		Color of the message
 * @param		WorldLocation		World location where this message occured
 * @param		MessageIcon			Texture of the message
 * @param		MessageIconU		Texture coordinate U of the message
 * @param		MessageIconV		Texture coordinate V of the message
 * @param		MessageIconUL		Texture coordinate UL of the message
 * @param		MessageIconVL		Texture coordinate VL of the message
 */
simulated function RegisterWorldMessage(String MessageText, Color MessageColor, Vector WorldLocation, Texture2D MessageIcon, float MessageIconU, float MessageIconV, float MessageIconUL, float MessageIconVL)
{
	local SHUDLocationMessage WorldMessage;

	// Register and add the world message to the HUD
	WorldMessage.Life = HUDProperties.MessagesLifeTime;
	WorldMessage.Icon = MessageIcon;
	WorldMessage.U = MessageIconU;
	WorldMessage.V = MessageIconV;
	WorldMessage.UL = MessageIconUL;
	WorldMessage.VL = MessageIconVL;
	WorldMessage.Message = MessageText;
	WorldMessage.Color = MessageColor;
	WorldMessage.WorldLocation = WorldLocation;

	WorldMessages.AddItem(WorldMessage);
}

/**
 * Registers a message onto the HUD
 *
 * @param		MessageText			Text of the message
 * @param		MessageColor		Color of the message
 */
simulated function RegisterMessage(String MessageText, Color MessageColor)
{
	local SHUDMessage HUDMessage;

	// Register and add the message to the HUD
	HUDMessage.Message = MessageText;
	HUDMessage.Color = MessageColor;
	HUDMessage.Life = HUDProperties.MessagesLifeTime;

	HUDMessages.AddItem(HUDMessage);
}

/**
 * Precalculate commonly used values
 */
function PreCalcValues()
{
	local float Height;

	Super.PreCalcValues();

	if (HUDProperties != None)
	{
		// Precalculate the playable space
		PlayableSpaceLeft = HUDProperties.ScrollWidth;
		PlayableSpaceRight = SizeX - HUDProperties.ScrollWidth;

		// Precalculate the first scroll space
		Height = SizeY * 0.2f;
		FirstScrollSpace.X = 0;
		FirstScrollSpace.Y = Height;

		// Precalculate the second scroll space
		SecondScrollSpace.X = FirstScrollSpace.X + FirstScrollSpace.Y;
		SecondScrollSpace.Y = Height;

		// Precalculate the third scroll space
		ThirdScrollSpace.X = SecondScrollSpace.X + SecondScrollSpace.Y;
		ThirdScrollSpace.Y = SizeY - (Height * 4);

		// Precalculate the fourth scroll space
		FourthScrollSpace.X = ThirdScrollSpace.X + ThirdScrollSpace.Y;
		FourthScrollSpace.Y = Height;

		// Precalculate the fifth scroll space
		FifthScrollSpace.X = FourthScrollSpace.X + FourthScrollSpace.Y;
		FifthScrollSpace.Y = Height;

		// Precalculate the selection group size
		SelectionGroupSize.X = (SizeX - (HUDProperties.ScrollWidth * 2.f)) / ArrayCount(class'UDKRTSMobilePlayerController'.default.SelectionGroup);
		SelectionGroupSize.Y = SelectionGroupSize.X * 0.5f;
	}	
}

/**
 * Unregisters a HUD action by associated actor and reference
 *
 * @param		AssociatedActor			Actor associated with a HUD action
 * @param		Reference				HUD action reference
 */
function UnregisterHUDActionByReference(Actor AssociatedActor, EHUDActionReference Reference)
{
	local int Index, i;

	// Find the associated HUD action index
	Index = AssociatedHUDActions.Find('AssociatedActor', AssociatedActor);
	if (Index == INDEX_NONE || AssociatedHUDActions[Index].HUDActions.Length <= 0)
	{
		return;
	}

	// Remove the HUD action
	for (i = 0; i < AssociatedHUDActions[Index].HUDActions.Length; ++i)
	{
		if (AssociatedHUDActions[Index].HUDActions[i].Reference == Reference)
		{
			AssociatedHUDActions[Index].HUDActions.Remove(i, 1);
			--i;
		}
	}
}

/**
 * Unregisters all HUD actions by associated actor
 *
 * @param		AssociatedActor			Actor associated with a HUD action
 */
function UnregisterHUDAction(Actor AssociatedActor)
{
	local int Index;

	// Remove associated HUD action
	Index = AssociatedHUDActions.Find('AssociatedActor', AssociatedActor);
	if (Index != INDEX_NONE)
	{
		AssociatedHUDActions.Remove(Index, 1);
	}
}

/**
 * Registers a HUD action associated to an actor
 *
 * @param		AssociatedActor			Actor to be associated with this HUD action
 * @param		HUDAction				HUD action to register
 */
function RegisterHUDAction(Actor AssociatedActor, SHUDAction HUDAction)
{
	local SAssociatedHUDAction AssociatedHUDAction;
	local int IndexA, IndexB;

	// Get index A 
	IndexA = AssociatedHUDActions.Find('AssociatedActor', AssociatedActor);
	if (IndexA != INDEX_NONE)
	{		
		// Get index B
		IndexB = AssociatedHUDActions[IndexA].HUDActions.Find('Reference', HUDAction.Reference);
		if (IndexB != INDEX_NONE && AssociatedHUDActions[IndexA].HUDActions[IndexB].Index == HUDAction.Index)
		{			
			return;
		}
	}

	if (IndexA != INDEX_NONE)
	{
		// Add the associated HUD action
		AssociatedHUDActions[IndexA].HUDActions.AddItem(HUDAction);
	}
	else
	{
		// Add the associated HUD action
		AssociatedHUDAction.AssociatedActor = AssociatedActor;
		AssociatedHUDAction.HUDActions.AddItem(HUDAction);
		AssociatedHUDActions.AddItem(AssociatedHUDAction);
	}
}

/**
 * Performs post rendering onto the HUD
 */
event PostRender()
{
	local UDKRTSMobilePlayerController UDKRTSMobilePlayerController;
	local Vector OriginWorldLocation, OriginWorldDirection, CurrentWorldLocation, CurrentWorldDirection;
	local Vector HitOriginWorldLocation, HitCurrentWorldLocation, HitNormal;
	local UDKRTSCameraBlockingVolume UDKRTSCameraBlockingVolume;
	local UDKRTSCamera UDKRTSCamera;
	local UDKRTSPawn UDKRTSPawn;
	local UDKRTSStructure UDKRTSStructure;
	local UDKRTSTeamInfo UDKRTSTeamInfo, PlayerUDKRTSTeamInfo;
	local UDKRTSGameReplicationInfo UDKRTSGameReplicationInfo;
	local UDKRTSPlayerReplicationInfo UDKRTSPlayerReplicationInfo;
	local int i, j, k, X, Y;
	local Vector2D Offset, Size, MinimapPosition, CameraFOV[4];
	local Texture2D MinimapTexture, MinimapIconTexture;
	local float XL, YL, MinimapIconU, MinimapIconV, MinimapIconUL, MinimapIconVL, Alpha;
	local Color MinimapIconColor;
	local Actor Actor;
	local UDKRTSMinimapInterface MinimapInterface;
	local UDKRTSHUDActionInterface UDKRTSHUDActionInterface;
	local Box MinimapBox;
	local UDKRTSHUDInterface UDKRTSHUDInterface;
	local byte RenderBlackBorder;
	local String Text;
	local UDKRTSAIController UDKRTSAIController;

	Super.PostRender();

	// Check to make sure we have a valid HUD properties archetype
	if (HUDProperties == None)
	{
		return;
	}

	// Check to make sure we have a Mobile RTS player controller
	UDKRTSMobilePlayerController = UDKRTSMobilePlayerController(PlayerOwner);
	if (UDKRTSMobilePlayerController == None)
	{
		return;
	}

	// Calculate the screen bounding boxes for all game relevant objects
	UDKRTSGameReplicationInfo = UDKRTSGameReplicationInfo(WorldInfo.GRI);	
	if (UDKRTSGameReplicationInfo == None)
	{
		return;
	}

	// Calculate the screen bounding boxes for all of the resources
	for (i = 0; i < UDKRTSGameReplicationInfo.Resources.Length; ++i)
	{
		if (UDKRTSGameReplicationInfo.Resources[i] != None)
		{
			UDKRTSGameReplicationInfo.Resources[i].ScreenBoundingBox = CalculateScreenBoundingBox(Self, UDKRTSGameReplicationInfo.Resources[i], UDKRTSGameReplicationInfo.Resources[i].CollisionCylinder);

			// Render the debug bounding box
			if (ShouldDisplayDebug('BoundingBoxes'))
			{
				Canvas.SetPos(UDKRTSGameReplicationInfo.Resources[i].ScreenBoundingBox.Min.X, UDKRTSGameReplicationInfo.Resources[i].ScreenBoundingBox.Min.Y);
				Canvas.DrawColor = UDKRTSGameReplicationInfo.Resources[i].BoundingBoxColor;
				Canvas.DrawBox(UDKRTSGameReplicationInfo.Resources[i].ScreenBoundingBox.Max.X - UDKRTSGameReplicationInfo.Resources[i].ScreenBoundingBox.Min.X, UDKRTSGameReplicationInfo.Resources[i].ScreenBoundingBox.Max.Y - UDKRTSGameReplicationInfo.Resources[i].ScreenBoundingBox.Min.Y);
			}
		}
	}
	
	if (WorldInfo != None && WorldInfo.GRI != None)
	{
		for (i = 0; i < WorldInfo.GRI.Teams.Length; ++i)
		{
			UDKRTSTeamInfo = UDKRTSTeamInfo(WorldInfo.GRI.Teams[i]);
			
			// Calculate the screen bounding boxes for all of the structures
			if (UDKRTSTeamInfo.Structures.Length > 0)
			{
				for (j = 0; j < UDKRTSTeamInfo.Structures.Length; ++j)
				{
					// Only care about structures that have health
					if (UDKRTSTeamInfo.Structures[j] != None)
					{
						if (UDKRTSTeamInfo.Structures[j].Health > 0)
						{
							UDKRTSTeamInfo.Structures[j].ScreenBoundingBox = CalculateScreenBoundingBox(Self, UDKRTSTeamInfo.Structures[j], UDKRTSTeamInfo.Structures[j].CollisionComponent);
							if (ShouldDisplayDebug('BoundingBoxes'))
							{
								Canvas.SetPos(UDKRTSTeamInfo.Structures[j].ScreenBoundingBox.Min.X, UDKRTSTeamInfo.Structures[j].ScreenBoundingBox.Min.Y);
								Canvas.DrawColor = UDKRTSTeamInfo.Structures[j].BoundingBoxColor;
								Canvas.DrawBox(UDKRTSTeamInfo.Structures[j].ScreenBoundingBox.Max.X - UDKRTSTeamInfo.Structures[j].ScreenBoundingBox.Min.X, UDKRTSTeamInfo.Structures[j].ScreenBoundingBox.Max.Y - UDKRTSTeamInfo.Structures[j].ScreenBoundingBox.Min.Y);
							}
						}
						else
						{
							// Reset the bounding box
							UDKRTSTeamInfo.Structures[j].ScreenBoundingBox = class'UDKRTSUtility'.default.NullBoundingBox;
						}
					}
				}
			}

			// Calculate the screen bounding boxes for all of the pawns
			if (UDKRTSTeamInfo.Pawns.Length > 0)
			{
				for (j = 0; j < UDKRTSTeamInfo.Pawns.Length; ++j)
				{
					// Only care about pawns that have health
					if (UDKRTSTeamInfo.Pawns[j] != None)
					{
						if (UDKRTSTeamInfo.Pawns[j].Health > 0)
						{
							UDKRTSTeamInfo.Pawns[j].ScreenBoundingBox = CalculateScreenBoundingBox(Self, UDKRTSTeamInfo.Pawns[j], UDKRTSTeamInfo.Pawns[j].CollisionComponent);
							if (ShouldDisplayDebug('BoundingBoxes'))
							{
								Canvas.SetPos(UDKRTSTeamInfo.Pawns[j].ScreenBoundingBox.Min.X, UDKRTSTeamInfo.Pawns[j].ScreenBoundingBox.Min.Y);
								Canvas.DrawColor = UDKRTSTeamInfo.Pawns[j].BoundingBoxColor;
								Canvas.DrawBox(UDKRTSTeamInfo.Pawns[j].ScreenBoundingBox.Max.X - UDKRTSTeamInfo.Pawns[j].ScreenBoundingBox.Min.X, UDKRTSTeamInfo.Pawns[j].ScreenBoundingBox.Max.Y - UDKRTSTeamInfo.Pawns[j].ScreenBoundingBox.Min.Y);
							}
						}
						else
						{
							// Reset the bounding box
							UDKRTSTeamInfo.Pawns[j].ScreenBoundingBox = class'UDKRTSUtility'.default.NullBoundingBox;
						}
					}
				}
			}
		}
	}

	// =============================================================
	// Call the post render for all HUD interface implemented actors
	// =============================================================
	ForEach DynamicActors(class'Actor', Actor, class'UDKRTSHUDInterface')
	{
		UDKRTSHUDInterface = UDKRTSHUDInterface(Actor);
		if (UDKRTSHUDInterface != None)
		{
			UDKRTSHUDInterface.PostRender(Self);
		}
	}

	// ==================
	// Render HUD Actions
	// ==================
	if (AssociatedHUDActions.Length > 0)
	{
		Offset.X = PlayableSpaceLeft;
		Offset.Y = 0;
		Size.X = SizeX * 0.0625f;
		Size.Y = Size.X;			

		for (i = 0; i < AssociatedHUDActions.Length; ++i)
		{
			if (AssociatedHUDActions[i].AssociatedActor != None && AssociatedHUDActions[i].HUDActions.Length > 0)
			{
				Offset.X = HUDProperties.ScrollWidth;

				for (j = 0; j < AssociatedHUDActions[i].HUDActions.Length; ++j)
				{
					if (AssociatedHUDActions[i].HUDActions[j].IsHUDActionActiveDelegate != None)
					{
						IsHUDActionActive = AssociatedHUDActions[i].HUDActions[j].IsHUDActionActiveDelegate;

						if (!IsHUDActionActive(AssociatedHUDActions[i].HUDActions[j].Reference, AssociatedHUDActions[i].HUDActions[j].Index, false))
						{
							Canvas.SetDrawColor(191, 191, 191, 191);
						}
						else
						{
							Canvas.SetDrawColor(255, 255, 255);
						}

						IsHUDActionActive = None;
					}
					else
					{
						Canvas.SetDrawColor(255, 255, 255);
					}

					Canvas.SetPos(Offset.X, Offset.Y);
					Canvas.DrawTile(AssociatedHUDActions[i].HUDActions[j].Texture, Size.X, Size.Y, AssociatedHUDActions[i].HUDActions[j].U, AssociatedHUDActions[i].HUDActions[j].V, AssociatedHUDActions[i].HUDActions[j].UL, AssociatedHUDActions[i].HUDActions[j].VL);

					if (AssociatedHUDActions[i].HUDActions[j].PostRender)
					{
						UDKRTSHUDActionInterface = UDKRTSHUDActionInterface(AssociatedHUDActions[i].AssociatedActor);
						if (UDKRTSHUDActionInterface != None)
						{
							UDKRTSHUDActionInterface.PostRenderHUDAction(Self, AssociatedHUDActions[i].HUDActions[j].Reference, AssociatedHUDActions[i].HUDActions[j].Index, Offset.X, Offset.Y, Size.X, Size.Y);
						}
					}

					Offset.X += Size.X;
				}
			}

			Offset.Y += Size.Y;
		}
	}

	// Handle pawn selection and command for the player
	if (PlayerOwner != None && PlayerOwner.PlayerReplicationInfo != None)
	{
		PlayerUDKRTSTeamInfo = UDKRTSTeamInfo(PlayerOwner.PlayerReplicationInfo.Team);
		if (PlayerUDKRTSTeamInfo != None)
		{
			MinimapBox.Min.X = PlayableSpaceRight - CurrentMinimapSize.X - DesiredMinimapSize.X;
			MinimapBox.Min.Y = 0.f;
			MinimapBox.Max.X = MinimapBox.Min.X + (CurrentMinimapSize.X - DesiredMinimapSize.X);
			MinimapBox.Max.Y = CurrentMinimapSize.Y - DesiredMinimapSize.Y;
		
			// Handle the player's pawns
			for (i = 0; i < PlayerUDKRTSTeamInfo.Pawns.Length; ++i)
			{
				if (PlayerUDKRTSTeamInfo.Pawns[i] != None && PlayerUDKRTSTeamInfo.Pawns[i].Health > 0 && PlayerUDKRTSTeamInfo.Pawns[i].HasPendingCommand)
				{
					// Check the mode the player has currently selected
					switch (PlayerUDKRTSTeamInfo.Pawns[i].CommandMode)
					{
					case ECM_AutomatedMove:
						// Check if the screen touch location is within the minimap
						if (IsPointWithinBox(PlayerUDKRTSTeamInfo.Pawns[i].PendingScreenCommandLocation, MinimapBox))
						{
							HitCurrentWorldLocation = ConvertMinimapPositionToWorldLocation(PlayerUDKRTSTeamInfo.Pawns[i].PendingScreenCommandLocation);
							HitCurrentWorldLocation.Z += 1.f;

							// Replicate the move order
							UDKRTSMobilePlayerController.GiveMoveOrder(HitCurrentWorldLocation, PlayerUDKRTSTeamInfo.Pawns[i]);
							// Playback the pawn confirmation effects and sounds
							PlayerUDKRTSTeamInfo.Pawns[i].ConfirmCommand();
						}
						else
						{
							// Check if the screen command location is within any resource screen bounding boxes,
							// If so harvest the resource
							for (j = 0; j < UDKRTSGameReplicationInfo.Resources.Length; ++j)
							{
								if (UDKRTSGameReplicationInfo.Resources[j] != None && IsPointWithinBox(PlayerUDKRTSTeamInfo.Pawns[i].PendingScreenCommandLocation, UDKRTSGameReplicationInfo.Resources[j].ScreenBoundingBox))
								{
									// Replicate the harvest resource order
									UDKRTSMobilePlayerController.GiveHarvestResourceOrder(UDKRTSGameReplicationInfo.Resources[j], PlayerUDKRTSTeamInfo.Pawns[i]);
									// Play back the confirmation command
									PlayerUDKRTSTeamInfo.Pawns[i].ConfirmCommand();
									break;
								}
							}

							// Check if the screen command location is within any enemy pawn screen bounding boxes,
							// If so engage the enemy
							// Need to find out if the team is friendly or not
							if (PlayerUDKRTSTeamInfo.Pawns[i].HasPendingCommand)
							{
								for (j = 0; j < UDKRTSGameReplicationInfo.Teams.Length; ++j)
								{
									if (UDKRTSGameReplicationInfo.Teams[j] != PlayerOwner.PlayerReplicationInfo.Team)
									{
										UDKRTSTeamInfo = UDKRTSTeamInfo(UDKRTSGameReplicationInfo.Teams[j]);
										for (k = 0; k < UDKRTSTeamInfo.Pawns.Length; ++k)
										{
											if (UDKRTSTeamInfo.Pawns[k] != None && UDKRTSTeamInfo.Pawns[k].Health > 0 && IsPointWithinBox(PlayerUDKRTSTeamInfo.Pawns[i].PendingScreenCommandLocation, UDKRTSTeamInfo.Pawns[k].ScreenBoundingBox))
											{
												// Replicate the engage target order
												UDKRTSMobilePlayerController.GiveEngageTargetOrder(UDKRTSTeamInfo.Pawns[k], PlayerUDKRTSTeamInfo.Pawns[i]);
												// Playback the pawn engaging effects and sounds
												PlayerUDKRTSTeamInfo.Pawns[i].EngageEnemy();
												break;
											}
										}

										if (!PlayerUDKRTSTeamInfo.Pawns[i].HasPendingCommand)
										{
											break;
										}

										for (k = 0; k < UDKRTSTeamInfo.Structures.Length; ++k)
										{
											if (UDKRTSTeamInfo.Structures[k] != None && UDKRTSTeamInfo.Structures[k].Health > 0 && IsPointWithinBox(PlayerUDKRTSTeamInfo.Pawns[i].PendingScreenCommandLocation, UDKRTSTeamInfo.Structures[k].ScreenBoundingBox))
											{
												// Replicate the engage target order
												UDKRTSMobilePlayerController.GiveEngageTargetOrder(UDKRTSTeamInfo.Structures[k], PlayerUDKRTSTeamInfo.Pawns[i]);
												// Playback the pawn engaging effects and sounds
												PlayerUDKRTSTeamInfo.Pawns[i].EngageEnemy();
												break;
											}
										}

										if (!PlayerUDKRTSTeamInfo.Pawns[i].HasPendingCommand)
										{
											break;
										}
									}
								}

								if (PlayerUDKRTSTeamInfo.Pawns[i] != None && PlayerUDKRTSTeamInfo.Pawns[i].HasPendingCommand)
								{
									// Deproject the pending screen command location
									Canvas.Deproject(PlayerUDKRTSTeamInfo.Pawns[i].PendingScreenCommandLocation, CurrentWorldLocation, CurrentWorldDirection);
									// Find the world location for the pending move location
									ForEach TraceActors(class'UDKRTSCameraBlockingVolume', UDKRTSCameraBlockingVolume, HitCurrentWorldLocation, HitNormal, CurrentWorldLocation + CurrentWorldDirection * 65536.f, CurrentWorldLocation)
									{
										// Replicate the move order
										UDKRTSMobilePlayerController.GiveMoveOrder(HitCurrentWorldLocation, PlayerUDKRTSTeamInfo.Pawns[i]);
										// Playback the pawn confirmation effects and sounds
										PlayerUDKRTSTeamInfo.Pawns[i].ConfirmCommand();
										break;
									}
								}
							}
						}
						break;

					case ECM_BuildStructure:
						if (PlayerUDKRTSTeamInfo.Pawns[i] != None)
						{
							PlayerUDKRTSTeamInfo.Pawns[i].HasPendingCommand = false;
							// Playback the pawn confirmation effects and sounds
							PlayerUDKRTSTeamInfo.Pawns[i].ConfirmCommand();
							// Deproject the pending screen command location
							Canvas.Deproject(PlayerUDKRTSTeamInfo.Pawns[i].PendingScreenCommandLocation, CurrentWorldLocation, CurrentWorldDirection);
							// Find the world location for the pending move location
							ForEach TraceActors(class'UDKRTSCameraBlockingVolume', UDKRTSCameraBlockingVolume, HitCurrentWorldLocation, HitNormal, CurrentWorldLocation + CurrentWorldDirection * 65536.f, CurrentWorldLocation)
							{
								// Request the structure
								UDKRTSMobilePlayerController.RequestStructure(PlayerUDKRTSTeamInfo.Pawns[i].BuildableStructureArchetypes[PlayerUDKRTSTeamInfo.Pawns[i].CommandIndex], HitCurrentWorldLocation);
								// Move the pawn there
								UDKRTSMobilePlayerController.GiveMoveOrder(HitCurrentWorldLocation + Normal(PlayerUDKRTSTeamInfo.Pawns[i].Location - HitCurrentWorldLocation) * PlayerUDKRTSTeamInfo.Pawns[i].BuildableStructureArchetypes[PlayerUDKRTSTeamInfo.Pawns[i].CommandIndex].CollisionCylinder.CollisionRadius * 1.5f, PlayerUDKRTSTeamInfo.Pawns[i]);
								break;
							}
						}
						break;

					default:
						break;
					}
				}
			}
		}
	}

	// Check if we need to pan the camera
	UDKRTSCamera = UDKRTSCamera(PlayerOwner.PlayerCamera);
	if (CameraPanningTouchEventIndex != -1 && UDKRTSCamera != None && !UDKRTSMobilePlayerController.TouchEvents[CameraPanningTouchEventIndex].Processed)
	{
		// Deproject the origin screen touch location
		Canvas.Deproject(UDKRTSMobilePlayerController.TouchEvents[CameraPanningTouchEventIndex].OriginScreenLocation, OriginWorldLocation, OriginWorldDirection);
		// Find the world location of the origin camera location
		ForEach TraceActors(class'UDKRTSCameraBlockingVolume', UDKRTSCameraBlockingVolume, HitOriginWorldLocation, HitNormal, OriginWorldLocation + OriginWorldDirection * 65536.f, OriginWorldLocation)
		{
			break;
		}

		// Deproject the current screen touch location
		Canvas.Deproject(UDKRTSMobilePlayerController.TouchEvents[CameraPanningTouchEventIndex].CurrentScreenLocation, CurrentWorldLocation, CurrentWorldDirection);
		// Find the world location of the current camera location
		ForEach TraceActors(class'UDKRTSCameraBlockingVolume', UDKRTSCameraBlockingVolume, HitCurrentWorldLocation, HitNormal, CurrentWorldLocation + CurrentWorldDirection * 65536.f, CurrentWorldLocation)
		{
			break;
		}

		UDKRTSCamera.CurrentLocation = UDKRTSCamera.Location + (HitOriginWorldLocation - HitCurrentWorldLocation);
		UDKRTSMobilePlayerController.TouchEvents[CameraPanningTouchEventIndex].Processed = true;
	}

	if (UDKRTSMobilePlayerController.TouchEvents.Length > 0)
	{
		for (i = 0; i < UDKRTSMobilePlayerController.TouchEvents.Length; ++i)
		{
			switch (UDKRTSMobilePlayerController.TouchEvents[i].Response)
			{
			case ETR_Pawn:
				UDKRTSPawn = UDKRTSPawn(UDKRTSMobilePlayerController.TouchEvents[i].AssociatedActor);
				if (UDKRTSPawn != None)
				{
					MinimapBox.Min.X = PlayableSpaceRight - CurrentMinimapSize.X - DesiredMinimapSize.X;
					MinimapBox.Min.Y = 0.f;
					MinimapBox.Max.X = MinimapBox.Min.X + (CurrentMinimapSize.X - DesiredMinimapSize.X);
					MinimapBox.Max.Y = CurrentMinimapSize.Y - DesiredMinimapSize.Y;

					// Check if the screen touch location is within the minimap
					if (IsPointWithinBox(UDKRTSMobilePlayerController.TouchEvents[i].CurrentScreenLocation, MinimapBox))
					{
						HitCurrentWorldLocation = ConvertMinimapPositionToWorldLocation(UDKRTSMobilePlayerController.TouchEvents[i].CurrentScreenLocation);
						HitCurrentWorldLocation.Z += 1.f;
					}
					else if (UDKRTSPawn.CommandMesh != None)
					{
						// Deproject the screen touch location
						Canvas.Deproject(UDKRTSMobilePlayerController.TouchEvents[i].CurrentScreenLocation, CurrentWorldLocation, CurrentWorldDirection);
						// Find the world location of the current camera location
						ForEach TraceActors(class'UDKRTSCameraBlockingVolume', UDKRTSCameraBlockingVolume, HitCurrentWorldLocation, HitNormal, CurrentWorldLocation + CurrentWorldDirection * 65536.f, CurrentWorldLocation)
						{
							break;
						}
					}

					UDKRTSPawn.SetCommandMeshTranslation(HitCurrentWorldLocation, false);
					// Draw the 3D connecting line
					HitCurrentWorldLocation -= Normal(HitCurrentWorldLocation - UDKRTSPawn.Location) * 36.f;
					Draw3DLine(UDKRTSPawn.Location, HitCurrentWorldLocation, class'HUD'.default.WhiteColor);
				}
				break;

			case ETR_Structure:
				UDKRTSStructure = UDKRTSStructure(UDKRTSMobilePlayerController.TouchEvents[i].AssociatedActor);
				if (UDKRTSStructure != None && UDKRTSStructure.IsConstructed && UDKRTSStructure.RallyPointMesh != None && UDKRTSStructure.CanSetRallyPoint)
				{
					// Check the distance of the touch location from the origin
					if (!UDKRTSStructure.SettingRallyPoint)
					{
						if (class'UDKRTSUtility'.static.VSizeVector2D(UDKRTSMobilePlayerController.TouchEvents[i].OriginScreenLocation, UDKRTSMobilePlayerController.TouchEvents[i].CurrentScreenLocation) > 64.f)
						{
							UDKRTSStructure.SettingRallyPoint = true;
						}
					}
					else
					{
						MinimapBox.Min.X = PlayableSpaceRight - CurrentMinimapSize.X - DesiredMinimapSize.X;
						MinimapBox.Min.Y = 0.f;
						MinimapBox.Max.X = MinimapBox.Min.X + (CurrentMinimapSize.X - DesiredMinimapSize.X);
						MinimapBox.Max.Y = CurrentMinimapSize.Y - DesiredMinimapSize.Y;

						// Check if the screen touch location is within the minimap
						if (IsPointWithinBox(UDKRTSMobilePlayerController.TouchEvents[i].CurrentScreenLocation, MinimapBox))
						{
							HitCurrentWorldLocation = ConvertMinimapPositionToWorldLocation(UDKRTSMobilePlayerController.TouchEvents[i].CurrentScreenLocation);
							HitCurrentWorldLocation.Z += 1.f;
						}
						else
						{
							// Deproject the screen touch location
							Canvas.Deproject(UDKRTSMobilePlayerController.TouchEvents[i].CurrentScreenLocation, CurrentWorldLocation, CurrentWorldDirection);
							// Find the world location of the current camera location
							ForEach TraceActors(class'UDKRTSCameraBlockingVolume', UDKRTSCameraBlockingVolume, HitCurrentWorldLocation, HitNormal, CurrentWorldLocation + CurrentWorldDirection * 65536.f, CurrentWorldLocation)
							{
								break;
							}
						}

						// Move the rally point mesh to the current touch location
						UDKRTSStructure.RallyPointMesh.SetTranslation(HitCurrentWorldLocation);
					}

					if (UDKRTSStructure.RallyPointMesh.Translation != UDKRTSStructure.Location)
					{
						// If the rally point is hidden, unhide it
						if (UDKRTSStructure.RallyPointMesh.HiddenGame)
						{
							UDKRTSStructure.RallyPointMesh.SetHidden(false);
						}

						// Draw the 3D connecting like
						HitCurrentWorldLocation = UDKRTSStructure.RallyPointMesh.Translation - Normal(UDKRTSStructure.RallyPointMesh.Translation - UDKRTSStructure.Location) * 36.f;
						Draw3DLine(UDKRTSStructure.Location, HitCurrentWorldLocation, UDKRTSStructure.RallyPointLineColor);
					}
				}
				break;

			default:
				break;
			}
		}
	}

	// =====================
	// Draw the HUD messages
	// =====================
	if (HUDMessages.Length > 0)
	{
		// Tick the HUD messages and see if there are any that need to be removed
		for (i = 0; i < HUDMessages.Length; ++i)
		{
			HUDMessages[i].Life -= RenderDelta;

			if (HUDMessages[i].Life <= 0.f)
			{
				HUDMessages.Remove(i, 1);
				--i;
			}
		}
	}

	if (HUDMessages.Length > 0)
	{
		Canvas.Font = HUDProperties.MessagesFont;
		Y = SizeY * 0.5f;

		// Render the HUD messages
		for (i = HUDMessages.Length - 1; i > -1; --i)
		{
			Canvas.StrLen(HUDMessages[i].Message, XL, YL);
			Canvas.DrawColor = HUDMessages[i].Color;
			Canvas.DrawColor.A = (HUDMessages[i].Life / HUDProperties.MessagesLifeTime) * 255.f;
			Canvas.SetPos((SizeX * 0.5f) - (XL * 0.5f), Y);
			Canvas.DrawText(HUDMessages[i].Message);

			Y -= YL;
		}
	}

	// =============================
	// Render the HUD world messages
	// =============================
	if (WorldMessages.Length > 0)
	{
		// Tick the HUD world messages and see if there are any that need to be removed
		for (i = 0; i < WorldMessages.Length; ++i)
		{
			WorldMessages[i].Life -= RenderDelta;

			if (WorldMessages[i].Life <= 0.f)
			{
				WorldMessages.Remove(i, 1);
				--i;
			}
		}
	}

	if (WorldMessages.Length > 0)
	{
		Canvas.Font = HUDProperties.MessagesFont;
		Y = SizeY - SelectionGroupSize.Y - 8.f;

		// Render the world messages
		for (i = WorldMessages.Length - 1; i > -1; --i)
		{
			if (WorldMessages[i].Message != "")
			{
				Canvas.StrLen(WorldMessages[i].Message, XL, YL);
				Canvas.DrawColor = WorldMessages[i].Color;
				Canvas.DrawColor.A = (WorldMessages[i].Life / HUDProperties.MessagesLifeTime) * 255.f;
				Canvas.SetPos(HUDProperties.ScrollWidth + (YL * 2.f) + 8.f, Y - (YL * 1.5f));
				Canvas.DrawText(WorldMessages[i].Message);

				if (WorldMessages[i].Icon != none)
				{
					WorldMessages[i].BoundingBox.Min.X = HUDProperties.ScrollWidth;
					WorldMessages[i].BoundingBox.Min.Y = Y - (YL * 2.f);
					WorldMessages[i].BoundingBox.Max.X = WorldMessages[i].BoundingBox.Min.X + (YL * 2.f);
					WorldMessages[i].BoundingBox.Max.Y = WorldMessages[i].BoundingBox.Min.Y + (YL * 2.f);
					Canvas.SetPos(WorldMessages[i].BoundingBox.Min.X, WorldMessages[i].BoundingBox.Min.Y);
					Canvas.DrawColor.R = 255;
					Canvas.DrawColor.G = 255;
					Canvas.DrawColor.B = 255;
					Canvas.DrawTile(WorldMessages[i].Icon, YL * 2.f, YL * 2.f, WorldMessages[i].U, WorldMessages[i].V, WorldMessages[i].UL, WorldMessages[i].VL);
				}

				Y -= (YL * 2.f);
			}
		}
	}

	// ==============================
	// Render controller debug states
	// ==============================
	for (i = 0; i < UDKRTSGameReplicationInfo.Teams.Length; ++i)
	{
		if (UDKRTSGameReplicationInfo.Teams[i] != None)
		{
			UDKRTSTeamInfo = UDKRTSTeamInfo(UDKRTSGameReplicationInfo.Teams[i]);
			if (UDKRTSTeamInfo != None && UDKRTSTeamInfo.Pawns.Length > 0)
			{
				for (j = 0; j < UDKRTSTeamInfo.Pawns.Length; ++j)
				{
					if (UDKRTSTeamInfo.Pawns[j] != None)
					{
						UDKRTSAIController = UDKRTSAIController(UDKRTSTeamInfo.Pawns[j].Controller);
						if (UDKRTSAIController != None)
						{
							UDKRTSAIController.RenderDebugState(Self);
						}
					}
				}
			}
		}
	}

	// =======================
	// Draw the idle unit icon
	// =======================
	if (UDKRTSMobilePlayerController.IdleUnits.Length > 0)
	{
		if (UDKRTSMobilePlayerController.CurrentIdleUnitIndex > 0 && UDKRTSMobilePlayerController.CurrentIdleUnitIndex < UDKRTSMobilePlayerController.IdleUnits.Length && UDKRTSMobilePlayerController.IdleUnits[UDKRTSMobilePlayerController.CurrentIdleUnitIndex] != None)
		{
			Size.X = SizeX * 0.03125;
			Size.Y = Size.X;

			Canvas.SetPos(Canvas.ClipX - HUDProperties.ScrollWidth - Size.X - 4.f, Canvas.ClipY - SelectionGroupSize.Y - Size.Y - 4.f);
			Canvas.SetDrawColor(255, 255, 255);
			Canvas.DrawTile(UDKRTSMobilePlayerController.IdleUnits[UDKRTSMobilePlayerController.CurrentIdleUnitIndex].Portrait.Texture, Size.X, Size.Y, UDKRTSMobilePlayerController.IdleUnits[UDKRTSMobilePlayerController.CurrentIdleUnitIndex].Portrait.U, UDKRTSMobilePlayerController.IdleUnits[UDKRTSMobilePlayerController.CurrentIdleUnitIndex].Portrait.V, UDKRTSMobilePlayerController.IdleUnits[UDKRTSMobilePlayerController.CurrentIdleUnitIndex].Portrait.UL, UDKRTSMobilePlayerController.IdleUnits[UDKRTSMobilePlayerController.CurrentIdleUnitIndex].Portrait.VL);

			if (UDKRTSMobilePlayerController.IdleUnits.Length > 1)
			{
				Canvas.Font = class'Engine'.static.GetTinyFont();
				Text = String(UDKRTSMobilePlayerController.IdleUnits.Length);
				Canvas.TextSize(Text, XL, YL);
				class'UDKRTSMobileHUD'.static.DrawBorderedText(Self, Canvas.ClipX - HUDProperties.ScrollWidth - XL - 8.f, Canvas.ClipY - SelectionGroupSize.Y - YL - 8.f, Text, class'HUD'.default.WhiteColor, class'UDKRTSPalette'.default.BlackColor);
			}
		}
	}

	// =======================
	// Draw the scroll borders
	// =======================
	// Draw the vertical scroll borders
	Canvas.DrawColor = HUDProperties.ScrollVerticalColor;	
	Canvas.SetPos(0, FirstScrollSpace.X);
	Canvas.DrawRect(HUDProperties.ScrollWidth, FirstScrollSpace.Y);
	Canvas.SetPos(PlayableSpaceRight, FirstScrollSpace.X);
	Canvas.DrawRect(HUDProperties.ScrollWidth, FirstScrollSpace.Y);
	Canvas.SetPos(0, FifthScrollSpace.X);
	Canvas.DrawRect(HUDProperties.ScrollWidth, FifthScrollSpace.Y);
	Canvas.SetPos(PlayableSpaceRight, FifthScrollSpace.X);
	Canvas.DrawRect(HUDProperties.ScrollWidth, FifthScrollSpace.Y);
	// Draw the diagonal scroll borders
	Canvas.DrawColor = HUDProperties.ScrollDiagonalColor;	
	Canvas.SetPos(0, SecondScrollSpace.X);
	Canvas.DrawRect(HUDProperties.ScrollWidth, SecondScrollSpace.Y);
	Canvas.SetPos(PlayableSpaceRight, SecondScrollSpace.X);
	Canvas.DrawRect(HUDProperties.ScrollWidth, SecondScrollSpace.Y);
	Canvas.SetPos(0, FourthScrollSpace.X);
	Canvas.DrawRect(HUDProperties.ScrollWidth, FourthScrollSpace.Y);
	Canvas.SetPos(PlayableSpaceRight, FourthScrollSpace.X);
	Canvas.DrawRect(HUDProperties.ScrollWidth, FourthScrollSpace.Y);
	// Draw the horizontal scroll borders
	Canvas.DrawColor = HUDProperties.ScrollHorizontalColor;
	Canvas.SetPos(0, ThirdScrollSpace.X);
	Canvas.DrawRect(HUDProperties.ScrollWidth, ThirdScrollSpace.Y);
	Canvas.SetPos(PlayableSpaceRight, ThirdScrollSpace.X);
	Canvas.DrawRect(HUDProperties.ScrollWidth, ThirdScrollSpace.Y);

	// ==============================
	// Draw the selection group icons
	// ==============================
	if (HUDProperties.SelectionGroupIcon != None)
	{
		X = HUDProperties.ScrollWidth;
		Y = SizeY - SelectionGroupSize.Y;		

		for (i = 0; i < ArrayCount(UDKRTSMobilePlayerController.SelectionGroup); ++i)
		{
			Canvas.SetPos(X, Y);
			Canvas.DrawColor = HUDProperties.SelectionGroupColor;
			Canvas.DrawTile(HUDProperties.SelectionGroupIcon, SelectionGroupSize.X, SelectionGroupSize.Y, HUDProperties.SelectionGroupIconCoordinates.U, HUDProperties.SelectionGroupIconCoordinates.V, HUDProperties.SelectionGroupIconCoordinates.UL, HUDProperties.SelectionGroupIconCoordinates.VL);

			Text = String(UDKRTSMobilePlayerController.SelectionGroup[i].GroupedActors.Length);
			Canvas.Font = class'Engine'.static.GetTinyFont();
			Canvas.TextSize(Text, XL, YL);
			DrawBorderedText(Self, X + (SelectionGroupSize.X * 0.5f) - (XL * 0.5f), Y + SelectionGroupSize.Y - YL, Text, class'HUD'.default.WhiteColor, class'UDKRTSPalette'.default.BlackColor);

			X += SelectionGroupSize.X;
		}
	}

	// ================
	// Draw the minimap
	// ================
	MinimapTexture = class'UDKRTSMapInfo'.static.GetMinimapTexture();
	if (MinimapTexture != None)
	{
		X = PlayableSpaceRight - CurrentMinimapSize.X - DesiredMinimapSize.X;
		Y = 0;

		// Draw the minimap border
		Canvas.DrawColor = HUDProperties.MinimapBorderColor;
		Canvas.SetPos(X, Y);
		Canvas.DrawBox(CurrentMinimapSize.X + DesiredMinimapSize.X, CurrentMinimapSize.Y - DesiredMinimapSize.Y);
		// Draw the minimap 
		Canvas.DrawColor = HUDProperties.MinimapColor;
		Canvas.SetPos(X, Y);
		Canvas.DrawTile(MinimapTexture, CurrentMinimapSize.X + DesiredMinimapSize.X, CurrentMinimapSize.Y - DesiredMinimapSize.Y, 0, 0, MinimapTexture.SizeX, MinimapTexture.SizeY);
		// Draw the minimap tab
		Canvas.DrawColor = HUDProperties.MinimapExpandTabColor;
		Canvas.SetPos(X, Y + CurrentMinimapSize.Y - DesiredMinimapSize.Y - HUDProperties.MinimapExpandTabCoordinates.VL);
		Canvas.DrawTile(HUDProperties.MinimapExpandTab, HUDProperties.MinimapExpandTabCoordinates.UL, HUDProperties.MinimapExpandTabCoordinates.VL, HUDProperties.MinimapExpandTabCoordinates.U, HUDProperties.MinimapExpandTabCoordinates.V, HUDProperties.MinimapExpandTabCoordinates.UL, HUDProperties.MinimapExpandTabCoordinates.VL);

		ForEach DynamicActors(class'Actor', Actor, class'UDKRTSMinimapInterface')
		{
			MinimapInterface = UDKRTSMinimapInterface(Actor);
			if (MinimapInterface != None && MinimapInterface.ShouldRenderMinimapIcon())
			{
				MinimapInterface.GetMinimapIcon(MinimapIconTexture, MinimapIconU, MinimapIconV, MinimapIconUL, MinimapIconVL, MinimapIconColor, RenderBlackBorder);

				if (MinimapIconTexture != None)
				{
					MinimapPosition = ConvertWorldLocationToMinimapPosition(Actor.Location);

					if (RenderBlackBorder == 1)
					{
						Canvas.SetPos(MinimapPosition.X - (MinimapIconUL * 0.5f) - 1, MinimapPosition.Y - (MinimapIconVL * 0.5f) - 1);
						Canvas.DrawColor = class'UDKRTSPalette'.default.BlackColor;
						Canvas.DrawColor.A = 191;
						Canvas.DrawRect(MinimapIconUL + 2, MinimapIconVL + 2);
					}

					Canvas.SetPos(MinimapPosition.X - (MinimapIconUL * 0.5f), MinimapPosition.Y - (MinimapIconVL * 0.5f));
					Canvas.DrawColor = MinimapIconColor;
					Canvas.DrawColor.A = 191;
					Canvas.DrawTile(MinimapIconTexture, MinimapIconUL, MinimapIconVL, MinimapIconU, MinimapIconV, MinimapIconUL, MinimapIconVL);
				}
			}
		}

		// Handle draw the FOV camera on the minimap
		// Deproject the screen touch location
		Offset.X = 0.f;
		Offset.Y = 0.f;
		Canvas.Deproject(Offset, CurrentWorldLocation, CurrentWorldDirection);
		// Find the world location of the current camera location
		ForEach TraceActors(class'UDKRTSCameraBlockingVolume', UDKRTSCameraBlockingVolume, HitCurrentWorldLocation, HitNormal, CurrentWorldLocation + CurrentWorldDirection * 65536.f, CurrentWorldLocation)
		{
			break;
		}
		CameraFOV[0] = ConvertWorldLocationToMinimapPosition(HitCurrentWorldLocation);

		Offset.X = SizeX;
		Offset.Y = 0.f;
		Canvas.Deproject(Offset, CurrentWorldLocation, CurrentWorldDirection);
		// Find the world location of the current camera location
		ForEach TraceActors(class'UDKRTSCameraBlockingVolume', UDKRTSCameraBlockingVolume, HitCurrentWorldLocation, HitNormal, CurrentWorldLocation + CurrentWorldDirection * 65536.f, CurrentWorldLocation)
		{
			break;
		}
		CameraFOV[1] = ConvertWorldLocationToMinimapPosition(HitCurrentWorldLocation);

		Offset.X = SizeX;
		Offset.Y = SizeY;
		Canvas.Deproject(Offset, CurrentWorldLocation, CurrentWorldDirection);
		// Find the world location of the current camera location
		ForEach TraceActors(class'UDKRTSCameraBlockingVolume', UDKRTSCameraBlockingVolume, HitCurrentWorldLocation, HitNormal, CurrentWorldLocation + CurrentWorldDirection * 65536.f, CurrentWorldLocation)
		{
			break;
		}
		CameraFOV[2] = ConvertWorldLocationToMinimapPosition(HitCurrentWorldLocation);

		Offset.X = 0.f;
		Offset.Y = SizeY;
		Canvas.Deproject(Offset, CurrentWorldLocation, CurrentWorldDirection);
		// Find the world location of the current camera location
		ForEach TraceActors(class'UDKRTSCameraBlockingVolume', UDKRTSCameraBlockingVolume, HitCurrentWorldLocation, HitNormal, CurrentWorldLocation + CurrentWorldDirection * 65536.f, CurrentWorldLocation)
		{
			break;
		}
		CameraFOV[3] = ConvertWorldLocationToMinimapPosition(HitCurrentWorldLocation);

		Draw2DLine(CameraFOV[0].X, CameraFOV[0].Y, CameraFOV[1].X, CameraFOV[1].Y, class'HUD'.default.WhiteColor);
		Draw2DLine(CameraFOV[1].X, CameraFOV[1].Y, CameraFOV[2].X, CameraFOV[2].Y, class'HUD'.default.WhiteColor);
		Draw2DLine(CameraFOV[2].X, CameraFOV[2].Y, CameraFOV[3].X, CameraFOV[3].Y, class'HUD'.default.WhiteColor);
		Draw2DLine(CameraFOV[3].X, CameraFOV[3].Y, CameraFOV[0].X, CameraFOV[0].Y, class'HUD'.default.WhiteColor);
	}

	// ==================================
	// Draw the resources the player owns
	// ==================================
	UDKRTSPlayerReplicationInfo = UDKRTSPlayerReplicationInfo(PlayerOwner.PlayerReplicationInfo);
	if (UDKRTSPlayerReplicationInfo == None)
	{
		return;
	}

	X = PlayableSpaceRight - CurrentMinimapSize.X - DesiredMinimapSize.X;
	Y = 0;

	if (CurrentlyRenderedResources != UDKRTSPlayerReplicationInfo.Resources)
	{
		if (CurrentlyRenderedResources < UDKRTSPlayerReplicationInfo.Resources)
		{
			CurrentlyRenderedResources = FCeil(Lerp(float(CurrentlyRenderedResources), float(UDKRTSPlayerReplicationInfo.Resources), 0.9f * RenderDelta));
		}
		else 
		{
			CurrentlyRenderedResources = FFloor(Lerp(float(CurrentlyRenderedResources), float(UDKRTSPlayerReplicationInfo.Resources), 0.9f * RenderDelta));
		}
	}

	if (HUDProperties.ResourcesTextFont != None)
	{
		Canvas.Font = HUDProperties.ResourcesTextFont;
		Canvas.TextSize("99999", XL, YL);
		Canvas.DrawColor = HUDProperties.ResourcesTextColor;
		Canvas.SetPos(X - XL - 4, Y - 8);			
		Canvas.DrawText(String(CurrentlyRenderedResources));
	}

	if (HUDProperties.ResourcesIcon != None)
	{
		Canvas.DrawColor = HUDProperties.ResourcesIconColor;
		Canvas.SetPos(X - XL - HUDProperties.ResourcesIconCoordinates.UL - 6, Y + 2);
		Canvas.DrawTile(HUDProperties.ResourcesIcon, HUDProperties.ResourcesIconCoordinates.UL, HUDProperties.ResourcesIconCoordinates.VL, HUDProperties.ResourcesIconCoordinates.U, HUDProperties.ResourcesIconCoordinates.V, HUDProperties.ResourcesIconCoordinates.UL, HUDProperties.ResourcesIconCoordinates.VL);
	}

	// ==============================
	// Draw the power the player owns
	// ==============================
	if (CurrentlyRenderedPower != UDKRTSPlayerReplicationInfo.Power)
	{
		if (CurrentlyRenderedPower < UDKRTSPlayerReplicationInfo.Power)
		{
			CurrentlyRenderedPower = FCeil(Lerp(float(CurrentlyRenderedPower), float(UDKRTSPlayerReplicationInfo.Power), 0.9f * RenderDelta));
		}
		else
		{
			CurrentlyRenderedPower = FFloor(Lerp(float(CurrentlyRenderedPower), float(UDKRTSPlayerReplicationInfo.Power), 0.9f * RenderDelta));
		}
	}

	if (HUDProperties.PowerTextFont != None)
	{
		Canvas.Font = HUDProperties.PowerTextFont;
		Canvas.TextSize("99999", XL, YL);
		Canvas.DrawColor = HUDProperties.PowerTextColor;
		Canvas.SetPos(X - XL - 4, Y + HUDProperties.PowerIconCoordinates.VL - 6);
		Canvas.DrawText(String(CurrentlyRenderedPower));
	}

	if (HUDProperties.PowerIcon != None)
	{
		Canvas.DrawColor = HUDProperties.PowerIconColor;
		Canvas.SetPos(X - XL - HUDProperties.PowerIconCoordinates.UL - 6, Y + HUDProperties.ResourcesIconCoordinates.VL + 4);
		Canvas.DrawTile(HUDProperties.PowerIcon, HUDProperties.PowerIconCoordinates.UL, HUDProperties.PowerIconCoordinates.VL, HUDProperties.PowerIconCoordinates.U, HUDProperties.PowerIconCoordinates.V, HUDProperties.PowerIconCoordinates.UL, HUDProperties.PowerIconCoordinates.VL);
	}

	// =======================
	// Draw the population cap
	// =======================
	UDKRTSPlayerReplicationInfo = UDKRTSPlayerReplicationInfo(PlayerOwner.PlayerReplicationInfo);

	if (UDKRTSPlayerReplicationInfo != None)
	{
		UDKRTSTeamInfo = UDKRTSTeamInfo(UDKRTSPlayerReplicationInfo.Team);

		if (UDKRTSTeamInfo != None)
		{
			if (HUDProperties.PopulationTextFont != None)
			{
				Canvas.Font = HUDProperties.PopulationTextFont;
				Canvas.TextSize("99999", XL, YL);
				Canvas.DrawColor = HUDProperties.PopulationTextColor;
				Canvas.SetPos(X - XL - 4, Y + HUDProperties.PowerIconCoordinates.VL + HUDProperties.PopulationIconCoordinates.VL - 4);
				Canvas.DrawText(UDKRTSTeamInfo.Population@"/"@UDKRTSPlayerReplicationInfo.PopulationCap);
			}

			if (HUDProperties.PopulationIcon != None)
			{
				Canvas.DrawColor = HUDProperties.PopulationIconColor;
				Canvas.SetPos(X - XL - HUDProperties.PopulationIconCoordinates.UL - 6, Y + HUDProperties.ResourcesIconCoordinates.VL + HUDProperties.PowerIconCoordinates.VL + 6);
				Canvas.DrawTile(HUDProperties.PopulationIcon, HUDProperties.PopulationIconCoordinates.UL, HUDProperties.PopulationIconCoordinates.VL, HUDProperties.PopulationIconCoordinates.U, HUDProperties.PopulationIconCoordinates.V, HUDProperties.PopulationIconCoordinates.UL, HUDProperties.PopulationIconCoordinates.VL);
			}
		}
	}

	// =============
	// Draw the menu
	// =============
	DrawMenu();

	// ============================
	// Draw the fade in or fade out
	// ============================
	if (IsTimerActive(NameOf(FadeOutTimer)))
	{
		Alpha = 1.f - (GetTimerCount(NameOf(FadeOutTimer)) / GetTimerRate(NameOf(FadeOutTimer)));
		Canvas.SetPos(0, 0);
		Canvas.SetDrawColor(0, 0, 0, 255 * Alpha);
		Canvas.DrawRect(SizeX, SizeY);
	}
}

/**
 * Draws the menu onto the HUD
 */
function DrawMenu()
{
}

/**
 * Converts a minimap space location into a world space location
 *
 * @param		MinimapPosition			Position somewhere within the minimap
 * @return								Returns the world space location
 */
function Vector ConvertMinimapPositionToWorldLocation(Vector2D MinimapPosition)
{
	local Vector WorldLocation, WorldUpperBounds, WorldLowerBounds;
	local float MinimapWidth, MinimapHeight, RelativeMinimapPosX, RelativeMinimapPosY, WorldWidth, WorldHeight;

	// Minimap dimensions
	MinimapWidth = CurrentMinimapSize.X + DesiredMinimapSize.X;
	MinimapHeight = CurrentMinimapSize.Y - DesiredMinimapSize.Y;

	// Clamp the minimap position
	MinimapPosition.X = FClamp(MinimapPosition.X, PlayableSpaceRight - MinimapWidth, PlayableSpaceRight);
	MinimapPosition.Y = FClamp(MinimapPosition.Y, 0.f, MinimapHeight);

	// Convert the minimap position into percentage coordinates
	RelativeMinimapPosX = ((PlayableSpaceRight - MinimapWidth) - MinimapPosition.X) / MinimapWidth;
	RelativeMinimapPosY = MinimapPosition.Y / MinimapHeight;

	// World upper bounds
	WorldUpperBounds = class'UDKRTSMapInfo'.static.GetMinimapUpperBounds();
	WorldLowerBounds = class'UDKRTSMapInfo'.static.GetMinimapLowerBounds();

	// World dimensions
	WorldWidth = WorldUpperBounds.X - WorldLowerBounds.X;
	WorldHeight = WorldUpperBounds.Y - WorldLowerBounds.Y;

	// Get the final world location
	WorldLocation.X = WorldLowerBounds.X - (RelativeMinimapPosX * WorldWidth);
	WorldLocation.Y = WorldLowerBounds.Y + (RelativeMinimapPosY * WorldHeight);

	return WorldLocation;
}

/**
 * Converts a world space location into a minimap space location
 *
 * @param		WorldLocation		Location somewhere within the world
 * @return							Returns the minimap space position
 */
function Vector2D ConvertWorldLocationToMinimapPosition(Vector WorldLocation)
{
	local Vector2D MinimapPosition;
	local float MinimapWidth, MinimapHeight, WorldWidth, WorldHeight;
	local Vector WorldUpperBounds, WorldLowerBounds;

	// World upper bounds
	WorldUpperBounds = class'UDKRTSMapInfo'.static.GetMinimapUpperBounds();
	WorldLowerBounds = class'UDKRTSMapInfo'.static.GetMinimapLowerBounds();

	// World dimensions
	WorldWidth = WorldUpperBounds.X - WorldLowerBounds.X;
	WorldHeight = WorldUpperBounds.Y - WorldLowerBounds.Y;

	// Minimap dimensions
	MinimapWidth = CurrentMinimapSize.X + DesiredMinimapSize.X;
	MinimapHeight = CurrentMinimapSize.Y - DesiredMinimapSize.Y;

	// Clamp the world location
	WorldLocation.X = FClamp(WorldLocation.X, WorldLowerBounds.X, WorldUpperBounds.X);
	WorldLocation.Y = FClamp(WorldLocation.Y, WorldLowerBounds.Y, WorldUpperBounds.Y);

	// Get the world location in relation to the lower bounds
	WorldLocation.X = WorldLocation.X - WorldLowerBounds.X;
	WorldLocation.Y = WorldLocation.Y - WorldLowerBounds.Y;

	// Get the mini map position
	MinimapPosition.X = WorldLocation.X / WorldWidth * MinimapWidth;
	MinimapPosition.Y = WorldLocation.Y / WorldHeight * MinimapHeight;

	// Offset the mini map position
	MinimapPosition.X += PlayableSpaceRight - CurrentMinimapSize.X - DesiredMinimapSize.X;
	MinimapPosition.Y += 0;

	return MinimapPosition;
}

/**
 * Handles input touch
 *
 * @param		ScreenTouchLocation			Touch location in screen space
 * @return									Returns the touch response, ETR_None if the HUD did not handle this touch event
 */
function ETouchResponse InputTouch(Vector2D ScreenTouchLocation)
{
	local int i, j, X, Y;
	local Vector2D Offset, Size;
	local Box MinimapExpandTabBox, MinimapBox, SelectionGroupBox, IdleButtonBox;
	local UDKRTSMobilePlayerController UDKRTSMobilePlayerController;
	local UDKRTSCamera UDKRTSCamera;

	if (HUDProperties == None)
	{
		return ETR_None;
	}

	// Check the minimap controls
	UDKRTSMobilePlayerController = UDKRTSMobilePlayerController(PlayerOwner);
	if (UDKRTSMobilePlayerController != None)
	{
		// Check minimap expand tab
		if (UDKRTSMobilePlayerController.TouchEvents.Find('Response', ETR_MinimapExpand) == INDEX_NONE)
		{
			MinimapExpandTabBox.Min.X = PlayableSpaceRight - CurrentMinimapSize.X - DesiredMinimapSize.X;
			MinimapExpandTabBox.Min.Y = CurrentMinimapSize.Y - DesiredMinimapSize.Y - HUDProperties.MinimapExpandTabCoordinates.VL;
			MinimapExpandTabBox.Max.X = MinimapExpandTabBox.Min.X + HUDProperties.MinimapExpandTabCoordinates.UL;
			MinimapExpandTabBox.Max.Y = MinimapExpandTabBox.Min.Y + HUDProperties.MinimapExpandTabCoordinates.VL;
			if (IsPointWithinBox(ScreenTouchLocation, MinimapExpandTabBox))
			{
				return ETR_MinimapExpand;
			}
		}

		// If we're panning the camera via finger panning, don't allow minimap panning
		// If we're panning the camera via edge panning, don't allow minimap panning
		if (UDKRTSMobilePlayerController.TouchEvents.Find('Response', ETR_Camera) == INDEX_NONE && UDKRTSMobilePlayerController.TouchEvents.Find('Response', ETR_CameraPanning) == INDEX_NONE)
		{
			// Check if we're in the mini map
			MinimapBox.Min.X = PlayableSpaceRight - CurrentMinimapSize.X - DesiredMinimapSize.X;
			MinimapBox.Min.Y = 0.f;
			MinimapBox.Max.X = MinimapBox.Min.X + (CurrentMinimapSize.X - DesiredMinimapSize.X);
			MinimapBox.Max.Y = CurrentMinimapSize.Y - DesiredMinimapSize.Y;
			if (IsPointWithinBox(ScreenTouchLocation, MinimapBox))
			{
				return ETR_Minimap;
			}
		}

		// Check the HUD action controls
		if (AssociatedHUDActions.Length > 0)
		{
			Offset.X = PlayableSpaceLeft;
			Offset.Y = 0;
			Size.X = SizeX * 0.0625f;
			Size.Y = Size.X;

			for (i = 0; i < AssociatedHUDActions.Length; ++i)
			{
				if (AssociatedHUDActions[i].AssociatedActor != None && AssociatedHUDActions[i].HUDActions.Length > 0)
				{
					Offset.X = HUDProperties.ScrollWidth;

					for (j = 0; j < AssociatedHUDActions[i].HUDActions.Length; ++j)
					{
						if (ScreenTouchLocation.X >= Offset.X && ScreenTouchLocation.Y >= Offset.Y && ScreenTouchLocation.X <= Offset.X + Size.X && ScreenTouchLocation.Y <= Offset.Y + Size.Y)
						{
							if (AssociatedHUDActions[i].HUDActions[j].IsHUDActionActiveDelegate != None)
							{
								IsHUDActionActive = AssociatedHUDActions[i].HUDActions[j].IsHUDActionActiveDelegate;

								if (!IsHUDActionActive(AssociatedHUDActions[i].HUDActions[j].Reference, AssociatedHUDActions[i].HUDActions[j].Index, true))
								{
									IsHUDActionActive = None;
									return ETR_HUDAction;
								}
								else
								{
									IsHUDActionActive = None;
								}
							}

							// Start the HUD action
							UDKRTSMobilePlayerController.StartHUDAction(AssociatedHUDActions[i].HUDActions[j].Reference, AssociatedHUDActions[i].HUDActions[j].Index, AssociatedHUDActions[i].AssociatedActor);
							return ETR_HUDAction;
						}

						Offset.X += Size.X;
					}

					Offset.Y += Size.Y;
				}
			}
		}
	}

	// Check the selection groups
	if (HUDProperties.SelectionGroupIcon != None)
	{
		X = HUDProperties.ScrollWidth;
		Y = SizeY - SelectionGroupSize.Y;

		for (i = 0; i < ArrayCount(UDKRTSMobilePlayerController.SelectionGroup); ++i)
		{
			SelectionGroupBox.Min.X = X;
			SelectionGroupBox.Min.Y = Y;
			SelectionGroupBox.Max.X = SelectionGroupBox.Min.X + SelectionGroupSize.X;
			SelectionGroupBox.Max.Y = SelectionGroupBox.Min.Y + SelectionGroupSize.Y;

			if (IsPointWithinBox(ScreenTouchLocation, SelectionGroupBox))
			{
				switch (i)
				{
				case 0:
					return ETR_SelectionGroup_0;

				case 1:
					return ETR_SelectionGroup_1;

				case 2:
					return ETR_SelectionGroup_2;

				case 3:
					return ETR_SelectionGroup_3;

				case 4:
					return ETR_SelectionGroup_4;

				case 5:
					return ETR_SelectionGroup_5;

				case 6:
					return ETR_SelectionGroup_6;

				case 7:
					return ETR_SelectionGroup_7;

				case 8:
					return ETR_SelectionGroup_8;

				case 9:
					return ETR_SelectionGroup_9;

				default:
					return ETR_None;
				}
			}

			X += SelectionGroupSize.X;
		}
	}

	// Check the world messages
	if (WorldMessages.Length > 0 && PlayerOwner != None)
	{
		for (i = 0; i < WorldMessages.Length; ++i)
		{
			if (IsPointWithinBox(ScreenTouchLocation, WorldMessages[i].BoundingBox))
			{
				UDKRTSCamera = UDKRTSCamera(PlayerOwner.PlayerCamera);
				if (UDKRTSCamera != None)
				{
					UDKRTSCamera.CurrentLocation = WorldMessages[i].WorldLocation;
					UDKRTSCamera.AdjustLocation(WorldMessages[i].WorldLocation);
				}

				return ETR_DeferTouch;
			}
		}
	}

	// Check the idle icon
	if (UDKRTSMobilePlayerController != None && UDKRTSMobilePlayerController.IdleUnits.Length > 0)
	{
		Size.X = SizeX * 0.03125;

		IdleButtonBox.Min.X = SizeX - HUDProperties.ScrollWidth - Size.X - 4.f;
		IdleButtonBox.Min.Y = SizeY - SelectionGroupSize.Y - Size.X - 4.f;
		IdleButtonBox.Max.X = IdleButtonBox.Min.X + Size.X;
		IdleButtonBox.Max.Y = IdleButtonBox.Min.Y + Size.X;

		if (IsPointWithinBox(ScreenTouchLocation, IdleButtonBox))
		{
			UDKRTSCamera = UDKRTSCamera(UDKRTSMobilePlayerController.PlayerCamera);

			if (UDKRTSCamera != None)
			{
				UDKRTSCamera.CurrentLocation = UDKRTSMobilePlayerController.IdleUnits[UDKRTSMobilePlayerController.CurrentIdleUnitIndex].Location;
				UDKRTSCamera.AdjustLocation(UDKRTSMobilePlayerController.IdleUnits[UDKRTSMobilePlayerController.CurrentIdleUnitIndex].Location);

				UDKRTSMobilePlayerController.CurrentIdleUnitIndex++;
				if (UDKRTSMobilePlayerController.CurrentIdleUnitIndex >= UDKRTSMobilePlayerController.IdleUnits.Length)
				{
					UDKRTSMobilePlayerController.CurrentIdleUnitIndex = 0;
				}
			}
		}
	}

	return ETR_None;
}

/**
 * Draws the clock specific for the mobile platform
 *
 * @param		HUD					HUD to draw the clock onto
 * @param		Percentage			Percentage of time left
 * @param		TimeLeft			Actual time left
 * @param		ClockPosX			X position of the clock 
 * @param		ClockPosY			Y position of the clock
 * @param		ClockSizeX			X size of the clock
 * @param		ClockSizeY			Y size of the clock
 */
static simulated function DrawClock(HUD HUD, float Percentage, float TimeLeft, float ClockPosX, float ClockPosY, float ClockSizeX, float ClockSizeY)
{
	local string Text;
	local int FrameIndex;
	local float XL, YL;

	// Draw the winding clock
	FrameIndex = Percentage * class'UDKRTSMobileHUD'.default.HUDProperties.ClockTextures.Length;
	if (FrameIndex >= 0 && FrameIndex < class'UDKRTSMobileHUD'.default.HUDProperties.ClockTextures.Length)
	{
		HUD.Canvas.SetPos(ClockPosX, ClockPosY);
		HUD.Canvas.DrawColor = class'UDKRTSMobileHUD'.default.HUDProperties.ClockColor;
		HUD.Canvas.DrawTile(class'UDKRTSMobileHUD'.default.HUDProperties.ClockTextures[FrameIndex], ClockSizeX, ClockSizeY, 0.f, 0.f, class'UDKRTSMobileHUD'.default.HUDProperties.ClockTextures[FrameIndex].SizeX, class'UDKRTSMobileHUD'.default.HUDProperties.ClockTextures[FrameIndex].SizeY);
	}

	// Draw the time left
	Text = String(TimeLeft);
	Text = Left(Text, InStr(Text, ".") + 2)$"s";
	HUD.Canvas.Font = class'Engine'.static.GetTinyFont();
	HUD.Canvas.TextSize(Text, XL, YL);
	class'UDKRTSMobileHUD'.static.DrawBorderedText(HUD, ClockPosX + (ClockSizeX * 0.5f) - (XL * 0.5f), ClockPosY + ClockSizeY - (YL * 0.5f) - 8, Text, class'HUD'.default.WhiteColor, class'UDKRTSPalette'.default.BlackColor);
	
	// Draw a black border around it
	HUD.Canvas.SetPos(ClockPosX - 1, ClockPosY - 1);
	HUD.Canvas.SetDrawColor(0, 0, 0, 191);
	HUD.Canvas.DrawBox(ClockSizeX + 2, ClockSizeY + 2);
}

defaultproperties
{
	HUDProperties=UDKRTSMobileHUDProperties'UDKRTSGameContent.Archetypes.MobileHUDProperties'
	CameraPanningTouchEventIndex=-1
	CurrentMinimapSize=(X=192,Y=192)
}