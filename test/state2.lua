-- https://github.com/ocamllabs/ocaml-effects-tutorial/blob/master/sources/solved/state2.ml

local eff = require('src/eff')
local inst, perform, handler = eff.inst, eff.perform, eff.handler

local imut
do
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

local State = function()
  local Get = inst()
  local get = function()
    return perform(Get)
  end
  local Put = inst()
  local put = function(v)
    return perform(Put, v)
  end
  local History = inst()
  local history = function()
    return perform(History)
  end

  local run = function(f, init)
    local comp = handler{
      val = function() return function() end end,
      [Get] = function(_, k)
        return function(s, h)
          return k(s)(s, h)
        end
      end,
      [Put] = function(s_, k)
        return function(_, h)
          return k()(s_, imut.cons(s_, h))
        end
      end,
      [History] = function(_, k)
        return function(s, h)
            return k(imut.rev(h))(s, imut.cp(h))
          end
      end
    }

    return comp(f)(init, {})
  end

  return {
    run = run,
    get = get,
    put = put,
    history = history
  }
end

local is = State()
local ss = State()

local foo = function()
  assert(0 == is.get())
  is.put(42)
  print(is.get())
  assert(42 == is.get())
  is.put(21)
  print(is.get())
  ss.put("Hello")
  assert("Hello" == ss.get())
  assert(21 == is.get())
  ss.put("world")
  is.get()

  local t = {42, 21}
  local hs = is.history()

  for i = 1, #hs do
    assert(t[i], hs[i])
  end
end

is.run(function() return ss.run(foo, "") end, 0)

-- ss.run(function()
  -- is.run(foo, 0)
-- end, "")

