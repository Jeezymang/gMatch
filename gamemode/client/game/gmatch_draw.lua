local blurMaterial = Material( "pp/blurscreen" )

//Credits to Chessnut for the screen blur effect.
function draw.BlurredRect( x, y, w, h, weight, amt, col )
	local col = col or Color( 255, 255, 255, 255 )
	surface.SetDrawColor( col )
	surface.SetMaterial( blurMaterial )
	local weight = weight or 5
	for i = 1, weight do
		blurMaterial:SetFloat( "$blur", ( i / 3 ) * ( amt or 6 ) )
		blurMaterial:Recompute( )
		render.UpdateScreenEffectTexture( )
		render.SetScissorRect( x, y, x + w, y + h, true )
			surface.DrawTexturedRect( 0, 0, ScrW( ), ScrH( ) )
		render.SetScissorRect( 0, 0, 0, 0, false )
	end
	surface.SetDrawColor( Color( 255, 255, 255, 255 ) )
end

function draw.TexturedRect( x, y, w, h, mat, col )
	local col = col or Color( 255, 255, 255, 255 )
	surface.SetDrawColor( col )
	surface.SetMaterial( mat )
	surface.DrawTexturedRect( x, y, w, h )
	surface.SetDrawColor( Color( 255, 255, 255, 255 ) )
end

function draw.HorizontalCutTexturedRect( x, y, w, h, mat, col, percent )
	render.SetScissorRect( x, y, x + ( w * percent ), y + h, true )
		draw.TexturedRect( x, y, w, h, mat, col )
	render.SetScissorRect( 0, 0, 0, 0, false )
end
