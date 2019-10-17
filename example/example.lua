local eff = require('src/eff')
local inst, perform, handle, Return, run = eff.inst, eff.perform, eff.handle, eff.Return, eff.run

local Write = inst()

local test = function()
  local x = perform(Write, "hello")
  return Return(x)
end

local printh = {
  val = function(v) print("printh ended", v); return v end,
  [Write] = function(arg, k)
    print(arg)
    return k()
  end
}

handle(printh, test)

local revh = {
  val = function(v) print("revh ended", v); return v end,
  [Write] = function(arg, k)
    print(arg:reverse())
    return k()
  end
}

local Choice = inst()

local choiceh = {
  val = function(v) return v end,
  [Choice] = function(lst, k)
    return k(lst[1])
  end }

local Any = inst()

local anyh = {
  val = function(v) print("anyh ended", v) return v end,
  [Any] = function(_, k) return k() end
}

handle(choiceh, function()
  return handle(anyh, function()
    return handle(revh, function()
      local lr = perform(Choice, {"left", "right"})
      perform(Any, nil)
      local lr_ = perform(Choice, {"one", "two"})
      perform(Write, lr)
      return handle(printh, function() perform(Write, lr_); return Return() end)
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
