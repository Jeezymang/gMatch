ENT.Type = "anim"
ENT.Base = "base_powerup"
ENT.PrintName = "XRay Powerup"
ENT.Author = "Jeezy"
ENT.Spawnable = true
ENT.Model = "models/jeezy/gslayer/props/powerup.mdl"
ENT.EntityColor = Color( 191, 85, 236, 255 )
ENT.AdminSpawnable = true
local haloRenderRange = 543380

if ( SERVER ) then
	AddCSLuaFile( )
	util.AddNetworkString( "GMatch:Powerups_XRay" )
	function ENT:Initialize( )
		self:SetModel( self.Model )
		self.PowerupLength = 15
		self:DoPhysics( )
		--self.EntityColor = Color( 191, 85, 236, 255 )
		self:SetColor( self.EntityColor )
		self.nextUse = CurTime( )
	end
	function ENT:ToggleXRay( ply )
		net.Start( "GMatch:Powerups_XRay" )
		net.Send( ply )
	end
	function ENT:Touch( entity )
		if entity:IsPlayer() then
			entity.nextXRayPowerUp = entity.nextXRayPowerUp or CurTime( )
			if ( entity.nextXRayPowerUp < CurTime( ) and self.nextUse < CurTime( ) ) then
				self:ToggleHalo( )
				entity.nextXRayPowerUp = CurTime( ) + self.PowerupLength
				self.nextUse = CurTime( ) + self.PowerupLength
				self:ToggleXRay( entity )
				entity:DisplayNotify( "Your vision sharpens, almost supernaturally.", 5, "icon16/eye.png" )
				entity:EmitSound( "ambient/levels/citadel/portal_beam_shoot5.wav" )
				local selTbl = self:GetDefaultParticles( )
				selTbl.selColor = { 170, 20, 200 }
				self:TriggerParticleEffects( selTbl )
				timer.Simple( self.PowerupLength, function( )
					if ( !entity or !entity:IsValid( ) ) then return end
					self:ToggleXRay( entity )
					entity:DisplayNotify( "Your vision returns to normal.", 5, "icon16/eye.png" )
					self:ToggleHalo( )
				end )
			end
		end
	end
elseif ( CLIENT ) then
	local function DrawXRayHalos( )
		for index, ply in ipairs ( player.GetAll( ) ) do
			if ( ply:GetObserverMode( ) == OBS_MODE_NONE ) then
				if not ( LocalPlayer( ):GetPos( ):DistToSqr( ply:GetPos( ) ) > haloRenderRange ) then
					halo.Add( { ply }, Color( 255, 0, 0 ), 5, 5, 2, 1, true )
				end
			end
		end
	end
	local function ReceiveServerNET( len )
		LocalPlayer( ).xRayEnabled = LocalPlayer( ).xRayEnabled or false
		if ( LocalPlayer( ).xRayEnabled ) then
			hook.Remove( "PreDrawHalos", "GSlayer_Powerups_XRay" )
			LocalPlayer( ).xRayEnabled = false
		else
			hook.Add( "PreDrawHalos", "GSlayer_Powerups_XRay", DrawXRayHalos )
			LocalPlayer( ).xRayEnabled = true
		end
	end
	net.Receive( "GMatch:Powerups_XRay", ReceiveServerNET )
end