include('shared.lua') -- At this point the contents of shared.lua are ran on the client only.
local haloRenderRange = 543380

function ENT:Draw( )
	self:DrawModel( )
end

function ENT:Initialize( )
	self:ToggleHalo( )
end

function ENT:OnRemove( )
	if ( self.haloToggled ) then
		hook.Remove( "PreDrawHalos", "GMatch:Powerups_PreDrawHalos_" .. self:EntIndex( ) )
	end
end

function ENT:ToggleHalo( )
	self.haloToggled = self.haloToggled or false
	if not ( self.haloToggled ) then
		hook.Add( "PreDrawHalos", "GMatch:Powerups_PreDrawHalos_" .. self:EntIndex( ), function( )
			if not ( LocalPlayer( ):GetPos( ):DistToSqr( self:GetPos( ) ) > haloRenderRange ) then
				halo.Add( { self }, self.EntityColor or Color( 255, 255, 255, 255 ), 5, 5, 2 )
			end
		end )
		self.haloToggled = true
	else
		hook.Remove( "PreDrawHalos", "GMatch:Powerups_PreDrawHalos_" .. self:EntIndex( ) )
		self.haloToggled = false
	end
end

net.Receive( "GMatch:TogglePowerupHalo", function( len )
	local entIndex = net.ReadUInt( 32 )
	if ( IsValid( Entity( entIndex ) ) ) then
		Entity( entIndex ):ToggleHalo( )
	end
end )