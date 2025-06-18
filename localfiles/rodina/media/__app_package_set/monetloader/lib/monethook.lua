-- Copyright (c) MonetLoader, 2023
-- Built-in library: monethook
-- Lua package is distributed under the MIT license

assert(MONET_VERSION ~= nil and MONET_VERSION >= 2008000, "This version of monethook requires MonetLoader 2.8.0.")

local ffi = require('ffi')
local lib = ffi.load('monetloader')

ffi.cdef[[
  int monethook_hook_enable(uintptr_t address, uintptr_t func, uintptr_t* orig);
  int monethook_hook_disable(uintptr_t address);
]]

local had_error = false
local error_msg = nil

local hook = {hooks = {}}

addEventHandler('onScriptTerminate', function(scr)
  if scr == script.this then
    for i, hook in ipairs(hook.hooks) do
      if hook.status then
        hook.stop()
      end
    end
  end
end)

lua_thread.create(function()
  while true do
    wait(0)
    if had_error then
      print('monethook: An error has occurred while executing hook user callback!')
      error(error_msg) -- If you have error on this line, an error has occurred in one of your hooks!
      had_error = false
    end
  end
end)

function hook.new(cast, callback, hook_addr)
  local new_hook = {}

  new_hook._hook_addr = hook_addr
  new_hook.call = ffi.cast(cast, ffi.cast('void*', new_hook._hook_addr))
  new_hook.status = false

  -- Provide Lua error handling in hook, function is in hook struct to prevent GC of it
  new_hook._wrap_cb = function(...)
    local status, result = pcall(callback, ...)
    if not status then
      had_error = true
      error_msg = result
      new_hook.stop()
      return new_hook.call(...)
    else
      return result
    end
  end
  jit.off(new_hook._wrap_cb, true) -- https://www.blast.hk/threads/99792/post-838497
  local cb_addr = ffi.cast('uintptr_t', ffi.cast('void*', ffi.cast(cast, new_hook._wrap_cb)))
  new_hook._cb_addr = cb_addr

  new_hook.stop = function()
    if not new_hook.status then
      return
    end

    local result = lib.monethook_hook_disable(new_hook._hook_addr)
    assert(result == 0, "Couldn't stop hook! Error code is " .. tostring(result))
    new_hook.call = ffi.cast(cast, ffi.cast('void*', new_hook._hook_addr))
    new_hook.status = false
  end

  new_hook.start = function()
    if new_hook.status then
      return
    end

    local buf = ffi.new('uintptr_t[1]')
    local result = lib.monethook_hook_enable(new_hook._hook_addr, new_hook._cb_addr, buf)
    assert(result == 0, "Couldn't start hook! Error code is " .. tostring(result))
    new_hook.call = ffi.cast(cast, ffi.cast('void*', buf[0]))
    new_hook.status = true
  end

  new_hook.start()
  table.insert(hook.hooks, new_hook)
  return setmetatable(new_hook, {
    __call = function(self, ...)
      return self.call(...)
    end
  })
end

return hook