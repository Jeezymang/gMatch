local SCOREBOARD = { }

function SCOREBOARD:Init( )
	self:SetSize( ScrW( ) * 0.6, ScrH( ) * 0.7 )
	self:Center( )
	self:CreatePlayerList( )
	self:GenerateLabels( )
	self:GeneratePlayerList( )
	self:MakePopup( )
end

function SCOREBOARD:CreatePlayerList( )
	self.dScrollPanel = vgui.Create( "DScrollPanel", self )
	self.dScrollPanel:SetSize( self:GetWide( ) * 0.8, self:GetTall( ) * 0.7 )
	self.dScrollPanel:SetPos( self:GetWide( ) * 0.1, self:GetTall( ) * 0.2 )
	self.dIconLayout = vgui.Create( "DIconLayout" )
	self.dScrollPanel:AddItem( self.dIconLayout )
	self.dIconLayout:SetSize( self.dScrollPanel:GetWide( ) * 1, self.dScrollPanel:GetTall( ) )
	self.dIconLayout:SetPos( 0, 0 )
	self.dIconLayout:SetSpaceX( 0 )
	self.dIconLayout:SetSpaceY( 5 )
end

function SCOREBOARD:GeneratePlayerList( )
	self.dIconLayout:Clear( )
	local sortedPlayerList = GMatch.Config.ScoreboardSort( )
	for index, plyRow in ipairs ( sortedPlayerList ) do
		local playerRow = self.dIconLayout:Add( "gMatch_ScoreboardPlayerRow" )
		playerRow.scoreboardPanel = self
		playerRow.dIconLayout = self.dIconLayout
		playerRow:SetPlayerEntity( plyRow.ply )
	end 
end

function SCOREBOARD:GenerateLabels( )
	self.rowLabels = { }
	local listX, listY = self.dScrollPanel:GetPos( )
	if not ( GMatch.Config.ScoreboardLabels ) then return end
	for index, lblData in ipairs( GMatch.Config.ScoreboardLabels ) do
		local dLabel = vgui.Create( "DLabel", self )
		local labelFont = lblData.labelFont or "GMatch_Lobster_SmallBold"
		local labelColor = lblData.labelColor or Color( 255, 255, 255 )
		dLabel:SetFont( labelFont )
		dLabel:SetTextColor( labelColor )
		dLabel:SetText( lblData.text )
		dLabel:SizeToContents( )
		local labelW, labelH = dLabel:GetSize( )
		local labelY = listY - labelH
		local labelX = ( self:GetWide( ) * lblData.offset ) - ( labelW * 0.5 )
		dLabel:SetPos( listX + labelX, labelY )
		self.rowLabels[index] = dLabel
	end
end

function SCOREBOARD:Paint( w, h )
	draw.RoundedBox( 4, 0, 0, w, h, Color( 0, 0, 0, 235 ) )
	draw.RoundedBox( 4, w * 0.1, h * 0.03, w * 0.8, h * 0.1, Color( 35, 35, 35, 255 ) )
	draw.RoundedBox( 4, w * 0.1, h * 0.2, w * 0.8, h * 0.7, Color( 35, 35, 35, 255 ) )
	self:DrawBlurredRect( 5, 4 )
	draw.SimpleText( GetHostName( ), "GMatch_Lobster_MediumBold", w * 0.5, h * 0.04, Color( 255, 255, 255 ), TEXT_ALIGN_CENTER )
	draw.SimpleText( gMatchGameName, "GMatch_Lobster_SmallBold", w * 0.5, h * 0.075, Color( 255, 255, 255 ), TEXT_ALIGN_CENTER )
end

function SCOREBOARD:Think( )
	for index, lbl in ipairs( self.rowLabels ) do
		if ( GMatch.Config.ScoreboardLabels[index] and GMatch.Config.ScoreboardLabels[index].labelRainbow ) then
			lbl:SetTextColor( util.RainbowStrobe( 2 ) )
		end
	end
