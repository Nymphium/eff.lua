local eff = require('src/eff')
local inst, perform, shallow_handler = eff.inst, eff.perform, eff.shallow_handler

local ref = require('spec/utils/ref')

local coroutine = {}

local Yield = inst()
coroutine.yield = function(...)
  return perform(Yield(...))
end

coroutine.resume = function(co, ...)
  local args = {...}

  return shallow_handler({
    val = function(...) return ... end,
    [Yield] = function(k, ...)
      co(k)
      return ...
    end
  })(function() return co.content(table.unpack(args)) end)
end

coroutine.create = function(th)
  return ref(th)
end

insulate("coroutine implemented with shallow handler", function()
  spy.on(_G, 'print')

  describe("coroutine", function()
    local co = coroutine.create(function()
      print("hello")
      print(coroutine.yield())
    end)

    coroutine.resume(co)
    coroutine.resume(co, "world")

    it("check 1", function()
      assert.spy(print).was_called_with("hello")
      assert.spy(print).was_called_with("world")
    end)
  end)
end)

