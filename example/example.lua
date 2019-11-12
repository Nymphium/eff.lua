local eff = require('eff')
local inst, perform, handler = eff.inst, eff.perform, eff.handler

local Write = inst()

local test = function()
  local x = perform(Write("hello"))
  return x
end

local printh = handler{
  val = function(v) print("printh ended", v) end,
  [Write] = function(k, arg)
    print(arg)
    k()
  end
}

printh(test)

local revh = handler {
  val = function(v) print("revh ended", v) end,
  [Write] = function(k, arg)
    print(arg:reverse())
    k()
  end }

local Choice = inst()

local choiceh = handler {
  val = function(v) return v end,
  [Choice] = function(k, l, _)
    k(l)
  end }

local Any = inst()

local anyh = handler {
  val = function(v) print("anyh ended", v) return v end,
  [Any] = function(k) return k() end }

choiceh(function()
  anyh(function()
    return revh(function()
      local lr = perform(Choice("left", "right"))
      perform(Any())
      local lr_ = perform(Choice("one", "two"))
      perform(Write(lr))
      printh(function() perform(Write(lr_)) end)
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
