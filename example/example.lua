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

local Choice = Eff("Choice")

local choiceh = handler(Choice,
function(v) return v end,
function(k, l, _)
  k(l)
end)

local Any = Eff("Any")

local anyh = handler(Any,
  function(v) print(v) return v end,
  function(k) return k() end)


choiceh(function()
  anyh(function()
    return revh(function()
      local lr = perform(Choice("left", "right"))
      perform(Write(lr))
    end)
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
