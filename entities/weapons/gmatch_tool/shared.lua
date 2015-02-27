if ( SERVER ) then
	AddCSLuaFile( )
end

if not ( SWEP.Tools ) then
	SWEP.Tools = { }
end
SWEP.PrintName = "GMatch Tool"
SWEP.Author = "Jeezy"
SWEP.Slot = 1
SWEP.SlotPos = 0
SWEP.Description = ""
SWEP.Contact = ""
SWEP.Purpose = ""
SWEP.Instructions = "Scroll to select a tool."

SWEP.Spawnable = true
SWEP.AdminOnly = true
SWEP.Category = "GMatch (Utility)"

SWEP.ViewModel = "models/weapons/c_toolgun.mdl"
SWEP.WorldModel = "models/weapons/w_toolgun.mdl"
SWEP.UseHands = true

SWEP.ShootSound = Sound( "Airboat.FireGunRevDown" )
SWEP.Primary.Recoil = 0
SWEP.Primary.ClipSize  = -1
SWEP.Primary.DefaultClip = 1
SWEP.Primary.Automatic  = true
SWEP.Primary.Delay = 0.1
SWEP.Primary.Ammo = "none"

SWEP.Secondary.Recoil = 0
SWEP.Secondary.ClipSize = -1
SWEP.Secondary.DefaultClip = 1
SWEP.Secondary.Automatic = true
SWEP.Secondary.Delay = 0.3
SWEP.Secondary.Ammo = "none"

function SWEP:FireToolTracer( hitPos )
	local effectData = EffectData( )
	effectData:SetOrigin( hitPos )
	effectData:SetStart( self.Owner:GetShootPos( ) )
	effectData:SetAttachment( 1 )
	effectData:SetEntity( self.Weapon )
	util.Effect( "ToolTracer", effectData )
	self.Weapon:EmitSound( self.ShootSound )
end

function SWEP:PrimaryAttack( )
	self.nextPrimaryAttack = self.nextPrimaryAttack or 0
	if ( self.nextPrimaryAttack > CurTime( ) ) then return end
	self.nextPrimaryAttack = CurTime( ) + 1
	if not ( self.Tools ) then return end
	if not ( IsValid( self.Owner ) ) then return end
	local selectedTool = self.Owner:GetInfo( "gmatchtool_selectedtool" )
	if not ( self.Tools[selectedTool] ) then return end
	if not ( self.Tools[selectedTool].PrimaryAttack ) then return end
	self.Tools[selectedTool]:PrimaryAttack( self.Owner:GetEyeTrace( ), self.Owner )
	self:FireToolTracer( self.Owner:GetEyeTrace( ).HitPos )
end

function SWEP:SecondaryAttack( )
	self.nextSecondaryAttack = self.nextSecondaryAttack or 0
	if ( self.nextSecondaryAttack > CurTime( ) ) then return end
	self.nextSecondaryAttack = CurTime( ) + 1
	if not ( self.Tools ) then return end
	if not ( IsValid( self.Owner ) ) then return end
	local selectedTool = self.Owner:GetInfo( "gmatchtool_selectedtool" )
	if not ( self.Tools[selectedTool] ) then return end
	if not ( self.Tools[selectedTool].SecondaryAttack ) then return end
	self.Tools[selectedTool]:SecondaryAttack( self.Owner:GetEyeTrace( ), self.Owner )
	self:FireToolTracer( self.Owner:GetEyeTrace( ).HitPos )
end

function SWEP:Reload( )
	self.nextReload = self.nextReload or 0
	if ( self.nextReload > CurTime( ) ) then return end
	self.nextReload = CurTime( ) + 1
	if not ( self.Tools ) then return end
	if not ( IsValid( self.Owner ) ) then return end
	local selectedTool = self.Owner:GetInfo( "gmatchtool_selectedtool" )
	if not ( self.Tools[selectedTool] ) then return end
	if not ( self.Tools[selectedTool].Reload ) then return end
	self.Tools[selectedTool]:Reload( self.Owner:GetEyeTrace( ), self.Owner )
