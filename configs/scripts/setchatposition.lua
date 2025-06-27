local env = require("android.jnienv")
local envu = require("android.jnienv-util")
local ffi = require("ffi")
local imgui = require("mimgui")
local inicfg = require("inicfg")
local settings = inicfg.load({
    pos = {
        x = 400.0,
        y = 0.0
    }
}, "chatpos.ini")
function saveCfg() inicfg.save(settings, 'chatpos.ini') end

local new, str, sizeof = imgui.new, ffi.string, ffi.sizeof
local settingsWindow = new.bool(false)


local min_x, min_y, max_x, max_y = -500, -300, getScreenResolution() 

local chat_x, chat_y = new.float(settings.pos.x), new.float(settings.pos.y)

function main()
    setChatPosition(settings.pos.x, settings.pos.y)
    sampRegisterChatCommand("cpos", function() settingsWindow[0] = not settingsWindow[0] end)
	wait(-1)
end


local isEditMode = false
function onTouch(type, id, x, y)
    if type == 2 and isEditMode then
        rpx, rpy = x, y
    end
    if isEditMode then
        local x, y = chat_x[0] - (rpx-x), chat_y[0] - (rpy-y)
        if x < min_x then x = min_x
        elseif x > max_x then x = max_x end
        if y < min_y then y = min_y
        elseif y > max_y then y = max_y end

        if type == 1 then
            chat_x[0] = x
            chat_y[0] = y
            setChatPosition(chat_x[0], chat_y[0])
            settings.pos.x = chat_x[0]
            settings.pos.y = chat_y[0]
            saveCfg()
        elseif type == 3 then
            setChatPosition(x, y)
        end
    end
    return not isEditMode
end



imgui.OnFrame(function() return settingsWindow[0] end,
    function(player)
        local x, y = getScreenResolution()
        imgui.SetNextWindowPos(imgui.ImVec2(x / 2, y / 2), imgui.Cond.FirstUseEver, imgui.ImVec2(0.5, 0.5))
        imgui.SetNextWindowSize(imgui.ImVec2(750, 500), imgui.Cond.FirstUseEver)
        imgui.Begin("ChatSettings", settingsWindow)
        if imgui.SliderFloat("pos X", chat_x, min_x, max_x) then
            setChatPosition(chat_x[0], chat_y[0])
            settings.pos.x = chat_x[0]
            saveCfg()
        end
        
        if imgui.SliderFloat("pos Y", chat_y, min_y, max_y) then
            setChatPosition(chat_x[0], chat_y[0])
            settings.pos.y = chat_y[0]
            saveCfg()
        end

        if imgui.Button(isEditMode and "disable edit position with touch" or "enable edit position with touch") then
            isEditMode = not isEditMode
        end
        imgui.End()
    end
)


function setChatPosition(x, y)
    local contextClass = envu.FindClass("com/arzmod/radare/InitGamePatch")
    if not contextClass then
        print("Failed to find InitGamePatch class")
        return
    end

    envu.CallStaticVoidMethod(contextClass, "setChatPosition", "(FF)V", ffi.cast('jfloat', x), ffi.cast('jfloat', y))
    env.DeleteLocalRef(jstr)
end