local create = coroutine.create
local resume = coroutine.resume
local yield = coroutine.yield
local unpack = table.unpack or unpack

local Eff
do
  local __tostring = function(self)
    return tostring(self.eff)
  end

  local v = {}
  v.cls = ("Eff: %s"):format(tostring(v):match('0x[0-f]+'))

  Eff = setmetatable(v, {__call = function(self, eff)
    -- uniqnize
    eff = ("%s: %s"):format(eff, tostring{}:match('0x[0-f]+'))
    local _Eff = setmetatable({eff = eff}, {__index = self})

    return setmetatable({--[[arg = nil]]}, {
      __index = _Eff,

      __tostring = function(self)
        return self.eff
      end,

      __call = function(self, ...)
        local ret = {}

        ret.arg = {...}
        return setmetatable(ret, { __index = self, __tostring = __tostring })
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
  return type(obj) == "table" and (obj.cls == Eff.cls or obj.cls == Resend.cls)
end

local handler
handler = function(eff, vh, effh)
  local is_the_eff = function(it)
    return tostring(eff) == it
  end

  return function(th)
    local gr = create(th)

    local handle
    local continue

    local rehandle = function(arg, k)
      return handler(eff, function(...) return continue(gr, ...) end, effh)(function()
        return k(arg)
      end)
    end

    handle = function(r)
      if not is_eff_obj(r) then
        return vh(r)
      end

      if r.cls == Eff.cls then
        if is_the_eff(r.eff) then
          return effh(function(arg)
            return continue(gr, arg)
          end, unpack(r.arg))
        else
          return Resend(r, function(arg)
            return continue(gr, arg)
          end)
        end
      elseif r.cls == Resend.cls then
        if is_the_eff(r.eff) then
          return effh(function(arg)
            return rehandle(arg, r.continue)
          end, unpack(r.arg))
        else
          return Resend(r, function(arg)
            return rehandle(arg, r.continue)
          end)
        end
      end
    end

    continue = function(co, arg)
      local st, r = resume(co, arg)
      if not st then
        if type(r) == "string" and
        (r:match("attempt to yield from outside a coroutine")
         or r:match("cannot resume dead coroutine"))
        then
            return error("continuation cannot be performed twice")
        else
          return error(r)
        end
      else
        return handle(r)
      end
    end

    return continue(gr, nil)
  end
end

local function get_effh(eff, effeffhs)
  eff = tostring(eff)

  for i = 1, #effeffhs do
    if effeffhs[i][1] == eff then
      return effeffhs[i][2]
    end
  end
end

local handlers
handlers = function(vh, effeffhs)
  return function(th)
    local gr = create(th)

    local handle
    local continue

    local rehandles = function(arg, k)
      return handlers(function(...) return continue(gr, ...) end, effeffhs)(function()
        return k(arg)
      end)
    end

    handle = function(r)
      if not is_eff_obj(r) then
        return vh(r)
      end

      if r.cls == Eff.cls then
        local effh = get_effh(r.eff, effeffhs)
        if effh then
          return effh(function(arg)
            return continue(gr, arg)
          end, unpack(r.arg))
        else
          return Resend(r, function(arg)
            return continue(gr, arg)
          end)
        end
      elseif r.cls == Resend.cls then
        local effh = get_effh(r.eff.eff, effeffhs)
        if effh then
          return effh(function(arg)
            return rehandles(arg, r.continue)
          end, unpack(r.arg))
        else
          return Resend(r, function(arg)
            return rehandles(arg, r.continue)
          end)
        end
      end
    end

    continue = function(co, arg)
      local st, r = resume(co, arg)
      if not st then
        if type(r) == "string" and
        (r:match("attempt to yield from outside a coroutine")
         or r:match("cannot resume dead coroutine"))
        then
            return error("continuation cannot be performed twice")
        else
          return error(r)
        end
      else
        return handle(r)
      end
    end

    return continue(gr, nil)
  end
end


return {
  Eff = Eff,
  perform = yield,
  handler = handler,
  handlers = handlers
}

