local plyMeta = FindMetaTable( "Player" )

function plyMeta:PrintCenterMessage( txt, length, col, isRainbow, font )
	GMatch.GameData.ScreenMessages = GMatch.GameData.ScreenMessages or { }
	table.insert( GMatch.GameData.ScreenMessages, {
		message = txt,
		mesLength = length,
		expireTime = CurTime( ) + length,
		col = col,
		isRainbow = isRainbow,
		font = font
	} )
	MsgC( col or Color( 145, 145, 225 ), txt .. "\n" )
end

function plyMeta:DisplayNotify( txt, length, iconPath, textColor, panelColor, isRainbow, font )
	GMatch.GameData.Notifies = GMatch.GameData.Notifies or { }
	table.insert( GMatch.GameData.Notifies, {
		message = txt,
		notifyLength = length,
		expireTime = CurTime( ) + length,
		iconPath = iconPath,
		textColor = textColor,
		panelColor = panelColor,
		isRainbow = isRainbow,
		font = font
	} )
	MsgC( panelColor or Color( 145, 145, 225 ), txt .. "\n" )
end