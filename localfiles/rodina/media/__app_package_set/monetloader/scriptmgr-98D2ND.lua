-- MonetLoader for Android 3.0.0
-- Reference script: Script Manager
--
-- For script developers:
-- If you want to allow your script to be toggled from Script Manager, you must implement the following API in EXPORTS:
-- 1. For "Enabled" checkbox:
--    a. canToggle: return true
--    b. getToggle: return <your toggled status variable>
--    c. toggle: execute any code, and switch <your toggled status variable> (switching is optional)
-- 2. For "Activate button":
--    a. canToggle: return false
--    b. getToggle: return false
--    c. toggle: execute any code
--
-- Simple example that implements "Enabled" checkbox:
-- local toggled = false
-- EXPORTS = {
--   canToggle = function() return true end,
--   getToggle = function() return toggled end,
--   toggle = function() toggled = not toggled end
-- }
--

-- script info
script_name('Script Manager')
script_version('2.1 ARZMOD')
script_version_number(2)
script_author('The MonetLoader Team', 'ARZMOD')
script_description('Script manager that opens on left swipe on radar and provides ability to manage scripts, view logs, execute Lua code in REPL-like mode and receive script notifications.')
script_properties('work-in-pause', 'forced-reloading-only') -- work even in pause and don't reload ourselves on reloadScripts()


-- libs
local levels = require('moonloader').message_prefix
local ffi = require('ffi')
local widgets = require('widgets') -- for WIDGET_(...)
local imgui = require('mimgui')
local faicons = require('fAwesome6')
local cfg = require('jsoncfg')
local cjson = require("cjson")
local memory = require("memory")
local copas = require ('copas') -- for download scripts from url
local http = require ('copas.http') -- for download scripts from url
local gta = ffi.load('GTASA') -- for hook to open link
local lfs = require('lfs') -- LuaFileSystem for directory operations
local isAndroidEnvLoaded, env = pcall(require, "android.jnienv")
local isAndroidEnvuLoaded, envu = pcall(require, "android.jnienv-util")
local isWebViewsLoaded, isWebViewsLoadTry, wv = false, false, nil


ffi.cdef[[
    void _Z12AND_OpenLinkPKc(const char* link);
]]


