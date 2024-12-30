script_name('Arizona Music Fix')
script_version('1.3')
script_version_number(1)
script_author('Radare')
script_properties('work-in-pause', 'forced-reloading-only')

local debugging = false
local imgui = require("mimgui")
local inicfg = require("inicfg")
local lfs = require("lfs")
local md5 = require("md5")
local bs_io = require('lib.samp.events.bitstream_io')
local bsread, bswrite = bs_io.bs_read, bs_io.bs_write
local bass = require('bass')
local ffi = require('ffi')
bass.BASS_Free()
bass.BASS_Init(-1, 44100, BASS_DEVICE_3D, nil, nil)

local ASInfo = {}
local cacheDir = getWorkingDirectory().."/cachemusic/"

local ini = inicfg.load({
    music = {
        working = true,
        fromfile = true,
        savefile = false,
        global = 100.0,
        vehicle = 100.0,
        position = 100.0
    }
}, "ArizonaMusicFix.ini")
function save() inicfg.save(ini, "ArizonaMusicFix.ini") end 

local sizeX, sizeY = getScreenResolution()
local new, str, sizeof = imgui.new, ffi.string, ffi.sizeof
local renderWindow = new.bool()
local volworking, volfile, volsave, volglobal, volvehicle, volposition = new.bool(ini.music.working), new.bool(ini.music.fromfile), new.bool(ini.music.savefile), new.float(ini.music.global), new.float(ini.music.vehicle), new.float(ini.music.position)
local encoding = require 'encoding'
encoding.default = 'CP1251'
local u8 = encoding.UTF8

imgui.OnFrame(function() return renderWindow[0] end,
  function(player)
    imgui.SetNextWindowPos(imgui.ImVec2(sizeX / 2,  sizeY / 2), imgui.Cond.FirstUseEver, imgui.ImVec2(0.5, 0.5))
    imgui.SetNextWindowSize(imgui.ImVec2(sizeX / 2, 200), imgui.Cond.Always)
    imgui.Begin(thisScript().name .. " " .. thisScript().version, renderWindow, imgui.WindowFlags.NoResize)
    
    if imgui.Checkbox(u8'Работа музыки', volworking) then     
        ini.music.working = volworking[0]
        save()
        if not ini.music.working then
           for streamid, info in pairs(ASInfo) do
			    if info.handle and bass.BASS_ChannelIsActive(info.handle) ~= 0 then deleteAudio(info.handle) info.handle = nil end
			end
        else
           for streamid, info in pairs(ASInfo) do
			    if info.url and info.state and string.len(info.url) > 0 and string.find(info.url, "http") then
			         loadAudioStream(ASInfo[streamid].url, streamid)
			    end
			end
        end
    end
    imgui.SameLine()
    if imgui.Checkbox(u8'Загрузка через файлы', volfile) then     
        ini.music.fromfile = volfile[0]
        save()
    end 
    if ini.music.fromfile then
        imgui.SameLine()
	    if imgui.Checkbox(u8'Сохранять файлы', volsave) then     
	        ini.music.savefile = volsave[0]
	        save()
	    end
    end
    if imgui.SliderFloat(u8'Громкость звука', volglobal, 0.0, 100.0) then
        ini.music.global = volglobal[0]
        save()
   end
    if imgui.SliderFloat(u8'Громокость машин', volvehicle, 0.0, 100.0) then
        ini.music.vehicle = volvehicle[0]
        save()
   end
    if imgui.SliderFloat(u8'Громкость бумбоксов', volposition, 0.0, 100.0) then
        ini.music.position = volposition[0]
        save()
   end
   imgui.End()
end)

function getVolumeConfig(type)
    if type == 2 then return ini.music.global/100
    elseif type == 3 then return ini.music.vehicle/100
    elseif type == 4 then return ini.music.position/100
    else return 0 end
end 

