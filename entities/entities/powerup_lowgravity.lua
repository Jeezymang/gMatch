ENT.Type = "anim"
ENT.Base = "base_powerup"
ENT.PrintName = "Low Gravity Powerup"
ENT.Author = "Jeezy"
ENT.Spawnable = true
ENT.Model = "models/jeezy/gslayer/props/powerup.mdl"
ENT.EntityColor = Color( 0, 255, 255, 255 )
ENT.AdminSpawnable = true
if ( SERVER ) then
	AddCSLuaFile( )
	function ENT:Initialize( )
		self:SetModel( self.Model )
		--self.EntityColor = Color( 0, 255, 255, 255 )
		self:SetColor( self.EntityColor )
		self:DoPhysics( )
		self.PowerupLength = 10
		self.nextUse = CurTime( )
	end
	function ENT:Touch( entity )
		if entity:IsPlayer() then
			entity.nextGravityPowerup = entity.nextGravityPowerup or CurTime( )
			if ( entity.nextGravityPowerup < CurTime( ) and self.nextUse < CurTime( ) ) then
				self:ToggleHalo( )
				local oldGravity = entity:GetGravity( )
				local newGravity = 0.1
				entity:SetGravity( newGravity )
				entity.nextGravityPowerup = CurTime( ) + self.PowerupLength
				self.nextUse = CurTime( ) + self.PowerupLength
				//entity:SendColoredMessage( { self.EntityColor, "You feel much lighter." } )
				entity:DisplayNotify( "You feel much lighter...", 5, "icon16/user_go.png" )
				entity:SetHealth( math.Clamp( entity:Health( ) + 35, 1, 100 ) ) -- One as minimum just incase some fucked up glitch occurs.
				entity:EmitSound( "ambient/levels/citadel/portal_beam_shoot5.wav" )
				local selTbl = self:GetDefaultParticles( )
				selTbl.selColor = { 0, 255, 255 }
				self:TriggerParticleEffects( selTbl )
				timer.Simple( self.PowerupLength, function( )
					if ( !entity or !entity:IsValid( ) ) then return end
					entity:DisplayNotify( "You've become gravity's bitch.", 5, "icon16/user_go.png" )
					entity:SetGravity( oldGravity )
					self:ToggleHalo( )
				end )
			end
		end
	end
end