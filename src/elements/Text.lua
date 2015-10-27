
class "Text" extends "Sheet" implements (IHasText) {}

function Text:Text( x, y, width, height, text )
	self.text = text
	return self:Sheet( x, y, width, height )
end

function Text:onPreDraw()
	self.canvas:clear( self.theme:getField( self.class, "colour", "default" ) )
	self:drawText "default"
end

Theme.addToTemplate( Text, "colour", {
	default = CYAN;
} )
Theme.addToTemplate( Text, "textColour", {
	default = WHITE;
} )