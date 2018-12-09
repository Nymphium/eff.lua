local create = coroutine.create
local resume = coroutine.resume
local _create = coroutine.wrap
local yield = coroutine.yield
local unpack = table.unpack

local Eff
do
  local _M = {
    __tostring = function(self)
      return tostring(self.eff)
    end
  }

  Eff = function(eff)
    -- uniqnize
    eff = eff .. (tostring{}):match("0x[0-f]+")
    local _Eff = {cls = "Eff", eff = eff}

    return setmetatable({--[[arg = nil]]}, {
      __index = _Eff,

      __tostring = function(self)
        return self.eff
      end,

      __call = function(self, ...)
        local ret = {}

        ret.cls = self.cls
        ret.eff = self.eff
        ret.arg = {...}
        return setmetatable(ret, _M)
      end,
    })
  end
end

local show_error = function(eff)
  return function()
    return ("uncaught effect `%s'"):format(eff)
  end
end

local UncaughtEff
do
  UncaughtEff = setmetatable({}, {
   __call = function(_, eff, continue)
     return yield(setmetatable({eff = eff, continue = continue, cls = "UncaughtEff"}, {
       __tostring = show_error(eff)
     }))
   end
 })
end

local is_eff_obj = function(obj)
  return type(obj) == "table" and (obj.cls == "Eff" or obj.cls == "UncaughtEff")
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

      if r.cls == "Eff" then
        if eff == r.eff then
          return effh(continue, unpack(r.arg))
        else
          return UncaughtEff(r, continue)
        end
      elseif r.cls == "UncaughtEff" then
        if eff == r.eff.eff then
          return effh(function(arg)
            return handle(_create(r.continue)(arg))
          end, unpack(r.eff.arg))
        else
          return UncaughtEff(r.eff, function(arg)
            return handle(_create(r.continue)(arg))
          end)
        end
      end
    end

    continue = function(arg)
      local st, r = resume(gr, arg)
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

    return continue()
  end
end

return {
  Eff = Eff,
  UncaughtEff = UncaughtEff,
  perform = yield,
  handler = handler,
}

