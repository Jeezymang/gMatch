local dermaMenu
function GM:OnContextMenuOpen( )
	if not ( LocalPlayer( ):IsAdmin( ) ) then return end
	gui.EnableScreenClicker( true )
end

function GM:OnContextMenuClose( )
	if not ( LocalPlayer( ):IsAdmin( ) ) then return end
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
	elseif ( !IsValid( traceEnt ) and mouseCode == MOUSE_RIGHT ) then
		dermaMenu = DermaMenu( )
		dermaMenu:SetPos( gui.MousePos( ) )
		dermaMenu:AddOption( "Finish Round", function( )
			RunConsoleCommand( "gmatch_finishround" )
		end ):SetIcon( "icon16/anchor.png" )
		dermaMenu:AddOption( "Start Gamemode Vote", function( )
			RunConsoleCommand( "gmatch_gamemodevote" )
		end ):SetIcon( "icon16/gun.png" )
		dermaMenu:AddOption( "Start Map Vote", function( )
			RunConsoleCommand( "gmatch_mapvote" )
		end ):SetIcon( "icon16/map.png" )
		dermaMenu:AddSpacer( )
		dermaMenu:AddOption( "Respawn Players", function( )
			RunConsoleCommand( "gmatch_respawnplayers" )
		end ):SetIcon( "icon16/user_add.png" )
		dermaMenu:AddOption( "Save Player Stats", function( )
			RunConsoleCommand( "gmatch_saveplayerstats" )
		end ):SetIcon( "icon16/shield_go.png" )
	end
end