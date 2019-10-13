-- https://github.com/ocamllabs/ocaml-effects-tutorial/blob/master/sources/solved/generator.ml
local eff = require('src/eff')
local inst, perform, handler = eff.inst, eff.perform, eff.handler

--[[
iter : ('a table, 'a -> 'b) ->  ()
--]]
local Yield = inst()

local generate = function(iter, c)
  local step = { f = nil }
  step.f = function()
    iter(c, function(v) return perform(Yield, v) end)
    step.f = function()
      return
    end
  end

  return function()
    return handler(Yield,
      function(v) return v end,
      function(v, k)
        step.f = k
        return v
      end
      )(function()
        return step.f()
      end)
  end
end

local table_iter = function(xs, f)
  for _, x in ipairs(xs) do
    f(x)
  end
end

local gen_list = function(c) return generate(table_iter, c) end
local gl = gen_list {3, 5, 7}
assert(gl() == 3)
assert(gl() == 5)
assert(gl() == 7)
assert(gl() == nil)
assert(gl() == nil)

local function nats(v, f)
  return function()
    f(v)
    return nats(v + 1, f)()
  end
end

local inf = function(g)
  return function()
    local v = g()
    if v then
      return v
    else
      assert(false)
    end
  end
end

local gen_nats = inf(generate(function(_, f) return nats(0, f)() end, nil))

assert(gen_nats() == 0)
assert(gen_nats() == 1)
assert(gen_nats() == 2)
assert(gen_nats() == 3)


local function filter(g, p)
  return function()
    local v = g ()
    if p(v) then return v
    else return filter(g, p)()
    end
  end
end

local function map(g, f)
  return function()
    return f(g())
  end
end

local gen_even
do
  local nat_stream = inf(generate(function(_, f)
    return nats(0, f)()
  end))

  gen_even = filter(nat_stream, function(n) return n % 2 == 0 end)
end

assert(gen_even() == 0)
assert(gen_even() == 2)
assert(gen_even() == 4)
assert(gen_even() == 6)

local gen_odd
do
  local nat_stream = inf(generate(function(_, f) return nats(0, f)() end))

  gen_odd = filter(nat_stream, function(n) return n % 2 == 1 end)
end


assert(gen_odd() == 1)
assert(gen_odd() == 3)
assert(gen_odd() == 5)
assert(gen_odd() == 7)

local gen_primes
do
  local s = inf(generate(function(_, f) return nats(2, f)() end))
  local rs = {s = s}

  gen_primes = function()
    local prime = rs.s()
    rs.s = filter(rs.s, function(n) return n % prime ~= 0 end)
    return prime
  end
end

assert(gen_primes() == 2)
assert(gen_primes() == 3)
assert(gen_primes() == 5)
assert(gen_primes() == 7)
assert(gen_primes() == 11)
assert(gen_primes() == 13)
assert(gen_primes() == 17)
assert(gen_primes() == 19)
assert(gen_primes() == 23)
assert(gen_primes() == 29)
assert(gen_primes() == 31)

