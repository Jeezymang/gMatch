AddCSLuaFile( "cl_init.lua" )
AddCSLuaFile( "shared.lua" )
include('shared.lua')
util.AddNetworkString( "GMatch:TogglePowerupHalo" )
ENT.UseCooldown = 10
ENT.EntityColor = Color( 255, 255, 255, 255 )
ENT.PowerupLength = 0

function ENT:Initialize( )
	self:SetModel("models/jeezy/gslayer/props/powerup.mdl")
end

function ENT:OnTakeDamage()
	return false
end 

function ENT:DoPhysics( )
	self:PhysicsInit(SOLID_VPHYSICS)
	self:SetMoveType(MOVETYPE_VPHYSICS)
	self:SetSolid(SOLID_VPHYSICS)
	self:SetUseType(SIMPLE_USE)
	local phys = self:GetPhysicsObject()
	phys:Wake()
end

function ENT:TriggerParticleEffects( selTbl )
	net.Start( "GMatch:ManipulateMisc" )
		net.WriteUInt( NET_MISC_TRIGGERPARTICLES, 16 )
		net.WriteTable( selTbl )
	net.Broadcast( )
end

function ENT:ToggleHalo( )
	net.Start( "GMatch:TogglePowerupHalo" )
		net.WriteUInt( self:EntIndex( ), 32 )
	net.Broadcast( )
end

function ENT:GetDefaultParticles( )
	local selTbl = { }
	selTbl.selOrigin = self:GetPos( )
	selTbl.selMax = 15
	selTbl.selSprite = "particle/particle_glow_02"
	selTbl.selVelocity = Vector( 0, 0, 0 )
	selTbl.selRoll = 0
	selTbl.selRollDelta = 0
	selTbl.selDieTime = 7
	selTbl.selLifeTime = 5
	selTbl.selStartAlpha = 255
	selTbl.selStartSize = 70
	selTbl.selEndSize = 60
	selTbl.selEndAlpha = 75
	selTbl.selGravity = Vector( 0, 0, 10 )
	selTbl.selStartLength = 50
	return selTbl
end