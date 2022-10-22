--- clocked pattern recorder library
-- @module lib.reflection

local reflection = {}
reflection.__index = reflection

--- constructor
function reflection.new()
    local p = {}
    setmetatable(p, reflection)
    p.rec   = 0
    p.play  = 0
    p.event = {}
    p.time  = {}
    p.step  = 0
    p.loop = 0
    -- p.time_factor = 1
    p.clock = nil
    p.quantize = 1/48
    p.endpoint = 0
    p.start_callback = function() end
    p.end_callback = function() end
    p.process = function(_) end
    return p
end

--- start transport
function reflection:start()
    if self.clock then
        clock.cancel(self.clock)
    end
    self.clock = clock.run(function()
        clock.sync(self.quantize)
        self:begin_playback()
    end)
end

--- stop transport
function reflection:stop()
    if self.clock then
        clock.cancel(self.clock)
    end
    self.clock = clock.run(function()
        clock.sync(self.quantize)
        self:end_playback()
    end)
end

--- enable / disable record head
-- @tparam number rec 1 for recording or 0 for not recording
function reflection:set_rec(rec)
    self.rec = rec == 0 and 0 or 1
end

--- enable / disable looping
-- (has no effect on first run)
-- @tparam number loop 1 for looping or 0 for not looping
function reflection:set_loop(loop)
    self.loop = loop == 0 and 0 or 1
end

--- quantize playback
-- @tparam float q defaults to 1/48
-- (should be at least 1/96)
function reflection:set_quantization(q)
    self.quantize = q == nil and 1/48 or q
end

-- --- set time factor
-- -- @tparam float f time factor (positive)
-- function reflection:set_time_factor(f)
--     self.time_factor = f == nil and 1 or f
-- end

--- reset
function reflection:clear()
    if self.clock then
        clock.cancel(self.clock)
    end
    self.rec    = 0
    self.play   = 0
    self.event  = {}
    self.time   = {}
    self.step   = 0
    -- self.time_factor = 1
    self.quantize = 1/48
    self.endpoint = 0
end

--- watch
function reflection:watch(event)
    if self.rec == 1 and self.play == 1 then
        local s = math.floor(self.step)
        if not self.event[s] then
            self.event[s] = {}
        end
        table.insert(self.event[s], event)
    end
end

function reflection:begin_playback()
    if self.clock then
        clock.cancel(self.clock)
    end
    self.step = 0
    self.play = 1
    self.clock = clock.run(function()
        while self.play == 1 do
            clock.sync(1/96)
            if self.step == 0 then
                self.start_callback()
            end
            self.step = self.step + 1
            local q = math.floor(96 * self.quantize)
            if self.step % q == 1 then
                for i = q - 1, 0, - 1 do
                    if self.event[self.step - i] and next(self.event[self.step - i]) then
                        for j = 1, #self.event[self.step - i] do
                            self.process(self.event[self.step - i][j])
                        end
                    end
                end
                if self.endpoint ~= 0 and self.step >= self.endpoint then
                    if self.loop == 0 then
                        self:end_playback()
                    elseif self.loop == 1 then
                        self.step = self.step - self.endpoint
                    end
                end
            end
        end
    end)
end

function reflection:end_playback()
    if self.clock then
        clock.cancel(self.clock)
    end
    self.play = 0
    self.rec = 0
    if self.endpoint == 0 and next(self.event) then
        self.endpoint = self.step
    end
    self.end_callback()
end

return reflection
