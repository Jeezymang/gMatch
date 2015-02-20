ENT.Type = "anim"
ENT.Base = "base_entity"
ENT.PrintName = "Small Ammo Crate"
ENT.Author = "Jeezy"
ENT.Spawnable = true
ENT.Model = "models/Items/BoxMRounds.mdl"
ENT.PossibleModels = { "models/Items/BoxMRounds.mdl", "models/Items/BoxSRounds.mdl" }
ENT.EntityColor = Color( 255, 255, 255, 255 )
ENT.Cooldown = 3
ENT.MaxUses = 3
ENT.MaxHealth = 50
ENT.AdminSpawnable = true
if ( SERVER ) then
	AddCSLuaFile( )
	function ENT:Initialize( )
		self:SetModel( self.PossibleModels[math.random( #self.PossibleModels )] )
		self:SetColor( self.EntityColor )
		self:DoPhysics( )
		self.MaxUses = math.random( 1, 3 )
		self.nextUse = CurTime( )
		self.usesLeft = self.MaxUses
		self.currentHealth = self.MaxHealth
	end
	function ENT:DoPhysics( )
		self:PhysicsInit(SOLID_VPHYSICS)
		self:SetMoveType(MOVETYPE_VPHYSICS)
		self:SetSolid(SOLID_VPHYSICS)
		self:SetUseType(SIMPLE_USE)
		local phys = self:GetPhysicsObject()
		phys:Wake()
	end
	function ENT:OnTakeDamage( dmgInfo )
		self.currentHealth = self.currentHealth - dmgInfo:GetDamage( )
		if ( self.currentHealth <= 0 ) then
			self.destructor = dmgInfo:GetAttacker( )
			self:Remove( )
		end
	end
	function ENT:OnRemove( )
		if ( self.currentHealth <= 0 ) then
			self.destructor = self.destructor or nil
			util.Explode( self:GetPos( ), self.destructor, 75, 125, "ambient/explosions/explode_1.wav", 400, 100 )
			self:TriggerParticles( )
		end
	end
	function ENT:Use( activator, caller, useType, val )
		if ( self.nextUse < CurTime( ) ) then
			self.nextUse = CurTime( ) + self.Cooldown
			self:EmitSound( "weapons/physcannon/physcannon_pickup.wav" )
			util.QuickEffect( self:GetPos( ), self:GetPos( ), 1, "ManhackSparks" )
			activator:GiveCurrentPrimaryAmmo( 100 )
			/*local hasPrimary, hasSecondary = activator:GiveEitherAmmoTypes( true, false, 5, 0, true )
			if ( hasPrimary ) then 
				activator:SendColoredMessage( { COLOR_GRAY, "You pick up some primary ammo." } )
			else
				activator:SendColoredMessage( { COLOR_GRAY, "None of your weapons take primary ammo." } )
				return
			end*/
			self.usesLeft = self.usesLeft - 1
			if ( self.usesLeft == 0 ) then 
				self:TriggerParticles( )
				self:Remove( )
			end
		end
	end
	function ENT:TriggerParticles( )
		local selTbl = { }
		selTbl.selOrigin = self:GetPos( )
		selTbl.selMax = 7
		selTbl.selSprite = "particle/particle_glow_02"
		selTbl.selColor = { 45, 45, 45 }
		selTbl.selVelocity = nil
		selTbl.selVelocityMulti = 76
		selTbl.selRoll = 0
		selTbl.selRollDelta = 0
		selTbl.selDieTime = 3
		selTbl.selLifeTime = 2
		selTbl.selStartAlpha = 100
		selTbl.selStartSize = 50
		selTbl.selEndSize = 15
		selTbl.selEndAlpha = 25
		selTbl.selGravity = Vector( 0, 0, 0 )
		selTbl.selStartLength = 0
		net.Start( "GMatch:ManipulateMisc" )
			net.WriteUInt( NET_MISC_TRIGGERPARTICLES, 16 )
			net.WriteTable( selTbl )
		net.Broadcast( )
	end
else
	function ENT:Draw( )
		self:DrawModel( )
	end
end