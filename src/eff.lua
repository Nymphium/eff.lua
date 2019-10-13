local create = coroutine.create
local resume = coroutine.resume
local yield = coroutine.yield
local unpack0 = table.unpack or unpack

local unpack = function(t)
  if t and #t > 0 then
    return unpack0(t)
  end
end

local inst do
  local cls = ("Eff: %s"):format(tostring(v):match('0x[0-f]+'))

  inst = setmetatable({ cls = cls }, {
    __call = function(self)
      local eff = ("instance: %s"):format(tostring{}:match('0x[0-f]+'))
      return { eff = eff, cls = self.cls}
    end
  })
end

local perform = function(eff, arg)
  return yield { cls = eff.cls, eff = eff.eff, arg = arg }
end

local show_error = function(eff)
  return function()
    return ("uncaught effect `%s'"):format(eff)
  end
end

local Resend do
  local cls = ("Resend: %s"):format(tostring(v):match('0x[0-f]+'))

  Resend = setmetatable({ cls = cls }, {
    __call = function(self, effobj, continue)
      return yield { eff = effobj.eff, arg = effobj.arg, continue = continue, cls = self.cls }
    end
  })
end

local is_eff_obj = function(obj)
  return type(obj) == "table" and (obj.cls == inst.cls or obj.cls == Resend.cls)
end

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

local gen_continue = function(co, handle)
  return function(arg)
    local st, r = resume(co, arg)
    if not st then
      return handle_error_message(r)
    else
      return handle(r)
    end
  end
end

local handler
handler = function(eff, vh, effh)
  local eff_type = eff.eff

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
      if not is_eff_obj(r) then
        return vh(r)
      end

      if r.cls == inst.cls then
        if r.eff == eff_type then
          return effh(r.arg, continue)
        else
          return Resend(r, function(arg)
            return continue(arg)
          end)
        end
      elseif r.cls == Resend.cls then
        if r.eff == eff_type then
          return effh(r.arg, rehandle(r.continue))
        else
          return Resend(r, rehandle(r.continue))
        end
      end
    end

    continue = function(arg)
      local st, r = resume(co, arg)
      if not st then
        return handle_error_message(r)
      else
        return handle(r)
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

