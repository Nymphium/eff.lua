local eff = require('eff')
local inst, perform, handler = eff.inst, eff.perform, eff.handler

local Fetch = inst()
local fetch = function(it) return perform(Fetch(it)) end

local Fallback = inst()

local fetchh = handler(Fetch,
  function(v) return v end,
  function(k, it)
    if it then
      return k(it)
    else
      return k(perform(Fallback()))
    end
  end)

local runfallback = function(default, th)
  return handler(Fallback,
    function(v) return v end,
    function(k)
      return k(default)
    end)(th)
end

local t = {1, 2, 3}
local u = {4, 5, 6}

local result = runfallback(0, function()
  return fetchh(function()
    local x = fetch(t[3])
    local y = fetch(u[4])
    return x + y
  end)
end)

print(result)
