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
    eff = ("%s: %s"):format(eff, (tostring{}):match("0x[0-f]+"))
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

local UncaughtEff
do
  local v = {}
  v.cls = ("UncaughtEff: %s"):format(tostring(v):match('0x[0-f]+'))
  UncaughtEff = setmetatable(v, {
   __call = function(self, eff, continue)
     return yield(setmetatable({eff = eff, continue = continue}, {
       __index = self,
       __tostring = show_error(eff)
     }))
   end
 })
end

local is_eff_obj = function(obj)
  return type(obj) == "table" and (obj.cls == Eff.cls or obj.cls == UncaughtEff.cls)
end

local handler = function(eff, vh, effh)
  eff = tostring(eff)

  return function(th)
    local gr = create(th)

    local handle
    local continue

    handle = function(r)
      if not is_eff_obj(r) then
        return vh(r)
      end

      if r.cls == Eff.cls then
        if eff == r.eff then
          return effh(function(arg) return continue(gr, arg) end, unpack(r.arg))
        else
          return UncaughtEff(r, function(arg) return continue(gr, arg) end)
        end
      elseif r.cls == UncaughtEff.cls then
        if eff == r.eff.eff then
          return effh(function(arg)
            return continue(create(r.continue), arg)
          end, unpack(r.eff.arg))
        else
          return UncaughtEff(r.eff, function(arg)
            return continue(create(r.continue), arg)
          end)
        end
      end
    end

    continue = function(co, arg)
      local st, r = resume(co, arg)
      if not st then
        if type(r) == "string"
          and r:match("attempt to yield from outside a coroutine")
           or r:match("cannot resume dead coroutine")
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
  UncaughtEff = UncaughtEff,
  perform = yield,
  handler = handler,
}

