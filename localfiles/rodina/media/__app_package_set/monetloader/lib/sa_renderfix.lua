-- Copyright (c) MonetLoader, 2023
-- Built-in library: sa_renderfix
-- Lua package is distributed under the MIT license

--[[

    SA Render Fix: Fixes WarDrum changes (yes, CorrectAspect, i'm looking at you)
    On MoonLoader modifies setTextScale for same look on WarDrum shitty render and PC

    Changed functions in MonetLoader:
    getStringWidth
    drawSprite
    drawSpriteWithRotation
    drawRect
    setTextScale
    displayText
    displayTextWithNumberFixed
    displayTextWith2NumbersFixed
    displayTextWithFloatFixed
    displayTextClamped
    displayTextWithNumberClamped

    Changed functions in MoonLoader:
    setTextScale
]]--

local is_monet = MONET_VERSION ~= nil

if is_monet then
  local sw, sh = getScreenResolution()
  local function toScreenW(w)
    return sw - (640 - w) * (sw / 640)
  end
  local function toScreenH(h)
    return sh - (448 - h) * (sh / 448)
  end

  local function fixX(x, forRect)
    -- Thx WolframAlpha
    if forRect then
      return (480 * toScreenW(x) - 240 * sw + 320 * sh) / sh
    else
      return ((0.75 * x - 240) * sw) / sh + 320
    end
  end

  local function fixY(y)
    return (448 * toScreenH(y)) / sh
  end

  local function fixW(w)
    return (480 * toScreenW(w)) / sh
  end

  local function fixH(h)
    return fixY(h)
  end


  local old_getStringWidth = getStringWidth
  local function getStringWidthFixed(gxtString)
    -- TBD: is 0.566 * scaleRatio + 1.11 valid function for division magic?
    return old_getStringWidth(gxtString) / 1.233 -- WTF was happening at WarDrum that they fucked up even this function?
  end
  _G.getStringWidth = getStringWidthFixed

  local old_drawSprite = drawSprite
  local function drawSpriteFixed(texture, positionX, positionY, width, height, r, g, b, a)
    return old_drawSprite(texture, fixX(positionX, true), fixY(positionY), fixW(width), fixH(height), r, g, b, a)
  end
  _G.drawSprite = drawSpriteFixed

  local old_drawSpriteWithRotation = drawSpriteWithRotation
  local function drawSpriteWithRotationFixed(texture, positionX, positionY, width, height, angle, r, g, b, a)
    return old_drawSpriteWithRotation(texture, fixX(positionX, true), fixY(positionY), fixW(width), fixH(height), angle, r, g, b, a)
  end
  _G.drawSpriteWithRotation = drawSpriteWithRotationFixed

  local old_drawRect = drawRect
  local function drawRectFixed(positionX, positionY, width, height, r, g, b, a)
    return old_drawRect(fixX(positionX, true), fixY(positionY), fixW(width), fixH(height), r, g, b, a)
  end
  _G.drawRect = drawRectFixed

  local old_displayText = displayText
  local function displayTextFixed(posX, posY, gxtString)
    return old_displayText(fixX(posX, false), posY, gxtString)
  end
  _G.displayText = displayTextFixed

  local old_displayTextWithNumber = displayTextWithNumber
  local function displayTextWithNumberFixed(posX, posY, gxtString, number)
    return old_displayTextWithNumber(fixX(posX, false), posY, gxtString, number)
  end
  _G.displayTextWithNumber = displayTextWithNumberFixed

  local old_displayTextWith2Numbers = displayTextWith2Numbers
  local function displayTextWith2NumbersFixed(posX, posY, gxtString, numbersX, numbersY)
    return old_displayTextWith2Numbers(fixX(posX, false), posY, gxtString, numbersX, numbersY)
  end
  _G.displayTextWith2Numbers = displayTextWith2NumbersFixed

  local old_displayTextWithFloat = displayTextWithFloat
  local function displayTextWithFloatFixed(posX, posY, gxtString, value, flag)
    return old_displayTextWithFloat(fixX(posX, false), posY, gxtString, value, flag)
  end
  _G.displayTextWithFloat = displayTextWithFloatFixed

  local old_displayTextClamped = displayTextClamped
  local function displayTextClampedFixed(posX, posY, gxtString, scale)
    return old_displayTextClamped(fixX(posX, false), posY, gxtString, scale)
  end
  _G.displayTextClamped = displayTextClampedFixed

  local old_displayTextWithNumberClamped = displayTextWithNumberClamped
  local function displayTextWithNumberClampedFixed(posX, posY, gxtString, number, scale)
    return old_displayTextWithNumberClamped(fixX(posX, false), posY, gxtString, number, scale)
  end
  _G.displayTextWithNumberClamped = displayTextWithNumberClampedFixed
end

local old_setTextScale = setTextScale
local function setTextScaleFixed(scaleX, scaleY)
  return old_setTextScale(scaleY * 0.22, scaleY)
end
_G.setTextScale = setTextScaleFixed


return nil