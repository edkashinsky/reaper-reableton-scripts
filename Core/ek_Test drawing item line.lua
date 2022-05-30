local item = reaper.GetSelectedMediaItem(0, 0)

local red, green, blue = 240, 240, 180
local function RGB(r,g,b)
  return (((b)&0xFF)|(((g)&0xFF)<<8)|(((r)&0xFF)<<16)|(0xFF<<24))
end

local bm = reaper.JS_LICE_CreateBitmap(true, 1, 1)
reaper.JS_LICE_Clear(bm, RGB(red, green, blue))

local MainHwnd = reaper.GetMainHwnd()
local trackview = reaper.JS_Window_FindChildByID(MainHwnd, 0x3E8)


reaper.JS_Composite(trackview, 100, 50, 1, 100, bm, 0, 0, 1, 1, true)