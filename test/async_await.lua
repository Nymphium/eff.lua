-- https://github.com/ocamllabs/ocaml-effects-tutorial/blob/master/sources/solved/async_await.ml

local eff = require('src/eff')
local inst, perform, handle, Return, effrun = eff.inst, eff.perform, eff.handle, eff.Return, eff.run

local imut do
  table.move = table.move
  or function(src, from, to, on, dst)
    for  i = from, to do
      dst[i + on - 1] = src[i]
    end

    return dst
  end

  local cp = function(t)
    return table.move(t, 1, #t, 1, {})
  end

  local cons = function(e, t)
    local ret = cp(t)
    table.insert(ret, e)
    return ret
  end

  local rev = function(t)
    local ret = {}

    for i = #t, 1, -1 do
      table.insert(ret, t[i])
    end

    return ret
  end

  imut = {
    cp = cp,
    cons = cons,
    rev = rev
  }
end

local ref do
  local newref = function()
    return setmetatable({
      content = nil,
      get = function(self)
        return self.content
      end
    }, {
      __call = function(self, v)
        self.content = v
        return self
      end,
      __bnot = function(self)
        return self.content
      end})
  end

  ref = function(v) return newref()(v) end
end

local Waiting = function(conts)
  return { conts, cls =  "waiting" }
end

local Done = function(a)
  return { a, cls = "done" }
end


local Async = inst()
local async = function(f)
  return perform(Async, f)
end

local Yield = inst()
local yield = function()
  return perform(Yield, nil)
end

local Await = inst()
local await = function(p)
  return effrun(perform(Await, p))
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
    local h = {
      val = function(v)
        local pp = ~pr
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
      [Async] = function(v, k)
        local pr_ = ref(Waiting{})
        enqueue(function() return k(pr_) end)
        return fork(pr_, v)
      end,
      [Yield] = function(_, k)
        enqueue(function() return k() end)
        return dequeue()
      end,
      [Await] = function(p, k)
        local pp = ~p

        if pp.cls == "done" then
          return k(pp[1])
        elseif pp.cls == "waiting" then
          p(Waiting(imut.cons(k, pp[1])))
          return dequeue()
        end
      end
    }

    return handle(h, main)
  end

  return fork(ref(Waiting{}), main)
end

local main = function()
  local task = function(name)
    return function()
      print(("Starting %s"):format(name))
      local v = math.random(100)
      print(("Yielding %s"):format(name))
      yield()
      print(("Ending %s with %d"):format(name, v))
      return Return(v)
    end
  end

  local pa = async(task "a")
  local pb = async(task "b")
  local pc = async(function()
    return Return(await(pa) + await(pb))
  end)

  print(("sum is %d"):format(await(pc)))
  assert(await(pa) + await(pb) == await(pc))

  return Return()
end

run(main)

