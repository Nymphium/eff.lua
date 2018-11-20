local eff = require('eff')
local Eff, perform, handler = eff.Eff, eff.perform, eff.handler

local Write = Eff("Write")

local test = function()
  local x = perform(Write("hello"))
  return x
end

local printh = handler(Write,
function(v) print("printh ended", v) end,
function(arg, k)
  print(arg)
  k()
end)

printh(test)

local revh = handler(Write,
function(v) print("revh ended", v) end,
function(arg, k)
  print(arg:reverse())
  k()
end)

printh(function()
  perform(Write("hello"))

  revh(function()
    perform(Write("World"))
  end)
end)

--[[
-- failed to run continuation twice

handler(Write,
function(v) print("printh ended", v) end,
function(arg, k)
  print(arg)
  k()
  k()
end)(function()
  perform(Write("Foo"))
end)

--]]
