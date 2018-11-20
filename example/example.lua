local eff = require('eff')
local Eff, perform, handler = eff.Eff, eff.perform, eff.handler

local Write = Eff("Write")

local test = function()
  local x = perform(Write("hello"))
  return x
end

local printh = handler(Write,
function(v) print("printh ended", v) end,
function(k, arg)
  print(arg)
  k()
end)

printh(test)

local revh = handler(Write,
function(v) print("revh ended", v) end,
function(k, arg)
  print(arg:reverse())
  k()
end)

local Amb = Eff("Amb")

local amblh = handler(Amb,
function(v) return v end,
function(k, l, _)
  k(l)
end)

amblh(function()
  local lr = perform(Amb("left", "right"))

  revh(function()
    perform(Write(lr))
  end)
end)

--[[
-- failed to run continuation twice

handler(Write,
function(v) print("printh ended", v) end,
function(k, arg)
  print(arg)
  k()
  k() -- call continuation twice
end)(function()
  perform(Write("Foo"))
end)

--]]