-- pretty printing (https://stackoverflow.com/questions/9168058/how-to-dump-a-table-to-console)

function prettyPrintTable(node)
  local cache, stack, output = {},{},{}
  local depth = 1
  local output_str = "{"

  while true do
    local size = 0
    for k,v in pairs(node) do
      size = size + 1
    end

    local cur_index = 1
    for k,v in pairs(node) do
      if (cache[node] == nil) or (cur_index >= cache[node]) then

        if (string.find(output_str,"}",output_str:len())) then
          output_str = output_str .. ","
        end

        -- This is necessary for working with HUGE tables otherwise we run out of memory using concat on huge strings
        table.insert(output,output_str)
        output_str = ""

        local key
        if (type(k) == "string") then
          key = "['"..tostring(k).."']"
        else
          key = "["..tostring(k).."]"
        end

        if (type(v) ~= "table" and type(v) ~= "string") then
          output_str = output_str .. key .. " = "..tostring(v)
        elseif (type(v) == "table") then
          output_str = output_str .. key .. " = {"
          table.insert(stack,node)
          table.insert(stack,v)
          cache[node] = cur_index+1
          break
        else
          output_str = output_str .. key .. " = '"..tostring(v).."'"
        end

        if (cur_index == size) then
          output_str = output_str .. "}"
        else
          output_str = output_str .. ","
        end
      else
        -- close the table
        if (cur_index == size) then
          output_str = output_str .. "}"
        end
      end

      cur_index = cur_index + 1
    end

    if (size == 0) then
      output_str = output_str .. "}"
    end

    if (#stack > 0) then
      node = stack[#stack]
      stack[#stack] = nil
      depth = cache[node] == nil and depth + 1 or depth - 1
    else
      break
    end
  end

  -- This is necessary for working with HUGE tables otherwise we run out of memory using concat on huge strings
  table.insert(output,output_str)
  output_str = table.concat(output)
  
  return output_str
end

-- pretty prints arguments, expanding tables (also supports multiple nils without omitting them)
function prettyPrint(...)
  -- we use select instead of table unpacking in order to handle nil values correctly
  local argc = select('#', ...)
  if argc == 0 then
    return 'nil'
  end

  local output_str = ''
  for i=1, argc do
    local v = select(i, ...)
    if type(v) == 'table' then
        output_str = output_str .. prettyPrintTable(v)
    elseif type(v) == 'string' then
        output_str = output_str .. "'" .. v .. "'"
    else
        output_str = output_str .. tostring(v)
    end
    if i ~= argc then
      output_str = output_str .. ',' 
    end
  end

  return output_str
end


-- simple ipairs implementation that supports any type

function stateless_iter(a, i)
  i = i + 1
  local v = a[i]
  if v then
    return i, v
  end
end

function any_ipairs(a)
  return stateless_iter, a, 0
end


-- circular buffer class (https://gist.github.com/johndgiese/3e1c6d6e0535d4536692)

local function rotate_indice(i, n)
  return ((i - 1) % n) + 1
end

local circular_buffer = {}

function circular_buffer.reverse_iter(a, i)
  i = i - 1
  local v = a[i]
  if v then
    return i, v
  end
end

function circular_buffer.reverse_ipairs(self)
  return circular_buffer.reverse_iter, self, 0
end

function circular_buffer.filled(self)
  return #(self.history) == self.max_length
end

function circular_buffer.push(self, value)
  if self:filled() then
    local value_to_be_removed = self.history[self.oldest]
    self.history[self.oldest] = value
    self.oldest = self.oldest == self.max_length and 1 or self.oldest + 1
  else
    self.history[#(self.history) + 1] = value
  end
end

function circular_buffer.clear(self)
  self.history = {}
  self.oldest = 1
end

circular_buffer.metatable = {}

-- positive values index from newest to oldest (starting with 1)
-- negative values index from oldest to newest (starting with -1)
function circular_buffer.metatable.__index(self, i)
  local history_length = #(self.history)
  if i == 0 or math.abs(i) > history_length then
    return nil
  elseif i > 0 then
    local i_rotated = rotate_indice(self.oldest - 1 + i, history_length)
    return self.history[i_rotated]
  else
    local i_rotated = rotate_indice(self.oldest + i, history_length)
    return self.history[i_rotated]
  end
end

function circular_buffer.metatable.__len(self)
  return #(self.history)
end

function circular_buffer.new(max_length)
  if type(max_length) ~= 'number' or max_length <= 1 then
    error("Buffer length must be a positive integer")
  end

  local instance = {
    history = {},
    oldest = 1,
    max_length = max_length,
    push = circular_buffer.push,
    filled = circular_buffer.filled,
    clear = circular_buffer.clear
  }
  setmetatable(instance, circular_buffer.metatable)
  return instance
end


-- notifications (https://www.blast.hk/threads/132205/)

Notifications = {
  _version = '0.2',
  _list = {},
  _COLORS = {
    [0] = {back = {0.26, 0.71, 0.81, 1},    text = {1, 1, 1, 1}, icon = {1, 1, 1, 1}, border = {1, 0, 0, 0}},
    [1] = {back = {0.26, 0.81, 0.31, 1},    text = {1, 1, 1, 1}, icon = {1, 1, 1, 1}, border = {1, 0, 0, 0}},
    [2] = {back = {1, 0.39, 0.39, 1},       text = {1, 1, 1, 1}, icon = {1, 1, 1, 1}, border = {1, 0, 0, 0}},
    [3] = {back = {0.97, 0.57, 0.28, 1},    text = {1, 1, 1, 1}, icon = {1, 1, 1, 1}, border = {1, 0, 0, 0}},
    [4] = {back = {0, 0, 0, 1},             text = {1, 1, 1, 1}, icon = {1, 1, 1, 1}, border = {1, 0, 0, 0}},
  },

  TYPE = {
      INFO = 0,
      OK = 1,
      ERROR = 2,
      WARN = 3,
      DEBUG = 4
  },
  ICON = {
      [0] = faicons('CIRCLE_INFO'),
      [1] = faicons('CHECK'),
      [2] = faicons('XMARK'),
      [3] = faicons('EXCLAMATION'),
      [4] = faicons('WRENCH')
  }
}

Notifications.Show = function(text, type, time, colors)
  table.insert(Notifications._list, {
    text = text,
    type = type or 2,
    time = time or 4,
    start = os.clock(),
    alpha = 0,
    colors = colors or Notifications._COLORS[type]
  })
end

Notifications._TableToImVec = function(tbl)
  return imgui.ImVec4(tbl[1], tbl[2], tbl[3], tbl[4])
end

Notifications._BringFloatTo = function(from, to, start_time, duration)
  local timer = os.clock() - start_time
  if timer >= 0.00 and timer <= duration then
      local count = timer / (duration / 100)
      return from + (count * (to - from) / 100), true
  end
  return (timer > duration) and to or from, false
end

imgui.OnFrame(
  function() return #Notifications._list > 0 end,
  function(self)
    self.HideCursor = true

    for k, data in ipairs(Notifications._list) do
      --==[ UPDATE ALPHA ]==--
      if data.alpha == nil then Notifications._list[k].alpha = 0 end
      if os.clock() - data.start < 0.5 then
        Notifications._list[k].alpha = Notifications._BringFloatTo(0, 1, data.start, 0.5)
      elseif data.time - 0.5 < os.clock() - data.start then
        Notifications._list[k].alpha = Notifications._BringFloatTo(1, 0, data.start + data.time - 0.5, 0.5)
      end

      --==[ REMOVE ]==--
      if os.clock() - data.start > data.time then
        table.remove(Notifications._list, k)
      end
    end

    local resX, resY = getScreenResolution()
    local sizeX, sizeY = 300 * MONET_DPI_SCALE, 300 * MONET_DPI_SCALE
    imgui.SetNextWindowPos(imgui.ImVec2(resX * 0.5, resY * 0.5), imgui.Cond.FirstUseEver, imgui.ImVec2(0.5, 0.5))
    imgui.SetNextWindowSize(imgui.ImVec2(sizeX, sizeY), imgui.Cond.FirstUseEver)
    imgui.Begin('notf_window', _, 0
        + imgui.WindowFlags.AlwaysAutoResize
        + imgui.WindowFlags.NoTitleBar
        + imgui.WindowFlags.NoResize
        + imgui.WindowFlags.NoMove
        + imgui.WindowFlags.NoBackground
    )
    
    local fiveSc = 5 * MONET_DPI_SCALE
    local winSize = imgui.GetWindowSize()
    imgui.SetWindowPosVec2(imgui.ImVec2(resX - 10 * MONET_DPI_SCALE - winSize.x, resY * 0.4))
    
    for k, data in ipairs(Notifications._list) do
      ------------------------------------------------
      local default_data = {
        text = 'text',
        type = 0,
        time = 1500
      }
      for k, v in pairs(default_data) do
        if data[k] == nil then
          data[k] = v
        end
      end
  
  
      local c = imgui.GetCursorPos()
      local p = imgui.GetCursorScreenPos()
      local DL = imgui.GetWindowDrawList()
  
      local textSize = imgui.CalcTextSize(data.text)
      local iconSize = imgui.CalcTextSize(Notifications.ICON[data.type] or faicons('XMARK'))
      local size = imgui.ImVec2(fiveSc + iconSize.x + fiveSc + textSize.x + fiveSc, fiveSc + textSize.y + fiveSc)
  
  
      local winSize = imgui.GetWindowSize()
      if winSize.x > size.x + 20 * MONET_DPI_SCALE then
          imgui.SetCursorPosX(winSize.x - size.x - 8 * MONET_DPI_SCALE)
      end
  
      
      imgui.PushStyleVarFloat(imgui.StyleVar.Alpha, data.alpha)
      imgui.PushStyleVarFloat(imgui.StyleVar.ChildRounding, fiveSc)
      imgui.PushStyleColor(imgui.Col.ChildBg,     Notifications._TableToImVec(data.colors.back or Notifications._COLORS[data.type].back))
      imgui.PushStyleColor(imgui.Col.Border,      Notifications._TableToImVec(data.colors.border or Notifications._COLORS[data.type].border))
      imgui.BeginChild('toastNotf:'..tostring(k)..tostring(data.text), size, true, imgui.WindowFlags.NoScrollbar + imgui.WindowFlags.NoScrollWithMouse)
        imgui.PushStyleColor(imgui.Col.Text,    Notifications._TableToImVec(data.colors.icon or Notifications._COLORS[data.type].icon))
        imgui.SetCursorPos(imgui.ImVec2(fiveSc, size.y / 2 - iconSize.y / 2))
        imgui.Text(Notifications.ICON[data.type] or faicons('XMARK'))
        imgui.PopStyleColor()

        imgui.PushStyleColor(imgui.Col.Text,    Notifications._TableToImVec(data.colors.text or Notifications._COLORS[data.type].text))
        imgui.SetCursorPos(imgui.ImVec2(fiveSc + iconSize.x + fiveSc, size.y / 2 - textSize.y / 2))
        imgui.Text(data.text)
        imgui.PopStyleColor()
      imgui.EndChild()
      imgui.PopStyleColor(2)
      imgui.PopStyleVar(2)
      ------------------------------------------------
    end
    
    imgui.End()
  end
)

local locales = {
    current = "ru",
    data = {
        en = {
            yes = "Yes",
            no = "No",
            wv_serverfind = "Trying to find an available server...",
            wv_progress = "[%d] Loading...",
            wv_librequired = "The WebViews library is not loaded.\nMake sure you have the lib.android and lib.webviews libraries installed.",
            scripts = "Scripts",
            reload_all = "Reload all",
            confirm_reload_all = "Confirm reload all",
            sure_reload_all = "Are you sure you want to reload all scripts?",
            reloaded_all = "Reloaded all scripts!",
            scr_name = "Name: %s",
            scr_filename = "File name: %s",
            scr_path = "Path: %s",
            scr_ver_sg = "Version: %s (%g)",
            scr_ver_g = "Version: %g",
            scr_ver_s = "Version: %s",
            scr_authors = "Authors: %s",
            scr_desc = "Description: %s",
            unload = "Unload",
            unloaded = "Unloaded",
            reload = "Reload",
            reloaded = "Reloaded",
            disable = "Disable",
            enable = "Enable",
            delete = "Delete",
            delete_script = "Delete script",
            confirm_delete_script = "Are you sure you want to delete the script: %s?",
            unloaded_and_deleted = "Unloaded and Deleted",
            status_disabled = "Status: Disabled",
            delete_disabled_script = "Delete disabled script",
            confirm_delete_disabled_script = "Are you sure you want to permanently delete the disabled script: %s?",
            deleted_permanently = "Deleted permanently",
            select_any_script = "<<<\nSelect any script on the left!",
            log = "Log",
            find = "Find",
            clear_history = "Clear history",
            last_crashes = "Last crashes",
            script_name = "Script name",
            time_since_crash = "Time since crash",
            actions = "Actions",
            reload_failed = "Reload failed",
            hide = "Hide",
            shell = "Shell",
            run = "Run",
            up = "Up",
            down = "Down",
            clear = "Clear",
            settings = "Settings",
            crash_notifications = "Crash notifications",
            script_message_notifications = "Script message notifications",
            log_messages_count = "Log messages count",
            last_crashes_count = "Last crashes count",
            shell_history_count = "Shell history count",
            mods_store = "Mods Store",
            confirm_download = "Are you sure you want to download %s?",
            confirm_reload_all_zip = "Are you want to reload all scripts?\n(the installed mod was in .zip and was not automatically loaded)",
            confirm_delete = "Are you sure you want to delete %s?",
            crashed = "Crashed",
            confirm_suggestion = "You don't have any scripts installed. Would you like to browse the script store?",
            skip_suggestion = "No, and don't offer it again.",
            script_disabled = "Script disabled: %s",
            failed_to_disable = "Failed to disable script: %s",
            script_enabled = "Script enabled: %s",
            failed_to_enable = "Failed to enable script: %s",
            script_unloaded = "Script unloaded: %s",
            script_not_found = "Script not found: %s"
        },
        ru = {
          yes = "Да",
            no = "Нет",
            wv_serverfind = "Поиск доступного сервера...",
            wv_progress = "[%d] Загрузка...",
            wv_librequired = "Библиотека WebViews не загружена.\nУбедитесь, что у вас установлены библиотеки lib.android и lib.webviews.",
            scripts = "Скрипты",
            reload_all = "Перезагрузить все",
            confirm_reload_all = "Подтверждение перезагрузки всех",
            sure_reload_all = "Вы уверены, что хотите перезагрузить все скрипты?",
            reloaded_all = "Все скрипты перезагружены!",
            scr_name = "Имя: %s",
            scr_filename = "Имя файла: %s",
            scr_path = "Путь: %s",
            scr_ver_sg = "Версия: %s (%g)",
            scr_ver_g = "Версия: %g",
            scr_ver_s = "Версия: %s",
            scr_authors = "Авторы: %s",
            scr_desc = "Описание: %s",
            unload = "Выгрузить",
            unloaded = "Выгружен",
            reload = "Перезагрузить",
            reloaded = "Перезагружен",
            disable = "Отключить",
            enable = "Включить",
            delete = "Удалить",
            delete_script = "Удалить скрипт",
            confirm_delete_script = "Вы уверены, что хотите удалить скрипт: %s?",
            unloaded_and_deleted = "Выгружен и удалён",
            status_disabled = "Статус: Отключён",
            delete_disabled_script = "Удалить отключённый скрипт",
            confirm_delete_disabled_script = "Вы уверены, что хотите безвозвратно удалить отключённый скрипт: %s?",
            deleted_permanently = "Удалён безвозвратно",
            select_any_script = "<<<\nВыберите любой скрипт слева!",
            log = "Лог",
            find = "Найти",
            clear_history = "Очистить историю",
            last_crashes = "Последние сбои",
            script_name = "Имя скрипта",
            time_since_crash = "Время с момента сбоя",
            actions = "Действия",
            reload_failed = "Не удалось перезагрузить",
            hide = "Скрыть",
            shell = "Консоль",
            run = "Выполнить",
            up = "Вверх",
            down = "Вниз",
            clear = "Очистить",
            settings = "Настройки",
            crash_notifications = "Уведомления о сбоях",
            script_message_notifications = "Уведомления о сообщениях скриптов",
            log_messages_count = "Количество сообщений в логе",
            last_crashes_count = "Количество последних сбоев",
            shell_history_count = "Количество записей истории шелла",
            mods_store = "Магазин модов",
            confirm_download = "Вы уверены, что хотите скачать %s?",
            confirm_reload_all_zip = "Хотите перезагрузить все скрипты?\n(установленный мод был в .zip и не был загружен автоматически)",
            confirm_delete = "Вы уверены, что хотите удалить %s?",
            crashed = "Произошёл сбой",
            confirm_suggestion = "У вас не установлено ни одного скрипта. Хотите перейти в магазин скриптов?",
            skip_suggestion = "Нет, и больше не предлагать.",
            script_disabled = "Скрипт выключен: %s",
            failed_to_disable = "Не удалось выключить скрипт: %s",
            script_enabled = "Скрипт включён: %s",
            failed_to_enable = "Не удалось включить скрипт: %s",
            script_unloaded = "Скрипт выгружен: %s",
            script_not_found = "Скрипт не найден: %s"
        }
    }
}


function locales.get(key, ...)
    local lang_data = locales.data[locales.current]
    local text = lang_data[key]
    
    if not text then
        text = locales.data.en[key] or key
    end
   
    if select("#", ...) > 0 then
        return string.format(text, ...)
    end
    return text
end

function locales.set_lang(lang)
    if locales.data[lang] then
        locales.current = lang
        return true
    end
    return false
end

function locales.get_languages()
    local langs = {}
    for lang, _ in pairs(locales.data) do
        table.insert(langs, lang)
    end
    return langs
end


-- global vars

local wvWindow = {
  windowUrls = {"https://app.arzmod.com", "https://mods.radarebot.hhos.net"},
  serverfind = false,
  created = false,
  visible = false,
  force = false,
  progress = 0,
  position = {x = 0, y = 0, w = 0, h = 0},
  confirmDialog = {
    text = nil,
    buttons = {locales.get("yes"), locales.get("no")},
    response = -1
  }
}

local DEFAULT_CONFIG = { -- default config
  crashNotifications = true, -- whether to show script crash notifications or not
  scriptMessageNotifications = false, -- whether to show script message notifications or not
  messagesCount = 100, -- count of saved messages
  lastCrashesCount = 10, -- count of saved crashed scripts
  shellHistoryCount = 50, -- count of saved shell history
  currentLang = "ru",
  skipSuggestion = false
}

local config = cfg.load(DEFAULT_CONFIG) -- simply config
local messages = circular_buffer.new(config.messagesCount) -- buffer that stores last messages
local lastCrashes = circular_buffer.new(config.lastCrashesCount) -- buffer that stores script info about last crashes
local shellHistory = circular_buffer.new(config.shellHistoryCount) -- buffer that stores shell history
local shellInputHistory = circular_buffer.new(math.ceil(config.shellHistoryCount / 2)) -- buffer that stores shell input history
local shellInputHistoryPos = 0 -- current position in shellInputHistory
local scriptCrashInfos = {} -- buffer that stores reasons for script crash
local reloadLastCrashInfos = {} -- buffer that stores crash info that initiated reload for a given path
local disabledScripts = nil -- buffer that stores disabled scripts

local selectedScriptId = -1 -- id of selected script
local selectedScriptExports -- table returned by import on selected script
local wasInLog = false -- set to true when tab is log, used to auto-scroll to bottom on tab switch
local wasInShell = false -- same, but with shell
local wasInScriptStore = false
local windowState = imgui.new.bool(false) -- script mgr window is active or not
-- some imgui wrappers
local imScriptStatus = imgui.new.bool(false) -- ffi variable for script toggling
local imCrashNotifications = imgui.new.bool(config.crashNotifications)
local imScriptMessageNotifications = imgui.new.bool(config.scriptMessageNotifications)
local imMessagesCount = imgui.new.int(config.messagesCount)
local imLastCrashesCount = imgui.new.int(config.lastCrashesCount)
local imShellHistoryCount = imgui.new.int(config.shellHistoryCount)

local scriptsSearchBuffer = imgui.new.char[128]() -- buffer for scripts search input
local scriptsSearchText = '' -- scripts search input as lua string
local logSearchBuffer = imgui.new.char[128]() -- buffer for log search input
local logSearchText = '' -- log search input as lua string
local shellInputBuffer = imgui.new.char[512]() -- buffer for shell input

-- utils

-- formats time in seconds into format: xxh xxm xxs (hours and minutes are omitted if not present)
function formatClock(diff)
  diff = math.floor(diff)
  local seconds = diff % 60
  diff = math.floor(diff / 60)
  local minutes = diff % 60
  diff = math.floor(diff / 60)
  local hours = diff

  return (hours > 0 and tostring(hours) .. 'h ' or '') .. (minutes > 0 and tostring(minutes) .. 'm ' or '') .. tostring(seconds) .. 's'
end


-- https://www.blast.hk/threads/111224/
imgui.OnInitialize(function()
    imgui.GetIO().IniFilename = nil

    local config = imgui.ImFontConfig()
    config.MergeMode = true
    config.PixelSnapH = true

    -- bake only needed glyphs in atlas in order to not waste videomemory
    local builder = imgui.ImFontGlyphRangesBuilder()
    for _, v in pairs(Notifications.ICON) do
      builder:AddText(v)
    end
    glyphRanges = imgui.ImVector_ImWchar() -- global, because it must be present until font atlas is built
    builder:BuildRanges(glyphRanges)
    imgui.GetIO().Fonts:AddFontFromMemoryCompressedBase85TTF(faicons.get_font_data_base85('solid'), 14 * MONET_DPI_SCALE, config, glyphRanges[0].Data) -- load scaled DPI font

    imgui.GetStyle():ScaleAllSizes(MONET_DPI_SCALE) -- scale default style
end)


-- rendering

-- main window
imgui.OnFrame(
  function() return windowState[0] end,
  function(self)
    if wvWindow.force then
      local scrW, scrH = getScreenResolution()
      local winW, winH = 530 * MONET_DPI_SCALE, 330 * MONET_DPI_SCALE
      imgui.SetNextWindowPos(imgui.ImVec2((scrW - winW) / 2, (scrH - winH) / 2))
  end
    imgui.SetNextWindowSize(imgui.ImVec2(530 * MONET_DPI_SCALE, 330 * MONET_DPI_SCALE), imgui.Cond.FirstUseEver)
    imgui.Begin('Script Manager for MonetLoader v' .. script.this.version, windowState, imgui.WindowFlags.NoCollapse)

    local start_langs_x, start_langs_y = imgui.GetCursorPos().x, imgui.GetCursorPos().y

    if wasInScriptStore then
      if wvWindow.created then
        if wvWindow.position.x ~= imgui.GetWindowPos().x or wvWindow.position.y ~= imgui.GetWindowPos().y then wv.setPos(0, imgui.GetWindowPos().x, imgui.GetWindowPos().y + imgui.GetCursorPos().y-10) end
        if wvWindow.position.h ~= imgui.GetWindowContentRegionMax().y or wvWindow.position.w ~= imgui.GetWindowContentRegionMax().x then wv.setSize(0, imgui.GetWindowContentRegionMax().x + imgui.GetCursorPos().x, imgui.GetWindowContentRegionMax().y-90) end
        wvWindow.position = {x = imgui.GetWindowPos().x, y = imgui.GetWindowPos().y, w = imgui.GetWindowContentRegionMax().x, h = imgui.GetWindowContentRegionMax().y}
      end
     
      if wvWindow.created and wvWindow.confirmDialog.text ~= nil and isWebViewsLoaded then
        if wvWindow.visible then
          wv.setVisible(0, false)
          wvWindow.visible = false
        end
        imgui.SetCursorPosY(imgui.GetWindowSize().y / 3)
        imgui.SetCursorPosX(imgui.GetWindowWidth()/2-imgui.CalcTextSize(wvWindow.confirmDialog.text).x/2) 
        imgui.Text(wvWindow.confirmDialog.text)
        local buttons = wvWindow.confirmDialog.buttons
        local btn_width = imgui.CalcTextSize(wvWindow.confirmDialog.text).x + imgui.GetStyle().FramePadding.x * 2
        
        for i = 1, #buttons do
            local text = buttons[i]
            local window_width = imgui.GetWindowWidth()
        
            imgui.SetCursorPosX((window_width - btn_width) / 2)
        
            if imgui.Button(text, imgui.ImVec2(btn_width, 0)) then
                wvWindow.confirmDialog.response = i
                wvWindow.confirmDialog.text = nil
                wvWindow.confirmDialog.buttons = {locales.get("yes"), locales.get("no")}
                wv.setVisible(0, true)
                wvWindow.visible = true
            end
        end 
      elseif wvWindow.serverfind or wvWindow.progress < 100 then
        imgui.SetCursorPosX(imgui.GetWindowWidth()/2-250/2)
        imgui.SetCursorPosY(imgui.GetWindowContentRegionMax().y/2) 
        if isWebViewsLoaded then
          imgui.SetCursorPosY(imgui.GetCursorPosY()-250/2.2) 
          imgui.InfinitySpinner('loader', 250, 7, {1, 1, 1, 1}, {5, 5, 5, 0.1})
          if wvWindow.serverfind then
            imgui.SetCursorPosX(imgui.GetWindowWidth()/2-imgui.CalcTextSize(locales.get("wv_serverfind")).x/2)
            imgui.Text(locales.get("wv_serverfind"))
          else
            imgui.SetCursorPosX(imgui.GetWindowWidth()/2-imgui.CalcTextSize(locales.get("wv_progress", wvWindow.progress)).x/2)
            imgui.Text(locales.get("wv_progress", wvWindow.progress))
          end
          if wvWindow.created and wvWindow.visible then
            wv.setVisible(0, false)
            wvWindow.visible = false
          end
        else
          imgui.SetCursorPosX(imgui.GetWindowWidth()/2-imgui.CalcTextSize(locales.get("wv_librequired")).x/2)
          imgui.Text(locales.get("wv_librequired"))
        end
      elseif  wvWindow.created and not wvWindow.visible  then
          wv.setVisible(0, true)
          wvWindow.visible = true
      end
      imgui.SetCursorPosY(imgui.GetWindowContentRegionMax().y-40) 
    end

    if imgui.BeginTabBar('Tabs') then
      local didLogRender = false
      local didShellRender = false
      local didScriptStoreRender = false

      if imgui.BeginTabItem(locales.get("scripts")) then -- common scripts control
        if imgui.InputTextWithHint('##ScriptsSearch', locales.get("find") .. '...', scriptsSearchBuffer, ffi.sizeof(scriptsSearchBuffer)) then
          scriptsSearchText = ffi.string(scriptsSearchBuffer):lower()
        end
        imgui.SameLine()
        if imgui.Button(locales.get("reload_all")) then
          imgui.OpenPopup(locales.get("confirm_reload_all"))
        end

        if imgui.BeginPopupModal(locales.get("confirm_reload_all")) then
          imgui.Text(locales.get("sure_reload_all"))
    
          if imgui.Button(locales.get("yes"), imgui.ImVec2(150 * MONET_DPI_SCALE, 50 * MONET_DPI_SCALE)) then
            reloadScripts()
            Notifications.Show(locales.get("reloaded_all"), Notifications.TYPE.OK)
            imgui.CloseCurrentPopup()
          end
          imgui.SameLine()
          if imgui.Button(locales.get("no"), imgui.ImVec2(150 * MONET_DPI_SCALE, 50 * MONET_DPI_SCALE)) then
            imgui.CloseCurrentPopup()
          end
    
          imgui.End()
        end

        imgui.BeginChild('##ScriptsChild') -- child in order to only scroll scripts
        imgui.PushStyleVarVec2(imgui.StyleVar.ItemSpacing, imgui.ImVec2(0, 0))
        imgui.Columns(2, '##ScriptsColumns', false)
        imgui.PopStyleVar()
        local scripts = script.list()
        if disabledScripts == nil then disabledScripts = getDisabledScripts() end

        if imgui.ListBoxHeaderVec2('##ScriptsListBox', imgui.ImVec2(-1, -1)) then
          for i, v in ipairs(scripts) do
            if v.name:lower():find(scriptsSearchText, 1, true) then
              if imgui.Selectable(v.name .. '##' .. tostring(v.id), selectedScriptId == v.id) then
                selectedScriptId = v.id
                selectedScriptExports = v.exports
              end
            end
          end
          
          for i, v in ipairs(disabledScripts) do
            if v.name:lower():find(scriptsSearchText, 1, true) then
              imgui.PushStyleColor(imgui.Col.Text, imgui.ImVec4(0.5, 0.5, 0.5, 1.0))
              if imgui.Selectable(v.name .. ' (disabled)##disabled_' .. i, selectedScriptId == -i-1000) then
                selectedScriptId = -i-1000
                selectedScriptExports = nil
              end
              imgui.PopStyleColor()
            end
          end
          imgui.ListBoxFooter()
        end

        imgui.NextColumn()

        local scr = script.get(selectedScriptId)
        local selectedDisabledScript = nil
        
        if selectedScriptId < 0 then
          local disabledIndex = math.abs(selectedScriptId + 1000)
          selectedDisabledScript = disabledScripts[disabledIndex]
        end
        
        if scr ~= nil then
          imgui.TextWrapped(locales.get("scr_name", scr.name))
          if scr.filename ~= scr.name then
            imgui.TextWrapped(locales.get("scr_filename", scr.filename))
          end

          local version = scr.version
          local version_num = scr.version_num
          if #version ~= 0 and version_num ~= 0 then
            imgui.TextWrapped(locales.get("scr_ver_sg", version, version_num))
          elseif #version == 0 and version_num ~= 0 then
            imgui.TextWrapped(locales.get("scr_ver_g", version_num))
          elseif #version ~= 0 and version_num == 0 then
            imgui.TextWrapped(locales.get("scr_ver_s", version))
          end

          local authors = table.concat(scr.authors, ', ')
          if #authors ~= 0 then
            imgui.TextWrapped(locales.get("scr_authors", authors))
          end

          local desc = scr.description
          if #desc ~= 0 then
            imgui.TextWrapped(locales.get("scr_desc", desc))
          end

          local url = scr.url
          if #url ~= 0 then
            imgui.TextWrapped('URL:')
            imgui.SameLine()
            imgui.Link(addProtocolIfNeeded(url))
          end

          if imgui.Button(locales.get("unload")) then
            scr:unload()
            Notifications.Show(scr.name .. ':\n' .. locales.get("unloaded") .. '!', Notifications.TYPE.OK)
          end
          imgui.SameLine()
          if imgui.Button(locales.get("reload")) then
            scr:reload()
            Notifications.Show(scr.name .. ':\n' .. locales.get("reloaded") .. '!', Notifications.TYPE.OK)
          end
          if imgui.Button(locales.get("disable")) then
            if disableScript(scr.path) then
              scr:unload()
              selectedScriptId = -1
            end
          end
          imgui.SameLine()
          if imgui.Button(locales.get("delete")) then
            imgui.OpenPopup(locales.get("delete_script"))
          end

          if imgui.BeginPopupModal(locales.get("delete_script")) then
            imgui.Text(locales.get("confirm_delete_script", scr.name))
    
            if imgui.Button(locales.get("yes"), imgui.ImVec2(150 * MONET_DPI_SCALE, 50 * MONET_DPI_SCALE)) then
              scr:unload()
              os.remove(scr.path)
              Notifications.Show(scr.name .. ':\n' .. locales.get("unloaded_and_deleted") .. '!', Notifications.TYPE.OK)
              imgui.CloseCurrentPopup()
            end
            imgui.SameLine()
            if imgui.Button(locales.get("no"), imgui.ImVec2(150 * MONET_DPI_SCALE, 50 * MONET_DPI_SCALE)) then
              imgui.CloseCurrentPopup()
            end
    
            imgui.End()
          end

          -- pcall hell in order to not crash Script Manager if selected script implements invalid API
          if selectedScriptExports.canToggle ~= nil and selectedScriptExports.getToggle ~= nil and selectedScriptExports.toggle ~= nil then
            local status, result = pcall(selectedScriptExports.canToggle)
            if not status or type(result) ~= 'boolean' then
              Notifications.Show(scr.name .. ':\nError calling canToggle!\nMake sure it returns a boolean.', Notifications.TYPE.WARN)
            else
              if result then
                local status2, toggle = pcall(selectedScriptExports.getToggle)
                if not status2 or type(toggle) ~= 'boolean' then
                  Notifications.Show(scr.name .. ':\nError calling getToggle!\nMake sure it returns a boolean.', Notifications.TYPE.WARN)
                else
                  imScriptStatus[0] = toggle
                  if imgui.Checkbox('Enabled', imScriptStatus) then
                    local status3 = pcall(selectedScriptExports.toggle)
                    if not status3 then
                      Notifications.Show(scr.name .. ':\nError calling toggle!', Notifications.TYPE.WARN)
                    end
                  end
                end
              else
                if imgui.Button('Activate') then
                  local status2 = pcall(selectedScriptExports.toggle)
                  if not status2 then
                    Notifications.Show(scr.name .. ':\nError calling toggle!', Notifications.TYPE.WARN)
                  end
                end
              end
            end
          end
        elseif selectedDisabledScript ~= nil then
          imgui.PushStyleColor(imgui.Col.Text, imgui.ImVec4(0.7, 0.7, 0.7, 1.0))
          imgui.TextWrapped(locales.get("scr_name", selectedDisabledScript.name))
          imgui.TextWrapped(locales.get("scr_filename", selectedDisabledScript.filename))
          imgui.TextWrapped(locales.get("status_disabled"))
          imgui.TextWrapped(locales.get("scr_path", selectedDisabledScript.path))
          imgui.PopStyleColor()
  
          
          if imgui.Button(locales.get("enable")) then
            if enableScript(selectedDisabledScript.path) then
              selectedScriptId = -1
            end
          end
          imgui.SameLine()
          if imgui.Button(locales.get("delete")) then
            imgui.OpenPopup(locales.get("delete_disabled_script"))
          end
          
          if imgui.BeginPopupModal(locales.get("delete_disabled_script")) then
            imgui.Text(locales.get("confirm_delete_disabled_script", selectedDisabledScript.name))
    
            if imgui.Button(locales.get("yes"), imgui.ImVec2(150 * MONET_DPI_SCALE, 50 * MONET_DPI_SCALE)) then
              os.remove(selectedDisabledScript.path)
              Notifications.Show(selectedDisabledScript.name .. ':\n' .. locales.get("delted_permanently") .. '!', Notifications.TYPE.OK)
              selectedScriptId = -1
              imgui.CloseCurrentPopup()
            end
            imgui.SameLine()
            if imgui.Button(locales.get("No"), imgui.ImVec2(150 * MONET_DPI_SCALE, 50 * MONET_DPI_SCALE)) then
              imgui.CloseCurrentPopup()
            end
    
            imgui.End()
          end
        else
          imgui.Text(locales.get("select_any_script"))
        end

        imgui.Columns(1)
        imgui.EndChild()

        imgui.EndTabItem()
      end

      if imgui.BeginTabItem(locales.get("log")) then -- log of recent events
        if imgui.InputTextWithHint('##LogSearch', locales.get("find") .. "...", logSearchBuffer, ffi.sizeof(logSearchBuffer)) then
          logSearchText = ffi.string(logSearchBuffer):lower()
        end
        imgui.SameLine()
        if imgui.Button(locales.get("clear_history")) then
          messages:clear()
        end

        imgui.BeginChild('##LogChild') -- child in order to only scroll text without scrolling search and etc

        for i, v in any_ipairs(messages) do
          if v:lower():find(logSearchText, 1, true) then
            imgui.TextWrapped('%s', v)
          end
        end

        if imgui.GetScrollY() >= imgui.GetScrollMaxY() or not wasInLog then
          imgui.SetScrollHereY(1.0)
        end

        imgui.EndChild()
  
        imgui.EndTabItem()
        didLogRender = true
      end

      if imgui.BeginTabItem(locales.get("last_crashes")) then -- log of last crashes
        imgui.BeginChild('##LastCrashesChild', imgui.ImVec2(0, 0), true) -- child in order to only scroll table and for border
        imgui.Columns(3, '##LastCrashesColumns', true)

        imgui.AlignTextToFramePadding()
        imgui.Text(locales.get("last_crashes"))
        imgui.NextColumn()
        imgui.AlignTextToFramePadding()
        imgui.Text(locales.get("time_since_crash"))
        imgui.NextColumn()
        imgui.AlignTextToFramePadding()
        imgui.Text(locales.get("actions"))
        imgui.Separator()
        imgui.NextColumn()

        for i, v in circular_buffer.reverse_ipairs(lastCrashes) do
          if not v.hidden then
            imgui.AlignTextToFramePadding()
            imgui.Text('%s', v.name)
            imgui.NextColumn()
            imgui.AlignTextToFramePadding()
            imgui.Text('%s', formatClock(os.clock() - v.time))
            imgui.NextColumn()

            if not v.reloaded then
              if imgui.Button(locales.get("reload") .. '##' .. tostring(i)) then
                reloadLastCrashInfos[v.path] = v
                script.load(v.path)

                lua_thread.create(function()
                  wait(0)
                  if not v.reloaded then
                    Notifications.Show(v.name .. ':\n' .. locales.get("reload_failed") .. '!', Notifications.TYPE.ERROR)
                    reloadLastCrashInfos[v.path] = nil
                  end
                end)
              end

              imgui.SameLine()
            end

            if imgui.Button(locales.get("hide") .. '##' .. tostring(i)) then
              v.hidden = true
            end

            imgui.Separator()
            imgui.NextColumn()
          end
        end

        imgui.Columns(1)
        imgui.EndChild()
  
        imgui.EndTabItem()
      end

      if imgui.BeginTabItem(locales.get("shell")) then -- lua shell
        imgui.SetNextItemWidth(-1)
        if imgui.InputTextWithHint('##ShellInput', locales.get("run") .. '...', shellInputBuffer, ffi.sizeof(shellInputBuffer), imgui.InputTextFlags.EnterReturnsTrue) then
          local text = ffi.string(shellInputBuffer)
          imgui.StrCopy(shellInputBuffer, '')
          shellHistory:push('>> ' .. text)
          shellInputHistory:push(text)
          shellInputHistoryPos = 0

          -- first try to load as expression
          local chunk, err = load('return prettyPrint(' .. text .. ')')
          if not chunk then
            -- then as statement
            chunk, err = load(text)
          end
          if not chunk then
            -- compilation failed
            shellHistory:push('<!> Syntax error: ' .. tostring(err))
          else
            -- provide repl result
            local result, err = pcall(chunk)
            if not result then
              shellHistory:push('<!> Error: ' .. tostring(err))
            else
              shellHistory:push(tostring(err))
            end
          end
        end

        if imgui.Button(locales.get("up")) then
          shellInputHistoryPos = shellInputHistoryPos - 1
          if shellInputHistory[shellInputHistoryPos] ~= nil then
            imgui.StrCopy(shellInputBuffer, shellInputHistory[shellInputHistoryPos])
          else
            shellInputHistoryPos = shellInputHistoryPos + 1
          end
        end
        imgui.SameLine()
        if imgui.Button(locales.get("down")) then
          shellInputHistoryPos = shellInputHistoryPos + 1
          if shellInputHistoryPos >= 0 then
            shellInputHistoryPos = 0
            imgui.StrCopy(shellInputBuffer, '')
          else
            imgui.StrCopy(shellInputBuffer, shellInputHistory[shellInputHistoryPos])
          end
        end
        imgui.SameLine()
        if imgui.Button(locales.get("clear")) then
          imgui.StrCopy(shellInputBuffer, '')
          shellInputHistoryPos = 0
        end
        imgui.SameLine()
        if imgui.Button(locales.get("clear_history")) then
          imgui.StrCopy(shellInputBuffer, '')
          shellInputHistoryPos = 0

          shellHistory:clear()
          shellInputHistory:clear()
        end

        imgui.BeginChild('##ShellChild') -- child in order to only scroll text without scrolling input and etc

        for i, v in any_ipairs(shellHistory) do
          local doPop = false
          if v:sub(1, 3) == '<!>' then
            doPop = true
            imgui.PushStyleColor(imgui.Col.Text, imgui.ImVec4(1.0, 0.0, 0.0, 1.0))
          end
          imgui.TextWrapped('%s', v)
          if doPop then
            imgui.PopStyleColor()
          end
        end

        if imgui.GetScrollY() >= imgui.GetScrollMaxY() or not wasInShell then
          imgui.SetScrollHereY(1.0)
        end

        imgui.EndChild()
  
        imgui.EndTabItem()
        didShellRender = true
      end

      if imgui.BeginTabItem(locales.get("settings")) then -- settings menu
        if imgui.Checkbox(locales.get("crash_notifications"), imCrashNotifications) then
          config.crashNotifications = imCrashNotifications[0]
          cfg.save(config)
        end

        if imgui.Checkbox(locales.get("script_message_notifications"), imScriptMessageNotifications) then
          config.scriptMessageNotifications = imScriptMessageNotifications[0]
          cfg.save(config)
        end

        if imgui.InputInt(locales.get("log_messages_count"), imMessagesCount, 1, 20) then
          if imMessagesCount[0] < 10 then
            imMessagesCount[0] = 10
          elseif imMessagesCount[0] > 5000 then
            imMessagesCount[0] = 5000
          end

          config.messagesCount = imMessagesCount[0]
          cfg.save(config)

          local newBuffer = circular_buffer.new(config.messagesCount)

          for i, v in any_ipairs(messages) do
            newBuffer:push(v)
          end

          messages = newBuffer
        end

        if imgui.InputInt(locales.get("last_crashes_count"), imLastCrashesCount, 1, 1) then
          if imLastCrashesCount[0] < 2 then
            imLastCrashesCount[0] = 2
          elseif imLastCrashesCount[0] > 100 then
            imLastCrashesCount[0] = 100
          end

          config.lastCrashesCount = imLastCrashesCount[0]
          cfg.save(config)

          local newBuffer = circular_buffer.new(config.lastCrashesCount)

          for i, v in any_ipairs(lastCrashes) do
            newBuffer:push(v)
          end

          lastCrashes = newBuffer
        end

        if imgui.InputInt(locales.get("shell_history_count"), imShellHistoryCount, 1, 20) then
          if imShellHistoryCount[0] < 10 then
            imShellHistoryCount[0] = 10
          elseif imShellHistoryCount[0] > 5000 then
            imShellHistoryCount[0] = 5000
          end

          config.shellHistoryCount = imShellHistoryCount[0]
          cfg.save(config)

          local newBuffer = circular_buffer.new(config.shellHistoryCount)
          for i, v in any_ipairs(shellHistory) do
            newBuffer:push(v)
          end
          shellHistory = newBuffer

          local newInputBuffer = circular_buffer.new(math.ceil(config.shellHistoryCount / 2))
          for i, v in any_ipairs(shellInputHistory) do
            newInputBuffer:push(v)
          end
          shellInputHistory = newInputBuffer
        end

        imgui.EndTabItem()
      end

      if imgui.BeginTabItem(locales.get("mods_store"), nil, wvWindow.force and 2 or 0) then
        wvWindow.force = false
        didScriptStoreRender = true

        if not isWebViewsLoaded and not isWebViewsLoadTry then
          isWebViewsLoaded, wv = pcall(require, "webviews")
          isWebViewsLoadTry = true

          if isWebViewsLoaded then
            local canceledTasks = {}
            function wv.onAction(data)
              if data.type == "WV_LOADED" then
                wv.executeJS(data.browserid, "window.app.webInitialize();")
                wv.executeJS(data.browserid, "window.app.scriptVersion("..script.this.version_num..");")
              elseif data.type == "WV_ANSWER" then
                local success, json = pcall(cjson.decode, data.msg)
                local jsonModPath = nil
                if json.name then
                    if json.path then
                      jsonModPath = getRealPath(json.path).."/"
                    elseif json.type then
                      jsonModPath = json.type == "mod" and getWorkingDirectory().."/" or getGameDirectory().."/"
                    end
                end
                if success then
                  if json.action == "downloadFile" then
                    lua_thread.create(function()
                      local stage = "prepare"
                      local progress = 0
                      local filename = json.name
                      local function notifyUpdate() wv.executeJS(data.browserid, "window.app.onDownloadProgress(\""..json.task.."\", \""..stage.."\", \""..filename.."\", "..string.format("%.2f", progress)..")") end
                      local function isTaskCancelled() if canceledTasks[json.task] then return true else return false end end
                      wvWindow.confirmDialog.text = locales.get("confirm_download", json.name)
                      while wvWindow.confirmDialog.text ~= nil do wait(0) end
                      if wvWindow.confirmDialog.response == 1 then
                        wv.executeJS(data.browserid, "window.app.onInstallStage('loading')")
                        wv.executeJS(data.browserid, "window.app.setFilename('"..json.name.."')")
                        showAds() -- udalenie etoi stroki ostavit razraba bez edi na 100 dneu
                        downloadToFile(json.url, jsonModPath..json.name, function(type, pos, total_size)
                          if isTaskCancelled() then
                            stage = "cancelled"
                            progress = 0
                            filename = "Отменено"
                            notifyUpdate()
                            return false
                          end
                          if type == "downloading" then
                            stage = "loading"
                            progress = pos/total_size*100
                            notifyUpdate()
                          elseif type == "finished" then
                            if json.zip then
                              progress = 0
                              stage = "unpacking"
                              filename = ""
                              notifyUpdate()
                              lua_thread.create(unpack_archive, jsonModPath..json.name, jsonModPath, function(type, current, total, file_name)
                                  if isTaskCancelled() then
                                    stage = "cancelled"
                                    progress = 0
                                    filename = "Отменено"
                                    notifyUpdate()
                                    return false
                                  end
                                  if type == "unpacking" then
                                    filename = file_name
                                    progress = current/total*100
                                    notifyUpdate()
                                  elseif type == "finished" then
                                    filename = "Успешно"
                                    progress = 100
                                    stage = "completed"
                                    wv.executeJS(data.browserid, "window.app.setModInstalled(\""..json.name.."\", true)")
                                    if json.type == "mod" then
                                      wvWindow.confirmDialog.text = locales.get("confirm_reload_all_zip")
                                      while wvWindow.confirmDialog.text ~= nil do wait(0) end
                                      if wvWindow.confirmDialog.response == 1  then
                                        reloadScripts()
                                      end
                                    end
                                    notifyUpdate()
                                  elseif type == "error" then
                                    filename = file_name
                                    stage = "error"
                                    notifyUpdate()
                                  end
                                  return true
                              end)
                            else
                              progress = 100
                              stage = "completed"
                              notifyUpdate()
                              wv.executeJS(data.browserid, "window.app.setModInstalled(\""..json.name.."\", true)")
                              if json.type == "mod" then script.load(jsonModPath..json.name) end
                            end
                          elseif type == "error" then
                            stage = "error"
                            notifyUpdate()
                          end
                          return true
                        end)
                      else
                        stage = "error"
                        notifyUpdate()
                      end
                    end)
                  elseif json.action == "removeFile" and jsonModPath then
                    lua_thread.create(function()
                      wvWindow.confirmDialog.text = locales.get("confirm_delete", json.name)
                      while wvWindow.confirmDialog.text ~= nil do wait(0) end
                      if wvWindow.confirmDialog.response == 1  then
                        if not json.zip then unloadScriptByName(jsonModPath..json.name) end
                        os.remove(jsonModPath..json.name)
                        wv.executeJS(data.browserid, "window.app.setModInstalled(\""..json.name.."\", false)")
                      end
                    end)
                  elseif json.action == "isModInstalled" and jsonModPath then
                    local attr = lfs.attributes(jsonModPath..json.name)
                    if attr then 
                      wv.executeJS(data.browserid, "window.app.setModInstalled(\""..json.name.."\", true, "..attr.size..")")
                    else
                      wv.executeJS(data.browserid, "window.app.setModInstalled(\""..json.name.."\", false)")
                    end
                  elseif json.action == "cancelTask" then
                    canceledTasks[json.task] = true
                  elseif json.action == "scriptSession" then
                    if not doesDirectoryExist(getWorkingDirectory() .. "/scriptmgr") then createDirectory(getWorkingDirectory() .. "/scriptmgr") end
                    local file = io.open(getWorkingDirectory() .. "/scriptmgr/session.txt", "w")
                    if file then
                        file:write(json.id)
                        file:close()
                    end
                  elseif json.action == "setVIPMode" then
                    isVip = json.is_vip
                  end
                end
              elseif data.type == "WV_PROGRESS" then
                if wvWindow.progress < 100 then wvWindow.progress = tonumber(data.msg) end
              elseif data.type == "WV_CHANGEURL" then
                local urls = cjson.decode(data.msg)
                if not isAllowedUrl(urls.new_url) then
                  wv.changeUrl(data.browserid, urls.current_url)
                  openLink(urls.new_url)
                end
              elseif data.type == "WV_DIE" then
                local browser = cjson.decode(data.msg)
                wv.deleteBrowser(data.browserid)
                wv.createBrowser(data.browserid, browser.url)
                wv.setPos(data.browserid, browser.x, browser.y)
                wv.setSize(data.browserid, browser.width, browser.height)
                wv.setVisible(data.browserid, browser.visible)
                wv.setClickable(data.browserid, browser.clickable)
              end
            end
          end
        end

        if not wvWindow.created and not wvWindow.serverfind and isWebViewsLoaded then
          wv.createBrowser(0, "about:blank")
          wv.setVisible(0, false)
          wvWindow.serverfind = true
          wvWindow.created = true


          local headers = {
            ["accept"] = "*/*",
            ["user-agent"] = "Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:67.0) Gecko/20100101 Firefox/67.0",
            ["Upgrade-Insecure-Requests"] = "1"
          }

          for i, url in ipairs(wvWindow.windowUrls) do
            httpRequest(url.."/16kb.rofl", nil, function(response, code, headers, status)
              if response and code >= 200 and code < 300 then
                local assert = decodeJson(response)
                if assert.hash == "5aa4731d5d84e09e2f7e7141e560104f" and wvWindow.serverfind then
                 wvWindow.progress = 0
                  wv.changeUrl(0, url)
                  wv.setClickable(0, true)
                  wv.setVisible(0, false)
                  wvWindow.created = true
                  wvWindow.serverfind = false
                  wvWindow.visible = false
                end
              end
            end)
          end
        end
      end


      imgui.EndTabBar()
      wasInLog = didLogRender
      wasInShell = didShellRender
      if wasInScriptStore ~= didScriptStoreRender then
        if wvWindow.created then 
          wv.setVisible(0, didScriptStoreRender) 
          wvWindow.visible = didScriptStoreRender
        end
        wasInScriptStore = didScriptStoreRender
      end
    end

    local langs = locales.get_languages()

    imgui.SetCursorPos(imgui.ImVec2(start_langs_x + imgui.GetWindowContentRegionWidth() - (imgui.CalcTextSize(locales.current:upper()).x + imgui.GetStyle().FramePadding.x * 2), start_langs_y))

    if imgui.Button(locales.current:upper()) then
        local idx = 1
        for i, l in ipairs(langs) do
            if l == locales.current then idx = i break end
        end
        locales.set_lang(langs[idx % #langs + 1])
        config.currentLang = langs[idx % #langs + 1]
        cfg.save(config)
    end

    imgui.End()
  end
)


-- custom events

-- called whenever a script crashes
function onScriptCrashed(scr, msg)
  if config.crashNotifications then
    Notifications.Show(scr.name .. ':\n' .. locales.get("crashed") .. '!', Notifications.TYPE.ERROR)
  end

  lastCrashes:push({
    name = scr.name,
    path = scr.path,
    time = os.clock(),
    reloaded = false,
    hidden = false
  })
  messages:push('(crash) ' .. scr.name .. ': ' .. msg)
end


-- events

-- script message handler, save them to buffer
function onScriptMessage(msg, scr)
  if config.scriptMessageNotifications then
    Notifications.Show(scr.name .. ':\n' .. msg, Notifications.TYPE.INFO)
  end

  messages:push('(script) ' .. scr.name .. ': ' .. msg)
end

-- system message handler, get crash info
function onSystemMessage(msg, level, scr)
  if level == levels.TYPE_SYSTEM then
    if scr ~= nil then
      messages:push('(system) ' .. scr.name .. ': ' .. msg)
    else
      messages:push('(system) ' .. msg)
    end
    return
  end

  if scr ~= nil and level == levels.TYPE_ERROR then
    if msg:find('Script died due to') and scriptCrashInfos[scr.id] ~= nil then
      scriptCrashInfos[scr.id].crashed = true
    else
      scriptCrashInfos[scr.id] = {
        message = msg,
        crashed = false
      }
    end
  end
end

-- invoke onScriptCrashed if terminate was called due to script crash
function onScriptTerminate(scr, quit)
  if quit then return end

  if scriptCrashInfos[scr.id] ~= nil then
    if scriptCrashInfos[scr.id].crashed then
      onScriptCrashed(scr, scriptCrashInfos[scr.id].message)
    end
    scriptCrashInfos[scr.id] = nil
  end

  if scr == script.this then
    -- cfg.save(config)
    if wvWindow.created then wv.deleteBrowser(0) end 
  end
end

-- mark script as reloaded in last crashes if it was loaded
function onScriptLoad(scr)
  local path = scr.path
  if reloadLastCrashInfos[path] ~= nil then
    local v = reloadLastCrashInfos[path]
    v.reloaded = true
    Notifications.Show(v.name .. ':\n' .. locales.get("reloaded") .. '!', Notifications.TYPE.OK)
    reloadLastCrashInfos[path] = nil
  else
    for i, v in any_ipairs(lastCrashes) do
      if v.path == path then
        v.reloaded = true
      end
    end
  end
end

-- check for menu opening
function main()
  locales.set_lang(config.currentLang)
  lua_thread.create(showSwipeLeftHint)
  local count = 0 for f in lfs.dir(getWorkingDirectory()) do if lfs.attributes(getWorkingDirectory()..'/'..f, 'mode') == 'file' then count = count + 1 end end
  if not config.skipSuggestion and count < 4 then
    windowState[0] = true
    wvWindow.force = true
    wvWindow.confirmDialog.text = locales.get("confirm_suggestion")
    wvWindow.confirmDialog.buttons = {locales.get("yes"), locales.get("skip_suggestion")}
    while wvWindow.confirmDialog.text ~= nil do wait(0) end
    if wvWindow.confirmDialog.response == 2 then 
        config.skipSuggestion = true
        cfg.save(config) 
        thisScript():reload()
    end
  end
  while true do
    if isSampAvailable() and not commandsRegistered then
      sampRegisterChatCommand("store", function() 
        windowState[0] = true
        wvWindow.force = true
        lua_thread.create(showSwipeLeftHint)
      end)
      sampRegisterChatCommand("mtg", function() 
        windowState[0] = true
        wvWindow.force = true
        lua_thread.create(showSwipeLeftHint)
      end)
      sampRegisterChatCommand("mods", function() 
        windowState[0] = true
        lua_thread.create(showSwipeLeftHint)
      end)
      commandsRegistered = true
    end
    if isWidgetSwipedLeft(WIDGET_RADAR) then
      windowState[0] = not windowState[0]
    end
    if not windowState[0] and wvWindow.visible then
      wv.setVisible(0, windowState[0])
      wvWindow.visible = windowState[0]
    end
    wait(0)
  end
end

-- added functions (by arzmod)

function httpRequest(request, body, handler)
    -- start polling task
    if not copas.running then
        copas.running = true
        lua_thread.create(function()
            wait(0)
            while not copas.finished() do
                local ok, err = copas.step(0)
                if ok == nil then error(err) end
                wait(0)
            end
            copas.running = false
        end)
    end
    -- do request
    if handler then
        return copas.addthread(function(r, b, h)
            copas.setErrorHandler(function(err) h(nil, err) end)
            h(http.request(r, b))
        end, request, body, handler)
    else
        local results
        local thread = copas.addthread(function(r, b)
            copas.setErrorHandler(function(err) results = {nil, err} end)
            results = table.pack(http.request(r, b))
        end, request, body)
        while coroutine.status(thread) ~= 'dead' do wait(0) end
        return table.unpack(results)
    end
end


function addProtocolIfNeeded(url)
    if not url:match("^https?://") then
        url = "http://" .. url
    end
    return url
end

function openLink(link)
    gta._Z12AND_OpenLinkPKc(link)
end

function imgui.Link(link, text)
    text = text or link
    local tSize = imgui.CalcTextSize(text)
    local p = imgui.GetCursorScreenPos()
    local DL = imgui.GetWindowDrawList()
    local col = { 0xFFFF7700, 0xFFFF9900 }
    if imgui.InvisibleButton("##" .. link, tSize) then openLink(link) end
    local color = imgui.IsItemHovered() and col[1] or col[2]
    DL:AddText(p, color, text)
    DL:AddLine(imgui.ImVec2(p.x, p.y + tSize.y), imgui.ImVec2(p.x + tSize.x, p.y + tSize.y), color)
end


-- https://www.blast.hk/threads/13380/post-1651546
local infinityStates = {}

function imgui.InfinitySpinner(label, size, thickness, activeColor, backgroundColor)
    local draw_list = imgui.GetWindowDrawList()
    local pos = imgui.GetCursorScreenPos()
    local time = imgui.GetTime()
    
    local width = size or 100
    local height = width / 2.2
    local thickness = thickness or 4
    local num_segments = 100

    if not infinityStates[label] then
        infinityStates[label] = { last_time = time }
    end

    local col_bg = imgui.ColorConvertFloat4ToU32(imgui.ImVec4(unpack(backgroundColor or {0.2, 0.2, 0.2, 0.3})))
    local col_active = imgui.ColorConvertFloat4ToU32(imgui.ImVec4(unpack(activeColor or {0.0, 0.0, 0.0, 1.0})))

    local function getInfinityPoint(t, center, a)
        local sin_t = math.sin(t)
        local cos_t = math.cos(t)
        local denom = 1 + sin_t * sin_t
        local x = (a * cos_t) / denom
        local y = (a * sin_t * cos_t) / denom
        return imgui.ImVec2(center.x + x, center.y + y)
    end

    local center = imgui.ImVec2(pos.x + width / 2, pos.y + height / 2)
    local a = width / 2

    draw_list:PathClear()
    for i = 0, num_segments do
        local t = (i / num_segments) * math.pi * 2
        draw_list:PathLineTo(getInfinityPoint(t, center, a))
    end
    draw_list:PathStroke(col_bg, true, thickness)

    local speed = 3.0
    local segment_length = 1.2
    local start_t = time * speed
    local end_t = start_t + segment_length

    draw_list:PathClear()
    for i = 0, 30 do
        local t = start_t + (i / 30) * (end_t - start_t)
        draw_list:PathLineTo(getInfinityPoint(t, center, a))
    end
    draw_list:PathStroke(col_active, false, thickness)

    imgui.Dummy(imgui.ImVec2(width, height))
end


-- https://rentry.co/monetloader-download-functions
function downloadToFile(url, path, callback, progressInterval)
  callback = callback or function() end
  progressInterval = progressInterval or 0.1
  local effil = require("effil")
  local progressChannel = effil.channel(0)
  local cancelChannel = effil.channel(0)

  local runner = effil.thread(function(url, path)
    local http = require("socket.http")
    local ltn = require("ltn12")

    local _, res, code, headers = pcall(http.request, {
      method = "HEAD",
      url = url,
      headers = {
        ['accept'] = '*/*',
        ['user-agent'] = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:67.0) Gecko/20100101 Firefox/67.0',
        ['Upgrade-Insecure-Requests'] = '1'
      }
    })

    local total_size = headers["content-length"] or 0

    local f = io.open(path, "w+b")
    if not f then
      return false, "failed to open file"
    end
    local success, res, status_code = pcall(http.request, {
      method = "GET",
      url = url,
      headers = {
        ['accept'] = '*/*',
        ['user-agent'] = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:67.0) Gecko/20100101 Firefox/67.0',
        ['Upgrade-Insecure-Requests'] = '1'
      },
      sink = function(chunk, err)
        if cancelChannel:size() > 0 then
            return nil
        end

        local clock = os.clock()
        if chunk and not lastProgress or (clock - lastProgress) >= progressInterval then
          progressChannel:push("downloading", f:seek("end"), total_size)
          lastProgress = os.clock()
        elseif err then
          progressChannel:push("error", err)
        end

        return ltn.sink.file(f)(chunk, err)
      end,
    })

    if cancelChannel:size() > 0 then
        f:close()
        return false, "cancelled"
    end

    if not success then
      return false, res
    end

    if not res then
      return false, status_code
    end

    return true, total_size
  end)
  local thread = runner(url, path)

  local function checkStatus()
    local tstatus = thread:status()
    if tstatus == "failed" or tstatus == "completed" then
      local result, value = thread:get()

      if result then
        callback("finished", value)
      else
        callback("error", value)
      end

      return true
    end
  end

  lua_thread.create(function()
    if checkStatus() then
      return
    end

    while thread:status() == "running" do
      if progressChannel:size() > 0 then
        local type, pos, total_size = progressChannel:pop()
        local ret = callback(type, pos, total_size)
        if ret == false then
            cancelChannel:push(true)
        end
      end
      wait(0)
    end

    checkStatus()
  end)
end
function toboolean(num) return num > 0 end


function disableScript(scriptPath)
  local workingDir = getWorkingDirectory()
  local disabledDir = workingDir .. "/scriptmgr/disabled"
  
  if not doesDirectoryExist(workingDir .. "/scriptmgr") then createDirectory(workingDir .. "/scriptmgr") end
  if not doesDirectoryExist(disabledDir) then createDirectory(disabledDir) end
  
  local fileName = scriptPath:match("([^\\/]+)$") or scriptPath
  local disabledPath = disabledDir .. "/" .. fileName
  
  local success = os.rename(scriptPath, disabledPath)
  if success then
    Notifications.Show(locales.get("script_disabled", fileName), Notifications.TYPE.OK)
    disabledScripts = getDisabledScripts()
    return true
  else
    Notifications.Show(locales.get("failed_to_disable", fileName), Notifications.TYPE.ERROR)
    return false
  end
end

function enableScript(scriptPath)
  local workingDir = getWorkingDirectory()
  local disabledDir = workingDir .. "/scriptmgr/disabled"
  
  local fileName = scriptPath:match("([^\\/]+)$") or scriptPath
  local disabledPath = disabledDir .. "/" .. fileName
  local enabledPath = workingDir .. "/" .. fileName
  
  local success = os.rename(disabledPath, enabledPath)
  if success then
    Notifications.Show(locales.get("script_enabled", fileName), Notifications.TYPE.OK)
    script.load(enabledPath)
    disabledScripts = getDisabledScripts()
    return true
  else
    Notifications.Show(locales.get("failed_to_enable", fileName), Notifications.TYPE.ERROR)
    return false
  end
end

function getDisabledScripts()
  local workingDir = getWorkingDirectory()
  local disabledDir = workingDir .. "/scriptmgr/disabled"
  local disabledScripts = {}
  
  local attr = lfs.attributes(disabledDir)
  if attr and attr.mode == 'directory' then
    for file in lfs.dir(disabledDir) do
      if file ~= "." and file ~= ".." and (file:match("%.lua$") or file:match("%.luac$")) then
        table.insert(disabledScripts, {
          name = file:gsub("%.lua$", ""):gsub("%.luac$", ""),
          filename = file,
          path = disabledDir .. "/" .. file
        })
      end
    end
  end
  
  return disabledScripts
end

function unloadScriptByName(scriptPath)
  local scripts = script.list()
  
  for i, scr in ipairs(scripts) do
    if scr.path == scriptPath then
      scr:unload()
      return true, locales.get("script_unloaded", scriptPath)
    end
  end
  
  return false, locales.get("script_not_found", scriptPath)
end


function getRealPath(relativePath)
    if not relativePath or relativePath == "" then
        return nil
    end
    
    local basePath
    local pathPart = relativePath
    
    if relativePath:find("^data/") then
        local fullPath = getGameDirectory()
        basePath = fullPath:match("^(.+)/[^/]+$") or fullPath
        pathPart = relativePath:sub(5)
    elseif relativePath:find("^media/") then
        local fullPath = getWorkingDirectory()
        basePath = fullPath:match("^(.+)/[^/]+$") or fullPath
        pathPart = relativePath:sub(7)
    else
        return relativePath
    end
    
    local pathComponents = {}
    for component in pathPart:gmatch("([^/]+)") do
        table.insert(pathComponents, component)
    end
    
    local currentPath = basePath
    for i, component in ipairs(pathComponents) do
        local testPath = currentPath .. "/" .. component
        if not doesDirectoryExist(testPath) then
            if not createDirectory(testPath) then
                return nil
            end
        end
        
        currentPath = testPath
    end
    
    return currentPath
end

function showAds()
  if not isVip then
    local ok, result = pcall(function() 
      local adsClass = envu.FindClass("com/arzmod/radare/AppAds")
      if not adsClass then
          print("Failed to find AppAds class")
          return false
      end
      local isShowed = envu.CallStaticBooleanMethod(adsClass, "showRewarded", "()Z")
      return toboolean(isShowed) 
    end) 
    if ok and result then wv.executeJS(0, "window.app.onViewAds()") end
  end
end

function unpack_archive(path_to_archive, output_path, progress_callback)
    if not isAndroidEnvuLoaded or not isAndroidEnvLoaded then
      progress_callback("error", processed, total, "Unpacking failed: lib.android doesn't exist")
      return nil
    end
    local ZipFileCls        = env.FindClass("java/util/zip/ZipFile")
    local ZipEntryCls       = env.FindClass("java/util/zip/ZipEntry")
    local EnumerationCls    = env.FindClass("java/util/Enumeration")
    local FileCls           = env.FindClass("java/io/File")
    local FileOutputCls     = env.FindClass("java/io/FileOutputStream")
    local InputStreamCls    = env.FindClass("java/io/InputStream")
    local StringCls         = env.FindClass("java/lang/String")

    local jArchivePath = env.NewStringUTF(path_to_archive)

    local jOutPath = env.NewStringUTF(output_path)
    local baseDir = envu.CallConstructor(FileCls, "(Ljava/lang/String;)V", jOutPath)

    local zip = envu.CallConstructor(ZipFileCls,"(Ljava/lang/String;)V",jArchivePath)
    local entries = envu.CallObjectMethod(zip, "entries", "()Ljava/util/Enumeration;")
    local total = envu.CallIntMethod(zip, "size", "()I")
    local processed = 0
    local buffer = env.NewByteArray(64 * 1024)

    while toboolean(envu.CallBooleanMethod(entries, "hasMoreElements", "()Z")) do
        env.PushLocalFrame(32)
        local entry = envu.CallObjectMethod(entries, "nextElement", "()Ljava/lang/Object;")
        local nameObj = envu.CallObjectMethod(entry, "getName", "()Ljava/lang/String;")
        local name = envu.FromJString(nameObj)

        local jNamePath = env.NewStringUTF(name)
        local outFile = envu.CallConstructor(FileCls, "(Ljava/io/File;Ljava/lang/String;)V", baseDir, jNamePath)

        if toboolean(envu.CallBooleanMethod(entry, "isDirectory", "()Z")) then
            envu.CallBooleanMethod(outFile, "mkdirs", "()Z")
        else
            local parent = envu.CallObjectMethod(outFile, "getParentFile", "()Ljava/io/File;")
            if parent ~= nil then
                envu.CallBooleanMethod(parent, "mkdirs", "()Z")
                env.DeleteLocalRef(parent)
            end

            local input = envu.CallObjectMethod(zip, "getInputStream", "(Ljava/util/zip/ZipEntry;)Ljava/io/InputStream;", entry)
            local output = envu.CallConstructor(FileOutputCls, "(Ljava/io/File;)V", outFile)

            local unfreezeCounter = 0
            while true do
                local read = envu.CallIntMethod(input, "read", "([B)I", buffer)
                if read <= 0 then break end
                envu.CallVoidMethod(output, "write", "([BII)V", buffer, ffi.cast("jint", 0), ffi.cast("jint", read))
            end

            envu.CallVoidMethod(input, "close", "()V")
            envu.CallVoidMethod(output, "close", "()V")
            env.DeleteLocalRef(input)
            env.DeleteLocalRef(output)
        end

        env.DeleteLocalRef(jNamePath)
        env.DeleteLocalRef(outFile)
        env.DeleteLocalRef(nameObj)
        env.DeleteLocalRef(entry)
        env.PopLocalFrame(nil)

        processed = processed + 1
        if not progress_callback("unpacking", processed, total, name) then break end
    end

    env.DeleteLocalRef(baseDir)
    env.DeleteLocalRef(jOutPath)
    env.DeleteLocalRef(entries)
    env.DeleteLocalRef(buffer)
    envu.CallVoidMethod(zip, "close", "()V")
    env.DeleteLocalRef(zip)

    progress_callback("finished", processed, total, "")
end

function isAllowedUrl(url)
    for _, base in ipairs(wvWindow.windowUrls) do
        if string.sub(url, 1, #base) == base then
            return true
        end
    end
    return false
end

function showSwipeLeftHint()
    local m_pWidgets = jit.arch == "arm" and memory.getuint32(MONET_GTASA_BASE + 0x67947C) or memory.getuint64(MONET_GTASA_BASE + 0x850910)
    local widgetPtr = jit.arch == "arm64" and memory.getuint64(m_pWidgets + WIDGET_RADAR * 8) or memory.getuint32(m_pWidgets + WIDGET_RADAR * 4)
    
    while widgetPtr == 0 do widgetPtr = jit.arch == "arm64" and memory.getuint64(m_pWidgets + WIDGET_RADAR * 8) or memory.getuint32(m_pWidgets + WIDGET_RADAR * 4) wait(0) end
    while not (memory.getuint8(widgetPtr + (jit.arch == "arm" and 78 or 90)) == 1) do wait(0) end

    local x1 = memory.getfloat(widgetPtr + (jit.arch == "arm" and 32 or 44))
    local x2 = memory.getfloat(widgetPtr + (jit.arch == "arm" and 40 or 52))
    local y1 = memory.getfloat(widgetPtr + (jit.arch == "arm" and 44 or 56))
    local y2 = memory.getfloat(widgetPtr + (jit.arch == "arm" and 36 or 48))
    local w, h = x2 - x1, y2 - y1

    local cy = y1 + h / 2
    local rightX = x1 + w - 10
    local leftX = x1 + 10
    local color = 0xFFFF0000
    local bgColor = 0x99000000

    local arrowSize = 60

    local font = renderCreateFont("Arial", 15, 6)
    local line1 = "Swipe left on map"
    local line2 = "to open mods menu"
    local w1 = renderGetFontDrawTextLength(font, line1)
    local w2 = renderGetFontDrawTextLength(font, line2)

    local totalDuration = 9
    local sweepDuration = 3
    local startTime = os.clock()

    while os.clock() - startTime < totalDuration do
        local elapsed = os.clock() - startTime
        local sweepT = (elapsed % sweepDuration) / sweepDuration
        local arrowX = rightX - (rightX - leftX) * sweepT

        renderDrawBox(x1, y1, w, h, bgColor)

        renderDrawLine(arrowX + arrowSize * 0.6, cy, arrowX + arrowSize * 1.5, cy, arrowSize * 0.4, color)
        renderDrawPolygon(arrowX + arrowSize * 0.27, cy - arrowSize * 0.5, arrowSize, arrowSize, 3, 180.0, color)

        renderFontDrawText(font, line1, x1 + w / 2 - w1 / 2, cy + 20, color)
        renderFontDrawText(font, line2, x1 + w / 2 - w2 / 2, cy + 40, color)

        wait(0)
    end
end