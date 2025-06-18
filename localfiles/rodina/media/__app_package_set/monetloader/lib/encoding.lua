-- This file is part of SA MoonLoader package.
-- Licensed under the MIT License.
-- Copyright (c) 2017, BlastHack Team <blast.hk>

-- Modified by MonetLoader to use built-in functions

-------------------
--- USAGE GUIDE ---
-------------------
--[[
-- initialization
local encoding = require 'encoding'
encoding.default = 'cp1251' -- set the same encoding as script file
u8 = encoding.UTF8 -- get the UTF-8 converter

-- usage
local utf8_string = u8'text in cp1251' -- convert to UTF-8 from default encoding
local utf8_string = u8:encode('text in cp1251') -- same as above
local text = u8:decode(utf8_string) -- convert UTF-8 back to default encoding
]]

local encoding = {
	default = 'UTF-8'
}

local aliases = {
	UTF8 = 'UTF-8',
	CP1251 = 'CP-1251'
}

local function normalize_encoding_name(e)
	e = string.upper(string.gsub(e, '_', '-'))
	if aliases[e] then return aliases[e] end
	return e
end

local function identity(text)
	return text
end

local function get_encoder(to, from)
	if to == 'UTF-8' and from == 'CP-1251' then
		return monet_cp1251_to_utf8
	elseif to == 'CP-1251' and from == 'UTF-8' then
		return monet_utf8_to_cp1251
	elseif to == from then
		return identity
	end
end

local converter = {}
function converter.new(enc)
	local private = {
		encoder = {},
		decoder = {},
	}

	local public = {
		encoding = enc
	}
	function public:encode(str, enc)
		if enc then enc = normalize_encoding_name(enc)
		else enc = normalize_encoding_name(encoding.default)
		end
		local cd = private.encoder[enc]
		if not cd then
			cd = get_encoder(self.encoding, enc)
			assert(cd)
			private.encoder[enc] = cd
		end
		local encoded = cd(str)
		return encoded
	end

	function public:decode(str, enc)
		if enc then enc = normalize_encoding_name(enc)
		else enc = normalize_encoding_name(encoding.default)
		end
		local cd = private.decoder[enc]
		if not cd then
			cd = get_encoder(enc, self.encoding)
			assert(cd)
			private.decoder[enc] = cd
		end
		local decoded = cd(str)
		return decoded
	end

	local mt = {}
	function mt:__call(str, enc)
		return self:encode(str, enc)
	end

	setmetatable(public, mt)
	return public
end

setmetatable(encoding, {
	__index = function(table, index)
		assert(type(index) == 'string')
		local enc = normalize_encoding_name(index)
		local already_loaded = rawget(table, enc)
		if already_loaded then
			table[index] = already_loaded
			return already_loaded
		else
			-- create new converter
			local conv = converter.new(enc)
			table[index] = conv
			table[enc] = conv
			return conv
		end
	end
})

return encoding
