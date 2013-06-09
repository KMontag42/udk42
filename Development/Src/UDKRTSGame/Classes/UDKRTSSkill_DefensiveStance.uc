//=============================================================================
// UDKRTSSkill_DefensiveStance: Defensive stance skill that units can perform.
//
// This skill gives units defensive bonuses when it is activated.
// 
// Copyright 1998-2011 Epic Games, Inc. All Rights Reserved.
//=============================================================================
class UDKRTSSkill_DefensiveStance extends UDKRTSSkill;

// Icon on the screen
var(Skill) const CanvasIcon CanvasIcon;

/**
 * Stub which subclasses will extend for custom skill activation code
 *
 * @param		Pawn			Pawn that activated this skill
 * @param		AimLocation		World location the skill is targeted at
 */
protected simulated function OnActivate(UDKRTSPawn Pawn, Vector AimLocation)
{
	Pawn.DefensiveBonus += 0.3f;
	Pawn.ShouldCrouch(true);
}

/**
 * Stub which subclasses will extend for custom skill deactivation code
 *
 * @param		Pawn			Pawn that deactivated this skill
 * @param		AimLocation		World location the skill is targeted at
 */
protected simulated function OnDeactivate(UDKRTSPawn Pawn, Vector AimLocation)
{
	Pawn.DefensiveBonus -= 0.3f;
	Pawn.ShouldCrouch(false);
}

/**
 * Returns true if the skill requires a post render event call
 *
 * @param		Pawn			Pawn that owns this skill
 */
simulated function bool RequiresPostRender(UDKRTSPawn Pawn)
{
	return IsActive;
}

/**
 * Sub which subclasses will extend to perform custom rendering onto the HUD
 *
 * @param		HUD				HUD to render to
 * @param		Pawn			Pawn that owns this skill
 */
simulated function PostRender(HUD HUD, UDKRTSPawn Pawn)
{
	local Vector WorldLocation, ScreenLocation;
	local float ShieldSize;

	if (CanvasIcon.Texture == None || HUD == None || !IsActive)
	{
		return;
	}

	WorldLocation = Pawn.Location + (Vect(0.f, 0.f, 1.f) * Pawn.GetCollisionHeight());
	ScreenLocation = HUD.Canvas.Project(WorldLocation);

	ShieldSize = HUD.Canvas.ClipX * 0.015625;
	HUD.Canvas.SetDrawColor(255, 255, 255, 191);
	HUD.Canvas.SetPos(ScreenLocation.X - (ShieldSize * 0.5f), ScreenLocation.Y - ShieldSize);
	HUD.Canvas.DrawTile(CanvasIcon.Texture, ShieldSize, ShieldSize, CanvasIcon.U, CanvasIcon.V, CanvasIcon.UL, CanvasIcon.VL);
}

defaultproperties
{
}