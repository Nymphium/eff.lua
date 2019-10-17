local create = coroutine.create
local yield = coroutine.yield

local resume = function(co, a)
  local st, r = coroutine.resume(co, a)

  if not st then
    return error(r)
  else
    return r
  end
end

local inst = function()
  return {}
end

-- Call : ('arg, 'res) operation * 'arg * ('res -> 'a computation) -> 'a computation
local callT = "call"
local call = function(op, x, k)
  return { type = callT, op = op, x = x, k = k }
end

local throwT = {
  perform = false,
  resend = true
}

local perform = function(op, arg)
  local current = coroutine.running()

  local k = function(a)
    return resume(current, a)
  end

  return yield(call(op, {arg, type = throwT.perform}, k) )
end


local resend = function(op, arg, k)
  return yield(call(op, {arg, type = throwT.resend}, k) )
end

local is_eff_obj = function(obj)
  return type(obj) == "table" and (obj.type == callT)
end

local handler
handler = function(op, vh, effh)
  return function(th)
    local co = create(th)

    local handle
    local handler_ do
      local vh_ = function(arg)
        return handle(resume(co, arg))
      end

      handler_ = handler(op, vh_, effh)
    end

    handle = function(r)
      if not is_eff_obj(r) then
        return vh(r)
      end

      if r.type == callT then
        local resended = r.x.type
        local k

        if resended then
          k = function(arg)
            return handler_(function()
              return r.k(arg)
            end)
          end
        else
          k = function(arg)
            return handle(r.k(arg))
          end
        end

        local arg = r.x[1]
        if r.op == op then
          return effh(arg, k)
        else
          return resend(r.op, arg, k)
        end
      end
    end

    return handle(resume(co, nil))
  end
end

return {
  inst = inst,
  perform = perform,
  handler = handler,
}

