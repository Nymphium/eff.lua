-- https://github.com/ocamllabs/ocaml-effects-tutorial/blob/master/sources/solved/fringe.ml

local eff = require('eff')
local Eff, perform, handler = eff.Eff, eff.perform, eff.handler

local imut
do
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
  local SEff = Eff("SEff")
  local get = function()
    return perform(SEff{ cls = "Get" })
  end
  local put = function(v)
    return perform(SEff{ v, cls = "Put" })
  end
  local history = function()
    return perform(SEff{ cls = "History" })
  end

  local run = function(f, init)
    local comp = handler(SEff,
    function() return function() end end,
    function(k, c)
      return function(s, h)
        if c.cls == "Get" then
          return k(s)(s, h)
        elseif c.cls == "Put" then
          local s_ = c[1]
          return k()(s_, imut.cons(s_, h))
        elseif c.cls == "History" then
          return k(imut.rev(h))(s, imut.cp(h))
        end
      end
    end)

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

