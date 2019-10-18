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

local function handler(eff, vh, effh)
  return function(th)
    local co = create(th)

    local handle
    local continue

    local rehandle = function(k)
      return function(arg)
        return handler(eff, continue, effh)(function()
          return k(arg)
        end)
      end
    end

    handle = function(r)
      if     not is_eff_obj(r)                   then return vh(r)
      elseif r.type == performT and r.eff == eff then return effh(r.arg, continue)
      elseif r.type == performT                  then return resend(r.eff, r.arg, continue)
      elseif r.type == resendT and r.eff == eff  then return effh(r.arg, rehandle(r.continue))
      elseif r.type == resendT                   then return resend(r.eff, r.arg, rehandle(r.continue))
      end
    end

    continue = function(arg)
      return handle(resume(co, arg))
    end

    return continue(nil)
  end
end

return {
  inst = inst,
  perform = perform,
  handler = handler,
}

