local eff = require('eff')
local inst, perform, handler = eff.inst, eff.perform, eff.handler

local Pcall = inst()
local epcall = function(f, ...)
  return perform(Pcall(f, ...))
end

local pcallh = handler(Pcall,
  function(v) return v end,
  function(k, f, ...)
    local ok, content = pcall(f, ...)
    if ok then
      return k(content)
    else -- error
      return nil, content
    end
  end)

pcallh(function()
  local file = epcall(io.open, you_cannot_read, "r")
  for l in file:lines() do
    print(l)
  end

  file:close()
end)
