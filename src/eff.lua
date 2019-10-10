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
  local v = {}
  v.cls = ("Eff: %s"):format(tostring(v):match('0x[0-f]+'))

  inst = setmetatable(v, {__call = function(self)
    -- uniqnize
    local eff = ("instance: %s"):format(tostring{}:match('0x[0-f]+'))
    local _Eff = setmetatable({eff = eff}, {__index = self})

    return setmetatable({--[[arg = nil]]}, {
      __index = _Eff,

      __call = function(self, ...)
        local ret = {}

        ret.arg = {...}
        return setmetatable(ret, { __index = self})
      end,
    })
  end})
end

local show_error = function(eff)
  return function()
    return ("uncaught effect `%s'"):format(eff)
  end
end

local Resend
do
  local v = {}
  v.cls = ("Resend: %s"):format(tostring(v):match('0x[0-f]+'))

  Resend = setmetatable(v, {
   __call = function(self, eff, continue)
     return yield(setmetatable({ eff = eff.eff, arg = eff.arg, continue = continue }, {
       __index = self,
       __tostring = show_error(eff)
     }))
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
  local is_the_eff = function(it)
    return eff.eff == it
  end

  return function(th)
    local co = create(th)

    local handle
    local continue

    local rehandle = function(k)
      return function(arg)
        return handler(eff, function(args) return continue(unpack(args)) end, effh)(function()
          return k(arg)
        end)
      end
    end

    handle = function(r)
      if not is_eff_obj(r) then
        return vh(r)
      end

      if r.cls == inst.cls then
        if is_the_eff(r.eff) then
          return effh(function(arg)
            return continue(arg)
          end, unpack(r.arg))
        else
          return Resend(r, function(arg)
            return continue(arg)
          end)
        end
      elseif r.cls == Resend.cls then
        if is_the_eff(r.eff) then
          return effh(rehandle(r.continue), unpack(r.arg))
        else
          return Resend(r, rehandle(r.continue))
        end
      end
    end

    continue = gen_continue(co, handle)

    return continue(nil)
  end
end

local function assemble_handler(vh, ...)
  local effeffhs = {...}

  if type(vh) == "table" and #effeffhs == 0 then
    -- handlers({vh, [eff] = f, ...})
    local vh_ = table.remove(vh)

    for k, h in pairs(vh) do
      effeffhs[k.eff] = h
    end

    vh = vh_
  elseif #effeffhs > 0 and #effeffhs[1] == 2 then
    -- handlers(vh, {{eff, f}, ...})
    local hs = {}

    for i = 1, #effeffhs do
      local effeffh = effeffhs[i]
      hs[effeffh[1].eff] = effeffh[2]
    end

    effeffhs = hs
  else
    -- handlers(vh, {[eff] = f, ...})
    assert(type(vh) == "function")
    assert(type(effeffhs[1]) == "table" and not effeffhs[2])

    effeffhs = effeffhs[1]
  end

  return vh, effeffhs
end

local handlers
handlers = function(...)
  local vh, effeffhs = assemble_handler(...)

  return function(th)
    local co = create(th)

    local handle
    local continue

    local rehandles = function(k)
      return function(arg)
        return handlers(function(...) return continue(...) end, effeffhs)(function()
          return k(arg)
        end)
      end
    end

    handle = function(r)
      if not is_eff_obj(r) then
        return vh(r)
      end

      if r.cls == inst.cls then
        local effh = effeffhs[r.eff]
        if effh then
          return effh(continue, unpack(r.arg))
        else
          return Resend(r, continue)
        end
      elseif r.cls == Resend.cls then
        local effh = effeffhs[r.eff]
        if effh then
          return effh(rehandles(r.continue), unpack(r.arg))
        else
          return Resend(r.eff, rehandles(r.continue))
        end
      end
    end

    continue = gen_continue(co, handle)

    return continue(nil)
  end
end

return {
  inst = inst,
  perform = yield,
  handler = handler,
  handlers = handlers
}

