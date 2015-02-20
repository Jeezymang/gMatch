GMatch.Config.RequiredPlayers = 2
GMatch.Config.RoundLength = 60
GMatch.Config.RespawnTime = 5
GMatch.Config.EnablePlayerDeathSpectate = true
GMatch.Config.TimeUntilSpectate = 2
GMatch.Config.SpectateTeamOnly = true
GMatch.Config.PlayerSearchInterval = 10
GMatch.Config.FallbackLoadout = { "weapon_crowbar", "weapon_smg1" }
GMatch.Config.GameVoteLength = 20
GMatch.Config.AutoResourceContent = true
GMatch.Config.TimeUntilGameSwitch = 30
GMatch.Config.TimeUntilMapSwitch = 60
GMatch.Config.RoundAmountPerGameSwitch = 3
GMatch.Config.RoundAmountPerMapSwitch = 2
GMatch.Config.EntityRespawnInterval = 30
GMatch.Config.HealthChargerRefillTime = 30
GMatch.Config.SuitChargerRefillTime = 30
GMatch.Config.StatSavingInterval = 60
GMatch.Config.KillingSpreeAmount = 5
GMatch.Config.KillingSpreeAnnounceInterval = 5
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