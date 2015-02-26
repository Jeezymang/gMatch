include( "shared.lua" )
local baseDirectory = gMatchGameFolder .. "/gamemode/"

-------------------------------------------------
--------------------Shared Tables
GMatch = GMatch or { }
GMatch.Config = GMatch.Config or { }

-------------------------------------------------
--------------------Client Tables
GMatch.GameData = GMatch.GameData or { }
GMatch.GameData.GameVars = GMatch.GameData.GameVars or { }
GMatch.GameData.PlayerVars = GMatch.GameData.PlayerVars or { }
--------------------------------------------------------------------------------------
--------------------Recursively Include Client Files
function GMatch:IncludeClientFiles( dir )
	clFiles, clDirs = file.Find( dir .. "*", "LUA", "namedesc" )
	if ( type( clFiles ) == "table" and table.getn( clFiles ) > 0 ) then
		for __, clFile in ipairs ( clFiles ) do
			local path = dir .. clFile
			include( path )
		end
	end
	if ( type( clDirs ) == "table" and table.getn( clDirs ) > 0 ) then
		for _, clDir in ipairs ( clDirs ) do
			local path = tostring( dir ) .. tostring( clDir ) .. "/"
			self:IncludeClientFiles( path )
		end
	end
end

function GMatch:IncludeAllFiles( baseDirectory )
	self:IncludeClientFiles( baseDirectory .. "shared/" )
	self:IncludeClientFiles( baseDirectory .. "client/" )
end
GMatch:IncludeAllFiles( gMatchGameFolder .. "/gamemode/" )
