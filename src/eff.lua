local create = coroutine.create
local yield = coroutine.yield
local unpack = table.unpack or unpack

local handle_error_message = function(r)
  if type(r) == "string" and
      (r:match("attempt to yield from outside a coroutine")
        or r:match("cannot resume dead coroutine"))
  then
    return error("continuation cannot be performed twice")
  else
    return error(r)
  end
end

local resume = function(co, ...)
  local st, r = coroutine.resume(co, ...)
  if not st then
    return handle_error_message(r)
  else
    return r
  end
end

local inst = function()
  local __call = function(eff, ...)
    return { eff = eff, arg = { ... } }
  end

  return setmetatable({}, { __call = __call })
end

local performT = "perform"
local perform = function(e)
  local eff, arg = e.eff, e.arg
  return yield { type = performT, eff = eff, arg = arg }
end

local resendT = "resend"
local resend = function(eff, arg, continue)
  return yield { type = resendT, eff = eff, arg = arg, continue = continue }
end

local is_eff_obj = function(obj)
  return type(obj) == "table" and (obj.type == performT or obj.type == resendT)
end

local function handler(h)
  return function(th)
    local co = create(th)

    local handle
    local continue = function(...)
      return handle(resume(co, ...))
    end

    local rehandle = function(k)
      return function(...)
        local arg = { ... }
        local newh = {}

        for op, effh in pairs(h) do
          newh[op] = effh
        end

        newh.val = continue

        return handler(newh)(function()
          return k(unpack(arg))
        end)
      end
    end

    handle = function(r)
      if not is_eff_obj(r) then
        return h.val(r)
      else
        local effh = h[r.eff]

        local genk
        local called = false
        genk = function(k)
          return function(...)
            called = not called
            if called then
              return error("continuation cannot be performed twice")
            end
            return k(...)
          end
        end

        if r.type == performT and effh then
          return effh(genk(continue), unpack(r.arg))
        elseif r.type == performT then
          return resend(r.eff, r.arg, genk(continue))
        elseif r.type == resendT and effh then
          return effh(genk(rehandle(r.continue)), unpack(r.arg))
        elseif r.type == resendT then
          return resend(r.eff, r.arg, genk(rehandle(r.continue)))
        else
          return error("unreachable")
        end
      end
    end

    return continue(nil)
  end
end

local function shallow_handler(h)
  return function(th)
    local co = create(th)

    local handle
    local continue = function(...)
      return handle(resume(co, ...))
    end

    local rehandle = function(k)
      return function(...)
        local arg = { ... }
        local newh = {
          val = continue,
        }

        for op, effh in pairs(h) do
          newh[op] = effh
        end

        return shallow_handler(newh)(function()
          return k(unpack(arg))
        end)
      end
    end

    local continue_ = function(co_)
      return function(...)
        local r = resume(co_, ...)

        if not is_eff_obj(r) or not r then
          return r
        else
          return resend(r.eff, r.arg, function(...) return resume(co, ...) end)
        end
      end
    end

    handle = function(r)
      if not is_eff_obj(r) then
        return h.val(r)
      else
        local effh = h[r.eff]

        local genk
        local called = false
        genk = function(k)
          return function(...)
            called = not called
            if called then
              return error("continuation cannot be performed twice")
            end
            return k(...)
          end
        end


        if r.type == performT and effh then
          return effh(genk(continue_(co)), unpack(r.arg))
        elseif r.type == performT then
          return resend(r.eff, r.arg, genk(continue))
        elseif r.type == resendT and effh then
          return effh(genk(continue_(create(r.continue))), unpack(r.arg))
        elseif r.type == resendT then
          return resend(r.eff, r.arg, genk(rehandle(r.continue)))
        else
          return error("unreachable")
        end
      end
    end

    return continue(nil)
  end
end

return {
  inst = inst,
  perform = perform,
  handler = handler,
  shallow_handler = shallow_handler,
}
