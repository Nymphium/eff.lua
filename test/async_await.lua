-- https://github.com/ocamllabs/ocaml-effects-tutorial/blob/master/sources/solved/async_await.ml

local eff = require('src/eff')
local inst, perform, handler = eff.inst, eff.perform, eff.handler

local imut = require('spec/utils/imut')
local ref = require('spec/utils/ref')
local randoms = require('spec/utils/SEED')
randoms.init()

local Waiting = function(conts)
  return { conts, cls =  "waiting" }
end

local Done = function(a)
  return { a, cls = "done" }
end

local Eff = inst()

local async = function(f)
  return perform(Eff, { type = "async", f })
end

local yield = function()
  return perform(Eff, { type = "yield" })
end

local await = function(p)
  return perform(Eff, { type = "await", p })
end

-- queue
local q = {}
local enqueue = function(t)
  table.insert(q, t)
end

local dequeue = function()
  local f = table.remove(q, 1)
  if f then
    return f()
  end
end

local run = function(main)
  local function fork(pr, main)
    return handler(Eff,
      function(v)
        local pp = pr:get()
        local l

        if pp.cls == "waiting" then
          l = pp[1]
        else
          error("impossible")
        end

        for _, k in ipairs(l) do
          enqueue(function() return k(v) end)
        end

        pr(Done(v))
        return dequeue()
      end,
      function(v, k)
        if v.type == "async" then
          local pr_ = ref(Waiting{})
          enqueue(function() return k(pr_) end)
          return fork(pr_, v[1])
        elseif v.type == "yield" then
          enqueue(function() return k() end)
          return dequeue()
        elseif v.type == "await" then
          local p = v[1]
          local pp = p:get()

          if pp.cls == "done" then
            return k(pp[1])
          elseif pp.cls == "waiting" then
            p(Waiting(imut.cons(k, pp[1])))
            return dequeue()
          end
        end
      end)(main)
  end

  return fork(ref(Waiting{}), main)
end

insulate("async await test", function()
  randomize(false)

  spy.on(_G, "print")

  local main = function()
    local task = function(name)
      return function()
        print(("Starting %s"):format(name))
        local v = math.random(100)
        print(("Yielding %s"):format(name))
        yield()
        print(("Ending %s with %d"):format(name, v))
        return v
      end
    end

    local pa = async(task "a")

    local pb = async(task "b")
    local pc = async(function()
      return await(pa) + await(pb)
    end)

    print(("sum is %d"):format(await(pc)))
    assert(await(pa) + await(pb) == await(pc))
  end

  describe("run", function()
    run(main)

    it("check first resuming a", function()
      assert.spy(print).was_called_with("Starting a")
      assert.spy(print).was_called_with("Yielding a")
    end)

    it("check first resuming b", function()
      assert.spy(print).was_called_with("Starting b")
      assert.spy(print).was_called_with("Yielding b")
    end)

    it("check task return value", function()
      randoms.init()

      local v1 = math.random(100)
      local v2 = math.random(100)

      assert.spy(print).was_called_with(("Ending %s with %d"):format("a", v1))
      assert.spy(print).was_called_with(("Ending %s with %d"):format("b", v2))
      assert.spy(print).was_called_with(("sum is %d"):format(v1 + v2))
      assert.spy(print).was_called(7)
    end)
  end)
end)