end

vgui.Register( "gMatch_Scoreboard", SCOREBOARD, "Panel" )

local SCOREBOARD_PLAYER_ROW = { }

function SCOREBOARD_PLAYER_ROW:Init( )
	self:SetSize( ( ScrW( ) * 0.6 ) * 0.8, ( ( ScrH( ) * 0.7 ) * 0.7 ) * 0.05 ) 
	self.defaultW, self.defaultH = self:GetSize( )
	self.playerEntity = nil
	self.textColor = Color( 255, 255, 255 )
end

function SCOREBOARD_PLAYER_ROW:GenerateLabels( )
	self.playerRowLabels = { }
	if not ( GMatch.Config.ScoreboardLabels ) then return end
	for index, lblData in ipairs( GMatch.Config.ScoreboardLabels ) do
		local dLabel = vgui.Create( "DLabel", self )
		local valueFont = lblData.valueFont or "GMatch_Lobster_SmallBold"
		local valueColor = lblData.valueColor or Color( 255, 255, 255 )
		local rowColor = GMatch.Config.ScoreboardPlayerRowColor( self.playerEntity )
		rowColor = rowColor:Darken( 100 )
		dLabel:SetFont( valueFont )
		dLabel:SetTextColor( valueColor )
		dLabel:SetText( lblData.valueFunc( self.playerEntity ) )
		dLabel:SizeToContents( )
		local labelW, labelH = dLabel:GetSize( )
		local parentW = self.scoreboardPanel.rowLabels[index]:GetWide( )
		local labelX = ( self.scoreboardPanel:GetWide( ) * lblData.offset )
		if ( lblData.isCentered ) then
			labelX = labelX - ( labelW * 0.5 )
		else
			labelX = labelX - ( parentW * 0.5 )
		end
		local labelY = ( self:GetTall( ) * 0.5 ) - ( labelH * 0.5 )
		dLabel:SetPos( labelX, labelY )
		self.playerRowLabels[index] = dLabel
	end
end

