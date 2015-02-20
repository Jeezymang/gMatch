local pnlMeta = FindMetaTable( "Panel" )
local blurMaterial = Material( "pp/blurscreen" )

function pnlMeta:DrawBlurredRect( weight, amt )
	local x, y = self:LocalToScreen( )
	surface.SetDrawColor( Color( 255, 255, 255, 255 ) )
	surface.SetMaterial( blurMaterial )
	local weight = weight or 5
	for i = 1, weight do
		blurMaterial:SetFloat( "$blur", ( i / 3 ) * ( amt or 6 ) )
		blurMaterial:Recompute( )
		render.UpdateScreenEffectTexture( )
		surface.DrawTexturedRect( x * -1, y * -1, ScrW( ), ScrH( ) )
	end
end

function pnlMeta:AlignToPanelBottom( pnl, offsetX, offsetY )
	local offsetX = offsetX or 0
	local offsetY = offsetY or 0
	local x, y = pnl:GetPos( )
	local w, h = pnl:GetSize( )
	x, y = x + offsetX, ( y + h ) + offsetY
	self:SetPos( x, y )
end