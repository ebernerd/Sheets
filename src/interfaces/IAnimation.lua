
 -- @once

 -- @ifndef __INCLUDE_sheets
	-- @error 'sheets' must be included before including 'sheets.interfaces.IAnimation'
 -- @endif

 -- @print Including sheets.interfaces.IAnimation

interface "IAnimation" {}

function IAnimation:IAnimation()
	self.animations = {}
end

function IAnimation:addAnimation( label, setter, animation )
	parameters.check( 3,
		"label", "string", label,
		"setter", "function", setter,
		"animation", Animation, animation
	)

	self.animations[label] = {
		setter = setter;
		animation = animation;
	}
	if animation.value then
		setter( self, animation.value )
	end

	return animation
end

function IAnimation:stopAnimation( label )
	parameters.check( 1, "label", "string", label )

	local a = self.animations[label]
	self.animations[label] = nil
	return a
end

function IAnimation:updateAnimations( dt )
	parameters.check( 1, "dt", "number", dt )

	local finished = {}
	local animations = self.animations
	local k, v = next( animations )

	while animations[k] do

		local animation = v.animation
		animation:update( dt )
		if animation.value then
			v.setter( self, animation.value )
		end

		if animation:finished() then
			finished[#finished + 1] = k
		end

		k, v = next( animations, k )
	end

	for i = 1, #finished do
		self.animations[finished[i]] = nil
	end
end
