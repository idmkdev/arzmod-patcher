-- cjson.safe implemented in lua

local normal = require('cjson')

local old_cjson_encode = normal.encode
local old_cjson_decode = normal.decode

local function json_new_safe()
  return require('cjson.safe')
end

local function json_encode_safe(data)
  local ok, result = pcall(old_cjson_encode, data)
  if not ok then
    return nil, result
  else
    return result
  end
end

local function json_decode_safe(data)
  local ok, result = pcall(old_cjson_decode, data)
  if not ok then
    return nil, result
  else
    return result
  end
end

normal.new = json_new_safe
normal.encode = json_encode_safe
normal.decode = json_decode_safe

return normal