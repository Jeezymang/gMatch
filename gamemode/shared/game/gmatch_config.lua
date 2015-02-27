GMatch.Config.RequiredPlayers = 2
GMatch.Config.RoundLength = 120
GMatch.Config.IntermissionLength = 30
GMatch.Config.RespawnTime = 5
GMatch.Config.EnablePlayerDeathSpectate = true
GMatch.Config.TimeUntilSpectate = 2
GMatch.Config.SpectateTeamOnly = true
GMatch.Config.PlayerSearchInterval = 5
GMatch.Config.FallbackLoadout = { "weapon_crowbar", "weapon_smg1" }
GMatch.Config.GameVoteLength = 30
GMatch.Config.AutoResourceContent = true
GMatch.Config.TimeUntilGameSwitch = 60
GMatch.Config.TimeUntilMapSwitch = 60
GMatch.Config.RoundAmountPerGameSwitch = 3
GMatch.Config.RoundAmountPerMapSwitch = 5
GMatch.Config.EntityRespawnInterval = 30
GMatch.Config.EntityRespawnChance = 75
GMatch.Config.HealthChargerRefillTime = 30
GMatch.Config.SuitChargerRefillTime = 30
GMatch.Config.StatSavingInterval = 60
GMatch.Config.KillingSpreeAmount = 5
GMatch.Config.KillingSpreeAnnounceInterval = 5
GMatch.Config.RespawnAmount = nil
GMatch.Config.NETDataSendDelay = 0.1
GMatch.Config.ScoreboardLabels = {
	{
		text = "Name",
		offset = 0.05,
		valueFunc = function( ply )
			return ( ply:Nick( ) )
		end,
		isCentered = false
	},
	{
		text = "Kills",
		offset = 0.5,
		valueFunc = function( ply )
			return ( ply:Frags( ) )
		end,
		isCentered = true
	},
	{
		text = "Deaths",
		offset = 0.6,
		valueFunc = function( ply )
			return ( ply:Deaths( ) )
		end,
		isCentered = true
	},
	{
		text = "Ping",
		offset = 0.7,
		valueFunc = function( ply )
			return ( ply:Ping( ) )
		end,
		isCentered = true
	}
}

GMatch.Config.ScoreboardSort = function( )
	local sortedPlayerList = { }
	for index, ply in ipairs ( player.GetAll( ) ) do
		table.insert( sortedPlayerList, { ply = ply, plyTeam = ply:Team( ) } )
	end
	table.SortByMember( sortedPlayerList, "plyTeam" )
	return sortedPlayerList
end

GMatch.Config.ScoreboardPlayerRowColor = function( ply )
	return ( team.GetColor( ply:Team( ) ) )
end

GMatch.Config.TargetIDInfo = {
	{ 
		textFunc = function( ply )
			return ( ply:Name( ) )
		end,
		color = Color( 255, 255, 255 ),
		font = "GMatch_Lobster_3D2DSmallBold",
	},
	{ 
		textFunc = function( ply )
			return ( team.GetName( ply:Team( ) ) )
		end,
		color = function( ply )
			return ( team.GetColor( ply:Team( ) ) )
		end,
		font = "GMatch_Lobster_3D2DMediumBold",
		yOffset = 5
	},
	{
		textFunc = function( ply ) 
			return "KILLING SPREE"
		end,
		color = function( ply )
			return ( util.RainbowStrobe( 2 ) )
		end,
		font = "GMatch_Lobster_3D2DMediumBold",
		shouldDisplay = function( ply )
			return ( ply:GetPlayerVar( "OnKillingSpree", false ) )
		end,
		yOffset = 5
	}
}

GMatch.Config.NetworkVars = {
}

GMatch.Config.DefaultTeams = {
	{ name = "Red", col = Color( 231, 76, 60 ) },
	{ name = "Orange", col = Color( 230, 126, 34 ) },
	{ name = "Yellow", col = Color( 241, 196, 15 ) },
	{ name = "Green", col = Color( 46, 204, 113 ) },
	{ name = "Blue", col = Color( 52, 152, 219 ) },
	{ name = "Purple", col = Color( 155, 89, 182 ) },
	{ name = "Turquoise", col = Color( 26, 188, 156 ) }
}
GMatch.Config.MaxTeamAmount = #GMatch.Config.DefaultTeams

GMatch.Config.Gamemodes = {
	["capturetheflag"] = {
		name = "Capture The Flag",
		desc = "Capture the enemy team's flag."
	},
	["deathmatch"] = {
		name = "Deathmatch",
		desc = "Kill all the opposing players."
	},
	["gungame"] = {
		name = "GunGame",
		desc = "Kill other players and reach max level first."
	},
	["lastmanstanding"] = {
		name = "Last Man Standing",
		desc = "Survive the zombies."
	},
	["kingofthehill"] = {
		name = "King of the Hill",
		desc = "Hold the enemy team's base and gather points."
	}
}

GMatch.Config.Maps = {
	["mu_steamlab"] = {
		name = "Steamlab",
		workshopid = "389474078"
	},
	["dm_bridge"] = {
		name = "Bridge",
		workshopid = "104841792"
	},
	["dm_autoroute"] = {
		name = "Autoroute",
		workshopid = "256834664"
	},
	["dm_tech"] = {
		name = "Tech",
		workshopid = "391434124"
	},
	["gm_construct"] = {
		name = "Construct",
		workshopid = nil
	}
}

GMatch.Config.MaxClips = {
	["weapon_smg1"] = 45,
	["weapon_ar2"] = 30,
	["weapon_357"] = 6,
	["weapon_pistol"] = 18,
	["weapon_shotgun"] = 6
}

GMatch.Config.EnableEndRoundMusic = true
GMatch.Config.EndRoundMusicURLs = {
	{ name = "Kishi Bashi - Bright Whites", url = "http://www.jeezy.rocks/gmatch/music_clips/BrightWhites.mp3" },
	{ name = "Tubthumping - Chumbawamba", url = "http://www.jeezy.rocks/gmatch/music_clips/Chumbawamba.mp3" },
	{ name = "Kid Cudi - Creepers", url = "http://www.jeezy.rocks/gmatch/music_clips/Creepers.mp3" },
	{ name = "Kishi Bashi ft. Kevin Barns - Evalyn, Summer Has Arrived", url = "http://www.jeezy.rocks/gmatch/music_clips/EvalynSummerHasArrived.mp3" },
	{ name = "Deadmau5 - I Remember", url = "http://www.jeezy.rocks/gmatch/music_clips/IRemember.mp3" },
	{ name = "STRFKR - Medicine", url = "http://www.jeezy.rocks/gmatch/music_clips/Medicine.mp3" },
	{ name = "Hot Chip - Ready For The Floor", url = "http://www.jeezy.rocks/gmatch/music_clips/ReadyForTheFloor.mp3" },
	{ name = "Of Montreal - Spiteful Intervention", url = "http://www.jeezy.rocks/gmatch/music_clips/SpitefulIntervention.mp3" },
	{ name = "Ghosthustler - Someone Else's Ride", url = "http://www.jeezy.rocks/gmatch/music_clips/SomeoneElsesRide.mp3" },
	{ name = "Basshunter - Welcome To Rainbow", url = "http://www.jeezy.rocks/gmatch/music_clips/WelcomeToRainbow.mp3" }
}