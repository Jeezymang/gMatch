PANEL = { }

function PANEL:Init()
	self:SetSize( ScrW( ) * 0.05, ScrH( ) * 0.025 )
	self:Center( )
	self:SetText( "" )
	self.buttonRoundness = 0
	self.buttonColor = Color( 255, 255, 255, 255 )
	self.buttonHoverColor = Color( 225, 225, 225, 255 )
	self.buttonHoverSound = "ui/buttonrollover.wav"
	self.buttonMaterial = nil
	self.buttonText = ""
	self.buttonTextColor = Color( 45, 45, 45, 255 )
	self.buttonFont = "GMatch_Lobster_MediumBold"
end

function PANEL:SetButtonColor( col )
	self.buttonColor = col
end

function PANEL:SetButtonHoverColor( col )
	self.buttonHoverColor = col
end

function PANEL:SetButtonHoverSound( snd )
	self.buttonHoverSound = snd
end

function PANEL:SetButtonMaterial( mat )
	self.buttonMaterial = mat
end

function PANEL:SetButtonText( txt )
	self.buttonText = txt
end

function PANEL:SetButtonTextColor( col )
	self.buttonTextColor = col
end

function PANEL:SetButtonFont( font )
	self.buttonFont = font
end

function PANEL:SetButtonRoundness( rnd )
	self.buttonRoundness = rnd
end

function PANEL:OnCursorEntered( )
	if not ( LocalPlayer( ).gMatchHoveringPanel == self ) then
		surface.PlaySound( self.buttonHoverSound )
	end
	LocalPlayer( ).gMatchHoveringPanel = self
end

function PANEL:OnCursorExited( )
	LocalPlayer( ).gMatchHoveringPanel = nil
end

function PANEL:Paint( w, h )
	if not ( LocalPlayer( ).gMatchHoveringPanel == self ) then
		draw.RoundedBox( self.buttonRoundness, 0, 0, w, h, self.buttonColor )
	else
		draw.RoundedBox( self.buttonRoundness, 0, 0, w, h, self.buttonHoverColor )
	end
	if not ( self.buttonMaterial ) then
		surface.SetFont( self.buttonFont )
		local txtW, txtH = surface.GetTextSize( self.buttonText )
		draw.SimpleText( self.buttonText, self.buttonFont, w * 0.5, ( h * 0.5 - ( txtH * 0.5 ) ), self.buttonTextColor, TEXT_ALIGN_CENTER )
	else
		surface.SetDrawColor( Color( 255, 255, 255, 255 ) )
		surface.SetMaterial( self.buttonMaterial )
		surface.DrawTexturedRect( 0, 0, w, h )
	end
end

vgui.Register( "gMatch_ColoredButton", PANEL, "DButton" )