ENT.Type = "anim"
ENT.Base = "base_entity"
ENT.PrintName = "Large Ammo Crate"
ENT.Author = "Jeezy"
ENT.Spawnable = true
ENT.Model = "models/Items/ammocrate_smg1.mdl"
ENT.EntityColor = Color( 255, 255, 255, 255 )
ENT.Cooldown = 3
ENT.MaxUses = 3
ENT.MaxHealth = 200
ENT.AdminSpawnable = true
if ( SERVER ) then
	AddCSLuaFile( )
	function ENT:Initialize( )
		self:SetModel( self.Model )
		self:SetColor( self.EntityColor )
		self:DoPhysics( )
		self.MaxUses = math.random( 2, 4 )
		self.nextUse = CurTime( )
		self.usesLeft = self.MaxUses
		self.currentHealth = self.MaxHealth
		self.wasOpened = false
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
			util.Explode( self:GetPos( ), self.destructor, 220, 175, "ambient/explosions/explode_2.wav", 400, 100 )
			self:TriggerParticles( )
		end
	end
	function ENT:Use( activator, caller, useType, val )
		if ( self.nextUse < CurTime( ) ) then
			self.nextUse = CurTime( ) + self.Cooldown
			self:EmitSound( "weapons/physcannon/physcannon_pickup.wav" )
			util.QuickEffect( self:GetPos( ), self:GetPos( ), 1, "ManhackSparks" )
			if not ( self.wasOpened ) then
				self:ResetSequence( self:LookupSequence( "open" ) )
				self.wasOpened = true
				timer.Simple( self:SequenceDuration( ), function( ) 
					if ( !self or !self:IsValid( ) ) then return end
					self:ResetSequence( self:LookupSequence( "close" ) )
					self.wasOpened = false
				end )
			end
			activator:GiveCurrentPrimaryAmmo( 45 )
			/*local hasPrimary, hasSecondary = activator:GiveEitherAmmoTypes( true, false, 20, 0, true )
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
		selTbl.selStartSize = 70
		selTbl.selEndSize = 50
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