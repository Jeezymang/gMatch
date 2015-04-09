local fileName = string.StripExtension( string.GetFileFromFilename( debug.getinfo(1).short_src ) )
local entityWhitelist = { "health_charger", "suit_charger", "powerup_", "flag_base", "ammocrate_", "capture_base" }
local TOOL = { }
local selectedEntity = nil

TOOL.Name = "Entity Spawner"
TOOL.Usage = {
	["LeftClick"] = "Spawn selected entity.",
	["RightClick"] = "Remove entity in trace.",
	["Reload"] = "Select an entity."
}

function TOOL:PrimaryAttack( trace, owner )
	if ( CLIENT ) then
		if not ( selectedEntity ) then
			owner:DisplayNotify( "You must select an entity to spawn.", 4, "icon16/error.png" )
			return
		end
		if not ( owner:IsSuperAdmin( ) ) then return end
		if not ( scripted_ents.Get( selectedEntity ) ) then 
			owner:DisplayNotify( "You tried to spawn an invalid entity.", 4, "icon16/error.png" )
			return 
		end
		RunConsoleCommand( "ent_create", selectedEntity )
		owner:DisplayNotify( "You've spawned a " .. selectedEntity .. "!", 4, "icon16/comment.png" )
	end
end

function TOOL:SecondaryAttack( trace, owner )
	if ( SERVER ) then
		if not ( owner:IsSuperAdmin( ) ) then return end
		local entTrace = trace.Entity
		if ( !IsValid( entTrace ) or entTrace:IsWorld( ) ) then
			owner:DisplayNotify( "You're not aiming at a valid entity.", 4, "icon16/error.png" )
			return
		end
		owner:DisplayNotify( "You've removed the entity " .. entTrace:GetClass( ) .. "!", 4, "icon16/comment.png" )
		SafeRemoveEntity( entTrace )
	end
end

function TOOL:Reload( )
	if ( CLIENT ) then
		local hoverData = nil
		self.entityPanel = vgui.Create( "DPanel" )
		local entPnl = self.entityPanel
		entPnl:SetSize( ScrW( ) * 0.4, ScrH( ) * 0.2 )
		entPnl:Center( )
		entPnl.OnMousePressed = function( pnl, btn )
			pnl:Remove( )
		end
		entPnl.OnRemove = function( pnl )
			gui.EnableScreenClicker( false )
		end
		entPnl.Paint = function( pnl, w, h )
			pnl:DrawBlurredRect( 4, 3 )
			draw.RoundedBox( 6, 0, 0, w, h, Color( 45, 45, 45, 195 ) )
		end
		entPnl.PaintOver = function( pnl, w, h )
			if ( hoverData ) then
				draw.SimpleText( hoverData.printName, "GMatch_Lobster_SmallBoldStatic", w * 0.05, h * 0.9, Color( 255, 255, 255 ), TEXT_ALIGN_LEFT )
			end
		end
		local closeButton = vgui.Create( "gMatch_ColoredButton", entPnl )
		closeButton:SetSize( entPnl:GetWide( ) * 0.05, entPnl:GetTall( ) * 0.09 )
		closeButton:AlignTop( entPnl:GetTall( ) * 0.1 )
		closeButton:AlignRight( entPnl:GetWide( ) * 0.05 )
		closeButton:SetButtonColor( Color( 175, 75, 75 ) )
		closeButton:SetButtonHoverColor( Color( 75, 25, 25 ) )
		closeButton:SetButtonRoundness( 4 )
		closeButton.OnMousePressed = function( btn )
			entPnl:Remove( )
		end
		entPnl.dScrollPanel = vgui.Create( "DScrollPanel", entPnl )
		entPnl.dScrollPanel:SetSize( entPnl:GetWide( ) * 0.8, entPnl:GetTall( ) * 0.8 )
		entPnl.dScrollPanel:SetPos( entPnl:GetWide( ) * 0.05, entPnl:GetTall( ) * 0.1 )
		entPnl.dIconLayout = vgui.Create( "DIconLayout" )
		entPnl.dScrollPanel:AddItem( entPnl.dIconLayout )
		entPnl.dIconLayout:SetSize( entPnl.dScrollPanel:GetWide( ) * 1, entPnl.dScrollPanel:GetTall( ) )
		entPnl.dIconLayout:SetPos( 0, 0 )
		entPnl.dIconLayout:SetSpaceX( 5 )
		entPnl.dIconLayout:SetSpaceY( 5 )
		for class, entTbl in pairs ( scripted_ents.GetList( ) ) do
			local foundClass = false
			for index, whitelistedEnt in ipairs ( entityWhitelist ) do
				if ( string.find( class, whitelistedEnt ) ) then
					foundClass = scripted_ents.Get( class )
					break
				end
			end
			if ( foundClass and foundClass.Model ) then
				local mdlPanel = entPnl.dIconLayout:Add( "GMatch_ModelPanelPlus" )
				mdlPanel:LoadModel( foundClass.Model )
				mdlPanel:ModifySize( 72, 72 )
				mdlPanel:SetModelFOV( 45 )
				mdlPanel:SetModelPanelBG( Color( 255, 255, 255, 75 ) )
				mdlPanel.iconRoundness = 8
				mdlPanel.PaintOver = function( pnl, w, h )
					if ( selectedEntity == class ) then
						pnl:SetModelPanelBG( Color( 45, 175, 45, 75 ) )
						--draw.RoundedBox( 8, 0, 0, w, h, Color( 45, 175, 45, 90 ) )
					elseif ( hoverData and hoverData.class == class ) then
						pnl:SetModelPanelBG( Color( 45, 175, 45, 75 ) )
						--draw.RoundedBox( 8, 0, 0, w, h, Color( 45, 175, 45, 90 ) )
					else
						pnl:SetModelPanelBG( Color( 255, 255, 255, 75 ) )
					end
				end
				if ( foundClass.EntityColor ) then mdlPanel:SetModelColor( foundClass.EntityColor ) end
				mdlPanel.dModelPanel.OnCursorEntered = function( pnl )
					hoverData = { class = class, printName = foundClass.PrintName }
				end
				mdlPanel.dModelPanel.OnCursorExited = function( pnl )
					hoverData = nil
				end
				mdlPanel.dModelPanel.OnMousePressed = function( pnl, btn )
					selectedEntity = class
				end
			end
		end
		gui.EnableScreenClicker( true )
	end
end

function TOOL:DrawHUD( )
	--draw.RoundedBox( 0, 0, 0, 256, 256, Color( 255, 255, 255 ) )
end

local gMatchToolTable = weapons.GetStored( "gmatch_tool" )
gMatchToolTable.Tools = gMatchToolTable.Tools or { }
gMatchToolTable.Tools[fileName] = TOOL