local eff = require('eff')
local e = eff.inst()

local h = eff.shallow_handler(e,
                              function(v) return v + 3 end,
function(k, y) return k(y + 10000) end)

local _e = eff.inst()
local h_ = eff.shallow_handler(_e,
                               function(v) return v end,
                               function(k, v) return nil end
)

print(
    h(function()
      return h(function()
        return h_(function()
          print("hello,")
          eff.perform(e(0))
          return eff.perform(e(0))
        end)
      end)
    end))
