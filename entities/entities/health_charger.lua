ENT.Type = "anim"
ENT.Base = "base_entity"
ENT.PrintName = "Health Charger"
ENT.Author = "Jeezy"
ENT.Spawnable = true
ENT.Model = "models/props_combine/health_charger001.mdl"
ENT.AdminSpawnable = true
if ( SERVER ) then
	AddCSLuaFile( )
	function ENT:Initialize( )
		self:SetModel( self.Model )
		self:DoPhysics( )
		self:SetSequence( self:LookupSequence( "idle" ) )
		self:SetUseType( CONTINUOUS_USE )
		self.nextSound = CurTime( )
	end
	function ENT:DoPhysics( )
		self:PhysicsInit(SOLID_VPHYSICS)
		self:SetMoveType(MOVETYPE_VPHYSICS)
		self:SetSolid(SOLID_VPHYSICS)
		self:SetUseType(SIMPLE_USE)
		local phys = self:GetPhysicsObject()
		phys:Wake()
	end
	function ENT:Use( activator, caller, useType, val )
		if ( self:GetCycle( ) == 1 or activator:Health( ) >= 100 ) then
			if ( self:GetCycle( ) == 1 ) then
				if not ( timer.Exists( "Health_Charger_Refill " .. self:EntIndex( ) ) ) then
					self:SetSequence( self:LookupSequence( "empty" ) )
					timer.Create( "Health_Charger_Refill " .. self:EntIndex( ), GMatch.Config.HealthChargerRefillTime, 1, function( )
						if ( !self or !self:IsValid( ) ) then return end
						self:SetSequence( self:LookupSequence( "idle" ) )
						self:ResetSequence( self:LookupSequence( "idle" ) )
						self:SetPlaybackRate( 0 )
						self:SetCycle( 0 )
					end )
				end
			end
			if ( self.nextSound < CurTime( ) ) then
				self.nextSound = CurTime( ) + 1
				self:EmitSound( "buttons/button2.wav" ) 
				activator:ConCommand( "-use" )
			end
			return 
		end
		if ( timer.Exists( "Health_Charger_EndUse " .. self:EntIndex( ) ) ) then
			timer.Destroy( "Health_Charger_EndUse " .. self:EntIndex( ) )
		end
		activator:SetHealth( activator:Health( ) + math.random( 0, 1 ) )
		self:SetPlaybackRate( 0.3 )
		self.useSound = CreateSound( self, "items/medcharge4.wav" )
		self.useSound:Play( )
		--if not ( self.useSound:IsPlaying( ) ) then self.useSound:Play( ) end
		timer.Create( "Health_Charger_EndUse " .. self:EntIndex( ), 0.2, 1, function( )
			if ( !self or !self:IsValid( ) ) then return end
			self:SetPlaybackRate( 0 )
			self.useSound:Stop( )
		end )
	end
else
	function ENT:Draw( )
		self:DrawModel( )
	end
end