function main()
    if not doesDirectoryExist(cacheDir) then createDirectory(cacheDir)
    else deleteFiles(cacheDir) end
    sampRegisterChatCommand("music", function() renderWindow[0] = not renderWindow[0] end)
    lua_thread.create(tickStreams)
    print("Arizona Music Fix on MonetLoader loaded by t.me/ryderinc")
    addEventHandler('onReceiveRpc', function(id, bs, ...)
        if id == 252 then
            packet = raknetBitStreamReadInt8(bs) 
            if packet == 10 then
               addStream(bs)
               return false
            end
            if packet == 17 then
                setStreamUrl(bs, nil)
                return false
            end
           if packet == 11 then
                 deleteStream(bs)
                 return false
            end
           if packet == 13 then
                 stopStream(bs)
                 return false
            end
        end
    end) 
    wait(-1)
end

function addStream(bs)
    streamid = raknetBitStreamReadInt16(bs)
    raknetBitStreamIgnoreBits(bs, 48)
    bstype = raknetBitStreamReadInt8(bs)
    if bstype == 4 then
        bstarget = {
            radius = raknetBitStreamReadFloat(bs),
            pos = bsread.compressedVector(bs)
        }
        raknetBitStreamIgnoreBits(bs, 112)
        debugMessage("onPositionStream: radius: "..bstarget.radius.." | position = "..bstarget.pos.x.." "..bstarget.pos.y.." "..bstarget.pos.z)
    else
        bstarget = raknetBitStreamReadInt16(bs)
    end
    status = raknetBitStreamReadInt16(bs) 
    debugMessage("addStream: type: "..bstype.." | target: "..(bstype ~= 4 and bstarget or "message up").." | status: "..status)
    ASInfo[streamid] = {
    	type = bstype,
        target = bstarget
    }
    if status > 0 then setStreamUrl(bs, streamid) end
end

function deleteStream(bs, streamid)
   if not streamid then streamid = raknetBitStreamReadInt16(bs) end 
   debugMessage("deleteStream: streamid: "..streamid)
   if ASInfo[streamid] then
	   if ASInfo[streamid].handle and bass.BASS_ChannelIsActive(ASInfo[streamid].handle) ~= 0 then  
	       deleteAudio(ASInfo[streamid].handle)
		   ASInfo[streamid].handle = nil
	   end
	   ASInfo[streamid].state = false
   end
end 

function stopStream(bs)
   streamid = raknetBitStreamReadInt16(bs)
   debugMessage("stopStream: streamid: "..streamid)
   if ASInfo[streamid] and ASInfo[streamid].handle then stopAudio(ASInfo[streamid].handle) end
   if ASInfo[streamid] then ASInfo[streamid].state = false end
end

function setStreamUrl(bs, streamid)
    if not streamid then streamid = raknetBitStreamReadInt16(bs) end 
    if ASInfo[streamid] then
	    state = raknetBitStreamReadBool(bs)
	    url = raknetBitStreamReadString(bs, raknetBitStreamReadInt16(bs))
	    raknetBitStreamIgnoreBits(bs, 1)
	    if raknetBitStreamReadInt32(bs) == 0 then
	        raknetBitStreamIgnoreBits(bs, 32)
	        ASInfo[streamid].time = raknetBitStreamReadInt32(bs)
	    else
	        ASInfo[streamid].time = 0
	    end
	    
	    ASInfo[streamid].url = url
	    ASInfo[streamid].state = state
	    if state and string.len(url) > 0 and string.find(url, "http") and ini.music.working then 
	          loadAudioStream(url, streamid)
	    end
	
	   debugMessage("setStreamUrl: streamid: "..streamid.." | playtime: "..ASInfo[streamid].time.." | url: "..url.." ("..string.len(url)..")")
   end
end

