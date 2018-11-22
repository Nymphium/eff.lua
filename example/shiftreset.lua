local eff = require("eff")
local Eff, perform, handler = eff.Eff, eff.perform, eff.handler

local inspect = require("inspect")

local sr
do
  local new_prompt = function()
    local Shift0 = Eff("Shift0")

    return {
      take = function(f) return perform(Shift0(f)) end,
      push = handler(Shift0,
        function(v) return v end,
        function(k, f)
          return f(k)
        end)
    }
  end

  local reset_at = function(p, th)
    return p.push(th)
  end

  local shift0_at = function(p, f)
    return p.take(function(k) return f(k) end)
  end

  sr = {
    new_prompt = new_prompt,
    reset_at = reset_at,
    shift0_at = shift0_at
  }
end

local p = sr.new_prompt()

sr.reset_at(p, function()
  print(sr.shift0_at(p, function(k)
     k("Hello")
     print("?")
  end))

  io.write("World")
end)


local cons = function(e, t)
  local newt = table.move(t, 0, #t, 0, {})
  table.insert(newt, 1, e)
  return newt
end

local q = sr.new_prompt()
local t = sr.reset_at(q, function()
  local r = sr.reset_at(q, function()
    print("1")
    local r = sr.shift0_at(q, function(_)
      print("2")
      local r = sr.shift0_at(q, function(_)
        return {'e', 'l', 'l', 'o'}
      end)

      print("3")
      return r
    end)

    print("4")
    return r
  end)

  print("5")
  r = cons('h', r)

  return r
end)

print(table.concat(t))

print([[

----
]])

local promless
do
  local Shift0 = Eff("Shift0")

  local shift0 = function(f)
    return perform(Shift0(f))
  end

  local reset0 = handler(Shift0,
    function(v) return v end,
    function(k, f)
      return f(k)
    end)

  promless = {
    shift0 = shift0,
    reset0 = reset0
  }
end

local shift0 = promless.shift0
local reset0 = promless.reset0

local t_ = reset0(function()
  return reset0(function()
    return cons(3, shift0(function(_)
      return shift0(function(_)
        return {}
      end)
    end))
  end)
end)

print(inspect(t_))

