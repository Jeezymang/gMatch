ENT.Type = "anim"
ENT.Base = "base_powerup"
ENT.PrintName = "Speed Powerup"
ENT.Author = "Jeezy"
ENT.Spawnable = true
ENT.Model = "models/jeezy/gslayer/props/powerup.mdl"
ENT.EntityColor = Color( 255, 255, 255, 255 )
ENT.AdminSpawnable = true
if ( SERVER ) then
	AddCSLuaFile( )
	function ENT:Initialize( )
		self:SetModel( self.Model )
		self.PowerupLength = 5
		self:DoPhysics( )
		self.nextUse = CurTime( )
	end
	function ENT:Touch( entity )
		if entity:IsPlayer() then
			entity.nextSpeedPowerUp = entity.nextSpeedPowerUp or CurTime( )
			if ( entity.nextSpeedPowerUp < CurTime( ) and self.nextUse < CurTime( ) ) then
				self:ToggleHalo( )
				entity.nextSpeedPowerUp = CurTime( ) + self.PowerupLength
				self.nextUse = CurTime( ) + self.PowerupLength
				local oldRunSpeed = entity:GetRunSpeed( )
				entity:SetRunSpeed( oldRunSpeed * 4 )
				--entity:SendColoredMessage( { self.EntityColor, "Suddenly you feel much faster." } )
				entity:DisplayNotify( "You feel much faster.", 5, "icon16/lightning.png" )
				//entity:AddGSNotify( "Suddenly you feel much faster.", "materials/icon16/lightning.png", self.EntityColor, 2, false )
				entity:EmitSound( "ambient/levels/citadel/portal_beam_shoot5.wav" )
				local selTbl = self:GetDefaultParticles( )
				selTbl.selColor = { 0, 0, 255 }
				self:TriggerParticleEffects( selTbl )
				timer.Simple( self.PowerupLength, function( )
					if ( !entity or !entity:IsValid( ) ) then return end
					entity:SetRunSpeed( oldRunSpeed )
					entity:DisplayNotify( "You begin to feel exhausted.", 5, "icon16/lightning.png" )
					--entity:SendColoredMessage( { self.EntityColor, "You begin to feel exhausted." } )
					//entity:AddGSNotify( "You've become exhausted.", "materials/icon16/lightning.png", self.EntityColor, 2, false )
					self:ToggleHalo( )
				end )
			end
		end
	end
end