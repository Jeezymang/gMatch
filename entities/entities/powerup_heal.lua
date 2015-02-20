ENT.Type = "anim"
ENT.Base = "base_powerup"
ENT.PrintName = "Heal Powerup"
ENT.Author = "Jeezy"
ENT.Spawnable = true
ENT.Model = "models/jeezy/gslayer/props/powerup.mdl"
ENT.EntityColor = Color( 0, 255, 0, 255 )
ENT.AdminSpawnable = true
if ( SERVER ) then
	AddCSLuaFile( )
	function ENT:Initialize( )
		self:SetModel( self.Model )
		--self.EntityColor = Color( 0, 255, 0, 255 )
		self:SetColor( self.EntityColor )
		self:DoPhysics( )
		self.PowerupLength = 10
		self.nextUse = CurTime( )
	end
	function ENT:Touch( entity )
		if entity:IsPlayer() then
			entity.nextHealPowerUp = entity.nextHealPowerUp or CurTime( )
			if ( entity.nextHealPowerUp < CurTime( ) and self.nextUse < CurTime( ) ) then
				self:ToggleHalo( )
				entity.nextHealPowerUp = CurTime( ) + self.PowerupLength
				self.nextUse = CurTime( ) + self.PowerupLength
				entity:DisplayNotify( "You feel slightly rejuvenated", 5, "icon16/heart_add.png" )
				entity:SetHealth( math.Clamp( entity:Health( ) + 35, 1, 100 ) )
				entity:EmitSound( "ambient/levels/citadel/portal_beam_shoot5.wav" )
				local selTbl = self:GetDefaultParticles( )
				selTbl.selColor = { 0, 255, 0 }
				self:TriggerParticleEffects( selTbl )
				timer.Simple( self.PowerupLength, function( )
					if ( !entity or !entity:IsValid( ) ) then return end
					self:ToggleHalo( )
				end )
			end
		end
	end
end