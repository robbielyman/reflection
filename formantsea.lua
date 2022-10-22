-- FormantSub based clocked Earthsea

local FormantSub = include("lib/formantsub_engine")
local Reflection = include("lib/reflection")
local UI = require("ui")
local musicutil = require("musicutil")

engine.name = "FormantSub"

local Grid = grid.connect()

MAX_NUM_VOICES = 16

function init()
    Needs_Restart = false
    if not util.file_exists(_path.code .. "/lamination/lamination.lua")
        and not util.file_exists(norns.state.path .. "/bin/FormantTriPTR/FormantTriPTR.sc") then
        util.os_capture("cp " .. norns.state.path .. "/ignore/FormantTriPTR/FormantTriPTR.sc " .. norns.state.path .. "/bin/FormantTriPTR/FormantTriPTR.sc")
        Needs_Restart = true
    end
    if not util.file_exists("/home/we/.local/share/SuperCollider/Extensions/FormantTriPTR/FormantTriPTR_scsynth.so") then
        util.os_capture("mkdir /home/we/.local/share/SuperCollider/Extensions/FormantTriPTR")
        util.os_capture("cp " .. norns.state.path .. "/bin/FormantTriPTR/FormantTriPTR_scsynth.so /home/we/.local/share/SuperCollider/Extensions/FormantTriPTR/FormantTriPTR_scsynth.so")
        Needs_Restart = true
    end
    Restart_Message = UI.Message.new{"please restart norns"}
    Grid.key = grid_key
    Narcissus = Reflection.new()
    Narcissus.process = grid_note

    params:add{
        type    = "option",
        id      = "enc2",
        name    = "enc2",
        options = {"slope, formant, noise, cut"}
    }
    params:add{
        type    = "option",
        id      = "enc3",
        name    = "enc3",
        options = {"slope, formant, noise, cut"},
        default = 2
    }
    params:add_separator("FormantSub")
    FormantSub.params()
    params:add{
        type    = "option",
        id      = "output",
        name    = "output",
        options = {"audio", "crow out 1+2", "crow ii JF"},
        action  = function(x)
            engine.stopAll()
            if x == 2 then crow.output[2].action = "{to(5,0),to(0,0.25)}"
            elseif x == 3 then
                crow.ii.pullup(true)
                crow.ii.jf.mode(1)
            end
        end
    }
    engine.stopAll()
    params:bang()
    Refresh_Metro = metro.init()
    Refresh_Metro.event = function()
        redraw()
        grid_redraw()
    end
    Refresh_Metro:start(1/15)
    Grid_Presses = {}
    for i = 1, 16 do
        Grid_Presses[i] = {}
    end
end

function grid_key(x, y, z)
    if x == 1 then
        if z == 1 then
            if y == 1 then
                Narcissus:set_rec(Narcissus.rec == 0 and 1 or 0)
                if Narcissus.rec == 1 and Narcissus.endpoint == 0 then
                    Narcissus:start()
                end
            elseif y == 2 then
                if Narcissus.play == 0 then
                    if Narcissus.endpoint == 0 then
                        Narcissus:set_rec(1)
                        Narcissus:start()
                    else
                        Narcissus:start()
                    end
                else
                    Narcissus:stop()
                end
            elseif y == 3 then
                Narcissus:set_loop(Narcissus.loop == 0 and 1 or 0)
            end
        end
    else
        local event = {
            id = x * 16 + y,
            x = x,
            y = y,
            z = z
        }
        Narcissus:watch(event)
        grid_note(event)
    end
    Grid_Presses[x][y] = z
end

function grid_note(event)
    local note = ((7 - event.y)*5) + event.x
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
end

function start_note(id, note)
    if params:get("output") == 1 then
        engine.start(id, musicutil.note_num_to_freq(note))
    elseif params:get("output") == 2  then
        crow.output[1].volts = note/12
        crow.output[2].execute()
    elseif params:get("output") == 3 then
        crow.ii.jf.play_note(note/12,5)
    end
end

function grid_redraw()
    Grid:all(0)
    Grid:led(1,1,Narcissus.rec == 0 and 0 or 10)
    Grid:led(1,2,Narcissus.play == 0 and 0 or 10)
    Grid:led(1,3,Narcissus.loop == 0 and 0 or 10)

    for i = 1, 16 do
        for j = 1,8 do
            if Grid_Presses[i][j] == 1 then
                Grid:led(i,j)
            end
        end
    end
end

function redraw()
    if Needs_Restart then
        Restart_Message:redraw()
    end
end

function cleanup()
    Narcissus:stop()
    Narcissus = nil
end
