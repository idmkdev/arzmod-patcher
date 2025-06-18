-- Virtual memory I/O module for internal process.
--
-- This file is part of SA MoonLoader package.
-- Licensed under the MIT License.
-- Copyright (c) 2019, BlastHack Team <blast.hk>
--
-- Modified by MonetLoader for (partial) Linux support

local ffi = require 'ffi'
local memory = {} -- all function must accept number-type address

local page_access = {
    NOACCESS          = 0x00, -- ---
    READONLY          = 0x01, -- r-- Default for rodata.
    READWRITE         = 0x03, -- rw- Default for bss, got, data and friends.
    EXECUTE           = 0x04, -- --x
    EXECUTE_READ      = 0x05, -- r-x Default for code.
    EXECUTE_READWRITE = 0x07  -- rwx
}
local pvoid_t = ffi.typeof('void*')

ffi.cdef [[
int mprotect(void* addr, size_t len, int prot);
int memcmp(const void* ptr1, const void* ptr2, size_t num);
]]

local function set_protection(address, size, access, do_print)
    local iaddress = ffi.cast('uintptr_t', address)
    local aligned = bit.band(iaddress, 0xFFFFF000)
    local aligned_ptr = ffi.cast(pvoid_t, aligned)
    local len = bit.lshift(bit.rshift(iaddress + size - aligned + 4095, 12), 12)
    if ffi.C.mprotect(aligned_ptr, len, access) ~= 0 then
        if do_print then
            print("memory: mprotect failed, errno = ", ffi.errno())
        end
        return nil
    end
    return 0
end

local function unprotect(address, size)
    local r = set_protection(address, size, page_access.EXECUTE_READWRITE, false)
    if r == nil then -- Execmod not allowed.
        return set_protection(address, size, page_access.READWRITE, true)
    end
    return r
end

local function unprotect_maybe(address, size, unprot)
    if unprot then
        return unprotect(address, size)
    end
end

local function protect_maybe(address, size, prot)
    if prot then
        return set_protection(address, size, prot, true)
    end
end

function memory.read(address, size, unprot)
    if size > 0 then
        if size > 8 then
            size = 8
        end
        address = ffi.cast(pvoid_t, address)
        local value = ffi.new('int64_t[1]')
        local prot = unprotect_maybe(address, size, unprot)
        if not unprot or prot ~= nil then
            ffi.copy(value, address, size)
			if size <= 4 then
				return tonumber(value[0])
			end
            return value[0]
        end
    end
end

function memory.write(address, value, size, unprot)
    if size > 0 then
        if size > 8 then
            size = 8
        end
        address = ffi.cast(pvoid_t, address)
        local val = ffi.new('int64_t[1]', value)
        local prot = unprotect_maybe(address, size, unprot)
        if not unprot or prot ~= nil then
            ffi.copy(address, val, size)
        end
    end
end

function memory.unprotect(address, size)
    address = ffi.cast(pvoid_t, address)
    return unprotect(address, size)
end

function memory.protect(address, size, prot)
    address = ffi.cast(pvoid_t, address)
    return set_protection(address, size, prot, true)
end

function memory.copy(dst, src, size, unprot)
    dst = ffi.cast(pvoid_t, dst)
    if type(src) ~= 'string' then
        src = ffi.cast(pvoid_t, src)
    end
    local prot = unprotect_maybe(dst, size, unprot)
    if not unprot or prot ~= nil then
        ffi.copy(dst, src, size)
    end
end

function memory.fill(address, value, size, unprot)
    address = ffi.cast(pvoid_t, address)
    local prot = unprotect_maybe(address, size, unprot)
    if not unprot or prot ~= nil then
        ffi.fill(address, size, value)
    end
end

function memory.tostring(address, size, unprot)
    address = ffi.cast(pvoid_t, address)
    local prot = unprotect_maybe(address, size, unprot)
    if not unprot or prot ~= nil then
        local str = ffi.string(address, size)
        return str
    end
end

