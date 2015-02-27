concommand.Add( "gmatch_finishround", function( ply, cmd, args, fstring )
	if not ( ply:IsAdmin( ) ) then return end
	if not ( GMatch:IsRoundActive( ) ) then 
		ply:DisplayNotify( "There isn't a round active at the moment.", 4, "icon16/error.png" ) 
		return
	end
	GMatch:BroadcastNotify( "(ADMIN) " .. ply:Name( ) .. " has forced the round to end.", 4, "icon16/comment.png" )
	GMatch:FinishRound( )
end )

concommand.Add( "gmatch_gamemodevote", function( ply, cmd, args, fstring )
	if not ( ply:IsAdmin( ) ) then return end
	if ( GMatch.GameData.GameVoteStarted or timer.Exists( "GMatch:GameSwitchTimer" ) ) then
		ply:DisplayNotify( "There is already a gamemode vote in progress.", 4, "icon16/error.png" ) 
		return 
	end
	if ( GMatch.GameData.MapVoteStarted or timer.Exists( "GMatch:MapSwitchTimer" ) ) then
		ply:DisplayNotify( "You cannot start a gamemode vote while there is a map vote.", 4, "icon16/error.png" )
		return 
	end
	GMatch:BroadcastNotify( "(ADMIN) " .. ply:Name( ) .. " has started a gamemode vote.", 4, "icon16/comment.png" )
	GMatch:BeginGameVote( )
end )

concommand.Add( "gmatch_mapvote", function( ply, cmd, args, fstring )
	if not ( ply:IsAdmin( ) ) then return end
	if ( GMatch.GameData.GameVoteStarted or timer.Exists( "GMatch:GameSwitchTimer" ) ) then
		ply:DisplayNotify( "You cannot start a map vote while there is a gamemode vote.", 4, "icon16/error.png" )
		return 
	end
	if ( GMatch.GameData.MapVoteStarted or timer.Exists( "GMatch:MapSwitchTimer" ) ) then
		ply:DisplayNotify( "There is already a map vote in progress.", 4, "icon16/error.png" )
		return 
	end
	GMatch:BroadcastNotify( "(ADMIN) " .. ply:Name( ) .. " has started a map vote.", 4, "icon16/comment.png" )
	GMatch:BeginMapVote( )
end )

concommand.Add( "gmatch_respawnplayers", function( ply, cmd, args, fstring )
	if not ( ply:IsAdmin( ) ) then return end
	GMatch:BroadcastNotify( "(ADMIN) " .. ply:Name( ) .. " has forced all players to respawn.", 4, "icon16/comment.png" )
	GMatch:RespawnPlayers( )
end )

concommand.Add( "gmatch_saveplayerstats", function( ply, cmd, args, fstring )
	if not ( ply:IsAdmin( ) ) then return end
	GMatch:BroadcastNotify( "(ADMIN) " .. ply:Name( ) .. " has saved all player stats.", 4, "icon16/comment.png" )
	GMatch:SaveAllPlayerStats( 0.15 )
end )