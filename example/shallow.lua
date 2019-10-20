local eff = require('src/eff')
local inst, perform, handler
inst = eff.inst
perform = eff.perform
handler = eff.shallow_handler

local E = inst()
local EE = inst()

local id = function(x) return x end

local h = handler {
  val = id,
  [E] = function(v, k)
    io.write(v)
    return k()
  end
}

local h2 = handler {
  val = id,
  [EE] = function(v, k)
    print(v)
    return k()
  end
}

local hthrow = handler {
  val = id
}

h2(function()
  hthrow(function()
    h(function()
      perform(E, "hello")
      io.write(", ")
      perform(EE, "world")
    end)
  end)
end)

local Yield = inst()
local Await = inst()

local pipe, copipe

pipe = function(p, c)
  return handler {
    val = id,
    [Await] = function(_, r)
      return copipe(r, p)
    end
  }(c)
end

copipe = function(c, p)
  return handler {
    val = id,
    [Yield] = function(p, r)
      return pipe(r, function() return c(p) end)
    end
  }(p)
end

local function ones()
  perform(Yield, 1)
  return ones()
end

print(pipe(ones, function() return perform(Await) end))
