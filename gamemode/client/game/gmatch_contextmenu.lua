local dermaMenu
function GM:OnContextMenuOpen( )
	if not ( LocalPlayer( ):IsSuperAdmin( ) ) then return end
	gui.EnableScreenClicker( true )
end

function GM:OnContextMenuClose( )
	if not ( LocalPlayer( ):IsSuperAdmin( ) ) then return end
	if ( IsValid( dermaMenu ) ) then
		dermaMenu:Remove( )
	end
	gui.EnableScreenClicker( false )
end

function GM:GUIMousePressed( mouseCode, aimVector )
 	if not ( LocalPlayer( ):IsSuperAdmin( ) ) then return end
	local traceRes = util.QuickTrace( LocalPlayer( ):EyePos( ), gui.ScreenToVector( gui.MousePos( ) ) * 2048, LocalPlayer( ) )
	local traceEnt = traceRes.Entity
	if ( IsValid( traceEnt ) and !traceEnt:IsPlayer( ) and mouseCode == MOUSE_RIGHT ) then
		dermaMenu = DermaMenu( )
		dermaMenu:SetPos( gui.MousePos( ) )
		dermaMenu:AddOption( "Make Persistent", function( )
			net.Start( "GMatch:ManipulateWorld" )
				net.WriteUInt( NET_WORLD_MAKEPERSISTENT, 16 )
				net.WriteEntity( traceEnt )
			net.SendToServer( )
			dermaMenu:Remove( )
		end ):SetIcon( "icon16/table_add.png" )
		dermaMenu:AddOption( "Remove Persistence", function( )
			net.Start( "GMatch:ManipulateWorld" )
				net.WriteUInt( NET_WORLD_REMOVEPERSISTENCE, 16 )
				net.WriteEntity( traceEnt )
			net.SendToServer( )
			dermaMenu:Remove( )
		end ):SetIcon( "icon16/table_delete.png" )
		dermaMenu:AddOption( "Make Respawnable", function( )
			net.Start( "GMatch:ManipulateWorld" )
				net.WriteUInt( NET_WORLD_MAKERESPAWNABLE, 16 )
				net.WriteEntity( traceEnt )
			net.SendToServer( )
			dermaMenu:Remove( )
		end ):SetIcon( "icon16/transmit_add.png" )
		dermaMenu:AddOption( "Disable Respawning", function( )
			net.Start( "GMatch:ManipulateWorld" )
				net.WriteUInt( NET_WORLD_REMOVERESPAWNABLE, 16 )
				net.WriteEntity( traceEnt )
			net.SendToServer( )
			dermaMenu:Remove( )
		end ):SetIcon( "icon16/transmit_delete.png" )
	end
end