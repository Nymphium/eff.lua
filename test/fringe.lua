-- https://github.com/ocamllabs/ocaml-effects-tutorial/blob/master/sources/solved/fringe.ml

local eff = require('src/eff')
local inst, perform, handler = eff.inst, eff.perform, eff.handler

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

local Leaf = function(a)
  return {a, cls = "Leaf"}
end

local Node = function(l, r)
  return {l, r, cls = "Node"}
end

local function iter(r, f)
  if r.cls == "Leaf" then
    return f(r[1])
  elseif r.cls == "Node" then
    iter(r[1], f)
    iter(r[2], f)
  end
end

local same_fringe = function(t1, t2)
  local gen_tree = function(c) return generate(iter, c) end
  local g1 = gen_tree(t1)
  local g2 = gen_tree(t2)
  local function loop()
    local r1, r2 = g1(), g2()
    if r1 and r2 and r1 == r2 then
      return loop()
    else
      -- nil, nil        -> true
      -- _, nil | nil, _ -> false
      return not (r1 or r2)
    end
  end

  return loop()
end

local t1 = Node(Leaf(1), Node(Leaf(2), Leaf(3)))
local t2 = Node(Node(Leaf(1), Leaf(2)), Leaf((3)))
local t3 = Node(Node(Leaf(3), Leaf(1)), Leaf((1)))
local t7 = Node(Leaf(1), Node(Leaf(2), Leaf(3)))

assert(same_fringe(t1, t2))
assert(same_fringe(t2, t1))
assert(not same_fringe(t1, t3))
assert(same_fringe(t1, t7))
assert(same_fringe(t2, t7))

