DEFINE_BASECLASS( "player_default" )

local PLAYER = { }

PLAYER.DisplayName			= "Player Class"

PLAYER.WalkSpeed 			= 200		-- How fast to move when not running
PLAYER.RunSpeed				= 450		-- How fast to move when running
PLAYER.CrouchedWalkSpeed 	= 0.3		-- Multiply move speed by this when crouching
PLAYER.DuckSpeed			= 0.3		-- How fast to go from not ducking, to ducking
PLAYER.UnDuckSpeed			= 0.3		-- How fast to go from ducking, to not ducking
PLAYER.JumpPower			= 200		-- How powerful our jump should be
PLAYER.CanUseFlashlight     = true		-- Can we use the flashlight
PLAYER.MaxHealth			= 100		-- Max health we can have
PLAYER.StartHealth			= 100		-- How much health we start with
PLAYER.StartArmor			= 100			-- How much armour we start with
PLAYER.DropWeaponOnDie		= false		-- Do we drop our weapon when we die
PLAYER.TeammateNoCollide 	= false		-- Do we collide with teammates or run straight through them
PLAYER.AvoidPlayers			= true		-- Automatically swerves around other players
PLAYER.UseVMHands			= true		-- Uses viewmodel hands


--
-- Name: PLAYER:SetupDataTables
-- Desc: Set up the network table accessors
-- Arg1:
-- Ret1:
--
function PLAYER:SetupDataTables()
	local networkVars = GMatch.Config.NetworkVars
	local varCount = { }
	if not ( networkVars ) then return end
	for varName, varType in pairs ( networkVars ) do
		local count = varCount[varType] or -1
		count = count + 1
		varCount[varType] = count
		self.Player:NetworkVar( varType, count, varName )
	end
end

--
-- Name: PLAYER:Spawn
-- Desc: Called serverside only when the player spawns
-- Arg1:
-- Ret1:
--
function PLAYER:Spawn()
	self.Player:SetupHands( )
	local playerColor = team.GetColor( self.Player:Team( ) ):ToVector( )
	local overrideColor = hook.Call( "OnPlayerSetColor", GAMEMODE, self.Player )
	if ( overrideColor ) then playerColor = overrideColor:ToVector( ) end
	self.Player:SetPlayerColor( playerColor )
end

--
-- Name: PLAYER:Loadout
-- Desc: Called on spawn to give the player their default loadout
-- Arg1:
-- Ret1:
--
function PLAYER:Loadout()
	local weaponLoadout = GMatch.Config.FallbackLoadout
	local gameLoadout = GMatch.Config.DefaultSpawnWeapons or { }
	if ( #gameLoadout > 0 ) then weaponLoadout = gameLoadout end
	local overrideWeapons = hook.Call( "OnWeaponLoadout", GAMEMODE, self.Player, weaponLoadout ) or { }
	if ( #overrideWeapons > 0 ) then weaponLoadout = overrideWeapons end
	for index, wep in ipairs ( weaponLoadout ) do
		self.Player:Give( wep )
	end
	if ( self.Player:IsSuperAdmin( ) ) then
		self.Player:Give( "weapon_physgun" )
		self.Player:Give( "gmatch_tool" )
	end
end

function PLAYER:SetModel( )
	local chosenModel = ""
	local isMale = tobool( math.random( 0, 1 ) )
	if ( isMale ) then
		chosenModel = player_manager.TranslatePlayerModel( "male0" .. math.random( 1, 9 ) )
	else
		local mdlNum = math.random( 1, 2 )
		if ( string.len( mdlNum ) == 1 ) then mdlNum = "0" .. mdlNum end
		chosenModel = player_manager.TranslatePlayerModel( "female" .. mdlNum )
	end
	local overrideModel = hook.Call( "OnPlayerSetModel", GAMEMODE, self.Player, chosenModel )
	if ( overrideModel ) then chosenModel = overrideModel end
	self.Player:SetModel( chosenModel )
end

/*function PLAYER:GetHandsModel( )

	-- return { model = "models/weapons/c_arms_cstrike.mdl", skin = 1, body = "0100000" }

	local playermodel = player_manager.TranslateToPlayerModelName( self.Player:GetModel() )
	return player_manager.TranslatePlayerHands( playermodel )

end*/

player_manager.RegisterClass( "gmatch_player_class", PLAYER, "player_default" )