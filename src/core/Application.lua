
 -- @once

 -- @ifndef __INCLUDE_sheets
	-- @error 'sheets' must be included before including 'sheets.core.Application'
 -- @endif

 -- @print Including sheets.core.Application

local function exceptionHandler( e )
	return error( tostring( e ), 0 )
end

local handleEvent

class "Application"
{
	name = "UnNamed Application";
	path = "";

	terminateable = true;
	running = true;

	screens = {};
	screen = nil;

	resource_loaders = {};
	extensions = {};

	threads = {};

	mouse = nil;
	keys = {};
	changed = false;
}

function Application:Application( name, path )
	self.screens = { Screen( self, term.getSize() ):addTerminal( term ) }
	self.screen = self.screens[1]

	self.name = name
	self.path = path or name

	self.resource_loaders = {}
	self.extensions = {}
	self.threads = {}
	self.keys = {}
end

function Application:registerResourceLoader( type, loader )
	parameters.check( 2, "type", "string", type, "loader", "function", loader )

	self.resource_loaders[type] = loader
end

function Application:unregisterResourceLoader( type )
	parameters.check( 1, "type", "string", type )
	self.resource_loaders[type] = nil
end

function Application:registerFileExtension( extension, type )
	parameters.check( 2, "extension", "string", extension, "type", "string", type )

	self.extensions[extension] = type
end

function Application:unregisterFileExtension( extension )
	parameters.check( 1, "extension", "string", extension )

	self.extensions[extension] = nil
end

function Application:loadResource( resource, type, ... )
	parameters.check( 2, "resource", "string", resource, "type", "string", type or "" )

	if not type then
		type = self.extensions[resource:match( "%.(%w+)$" ) or "txt"] or "text.plain"
	end

	if self.resource_loaders[type] then

		local h = fs.open( fs.combine( self.path, resource ), "r" ) or fs.open( resource, "r" )
		if h then

			local content = h.readAll()
			h.close()

			return self.resource_loaders[type]( self, resource, content, ... )

		else
			Exception.throw( ResourceLoadException, "Failed to open file '" .. resource .. "': not found under '/'' or '" .. self.path .. "'", 2 )
		end

	else
		Exception.throw( ResourceLoadException, "No loader for resource type '" .. type .. "'", 2 )
	end
end