end

local function AddTools( )
	 if ( SERVER ) then
        local toolFiles, _ = file.Find( "gamemodes/gmatch/entities/weapons/gmatch_tool/tools/*.lua", "GAME", "DESC" )
        for index, toolFile in ipairs( toolFiles ) do
            AddCSLuaFile( "gmatch/entities/weapons/gmatch_tool/tools/" ..toolFile )
            include( "gmatch/entities/weapons/gmatch_tool/tools/" ..toolFile )
        end
    else
        local toolFiles, _ = file.Find( "gmatch/entities/weapons/gmatch_tool/tools/*.lua", "LUA", "DESC" )
        for index, toolFile in ipairs( toolFiles ) do
            include( "gmatch/entities/weapons/gmatch_tool/tools/" .. toolFile )
        end
    end
end

hook.Add( "PostGamemodeLoaded", "dsfdsfadsf", function( )
	AddTools( )
end )

function SWEP:OnReloaded( )
	AddTools( )
end

if not ( CLIENT ) then return end
local rightClickMat = Material( "gui/mouse_rightclick100x192.png", "noclamp" )
local leftClickMat = Material( "gui/mouse_leftclick100x192.png", "noclamp" )
local reloadKeyMat = Material( "gui/keyboard_rkey96x95.png", "noclamp" )
local selectedTool = CreateClientConVar( "gmatchtool_selectedtool", "", false, true )
local selectedToolIndex = 1

function SWEP:Initialize( )
	if ( self.Tools ) then
		local toolNum = 1
		for name, toolTbl in pairs ( self.Tools ) do
			if ( toolNum == selectedToolIndex ) then
				RunConsoleCommand( "gmatchtool_selectedtool", name )
				break
			end
			toolNum = toolNum + 1
		end
	end
end

function SWEP:DrawHUD( )
	if not ( self.Tools ) then return end
	if not ( IsValid( self.Owner ) ) then return end
	local selectedTool = self.Owner:GetInfo( "gmatchtool_selectedtool" )
	if not ( self.Tools[selectedTool] ) then return end
	draw.RoundedBox( 4, ScrW( ) * 0.04, ScrH( ) * 0.04, 512, 140, Color( 45, 45, 45, 235 ) )
	draw.BlurredRect( ScrW( ) * 0.04, ScrH( ) * 0.04, 512, 140, 4, 3, Color( 45, 45, 45 ) )
	local textColor = Color( 255, 255, 255 )
	draw.SimpleText( self.Tools[selectedTool].Name, "GMatch_Lobster_MediumBoldStatic", ScrW( ) * 0.0525, ScrH( ) * 0.05, textColor, TEXT_ALIGN_LEFT )
	if ( istable( self.Tools[selectedTool].Usage ) ) then
		local yIncrement = 32
		if ( self.Tools[selectedTool].Usage["RightClick"] ) then
			draw.TexturedRect( ScrW( ) * 0.05, ScrH( ) * 0.0425 + yIncrement, 16, 28, rightClickMat, Color( 255, 255, 255 ) )
			draw.SimpleText( "Right Click: " .. self.Tools[selectedTool].Usage["RightClick"], "GMatch_Lobster_MediumBoldStatic", ScrW( ) * 0.065, ScrH( ) * 0.05 + yIncrement, textColor, TEXT_ALIGN_LEFT )
			yIncrement = yIncrement + 32
		end
		if ( self.Tools[selectedTool].Usage["LeftClick"] ) then
			draw.TexturedRect( ScrW( ) * 0.05, ScrH( ) * 0.0425 + yIncrement, 16, 28, leftClickMat, Color( 255, 255, 255 ) )
			draw.SimpleText( "Left Click: " .. self.Tools[selectedTool].Usage["LeftClick"], "GMatch_Lobster_MediumBoldStatic", ScrW( ) * 0.065, ScrH( ) * 0.05 + yIncrement, textColor, TEXT_ALIGN_LEFT )
			yIncrement = yIncrement + 32
		end
		if ( self.Tools[selectedTool].Usage["Reload"] ) then
			draw.TexturedRect( ScrW( ) * 0.05, ScrH( ) * 0.05 + yIncrement, 16, 16, reloadKeyMat, Color( 255, 255, 255 ) )
			draw.SimpleText( "Reload Click: " .. self.Tools[selectedTool].Usage["Reload"], "GMatch_Lobster_MediumBoldStatic", ScrW( ) * 0.065, ScrH( ) * 0.05 + yIncrement, textColor, TEXT_ALIGN_LEFT )
			yIncrement = yIncrement + 32
		end
	end
	if not ( isfunction( self.Tools[selectedTool].DrawHUD ) ) then return end
	self.Tools[selectedTool]:DrawHUD( )
