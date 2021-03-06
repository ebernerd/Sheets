
 -- @once

 -- @ifndef __INCLUDE_sheets
	-- @error 'sheets' must be included before including 'sheets.interfaces.IHasText'
 -- @endif

 -- @print Including sheets.interfaces.IHasText

local wrapline, wrap

interface "IHasText" {
	text = "";
	text_lines = nil;
}

function IHasText:autoHeight()
	if not self.text_lines then
		self:wrapText( true )
	end
	return self:setHeight( #self.text_lines )
end

function IHasText:setText( text )
	parameters.check( 1, "text", "string", text )

	self.text = text
	self:wrapText()
	self:setChanged()
	return self
end

function IHasText:wrapText( ignoreHeight )
	self.text_lines = wrap( self.text, self.width, not ignoreHeight and self.height )
end

function IHasText:drawText( mode )
	local offset, lines = 0, self.text_lines
	mode = mode or "default"

	local horizontal_alignment = self.style:getField( "horizontal-alignment." .. mode )
	local vertical_alignment = self.style:getField( "vertical-alignment." .. mode )

	if not lines then
		self:wrapText()
		lines = self.text_lines
	end

	if vertical_alignment == ALIGNMENT_CENTRE then
		offset = math.floor( self.height / 2 - #lines / 2 + .5 )
	elseif vertical_alignment == ALIGNMENT_BOTTOM then
		offset = self.height - #lines
	end

	for i = 1, #lines do

		local xOffset = 0
		if horizontal_alignment == ALIGNMENT_CENTRE then
			xOffset = math.floor( self.width / 2 - #lines[i] / 2 + .5 )
		elseif horizontal_alignment == ALIGNMENT_RIGHT then
			xOffset = self.width - #lines[i]
		end

		self.canvas:drawText( xOffset, offset + i - 1, lines[i], {
			colour = 0;
			textColour = self.style:getField( "textColour." .. mode );
		} )

	end
end

function IHasText:onPreDraw()
	self:drawText "default"
end

function wrapline( text, width )
	if text:sub( 1, width ):find "\n" then
		return text:match "^(.-)\n[^%S\n]*(.*)$"
	end
	if #text < width then
		return text
	end
	for i = width + 1, 1, -1 do
		if text:sub( i, i ):find "%s" then
			return text:sub( 1, i - 1 ):gsub( "[^%S\n]+$", "" ), text:sub( i + 1 ):gsub( "^[^%S\n]+", "" )
		end
	end
	return text:sub( 1, width ), text:sub( width + 1 )
end

function wrap( text, width, height )
	local lines, line = {}
	while text and ( not height or #lines < height ) do
		line, text = wrapline( text, width )
		lines[#lines + 1] = line
	end
	return lines
end
