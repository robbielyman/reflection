-- formantsub

local controlspec = require("controlspec")

local formantsub = {}

function formantsub.params()
    -- synth
    params:add{
        type    = "control",
        id      = "slope",
        name    = "slope",
        controlspec = controlspec.new(0, 1, "lin", 0, 0.5, ""),
        action  = engine.slope
    }
    params:add{
        type    = "control",
        id      = "formant",
        name    = "formant",
        controlspec = controlspec.new(50, 1000, "exp", 0, 400, "Hz"),
        action  = engine.formant
    }
    params:add{
        type    = "control",
        id      = "hz_to_formant",
        name    = "pitch > formant",
        controlspec = controlspec.new(0, 100, "lin", 0, 100, "%"),
        action  = function(x)
            engine.hzToFormant(x/100)
        end
    }
    params:add{
        type    = "control",
        id      = "sub",
        name    = "sub",
        controlspec = controlspec.new(0, 1, "lin", 0, 0.4, ""),
        action  = engine.sub
    }
    params:add{
        type    = "control",
        id      = "noise",
        name    = "noise",
        controlspec = controlspec.new(0, 1, "lin", 0, 0, ""),
        action  = engine.noise
    }
    params:add{
        type    = "control",
        id      = "detune",
        name    = "detune",
        controlspec = controlspec.new(0, 1, "lin", 0, 0, ""),
        action  = engine.detune
    }
    params:add{
        type    = "control",
        id      = "width",
        name    = "stereo width",
        controlspec = controlspec.new(0, 1, "lin", 0, 0.5, ""),
        action  = engine.width
    }
    params:add{
        type    = "control",
        id      = "hzLag",
        name    = "pitch lag",
        controlspec = controlspec.new(0, 1, "lin", 0, 0.1, ""),
        action  = engine.hzLag
    }
    -- filter
    params:add{
        type    = "control",
        id      = "fgain",
        name    = "filter gain",
        controlspec = controlspec.new(0, 4, "lin", 0, 0, ""),
        action  = engine.fgain
    }
    params:add{
        type    = "control",
        id      = "cut",
        name    = "cut",
        controlspec = controlspec.new(0, 32, "lin", 0, 8, ""),
        action  = engine.cut
    }
    params:add{
        type    = "control",
        id      = "cutenvamt",
        name    = "cut env amt",
        controlspec = controlspec.new(0, 1, "lin", 0, 0, ""),
        action  = engine.cutEnvAmt
    }
    params:add{
        type    = "control",
        id      = "cutatk",
        name    = "cut attack",
        controlspec = controlspec.new(0.01, 10, "lin", 0, 0.05, ""),
        action  = engine.cutAtk
    }
    params:add{
        type    = "control",
        id      = "cutdec",
        name    = "cut decay",
        controlspec = controlspec.new(0, 2, "lin", 0, 0.1, ""),
        action  = engine.cutDec
    }
    params:add{
        type    = "control",
        id      = "cutsus",
        name    = "cut sustain",
        controlspec = controlspec.new(0, 1, "lin", 0, 0.9, ""),
        action  = engine.cutSus
    }
    params:add{
        type    = "control",
        id      = "cutrel",
        name    = "cut release",
        controlspec = controlspec.new(0.01, 10, "lin", 0, 1, ""),
        action  = engine.cutRel
    }
    -- amp
    params:add{
        type    = "control",
        id      = "level",
        name    = "level",
        controlspec = controlspec.new(0, 1, "lin", 0, 0.15, ""),
        action  = engine.level
    }
    params:add{
        type    = "control",
        id      = "ampatk",
        name    = "amp attack",
        controlspec = controlspec.new(0.01, 10, "lin", 0, 0.5, ""),
        action  = engine.ampAtk
    }
    params:add{
        type    = "control",
        id      = "ampdec",
        name    = "amp decay",
        controlspec = controlspec.new(0, 2, "lin", 0, 0.1, ""),
        action  = engine.ampDec
    }
    params:add{
        type    = "control",
        id      = "ampsus",
        name    = "amp sustain",
        controlspec = controlspec.new(0, 1, "lin", 0, 0.9, ""),
        action  = engine.ampSus
    }
    params:add{
        type    = "control",
        id      = "amprel",
        name    = "amp release",
        controlspec = controlspec.new(0.01, 10, "lin", 0, 1, ""),
        action  = engine.ampRel
    }
end

return formantsub
