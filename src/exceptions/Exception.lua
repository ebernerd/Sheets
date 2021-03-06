
 -- @once

 -- @ifndef __INCLUDE_sheets
	-- @error 'sheets' must be included before including 'sheets.exceptions.Exception'
 -- @endif

 -- @print Including sheets.exceptions.Exception

local thrown

local function handler( t )
	for i = 1, #t do
		if t[i].catch == thrown.name or t[i].default or t[i].catch == thrown.class then
			return t[i].handler( thrown )
		end
	end
	return Exception.throw( thrown )
end

class "Exception" {
	name = "undefined";
	data = "undefined";
	trace = {};
}

function Exception:Exception( name, data, level )
	self.name = name
	self.data = data
	self.trace = {}

	level = ( level or 1 ) + 2

	if level > 2 then
		for i = 1, 5 do
			local src = select( 2, pcall( error, "", level + i ) ):gsub( ": $", "" )

			if src == "pcall" or src == "" then
				break
			else
				self.trace[i] = src
			end
		end
	end
end

function Exception:getTraceback( initial, delimiter )
	initial = initial or ""
	delimiter = delimiter or "\n"

	parameters.check( 2, "initial", "string", initial, "delimiter", "string", delimiter )

	if #self.trace == 0 then return "" end

	return initial .. table.concat( self.trace, delimiter )
end

function Exception:getData()
	if type( self.data ) == "string" or class.isClass( self.data ) or class.isInstance( self.data ) then
		return tostring( self.data )
	else
		return textutils.serialize( seld.data )
	end
end

function Exception:getDataAndTraceback( indent )
	parameters.check( 1, "indent", "number", indent or 1 )

	return self:getData() .. self:getTraceback( "\n" .. (" "):rep( indent or 1 ) .. "in ", "\n" .. (" "):rep( indent or 1 ) .. "in " )
end

function Exception:tostring()
	return tostring( self.name ) .. " exception:\n  " .. self:getDataAndTraceback( 4 )
end

function Exception.thrown()
	return thrown
end

function Exception.throw( e, data, level )
	if class.isClass( e ) then
		e = e( data, ( level or 1 ) + 1 )
	elseif type( e ) == "string" then
		e = Exception( e, data, ( level or 1 ) + 1 )
	elseif not class.typeOf( e, Exception ) then
		return Exception.throw( "IncorrectParameterException", "expected class, string, or Exception e, got " .. class.type( e ) )
	end
	thrown = e
	error( SHEETS_EXCEPTION_ERROR, 0 )
end

function Exception.try( func )
	local ok, err = pcall( func )

	if not ok and err == SHEETS_EXCEPTION_ERROR then
		return handler
	end

	return error( err, 0 )
end

function Exception.catch( etype )
	return function( handler )
		return { catch = etype, handler = handler }
	end
end

function Exception.default( handler )
	return { default = true, handler = handler }
end
