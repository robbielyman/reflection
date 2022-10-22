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
            Needs_Restart = true
        end
    end
    Restart_Message = UI.Message.new{"please restart norns"}
    Grid.key = grid_key
    Narcissus = Reflection.new()
    Narcissus.process = grid_note

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
    if engine.name then
        engine.stopAll()
    end
    params:bang()
    Refresh_Metro = metro.init()
    Refresh_Metro.event = grid_redraw
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
            id = x + y * 16,
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
end

function start_note(id, note)
    if params:get("output") == 1 then
        engine.start(id, Musicutil.note_num_to_freq(note))
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
                Grid:led(i,j,15)
            end
        end
    end
    Grid:refresh()
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
