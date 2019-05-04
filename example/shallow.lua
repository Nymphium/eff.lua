local eff = require('eff')
local inst, perform, handler, shallow_handler = eff.inst, eff.perform, eff.handler, eff.shallow_handler

local Yield = inst()
local Await = inst()

local pipe, copipe
pipe = function(p, c)
  return shallow_handler(
      Await,
      function(v) return v end,
      function(k, a)
        return copipe(k, p)
      end
  )(c)
end

copipe = function(c, p)
  return shallow_handler(
      Yield,
      function(v) return v end,
      function(k, p)
        return pipe(k, function()
          return c(p)
        end)
      end
  )(p)
end

local function ones()
  perform(Yield(1))
  ones()
end

print(pipe(ones, function()
  return perform(Await())
end)) -- 1


local pipe_ = function(c)
  return handler(
      Await,
      function(x) return function()
        return x
      end end,
      function(r) return function(p)
        return p()(r)
      end end
  )(c)
end

local copipe_ = function(p)
  return handler(
      Yield,
      function(x) return function()
        return x
      end end,
      function(r, p) return function(c)
        return c(p)(r)
      end end
  )(p)
end

local runpipe = function(p, c)
  return pipe_(c)(function() return copipe_(p) end)
end

print(runpipe(ones, function() return perform(Await()) end))

