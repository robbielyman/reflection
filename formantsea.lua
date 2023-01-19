-- FormantSub based clocked Earthsea

FormantSub = include("lib/formantsub_engine")
Reflection = include("lib/reflection")
UI = require("ui")
Musicutil = require("musicutil")

local extensions = "/home/we/.local/share/SuperCollider/Extensions"
engine.name = util.file_exists(extensions .. "/FormantTriPTR/FormantTriPTR.sc") and "FormantSub" or nil

local Grid = grid.connect()

MAX_NUM_VOICES = 16

function init()
  Num_Voices = 0
  Needs_Restart = false
  local formanttri_files = {"FormantTriPTR.sc", "FormantTriPTR_scsynth.so"}
  for _,file in pairs(formanttri_files) do
    if not util.file_exists(extensions .. "/FormantTriPTR/" .. file) then
      util.os_capture("mkdir " .. extensions .. "/FormantTriPTR")
      util.os_capture("cp " .. norns.state.path .. "/ignore/" .. file .. " " .. extensions .. "/FormantTriPTR/" .. file)
      print("installed " .. file)
      Needs_Restart = true
    end
  end
  Restart_Message = UI.Message.new{"please restart norns"}
  Grid.key = grid_key
  Narcissus = Reflection.new()
  Narcissus.process = grid_note
  Narcissus.end_callback = stop_all_notes

  params:add{
    type      = "number",
    id        = "rec_dur",
    name      = "rec duration (in beats)",
    min       = 0,
    max       = 300,
    default   = 0,
    formatter = function(param) if param:get() == 0 then return 'free' else return param:get() end end
  }
  
  params:add{
    type    = "option",
    id      = "enc2",
    name    = "enc2",
    options = {"slope", "formant", "noise", "cut"}
  }
  params:add{
    type    = "option",
    id      = "enc3",
    name    = "enc3",
    options = {"slope", "formant", "noise", "cut"},
    default = 2
  }
  params:add_separator("FormantSub")
  if engine.name ~= "None" then
    FormantSub.params()
    engine.stopAll()
    params:bang()
  end
  Refresh_Metro = metro.init()
  Refresh_Metro.event = function()
    redraw()
    grid_redraw()
  end
  Refresh_Metro:start(1/15)
  GridDirty = true
  GridRedraw_Metro = metro.init()
  GridRedraw_Metro.event = function()
    if GridDirty then
      grid_redraw()
      GridDirty = false
    end
  end
  GridRedraw_Metro:start(1/60)
  Grid_Presses = {}
  for i = 1, 16 do
    Grid_Presses[i] = {}
  end
end

function toggle_record()
  Narcissus:set_rec(Narcissus.rec == 0 and 1 or 0, 5)
  if Narcissus.rec == 1 and Narcissus.endpoint == 0 then
    Narcissus:start()
  end
end

function grid_key(x, y, z)
  if x == 1 then
    if z == 1 then
      if y == 1 then
        Narcissus:set_rec(Narcissus.rec == 0 and 1 or 0, params:get('rec_dur') ~= 0 and params:get('rec_dur') or nil)
      elseif y == 2 then
        if grid_alt and Narcissus.count > 0 then
          Narcissus:clear()
          stop_all_notes()
        else
          if Narcissus.play == 0 then
            if Narcissus.endpoint == 0 then
              Narcissus:set_rec(1)
            else
              Narcissus:start()
            end
          else
            Narcissus:stop()
          end
        end
      elseif y == 3 then
        Narcissus:set_loop(Narcissus.loop == 0 and 1 or 0)
      elseif y == 4 then -- queue recording
        Narcissus:set_rec(2,params:get('rec_dur') ~= 0 and params:get('rec_dur') or nil)
      end
    end
    if y == 8 then
      grid_alt = z == 1 and true or false
    end
  else
    local event = {
      id = x + y * 16,
      x = x,
      y = y,
      z = z
    }
    Narcissus:watch(event)
    grid_note(event)
    Grid_Presses[x][y] = z
  end
  GridDirty = true
end

function grid_note(event)
  local note = ((10 - event.y)*5) + event.x + 30
  if event.z == 1 then
    if Num_Voices < MAX_NUM_VOICES then
      start_note(event.id, note)
      Grid_Presses[event.x][event.y] = event.z
      Num_Voices = Num_Voices + 1
    end
  else
    engine.stop(event.id)
    Grid_Presses[event.x][event.y] = event.z
    Num_Voices = Num_Voices - 1
  end
  GridDirty = true
end

function start_note(id, note)
  engine.start(id, Musicutil.note_num_to_freq(note))
end

function stop_all_notes()
  for i = 1,16 do
    Grid_Presses[i] = {}
  end
  engine.stopAll()
end

function grid_redraw()
  Grid:all(0)
  Grid:led(1,1,Narcissus.rec == 0 and 0 or 10)
  if Narcissus.count == 0 then
    Grid:led(1,2,Narcissus.play == 0 and 0 or 10)
  else
    Grid:led(1,2,Narcissus.play == 0 and 5 or 10)
  end
  Grid:led(1,3,Narcissus.loop == 0 and 0 or 10)
  Grid:led(1,4,Narcissus.queued_rec == nil and 0 or 10)
  Grid:led(1,8,grid_alt and 10 or 3)

  for i = 1, 16 do
    for j = 1,8 do
      if Grid_Presses[i][j] == 1 then
        Grid:led(i,j,15)
      end
    end
  end
  Grid:refresh()
end

function redraw()
  screen.clear()
  if Needs_Restart then
    Restart_Message:redraw()
  end
  screen.update()
end

function cleanup()
  Narcissus:stop()
  Narcissus = nil
end
