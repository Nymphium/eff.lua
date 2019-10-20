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
  return {} -- something unique
end

local performT = "perform"
local perform = function(eff, arg)
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
    local continue = function(arg)
      return handle(resume(co, arg))
    end

    local rehandle = function(k)
      return function(arg)
        local newh = {
          val = continue,
        }

        for op, effh in pairs(h) do
          newh[op] = effh
        end

        return handler(newh)(function()
          return k(arg)
        end)
      end
    end

    handle = function(r)
      if not is_eff_obj(r) then return h.val(r)
      else
        local effh = h[r.eff]

        if     r.type == performT and effh then
          return effh(r.arg, continue)
        elseif r.type == performT          then
          return resend(r.eff, r.arg, continue)
        elseif r.type == resendT  and effh then
          return effh(r.arg, rehandle(r.continue))
        elseif r.type == resendT           then
          return resend(r.eff, r.arg, rehandle(r.continue))
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
    local continue = function(arg)
      return handle(resume(co, arg))
    end

    local rehandle = function(k)
      return function(arg)
        local newh = {
          val = continue,
        }

        for op, effh in pairs(h) do
          newh[op] = effh
        end

        return shallow_handler(newh)(function()
          return k(arg)
        end)
      end
    end

    local continue_ = function(co_)
      return function(arg)
        local r = resume(co_, arg)

        if not is_eff_obj(r) then
          return r
        else
          return resend(r.eff, r.arg, function(arg) return resume(co, arg) end)
        end
      end
    end

    handle = function(r)
      if not is_eff_obj(r) then return h.val(r)
      else
        local effh = h[r.eff]

        if     r.type == performT and effh then
          return effh(r.arg, continue_(co))
        elseif r.type == performT          then
          return resend(r.eff, r.arg, continue)
        elseif r.type == resendT  and effh then
          return effh(r.arg, continue_(create(r.continue)))
        elseif r.type == resendT           then
          return resend(r.eff, r.arg, rehandle(r.continue))
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

