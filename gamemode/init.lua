AddCSLuaFile( "cl_init.lua" )
AddCSLuaFile( "shared.lua" )

include( "shared.lua" )

-------------------------------------------------
--This should probably be disabled.
RunConsoleCommand( "sv_allowcslua", "0" )

-------------------------------------------------
--------------------Shared Tables
GMatch = GMatch or { }
GMatch.Config = GMatch.Config or { }

-------------------------------------------------
--------------------Server Tables
GMatch.GameData = GMatch.GameData or { }
GMatch.GameData.GameVars = GMatch.GameData.GameVars or { }
GMatch.GameVarTypes = {
	["string"] = function( val ) net.WriteString( val ) end,
	["boolean"] = function( val ) net.WriteBit( val ) end,
	["table"] = function( val ) net.WriteTable( val ) end,
	["number"] = function( val ) net.WriteInt( val, 32 ) end,
	["Vector"] = function( val ) net.WriteVector( val ) end,
	["Angle"] = function( val ) net.WriteAngle( val ) end,
	["Entity"] = function( val ) net.WriteEntity( val ) end
}
GMatch.GameData.PlayerVars = GMatch.GameData.PlayerVars or { }
GMatch.PlayerVarTypes = table.Copy( GMatch.GameVarTypes )

-------------------------------------------------
------------------Recursively Add Sounds
function GMatch:AddSoundResource( dir )
	local soundFiles, soundDirs = file.Find( dir .. "*", "MOD", "namedesc" )
	for _, soundFile in ipairs ( soundFiles or { } ) do
		local path = dir .. soundFile
		resource.AddFile( path )
		print( "Adding sound resource " .. path )
	end
	for _, soundDir in ipairs ( soundDirs or { } ) do
		local path = dir .. soundDir .. "/"
		self:AddSoundResource( path )
	end
end

-------------------------------------------------
-----------------Recursively Add Models
function GMatch:AddModelResource( dir )
	local modelFiles, modelDirs = file.Find( dir .. "*", "MOD", "namedesc" )
	for _, modelFile in ipairs ( modelFiles or { } ) do
		local path = dir .. modelFile
		resource.AddSingleFile( path )
		print( "Adding model resource: " .. path )
	end
	for _, modelDir in ipairs ( modelDirs or { } ) do
		local path = dir .. modelDir .. "/"
		self:AddModelResource( path )
	end
end

-------------------------------------------------
-----------------Recursively Add Materials / Textures
function GMatch:AddMaterialResource( dir )
	local materialFiles, materialDirs = file.Find( dir .. "*", "MOD", "namedesc" )
	for _, materialFile in ipairs ( materialFiles or { } ) do
		local path = dir .. materialFile
		resource.AddSingleFile( path )
		print( "Adding material resource: " .. path )
	end
	for _, materialDir in ipairs ( materialDirs or { } ) do
		local path = dir .. materialDir .. "/"
		self:AddMaterialResource( path )
	end
end

local extensionWhitelist = {
	["vmt"] = true,
	["vtf"] = true,
	["png"] = true,
	["wav"] = true,
	["mp3"] = true,
	["mdl"] = true
}

function GMatch:AddGamemodeResources( dir )
	local dir = dir or "gamemodes/" .. gMatchGameFolder .. "/content/"
	local resFiles, resDirs = file.Find( dir .. "*", "GAME" )
	for _, resFile in ipairs ( resFiles or { } ) do
		local extension = string.GetExtensionFromFilename( resFile )
		if not ( extensionWhitelist[ extension ] ) then continue end
		local resourcePath = string.Replace( dir, "gamemodes/" .. gMatchGameFolder .. "/content/", "" )
		print( "Resourcing file: " .. dir .. resFile )
		resource.AddFile( resourcePath .. resFile )
	end
	for _, resDir in ipairs ( resDirs or { } ) do
		local newPath = dir .. resDir .. "/"
		self:AddGamemodeResources( newPath )
	end
end

-------------------------------------------------
------------------Add File to Specific Realm
function GMatch:AddFileToRealm( realm, filePath )
	if ( realm == "SV" ) then
		print( "[SERVER FILE] " .. filePath )
		include( filePath )
	elseif ( realm == "SH" ) then
		print( "[SHARED FILE] " .. filePath )
		AddCSLuaFile( filePath )
		include( filePath )
	elseif ( realm == "CL" ) then
		print( "[CLIENT FIle] " .. filePath )
		AddCSLuaFile( filePath )
	end
end

--------------------------------------------------
----------------Recursively Add the Files
function GMatch:IncludeServerFiles( dir, realm )
	local svFiles, svDirs = file.Find( dir .. "*", "LUA", "namedesc" )
	for __, svFile in ipairs ( svFiles or { } ) do
		local path = dir .. svFile
		print( path )
		self:AddFileToRealm( realm, path )
	end
	for _, svDir in ipairs ( svDirs or { } ) do
		local path =  tostring( dir ) .. tostring( svDir ) .. "/"
		self:IncludeServerFiles( path, realm )
	end
end

function GMatch:IncludeAllFiles( baseDirectory )
	GMatch:IncludeServerFiles( baseDirectory .. "server/", "SV" )
	GMatch:IncludeServerFiles( baseDirectory .. "client/", "CL" )
	GMatch:IncludeServerFiles( baseDirectory .. "shared/", "SH"  )
end

GMatch:IncludeAllFiles( gMatchGameFolder .. "/gamemode/" )
if ( GMatch.Config.AutoResourceContent ) then
	GMatch:AddGamemodeResources( )
end
//AddModelResource( "models/items/jeezy/" )
//AddMaterialResource( "materials/models/items/jeezy/" )