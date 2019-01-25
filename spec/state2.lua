-- https://github.com/ocamllabs/ocaml-effects-tutorial/blob/master/sources/solved/state2.ml

local eff = require('src/eff')
local Eff, perform, handler = eff.Eff, eff.perform, eff.handler

local imut = require('spec/utils/imut')

local State = function()
  local State = Eff("State")
  local get = function()
    return perform(State{ cls = "Get" })
  end
  local put = function(v)
    return perform(State{ v, cls = "Put" })
  end
  local history = function()
    return perform(State{ cls = "History" })
  end

  local run = function(f, init)
    local comp = handler(State,
    function() return function() end end,
    function(k, c)
      if c.cls == "Get" then
        return function(s, h)
          return k(s)(s, h)
        end
      elseif c.cls == "Put" then
        return function(_, h)
          local s_ = c[1]
          return k()(s_, imut.cons(s_, h))
        end
      elseif c.cls == "History" then
        return function(s, h)
          return k(imut.rev(h))(s, imut.cp(h))
        end
      end
    end)(f)

    return comp(init, {})
  end

  return {
    run = run,
    get = get,
    put = put,
    history = history
  }
end

insulate("state test", function()
  local is = State()
  local ss = State()

  spy.on(_G, "print")

  spy.on(is, "get")
  spy.on(is, "put")
  spy.on(ss, "get")
  spy.on(ss, "put")

  local sh, ih

  local main = function()
    print(is.get())
    is.put(42)
    print(ss.get())
    ss.put("Hello")
    print(is.get())
    ss.put("world")
    print(is.get())
    is.put(21)
    is.get()

    print(ss.get())

    sh = ss.history()
    ih = is.history()
  end

  describe("run", function()
    is.run(function() return ss.run(main, "") end, 0)

    it("check call", function()
      assert.spy(is.get).was_called(4)
      assert.spy(ss.get).was_called(2)

      for i = 1, #sh do
        assert.spy(ss.put).was_called_with(sh[i])
      end

      for i = 1, #ih do
        assert.spy(is.put).was_called_with(ih[i])
      end
    end)
  end)
end)