function attachStream(stream, stype, target)
    debugMessage("attachStream: stype: "..stype.." | target: "..(stype ~= 4 and target or "radius: "..target.radius.." | position = "..target.pos.x.." "..target.pos.y.." "..target.pos.z))
    lua_thread.create(function()
        while true do
            wait(0)
            if bass.BASS_ChannelIsActive(stream) ~= 0 then
                local result, handle
                if stype == 4 then
                    if type(target) == "table" and target.radius ~= nil and target.pos.x ~= nil and target.pos.y ~= nil and target.pos.z ~= nil then result = true
                    else result = false end
                elseif stype == 3 then
                    result, handle = sampGetCarHandleBySampVehicleId(target)
                elseif stype == 2 then
                    result, handle = sampGetCharHandleBySampPlayerId(target)
                end
                if not result and stype == 2 and target == select(2, sampGetPlayerIdByCharHandle(PLAYER_PED)) then result, handle = true, PLAYER_PED end
                if result then
                    px, py, pz = getCharCoordinates(PLAYER_PED)
                    if stype == 4 then
                        bx, by, bz = target.pos.x, target.pos.y, target.pos.z
                    elseif stype == 3 then 
                        if doesVehicleExist(handle) then 
                            bx, by, bz = getCarCoordinates(handle)
                        else setVolume(stream, 0.0) end
                    elseif stype == 2 then
                        if doesCharExist(handle) then 
                            bx, by, bz = getCharCoordinates(handle)
                        else setVolume(stream, 0.0) end
                    else
                        print("No type for this stream")
                        deleteStream(0x0, stream)
                        return
                    end
                    if getDistanceBetweenCoords3d(px, py, pz, bx, by, bz) < (stype == 4 and target.radius ~= nil and target.radius or 30.0) then
                        setVolume(stream, getVolumeConfig(stype))
                    else setVolume(stream, 0.0) end
                    bass.BASS_ChannelSet3DPosition(stream, _3d_pos({x=px,y=py,z=pz},{x=bx,y=by,z=bz}), nil, nil);
                    bassError("BASS_ChannelSet3DPosition")
                    bass.BASS_Apply3D()
                else setVolume(stream, 0.0) end
            else return end
        end
    end)
end

function _3d_pos(check_pos, sound_pos)
    local pos = ffi.new("BASS_3DVECTOR")
    pos.x = sound_pos.x - check_pos.x
    pos.y = sound_pos.y - check_pos.y
    pos.z = sound_pos.z - check_pos.z
    return pos
end

function tickStreams()
    while true do
	    wait(1000)
	    for streamid, info in pairs(ASInfo) do
		    if info.time then info.time = info.time + 1 end
		end
    end
end

function loadAudio(url)
    debugMessage("loadAudio: url: "..url)
    local handle = bass.BASS_StreamCreateURL(url, 0, bit.bor(BASS_SAMPLE_MONO, BASS_SAMPLE_3D), nil, nil)
    bassError("BASS_StreamCreateURL")
    return handle
end


function loadAudioStream(url, streamid)
    if not ini.music.fromfile then
	     ASInfo[streamid].handle = loadAudio(url)  
         playAudio(ASInfo[streamid].handle)
         attachStream(ASInfo[streamid].handle, ASInfo[streamid].type, ASInfo[streamid].target)
         if ASInfo[streamid].time > 0 then setAudioTime(ASInfo[streamid].handle, ASInfo[streamid].time) end
    else
	    local path = cacheDir..md5.sumhexa(url)..".mp3"
	    debugMessage("loadAudioStream: url: "..url)
	    if not doesFileExist(path) then 
		    downloadToFile(url, path, function(type, pos, total_size)
		        if ASInfo[streamid].url ~= url or not ASInfo[streamid].state then return os.remove(path) end
			    if type == "finished" then
			        if ASInfo[streamid] and ASInfo[streamid].handle and bass.BASS_ChannelIsActive(ASInfo[streamid].handle) ~= 0 then deleteAudio(ASInfo[streamid].handle) end
			        ASInfo[streamid].handle = bass.BASS_StreamCreateFile(false, path, 0, 0, bit.bor(BASS_SAMPLE_MONO, BASS_SAMPLE_3D))
		 	       bassError("BASS_StreamCreateFile")
			        playAudio(ASInfo[streamid].handle)
			        attachStream(ASInfo[streamid].handle, ASInfo[streamid].type, ASInfo[streamid].target)
		            if ASInfo[streamid].time > 0 then setAudioTime(ASInfo[streamid].handle, ASInfo[streamid].time) end
		            if not ini.music.savefile then os.remove(path) end
			    elseif type == "error" then
			        print("Ошибка скачивания: " .. pos)
			    end
		   end) 
		else
		    if ASInfo[streamid] and ASInfo[streamid].handle and bass.BASS_ChannelIsActive(ASInfo[streamid].handle) ~= 0 then deleteAudio(ASInfo[streamid].handle) end
	        ASInfo[streamid].handle = bass.BASS_StreamCreateFile(false, path, 0, 0, bit.bor(BASS_SAMPLE_MONO, BASS_SAMPLE_3D))
	 	   bassError("BASS_StreamCreateFile")
	        playAudio(ASInfo[streamid].handle)
	        attachStream(ASInfo[streamid].handle, ASInfo[streamid].type, ASInfo[streamid].target)
	        if ASInfo[streamid].time > 0 then setAudioTime(ASInfo[streamid].handle, ASInfo[streamid].time) end
		end
	end
