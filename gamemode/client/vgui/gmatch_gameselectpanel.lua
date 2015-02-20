PANEL = { }

function PANEL:Init( )
	LocalPlayer( ).gMatchGameSelect = self
	gui.EnableScreenClicker( true )
	self:SetSize( ScrW( ) * 0.3, ScrH( ) * 0.5 )
	self:Center( )
	self.gameVoteButtons = { }
	self:SetupGameChoices( )
	local closeButton = vgui.Create( "gMatch_ColoredButton", self )
	closeButton:SetSize( self:GetWide( ) * 0.075, self:GetTall( ) * 0.025 )
	closeButton:AlignTop( self:GetTall( ) * 0.025 )
	closeButton:AlignRight( self:GetWide( ) * 0.05 )
	closeButton:SetButtonColor( Color( 175, 75, 75 ) )
	closeButton:SetButtonRoundness( 4 )
	closeButton.OnMousePressed = function( btn )
		self:Remove( )
	end
end

function PANEL:OnRemove( )
	gui.EnableScreenClicker( false )
end

function PANEL:SetupGameChoices( )
	local dScrollPanel = vgui.Create( "DScrollPanel", self )
	dScrollPanel:SetSize( self:GetWide( ) * 0.9, self:GetTall( ) * 0.8 )
	dScrollPanel:Center( )
	local dIconLayout = vgui.Create( "DIconLayout", dScrollPanel )
	dIconLayout:SetSize( dScrollPanel:GetWide( ), dScrollPanel:GetTall( ) )
	dIconLayout:SetPos( 0, 0 )
	dIconLayout:SetSpaceX( 5 )
	dIconLayout:SetSpaceY( 5 )
	local count = 0
	for folder, gameData in pairs ( GMatch.Config.Gamemodes ) do
		count = count + 1
		local votePanel = dIconLayout:Add( "DPanel" )
		votePanel:SetSize( dScrollPanel:GetWide( ), self:GetTall( ) * 0.3 )
		votePanel.Paint = function( pnl, w, h )
			draw.RoundedBox( 6, 0, 0, w, h, Color( 25, 25, 25, 125 ) )
		end
		local voteButton = vgui.Create( "gMatch_ColoredButton", votePanel )
		voteButton:SetSize( self:GetWide( ) * 0.2, self:GetTall( ) * 0.05 )
		voteButton:SetButtonText( "VOTE" )
		local buttonPosX, buttonPosY = votePanel:GetWide( ) * 0.01, votePanel:GetTall( ) * 0.2
		voteButton:SetPos( buttonPosX, buttonPosY )
		voteButton:CenterHorizontal( )
		voteButton.OnMousePressed = function( pnl, btn )
			net.Start( "GMatch:ManipulateGameVotes" )
				net.WriteUInt( NET_GAMEVOTES_VOTE, 16 )
				net.WriteString( folder )
			net.SendToServer( )
		end
		local dNameLabel = vgui.Create( "DLabel", votePanel )
		dNameLabel:SetText( gameData.name )
		dNameLabel:SetFont( "GMatch_Lobster_MediumBold" )
		dNameLabel:SizeToContents( )
		dNameLabel:AlignToPanelBottom( voteButton )
		dNameLabel:CenterHorizontal( )
		local dDescLabel = vgui.Create( "DLabel", votePanel )
		dDescLabel:SetText( gameData.desc )
		dDescLabel:SetFont( "GMatch_Lobster_SmallBoldStatic" )
		dDescLabel:SizeToContents( )
		dDescLabel:AlignToPanelBottom( dNameLabel )
		dDescLabel:CenterHorizontal( )
		self:CreateVoteBoxes( votePanel, voteButton, ( dScrollPanel:GetWide( ) * 0.5 ) - ( ( 16 * 10 ) * 0.6 ), buttonPosY + self:GetTall( ) * 0.15, 10 )
		self.gameVoteButtons[folder] = voteButton
	end
end

function PANEL:CreateVoteBoxes( parent, pnlOwner, x, y, amt )
	for i=1, amt do
		local offsetX = x + ( i * 16 )
		local dVoteBox = vgui.Create( "DCheckBox", parent )
		dVoteBox:SetPos( offsetX, y )
		dVoteBox.DoClick = function( ) end
		pnlOwner.voteBoxes = pnlOwner.voteBoxes or { }
		table.insert( pnlOwner.voteBoxes, dVoteBox )
	end
end

function PANEL:SetVotesChecked( pnlOwner, amt )
	local votesChecked = pnlOwner.votesChecked or 0
	for index, dVoteBox in ipairs ( pnlOwner.voteBoxes or { } ) do
		local shouldCheck = true
		if ( votesChecked > amt and index > amt ) then
			if ( index > votesChecked ) then break end
			shouldCheck = false
		elseif ( votesChecked <= amt and index > amt ) then
			break
		end
		dVoteBox:SetChecked( shouldCheck )
	end
	pnlOwner.votesChecked = amt
end

function PANEL:Paint( w, h )
	local x, y = self:LocalToScreen( )
	self:DrawBlurredRect( )
	draw.RoundedBox( 0, 0, 0, w, h, Color( 45, 45, 45, 225 ) )
end

function PANEL:AddVote( gameName )
	if not ( self.gameVoteButtons[ gameName ] ) then return end
	local voteButton = self.gameVoteButtons[ gameName ]
	local currentVotes = voteButton.votesChecked or 0
	currentVotes = currentVotes + 1
	self:SetVotesChecked( voteButton, currentVotes )
end

function PANEL:RemoveVote( gameName )
	if not ( self.gameVoteButtons[ gameName ] ) then return end
	local voteButton = self.gameVoteButtons[ gameName ]
	local currentVotes = voteButton.votesChecked or 0
	currentVotes = currentVotes - 1
	self:SetVotesChecked( voteButton, currentVotes )
end

vgui.Register( "gMatch_GameSelect", PANEL, "Panel" )