local socket = require("socket")
local cjson = require("cjson")
local copas = require("copas")
local http = require("copas.http")
local requests = require("requests")
local sampev = require("lib.samp.events")
local UDP = assert(socket.udp())

requests.http_socket, requests.https_socket = http, http

-- UDP:settimeout(0)
-- UDP:setpeername('!', 8101)


function httpRequest(method, request, args, handler) if not copas.running then copas.running = true lua_thread.create(function() wait(0) while not copas.finished() do local ok, err = copas.step(0) if ok == nil then error(err) end wait(0) end copas.running = false end) end if handler then return copas.addthread(function(m, r, a, h) copas.setErrorHandler(function(err) h(nil, err) end) h(requests.request(m, r, a)) end, method, request, args, handler) else local results local thread = copas.addthread(function(m, r, a) copas.setErrorHandler(function(err) results = {nil, err} end) results = table.pack(requests.request(m, r, a)) end, method, request, args) while coroutine.status(thread) ~= 'dead' do wait(0) end return table.unpack(results) end end
function watermarkInstall() font = renderCreateFont("Arial", 19, 4) local thread = lua_thread.create(function() while true do wait(0) if isGamePaused() then renderFontDrawText(font, "And telegram of launcher: t.me/CleoArizona ;)", 10, 130, 0xFFFFFFFF) end end end) thread.work_in_pause=true end
function msg(t, m) sampAddChatMessage("["..t.."] {ffffff}"..m, 0xD2691EFF) end


function main() 
  watermarkInstall()
  while not isSampAvailable() do wait(0) end
  -- sampRegisterChatCommand('msg', function(arg)
  --   if #arg <= 0 or #arg > 100 then return msg("Error", monet_utf8_to_cp1251("Сообщение ничего не содержит либо вы превысили лимит в 100 символов!")) end
  --   local success, settings = pcall(cjson.decode, io.open(getGameDirectory().."/SAMP/settings.json"):read("*a"))
  --   if not success then return msg("Error", monet_utf8_to_cp1251("Произошла ошибка взятия конфига игры. Сообщение не отправлено")) end
  --   local data = {
  --     command = "new_message",
  --     author = sampGetPlayerNickname(select(2, sampGetPlayerIdByCharHandle(PLAYER_PED))),
  --     message = monet_cp1251_to_utf8(arg),
  --     from_game = {status = true, p = settings.client.server.id, n = settings.client.server.serverid}
  --   }
  --   UDP:send(cjson.encode(data))
  -- end)
  -- wait(1000)
  -- UDP:send('{"command": "check"}')
  -- lua_thread.create(function()
  --   while true do
  --     wait(0)
  --       local data = UDP:receive()
  --       if data ~= nil then
  --         UDPRecieve(data)
  --       end
  --   end
  -- end)
end

function sampev.onInitGame(_, hostName)
  local success, settings = pcall(cjson.decode, io.open(getGameDirectory().."/SAMP/settings.json"):read("*a"))
  if success then serverName = ((settings.client.server.id == 0 and settings.client.server.serverid == 0) and hostName or "")
  else serverName = "Unknown Server" end
  local headers = {
    ["accept"] = "*/*",
    ["Upgrade-Insecure-Requests"] = "1"
  }
  httpRequest('POST', 'https://radarebot.hhos.net/api/setserver', {data={name=serverName}, headers=headers}, function(response, code, headers, status)
    print(response.text)
  end)
end


-- function UDPRecieve(data)
--   local success, data = pcall(cjson.decode, data)
--   if success and data.command then
--     if data.command == "new_message" then
--       if data.author and data.message and data.from_game and data.from_game.p and data.from_game.n then 
--         if data.from_game.status then
--             msg("CHAT", "[" .. data.from_game.p .. " " .. data.from_game.n .. "] " .. data.author .. ": " .. monet_utf8_to_cp1251(data.message))
--         else
--             msg("CHAT", "[t.me/cleodis] " .. data.author .. ": " .. monet_utf8_to_cp1251(data.message))
--         end
--       end
--     elseif data.command == "server_message" then
--         if data.message then
--           msg("ChatServerMessage", data.message)
--         end
--     elseif data.command == "status" then
--         if data.status then
--           if data.status == 'ok' then
--             msg("Connected", monet_utf8_to_cp1251("Вы успешно подключились к чату LUA Arizona Mobile (t.me/cleodis)"))
--           elseif data.status == 'block' then
--             msg("Error", monet_utf8_to_cp1251("Вы заблокированы в чате LUA Arizona Mobile (t.me/cleodis)"))
--           elseif data.status == 'plswait' then
--             msg("Wait", monet_utf8_to_cp1251("Сообщения можно отправлять раз в 5 секунд!"))
--           end
--         end
--     elseif data.command == "online_check" then
--       UDP:send('{"command": "answer_online_check"}')
--     end
--   end
-- end