end

function setAudioTime(handle, second)
    if handle == nil then return false end
    if second < 0 then
        print("Invalid time value")
        return
    end
    lua_thread.create(function() 
        local bass_error = 7 
        local target_seconds = second
        while bass_error == 7 do 
            wait(0) 
            local byte_position = bass.BASS_ChannelSeconds2Bytes(handle, second)
            local result = bass.BASS_ChannelSetPosition(handle, byte_position, BASS_POS_BYTE)
            bass_error = bass.BASS_ErrorGetCode()
            target_seconds = target_seconds + 0.01
        end 
        bassError("BASS_ChannelSetPosition")
    end)
    return result
end

function playAudio(handle)
    if handle == nil or not ini.music.working then return false end
    local result = bass.BASS_ChannelPlay(handle, false)
    bassError("BASS_ChannelPlay")
    return result
end

function stopAudio(handle)
    if handle == nil then return false end
    local result = bass.BASS_ChannelStop(handle)
    bassError("BASS_ChannelStop")
    return result
end

function deleteAudio(handle)
    if handle == nil then return false end
    stopAudio(handle)
    local result = bass.BASS_StreamFree(handle)
    bassError("BASS_StreamFree")
    return result
end

function setVolume(handle, volume)
    if handle == nil then return false end
    local result = bass.BASS_ChannelSetAttribute(handle, BASS_ATTRIB_VOL, volume)
    bassError("BASS_ChannelSetAttribute(BASS_ATTRIB_VOL)")
    return result
end

function bassError(TAG) if bass.BASS_ErrorGetCode() ~= 0 then print("["..TAG.."] BASS_ERROR:", bass.BASS_ErrorGetCode()) end end
function debugMessage(msg) if debugging then sampAddChatMessage("{ffffff}[ARZMusicFix_Debugging] {ffffff}"..msg, -1) end end
function downloadToFile(a,b,c,d)c=c or function()end;d=d or 0.1;local e=require("effil")local f=e.channel(0)local g=e.thread(function(a,b)local h=require("socket.http")local i=require("ltn12")local j,k,l=h.request({method="HEAD",url=a})if k~=200 then return false,k end;local m=l["content-length"]local n=io.open(b,"w+b")if not n then return false,"failed to open file"end;local o,p,q=pcall(h.request,{method="GET",url=a,sink=function(r,s)local t=os.clock()if r and not lastProgress or t-lastProgress>=d then f:push("downloading",n:seek("end"),m)lastProgress=os.clock()elseif s then f:push("error",s)end;return i.sink.file(n)(r,s)end})if not o then return false,p end;if not p then return false,q end;return true,m end)local u=g(a,b)local function v()local w=u:status()if w=="failed"or w=="completed"then local x,y=u:get()if x then c("finished",y)else c("error",y)end;return true end end;lua_thread.create(function()if v()then return end;while u:status()=="running"do if f:size()>0 then local z,A,m=f:pop()c(z,A,m)end;wait(0)end;v()end)end
function deleteFiles(path) for file in lfs.dir(path) do if file ~= "." and file ~= ".." then local full_path = path .. '/' .. file local mode = lfs.attributes(full_path, "mode") if mode == "directory" then remove_directory(full_path) else os.remove(full_path) end end end end