function Application:addThread( thread )
	parameters.check( 1, "thread", Thread, thread )

	self.threads[#self.threads + 1] = thread
	
	return thread
end

function Application:isKeyPressed( key )
	parameters.check( 1, "key", "string", key )

	self.resource_loaders = {}
	self.extensions = {}

	return self.keys[key] ~= nil
end

function Application:stop()
	self.running = false
	return self
end

function Application:addScreen()

	local screen = Screen( self, term.getSize() )
	self.screens[#self.screens + 1] = screen
	return screen

end

function Application:removeScreen( screen )

	parameters.check( 1, "screen", Screen, screen )

	for i = #self.screens, 1, -1 do
		if self.screens[i] == screen then
			return table.remove( self.screens, i )
		end
	end

end

function Application:event( event, ... )
	local params = { ... }
	local screens = {}

	local function handle( e )
		for i = #screens, 1, -1 do
			screens[i]:handle( e )
		end
	end

	if event == "timer" and timer.update( ... ) then
		return
	end

	for i = 1, #self.screens do
		screens[i] = self.screens[i]
	end

	return handleEvent( self, handle, event, params, ... )
end

function Application:draw()

	if self.changed then
		for i = 1, #self.screens do
			self.screens[i]:draw()
		end
		self.changed = false
	end

end

function Application:update()

	local dt = timer.getDelta()
	timer.step()

	for i = 1, #self.screens do
		self.screens[i]:update( dt )
	end

	if self.onUpdate then
		self:onUpdate( dt )
	end

end

function Application:load()
	self.changed = true

	if self.onLoad then
		return self:onLoad()
	end
end

function Application:run()

	Exception.try (function()
		self:load()
		local t = timer.new( 0 ) -- updating timer
		while self.running do
			local event = { coroutine.yield() }
			if event[1] == "timer" and event[2] == t then
				t = timer.new( .05 )
				timer.update( event[2] )
			elseif event[1] == "terminate" and self.terminateable then
				self:stop()
			else
				self:event( unpack( event ) )
			end
			self:update()
			self:draw()
		end

	end) {
		Exception.default (exceptionHandler);
	}

end

function handleEvent( self, handle, event, params, ... )
	if event == "mouse_click" then
		self.mouse = {
			x = params[2] - 1, y = params[3] - 1;
			down = true, button = params[1];
			timer = os.startTimer( 1 ), time = os.clock(), moved = false;
		}

		handle( MouseEvent( SHEETS_EVENT_MOUSE_DOWN, params[2] - 1, params[3] - 1, params[1], true ) )

	elseif event == "mouse_up" then
		handle( MouseEvent( SHEETS_EVENT_MOUSE_UP, params[2] - 1, params[3] - 1, params[1], true ) )

		self.mouse.down = false
		os.cancelTimer( self.mouse.timer )

		if not self.mouse.moved and os.clock() - self.mouse.time < 1 and params[1] == self.mouse.button then
			handle( MouseEvent( SHEETS_EVENT_MOUSE_CLICK, params[2] - 1, params[3] - 1, params[1], true ) )
		end

	elseif event == "mouse_drag" then
		handle( MouseEvent( SHEETS_EVENT_MOUSE_DRAG, params[2] - 1, params[3] - 1, params[1], true ) )

		self.mouse.moved = true
		os.cancelTimer( self.mouse.timer )

	elseif event == "mouse_scroll" then
		handle( MouseEvent( SHEETS_EVENT_MOUSE_SCROLL, params[2] - 1, params[3] - 1, params[1], true ) )

	elseif event == "monitor_touch" then -- broken
		--[[handle( MouseEvent( SHEETS_EVENT_MOUSE_DOWN, params[2] - 1, params[3] - 1, 1 ) )
		handle( MouseEvent( SHEETS_EVENT_MOUSE_UP, params[2] - 1, params[3] - 1, 1 ) )
		handle( MouseEvent( SHEETS_EVENT_MOUSE_CLICK, params[2] - 1, params[3] - 1, 1 ) )]]

	elseif event == "chatbox_something" then
		-- handle( TextEvent( SHEETS_EVENT_VOICE, params[1] ) )

	elseif event == "char" then
		handle( TextEvent( SHEETS_EVENT_TEXT, params[1] ) )

	elseif event == "paste" then
		if self.keys.leftShift or self.keys.rightShift then
			handle( KeyboardEvent( SHEETS_EVENT_KEY_DOWN, keys.v, { leftCtrl = true, rightCtrl = true } ) )
		else
			handle( TextEvent( SHEETS_EVENT_PASTE, params[1] ) )
		end

	elseif event == "key" then
		self.keys[keys.getName( params[1] ) or params[1]] = os.clock()
		handle( KeyboardEvent( SHEETS_EVENT_KEY_DOWN, params[1], self.keys ) )

	elseif event == "key_up" then
		self.keys[keys.getName( params[1] ) or params[1]] = nil
		handle( KeyboardEvent( SHEETS_EVENT_KEY_UP, params[1], self.keys ) )

	elseif event == "term_resize" then
		self.width, self.height = term.getSize()
		for i = 1, #self.screens do
			self.screens[i]:onParentResized()
		end

	elseif event == "timer" and params[1] == self.mouse.timer then
		handle( MouseEvent( SHEETS_EVENT_MOUSE_HOLD, self.mouse.x, self.mouse.y, self.mouse.button, true ) )

	else
		local ev = MiscEvent( event, ... )
		handle( ev )

		if not ev.handled then
			for i = #self.threads, 1, -1 do
				if self.threads[i].running then
					self.threads[i]:resume( event, ... )
				else
					table.remove( self.threads, i )
				end
			end
		end
	end
end
