local eff = require('eff')
local inst, perform, handler, shallow_handler = eff.inst, eff.perform, eff.handler, eff.shallow_handler

local Shift0 = inst()

local Reset0
Reset0 = shallow_handler {
  [Shift0] = function(k, f)
    return f(function(v)
      return Reset0(function() return k(v) end)
    end)
  end,
  val = function(v)
    return v
  end
}

Reset0(function()
  local _ = perform(Shift0(function(k1)
    local r1 = k1(10)
    local _ = k1(20)
    return r1
  end))
  return perform(Shift0(function(_)
    return 30
  end))
end)