function SCOREBOARD_PLAYER_ROW:Paint( w, h )
	local rowName, rowKills, rowDeaths, rowPing, rowColor = "Unknown", 0, 0, 0, Color( 255, 255, 255 )
	local rowColor = Color( 255, 255, 255 )
	if ( IsValid( self.playerEntity ) ) then
		rowName = self.playerEntity:Name( )
		rowKills = self.playerEntity:Frags( )
		rowDeaths = self.playerEntity:Deaths( )
		rowPing = self.playerEntity:Ping( )
		rowColor = GMatch.Config.ScoreboardPlayerRowColor( self.playerEntity )
	end
	rowColor = Color( rowColor.r - 45, rowColor.g - 45, rowColor.b - 45 )
	surface.SetFont( "GMatch_Lobster_Small" )
	local nameWide, textTall = surface.GetTextSize( rowName )
	local textYPos = ( h * 0.5 ) - ( textTall / 2 )
	if ( self.isExpanded ) then textYPos = textYPos - 40 end
	self.textColor = Color( 255, 255, 255 )
	draw.RoundedBox( 4, 0, 0, w, h, rowColor )
	if ( self.isExpanded ) then
		self.textColor = Color( 45, 45, 45 )
		draw.RoundedBox( 0, 0, h * 0.25, w, h, Color( 255, 255, 255 ) )
		draw.SimpleText( "Kills: " .. self.playerEntity:GetGameStat( "Kills" ), "GMatch_Lobster_MediumBoldStatic", w * 0.025, textYPos + 30, self.textColor, TEXT_ALIGN_LEFT )
		draw.SimpleText( "Deaths: " .. self.playerEntity:GetGameStat( "Deaths" ), "GMatch_Lobster_MediumBoldStatic", w * 0.025, textYPos + 50, self.textColor, TEXT_ALIGN_LEFT )
		draw.SimpleText( "Suicides: " .. self.playerEntity:GetGameStat( "Suicides" ), "GMatch_Lobster_MediumBoldStatic", w * 0.025, textYPos + 70, self.textColor, TEXT_ALIGN_LEFT )
		draw.SimpleText( "Headshots: " .. self.playerEntity:GetGameStat( "Headshots" ), "GMatch_Lobster_MediumBoldStatic", w * 0.3, textYPos + 30, self.textColor, TEXT_ALIGN_LEFT )
		draw.SimpleText( "Killing Sprees: " .. self.playerEntity:GetGameStat( "KillingSprees" ), "GMatch_Lobster_MediumBoldStatic", w * 0.3, textYPos + 50, self.textColor, TEXT_ALIGN_LEFT )
		draw.SimpleText( "Highest Killing Spree: " .. self.playerEntity:GetGameStat( "HighestKillingSpree" ), "GMatch_Lobster_MediumBoldStatic", w * 0.3, textYPos + 70, self.textColor, TEXT_ALIGN_LEFT )
		draw.SimpleText( "Revenges: " .. self.playerEntity:GetGameStat( "Revenges" ), "GMatch_Lobster_MediumBoldStatic", w * 0.95, textYPos + 30, self.textColor, TEXT_ALIGN_RIGHT )
		draw.SimpleText( "Dominations: " .. self.playerEntity:GetGameStat( "Dominations" ), "GMatch_Lobster_MediumBoldStatic", w * 0.95, textYPos + 50, self.textColor, TEXT_ALIGN_RIGHT )
		draw.SimpleText( "Wins: " .. self.playerEntity:GetGameStat( "Wins" ), "GMatch_Lobster_MediumBoldStatic", w * 0.95, textYPos + 70, self.textColor, TEXT_ALIGN_RIGHT )
		draw.SimpleText( "Join Date: " .. os.date( "%x", self.playerEntity:GetGameStat( "JoinDate" ) ), "GMatch_Lobster_MediumBoldStatic", w * 0.025, textYPos + 90, self.textColor, TEXT_ALIGN_LEFT ) 
	end
end

function SCOREBOARD_PLAYER_ROW:OnMousePressed( btn )
	if ( self:GetTall( ) == 110 ) then
		self:SetTall( self.defaultH )
		self.isExpanded = false
		self.dIconLayout:Layout( )
	else
		self:SetTall( 110 )
		self.isExpanded = true
		self.dIconLayout:Layout( )
	end
end

function SCOREBOARD_PLAYER_ROW:SetPlayerEntity( ply )
	self.playerEntity = ply
	self:GenerateLabels( )
end

function SCOREBOARD_PLAYER_ROW:Think( )
	for index, lbl in ipairs( self.playerRowLabels ) do
		if ( GMatch.Config.ScoreboardLabels[index] ) then
			if ( IsValid( self.playerEntity ) ) then
				lbl:SetText( GMatch.Config.ScoreboardLabels[index].valueFunc( self.playerEntity ) )
			end
			if ( GMatch.Config.ScoreboardLabels[index].valueRainbow ) then
				lbl:SetTextColor( util.RainbowStrobe( 2 ) )
			end
		end
	end
end

vgui.Register( "gMatch_ScoreboardPlayerRow", SCOREBOARD_PLAYER_ROW, "Panel" )

function GM:ScoreboardShow( )
	local scoreboardPanel = LocalPlayer( ).scoreboardPanel
	if not ( ValidPanel( scoreboardPanel ) ) then
		LocalPlayer( ).scoreboardPanel = vgui.Create( "gMatch_Scoreboard" )
	else
		scoreboardPanel:SetVisible( true )
		scoreboardPanel:GeneratePlayerList( )
	end
end

function GM:ScoreboardHide( )
	local scoreboardPanel = LocalPlayer( ).scoreboardPanel
	if not ( ValidPanel( scoreboardPanel ) ) then return end
	scoreboardPanel:SetVisible( false )
end