function memory.compare(m1, m2, size)
    m1 = ffi.cast(pvoid_t, m1)
    m2 = ffi.cast(pvoid_t, m2)
    return ffi.C.memcmp(m1, m2, size) == 0
end

function memory.strptr(str)
    return tonumber(ffi.cast('uintptr_t', ffi.cast('const char*', str)))
end

function memory.tohex(data, size, unprot)
    data = ffi.cast('const uint8_t*', data)
    local prot = unprotect_maybe(data, size, unprot)
    if not unprot or prot ~= nil then
        local str = {}
        for i = 0, size - 1 do
            str[#str + 1] = bit.tohex(data[i], 2)
        end
        return table.concat(str):upper()
    end
end

function memory.hex2bin(hex, dst, size)
    if #hex == 0 or #hex % 2 ~= 0 then
        return false
    end
    if dst then
        if not size or size == 0 then
            return false
        end
        dst = ffi.cast('uint8_t*', dst)
        local idx = 0
        for i = 1, #hex, 2 do
            local byte = tonumber(hex:sub(i, i + 1), 16)
            if not byte then
                return false
            end
            dst[idx] = byte
            idx = idx + 1
            if idx >= size then
                return true
            end
        end
        return true
    else
        local str = {}
        for i = 1, #hex, 2 do
            local byte = tonumber(hex:sub(i, i + 1), 16)
            if not byte then
                return nil
            end
            str[#str + 1] = string.char(byte)
        end
        return table.concat(str)
    end
end

local function get_value(ctype, address, unprot)
    address = ffi.cast(pvoid_t, address)
    local size = ffi.sizeof(ctype)
    local prot = unprotect_maybe(address, size, unprot)
    if not unprot or prot ~= nil then
        local val = ffi.cast(ctype..'*', address)[0]
        return val
    end
end

local function set_value(ctype, address, value, unprot)
    address = ffi.cast(pvoid_t, address)
    local size = ffi.sizeof(ctype)
    local prot = unprotect_maybe(address, size, unprot)
    if not unprot or prot ~= nil then
        ffi.cast(ctype..'*', address)[0] = value
    end
end

memory.getvalue = get_value
memory.setvalue = set_value
memory.getint8 = function(address, unprot) return get_value('int8_t', address, unprot) end
memory.getint16 = function(address, unprot) return get_value('int16_t', address, unprot) end
memory.getint32 = function(address, unprot) return get_value('int32_t', address, unprot) end
memory.getint64 = function(address, unprot) return get_value('int64_t', address, unprot) end
memory.getuint8 = function(address, unprot) return get_value('uint8_t', address, unprot) end
memory.getuint16 = function(address, unprot) return get_value('uint16_t', address, unprot) end
memory.getuint32 = function(address, unprot) return get_value('uint32_t', address, unprot) end
memory.getuint64 = function(address, unprot) return get_value('uint64_t', address, unprot) end
memory.getfloat = function(address, unprot) return get_value('float', address, unprot) end
memory.getdouble = function(address, unprot) return get_value('double', address, unprot) end
memory.setint8 = function(address, value, unprot) return set_value('int8_t', address, value, unprot) end
memory.setint16 = function(address, value, unprot) return set_value('int16_t', address, value, unprot) end
memory.setint32 = function(address, value, unprot) return set_value('int32_t', address, value, unprot) end
memory.setint64 = function(address, value, unprot) return set_value('int64_t', address, value, unprot) end
memory.setuint8 = function(address, value, unprot) return set_value('uint8_t', address, value, unprot) end
memory.setuint16 = function(address, value, unprot) return set_value('uint16_t', address, value, unprot) end
memory.setuint32 = function(address, value, unprot) return set_value('uint32_t', address, value, unprot) end
memory.setuint64 = function(address, value, unprot) return set_value('uint64_t', address, value, unprot) end
memory.setfloat = function(address, value, unprot) return set_value('float', address, value, unprot) end
memory.setdouble = function(address, value, unprot) return set_value('double', address, value, unprot) end
memory.pageaccess = page_access

return memory
