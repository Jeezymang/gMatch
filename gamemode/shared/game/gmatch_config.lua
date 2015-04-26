GMatch.Config.RequiredPlayers = 2 // Amount of players required to start
GMatch.Config.RoundLength = 120 // Length of the round
GMatch.Config.IntermissionLength = 30 // Length of the time inbetween rounds
GMatch.Config.RespawnTime = 5 // Time it takes to respawn
GMatch.Config.EnablePlayerDeathSpectate = true // Whether the player should spectate others while dead
GMatch.Config.TimeUntilSpectate = 2 // Time until camera transitions from the ragdoll to spectating another player
GMatch.Config.SpectateTeamOnly = true // Only spectate other team members while dead
GMatch.Config.PlayerSearchInterval = 5 // Interval length that that the server checks if there's enough players to start
GMatch.Config.FallbackLoadout = { "weapon_crowbar", "weapon_smg1" } // The loadout if another isn't set
GMatch.Config.GameVoteLength = 30 // Length that votes are allowed for a new gamemode
GMatch.Config.AutoResourceContent = true // Whether to automatically resource.AddFile content
GMatch.Config.TimeUntilGameSwitch = 60 // Time until the gamemode switches when a new one has been chosen
GMatch.Config.TimeUntilMapSwitch = 60 // Time until the map switches when a new one has been chosen
GMatch.Config.RoundAmountPerGameSwitch = 3 // Rounds inbetween gamemode switch votes
GMatch.Config.RoundAmountPerMapSwitch = 5 // Rounds inbetween map switch votes
GMatch.Config.EntityRespawnInterval = 30 // Interval that respawning entities will attempt to respawn
GMatch.Config.EntityRespawnChance = 75 // Chance that the respawning entity will respawn
GMatch.Config.HealthChargerRefillTime = 30 // Time it takes for the health charger to refill completely
GMatch.Config.SuitChargerRefillTime = 30 // Time it takes for the armor charger to refill completely
GMatch.Config.StatSavingInterval = 60 // Interval the player's stats are saved to the SQLite databse
GMatch.Config.KillingSpreeAmount = 5 // Amount of kills that begins a killing spree
GMatch.Config.KillingSpreeAnnounceInterval = 5 // Amount of kills inbetween announcing the player's current kill spreee count
GMatch.Config.RespawnAmount = nil // Amount of times the player can respawn, nil means unlimited.
GMatch.Config.NETDataSendDelay = 0.1 // The interval inbetween sending the player shared variables upon joining
GMatch.Config.KillsForRevenge = 3 // Amount of kills for the attacker to be marked for revenge by the victim
GMatch.Config.KillsForDomination = 8 // Amount of kills for the attacker to be marked as dominating the victim
GMatch.Config.PlayerHurtSoundChance = 45 // Chance the hurt sound will play
GMatch.Config.NoDrawHealth = false // Whether to hide the health or not
GMatch.Config.NoDrawAmmo = false // Whether to hide ethe ammo or not
GMatch.Config.NoDrawDataTime = false // Whether to hide the networked data progress on joining
GMatch.Config.NoDrawRespawnTime = false // Whether to hide the respawn time
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

GMatch.Config.KillingSpreeSounds = {
	[2] = "halo/doublekill.mp3",
	[3] = "halo/triplekill.mp3",
	[GMatch.Config.KillingSpreeAmount] = "halo/killingspree.mp3",
	[GMatch.Config.KillingSpreeAmount + 3] = "halo/killfrenzy.mp3",
	[GMatch.Config.KillingSpreeAmount + 7] = "halo/killtrocity.mp3",
	[GMatch.Config.KillingSpreeAmount + 12] = "halo/runningriot.mp3",
	[GMatch.Config.KillingSpreeAmount + 15] = "halo/untouchable.mp3",
	[GMatch.Config.KillingSpreeAmount + 20] = "halo/unfreakinbelievable.mp3",
	[GMatch.Config.KillingSpreeAmount + 30] = "quake/holyshit.mp3"
}