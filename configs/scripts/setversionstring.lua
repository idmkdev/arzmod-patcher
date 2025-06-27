local env = require("android.jnienv")
local envu = require("android.jnienv-util")

function main()
    setVersionString("custom string {version} {commit}")
	-- animateString("my string ", 1, 100)
	wait(-1)
end

function animateString(str, type, delay)
    delay = delay or 50
    local result = str
    local len = #str
    
    if type == 1 then
        while true do
            for i = 1, len do
                result = str:sub(i) .. str:sub(1, i-1)
                setVersionString(result)
                wait(delay)
            end
        end
    elseif type == 2 then
        while true do
            for i = len, 0, -1 do
                result = str:sub(1, i) .. string.rep(" ", len - i)
                setVersionString(result)
                wait(delay)
            end
            for i = 1, len do
                result = str:sub(1, i) .. string.rep(" ", len - i)
                setVersionString(result)
                wait(delay)
            end
        end
    elseif type == 3 then
	    local chars = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
	    local result = ""
	    while true do
	        for i = 1, len do
	        	local randChar = math.random(1, #chars)
	            result = result:sub(1, i-1) .. chars:sub(randChar, randChar).. result:sub(i+1)
	        	setVersionString(result)
	            wait(delay)
	        end

	        for i = 1, len do
	            result = result:sub(1, i-1) .. str:sub(i, i) .. result:sub(i+1)
	            setVersionString(result)
	            wait(delay)
	        end
	    end
	end
end

function setVersionString(verstr)
	if #verstr > 155 then return false end
    local contextClass = envu.FindClass("com/arzmod/radare/InitGamePatch")
    if not contextClass then
        print("Failed to find InitGamePatch class")
        return
    end

    local jstr = env.NewStringUTF(verstr)
    if not jstr then
        print("Failed to create jstring")
        return
    end

    envu.CallStaticVoidMethod(contextClass, "setVersionString", "(Ljava/lang/String;)V", jstr)
    env.DeleteLocalRef(jstr)
end