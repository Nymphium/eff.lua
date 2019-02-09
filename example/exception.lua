--[[
algebraic-exception for Lua
--]]

local exn
do
  local eff = require('eff')
  local Eff, perform, handlers = eff.Eff, eff.perform, eff.handlers

  local handlers_ = function(...)
    local effeffhs = {...}
    local hs = {}

    for i = 1, #effeffhs do
      local t = effeffhs[i]
      local eff, effh = t[1], t[2]

      hs[i] = {eff, function(...) return effh(nil, ...) end}
    end

    return handlers(function(...) return ... end, unpack(hs))
  end

  exn = { raise = perform
        , handlers = handlers_
        , Exception = Eff
        }
end

local DivideByZero = exn.Exception("DivideByZero")
local div_ = function(a, b)
  if b == 0 then
    return exn.raise(DivideByZero())
  else
    return a / b
  end
end

exn.handlers({DivideByZero, function() print("dividebyzero") end})(function()
  print("hello")
  print(div_(3, 0))
  print("world")
end)

