local colorMeta = FindMetaTable( "Color" )
local vectorMeta = FindMetaTable( "Vector" )
local plyMeta = FindMetaTable( "Player" )
// Credits to bobbleheadbob for the point of circle function. how 2 trig
function math.PointOnCircle( ang, radius, offsetX, offsetY )
	local ang = math.rad( ang )
	local x = math.cos( ang ) * radius + offsetX
	local y = math.sin( ang ) * radius + offsetY
	return x, y
end

// This function is from the link below:
// https://github.com/xfbs/PiL3/blob/master/18MathLibrary/shuffle.lua
function table.Shuffle( tbl )
	local indices = { }
    for i = 1, #tbl do
        indices[#indices+1] = i
    end

    local shuffled = {}
    for i = 1, #tbl do
        local index = math.random(#indices)
        local value = tbl[indices[index]]
        table.remove(indices, index)
        shuffled[#shuffled+1] = value
    end

    return shuffled
end

function util.QuickEffect( start, origin, scale, effect )
    local effectData = EffectData()
    effectData:SetStart( start )
    effectData:SetOrigin( origin )
    effectData:SetScale( scale )
    util.Effect( effect, effectData, true, true )
end

function util.Explode( pos, owner, magnitude, radius, snd, sndLevel, sndPitch )
    local explosion = ents.Create( "env_explosion" )
    explosion:SetPos( pos )
    --explosion:SetPhysicsAttacker( owner )
    explosion:SetOwner( owner )
    explosion:Spawn( )
    explosion:SetKeyValue( "iMagnitude", magnitude )
    explosion:SetKeyValue( "iRadiusOverride", radius )
    explosion:Fire( "Explode", 0, 0 )
    explosion:EmitSound( snd or "ambient/explosions/explode_1.wav", sndLevel, sndPitch )
    SafeRemoveEntityDelayed( explosion, 1 )
end

//Credits to rejax for this.
function util.RainbowStrobe( freq )
    local frequency, time = ( freq or .5 ), RealTime()
    local red = math.sin( frequency * time ) * 127 + 128
    local green = math.sin( frequency * time + 2 ) * 127 + 128
    local blue = math.sin( frequency * time + 4 ) * 127 + 128
    return Color( red, green, blue )
end

function colorMeta:ToVector( )
	return Vector( self.r / 255, self.g / 255, self.b / 255 )
end

function vectorMeta:ToColor( )
	return ( Color( self.x * 255, self.y * 255, self.z * 255 ) )
end

function GMatch:GetGameVar( name, fallback )
	local varValue = GMatch.GameData.GameVars[name] or fallback
	return ( varValue )
end

function plyMeta:GetGameStat( stat )
    if ( self:IsBot( ) ) then return 0 end
    if ( SERVER ) then
        GMatch.GameData.PlayerStats = GMatch.GameData.PlayerStats or { }
        local playerTable = GMatch.GameData.PlayerStats[ self:SteamID( ) ]
        if not ( playerTable ) then return nil end
        if not ( playerTable[stat] ) then return nil end
        return ( playerTable[stat] )
    else
        GMatch.GameData.PlayerStats = GMatch.GameData.PlayerStats or { }
        GMatch.GameData.PlayerStats[self:SteamID( )] = GMatch.GameData.PlayerStats[self:SteamID( )] or { }
        return ( GMatch.GameData.PlayerStats[self:SteamID( )][stat] or 0 )
    end
end
    