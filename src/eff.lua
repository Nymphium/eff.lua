local Return = function(v)
  return { type = "Return",  x = v }
end

local Call = function(op, x, k)
  return { type = "Call", op = op, x = x, k = k }
end


local create = coroutine.create
local yield = coroutine.yield

local resume = function(co, arg)
  coroutine.current = co
  local st, r  = coroutine.resume(co, arg)
  if not st then
    return error(r)
  else
    return r
  end
end

local perform = function(eff, arg)
  local current = coroutine.current
  local continue = function(arg)
    return resume(current, arg)
  end
  return yield(Call(eff, arg, continue))
end

local handle do
  local function step(h, r)
    if r.type == "Return" then
      return h.val(r)
    elseif r.type == "Call" then
      local k = function(y)
        return step(h, r.k(y))
      end

      local effh = h[r.op]
      if not effh then
        -- r >>= \y -> step h y
        return Call(r.op, r.x, k)
      else
        return effh(r.x, k)
      end
    end
  end

  handle = function(h, th)
    local co = create(th)
    return step(h, resume(co, nil))
  end
end

local inst = function()
  return {}
end

local run = function(v --[[assume Return]])
  return v.x
end

local function bind(v, k)
  if v.type == "Return" then
    return k(v.x)
  elseif v.type == "Call" then
    return Call(v.op, v.x, function(y)
      return bind(v.k(y), k)
    end)
  end
end

return {
  inst = inst,
  perform = perform,
  handle = handle,
  Return = Return,
  Call = Call,
  run = run,
  bind = bind
}

