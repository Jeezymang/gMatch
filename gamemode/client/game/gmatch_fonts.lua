GMatch.GameData.Fonts = GMatch.GameData.Fonts or { }
local oldFontCreate = surface.CreateFont
function surface.CreateFont( name, fontData )
	GMatch.GameData.Fonts[name] = true
	return ( oldFontCreate( name, fontData ) )
end

surface.CreateFont( "GMatch_Lobster_MediumBoldStatic", {
	font = "Lobster", 
	size = 14, 
	weight = 750
} )

surface.CreateFont( "GMatch_Lobster_SmallBoldStatic", {
	font = "Lobster", 
	size = 12, 
	weight = 750
} )

surface.CreateFont( "GMatch_Lobster_LargeBold", {
	font = "Lobster", 
	size = ScreenScale( 15 ), 
	weight = 750
} )

surface.CreateFont( "GMatch_Lobster_MediumBold", {
	font = "Lobster", 
	size = ScreenScale( 11 ), 
	weight = 750
} )

surface.CreateFont( "GMatch_Lobster_MediumBold_S", {
	font = "Lobster", 
	size = ScreenScale( 11 ), 
	weight = 750,
	blursize = 4
} )

surface.CreateFont( "GMatch_Lobster_SmallBold", {
	font = "Lobster", 
	size = ScreenScale( 10 ), 
	weight = 750
} )

surface.CreateFont( "GMatch_Lobster_Small", {
	font = "Lobster", 
	size = ScreenScale( 10 ), 
	weight = 500
} )

surface.CreateFont( "GMatch_Lobster_3D2DMediumBold", {
	font = "Lobster", 
	size = 35,
	weight = 750
} )

surface.CreateFont( "GMatch_Lobster_3D2DSmallBold", {
	font = "Lobster", 
	size = 25,
	weight = 750
} )