end

local matScreen 	= Material( "models/weapons/v_toolgun/screen" )
local txBackground	= surface.GetTextureID( "models/weapons/v_toolgun/screen_bg" )

-- GetRenderTarget returns the texture if it exists, or creates it if it doesn't
local RTTexture 	= GetRenderTarget( "GModToolgunScreen", 256, 256 )

surface.CreateFont( "GModToolScreen", {
	font	= "Helvetica",
	size	= 24,
	weight	= 900
} )

function SWEP:RenderScreen( )
	local TEX_SIZE = 256
	local oldW = ScrW()
	local oldH = ScrH()
	
	matScreen:SetTexture( "$basetexture", RTTexture )
	
	local OldRT = render.GetRenderTarget()
	render.SetRenderTarget( RTTexture )
	render.SetViewPort( 0, 0, TEX_SIZE, TEX_SIZE )
	cam.Start2D()
		draw.RoundedBox( 0, 0, 0, TEX_SIZE, TEX_SIZE, Color( 45, 45, 45, 255 ) )
		local toolNum = 0
		for name, toolTbl in pairs ( self.Tools ) do
			local boxColor = Color( 175, 45, 45 )
			if ( selectedTool:GetString( ) == name ) then boxColor = Color( 45, 175, 45 ) end
			draw.RoundedBox( 0, 16, ( toolNum * 24 ), TEX_SIZE - 32, 22, boxColor )
			draw.SimpleText( toolTbl.Name, "GModToolScreen", 16 + ( TEX_SIZE * 0.5 - 16 ), ( toolNum * 24 ), Color( 255, 255, 255 ), TEXT_ALIGN_CENTER )
			toolNum = toolNum + 1
		end

	cam.End2D()
	render.SetRenderTarget( OldRT )
	render.SetViewPort( 0, 0, oldW, oldH )
	
end

hook.Add( "PlayerBindPress", "GMatchTool_PlayerBindPress", function( ply, bind, pressed )
	local activeWeapon = ply:GetActiveWeapon( )
	if not ( IsValid( activeWeapon ) ) then return end
	if not ( activeWeapon:GetClass( ) == "gmatch_tool" ) then return end
	local toolTable = weapons.Get( "gmatch_tool" ).Tools
	local toolCount = table.Count( toolTable )
	if not ( toolCount > 1 ) then return end
	if ( bind == "invnext" ) then
		local goalIndex = selectedToolIndex + 1
		if ( toolCount < goalIndex ) then return end
		local curCount = 1
		for name, toolTbl in pairs ( toolTable ) do
			if ( goalIndex == curCount ) then
				RunConsoleCommand( "gmatchtool_selectedtool", name )
				selectedToolIndex = curCount
				break
			end
			curCount = curCount + 1
		end
	elseif ( bind == "invprev" ) then
		local goalIndex = selectedToolIndex - 1
		if ( goalIndex < 1 ) then return end
		local curCount = 1
		for name, toolTbl in pairs ( toolTable ) do
			if ( goalIndex == curCount ) then
				RunConsoleCommand( "gmatchtool_selectedtool", name )
				selectedToolIndex = curCount
				break
			end
			curCount = curCount + 1
		end
	end
end )