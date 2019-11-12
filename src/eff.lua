local create = coroutine.create
local coresume = coroutine.resume
local yield = coroutine.yield
local unpack_ = table.unpack or unpack

local function handle_error_message(r)
  if type(r) == "string" and
  (r:match("attempt to yield from outside a coroutine")
   or r:match("cannot resume dead coroutine"))
  then
    return error("continuation cannot be performed twice")
  else
    return error(r)
  end
end

local resume = function(co, a)
  local st, r = coresume(co, a)
  if not st then
    return handle_error_message(r)
  else
    return r
  end
end

---

local inst = function()
  local o = {}
  local tostr = "Eff: " .. tostring(o):match("0x[0-f]+")
  return setmetatable(o, {
    __call = function(self, ...)
      return { eff = self, arg = {...} }
    end,
    __tostring = function(_)
      return tostr
    end
  })
end

local performT = "perform"
local perform = function(obj)
  return yield { type = performT, eff = obj.eff, arg = obj.arg }
end

local resendT = "resend"
local resend = function(obj, continue)
  return yield { type = resendT, eff = obj.eff, arg = obj.arg, continue = continue }
end

local unpack = function(t)
  if t and #t > 0 then
    return unpack_(t)
  end
end

local is_eff_obj = function(obj)
  return type(obj) == type{} and (obj.type == performT or obj.type == resendT)
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
        local newh = { }

        for op, effh in pairs(h) do
          newh[op] = effh
        end

        newh.val = continue

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
          return effh(continue, unpack(r.arg))
        elseif r.type == performT          then
          return resend(r, continue)
        elseif r.type == resendT  and effh then
          return effh(rehandle(r.continue), unpack(r.arg))
        elseif r.type == resendT           then
          return resend(r, rehandle(r.continue))
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
}
