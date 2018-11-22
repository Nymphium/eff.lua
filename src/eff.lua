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
    return ("uncaught effect `%s\n%s`"):format(eff, debug.traceback())
  end
end

local UncaughtEff
do
  UncaughtEff = setmetatable({}, {
   __call = function(_, eff, continue)
      return coroutine.yield(setmetatable({eff = eff, continue = continue, cls = "UncaughtEff"}, {
        __tostring = show_error(eff)
      }))
    end
  })
end

local ValueV
do
  local _vv = {cls = "Value"}

  ValueV = setmetatable(_vv, {
    __tostring = function() return _vv.cls end,
    __call = function(self, v)
      return setmetatable({v = v}, {
        __index = self,
      })
      end
    })
end

local EffV
do
  local _vv = {cls = "EffValue"}

  EffV = setmetatable(_vv, {
    __tostring = function() return _vv.cls end,
    __call = function(self, v)
      return setmetatable({v = v}, {
        __index = self,
      })
      end
    })
end

local is_eff_obj = function(obj)
  return type(obj) == "table" and (obj.cls == "Eff" or obj.cls == "UncaughtEff")
end

local is_uncaught_eff_obj = function(obj)
  return type(obj) == "table" and obj.cls == "UncaughtEff"
end

local is_vv = function(obj)
  return type(obj) == "table" and (obj.cls == "Value" or obj.cls == "EffValue")
end

local handler = function(eff, vh, effh)
  eff = tostring(eff)

  return function(th)
    local gr = coroutine.create(th);

    -- for mutual recursion
    local mut = {
      handle = nil,
      continue = nil
    }

    mut.handle = function(r)
      if not is_eff_obj(r) then
        return ValueV(vh(r))
      end

      if r.cls == "Eff" then
        if eff == r.eff then
          return effh(function(arg)
            local ret = mut.continue(arg)

            if not is_vv(ret) then
              return EffV(ret)
            else
              return ret
            end
          end, table.unpack(r.arg))
        else
          return UncaughtEff(r, mut.continue)
        end

      elseif r.cls == "UncaughtEff" then
        if eff == r.eff.eff then
          return effh(r.continue, table.unpack(r.eff.arg))
        else
          return r
        end
      end
    end

    mut.continue = function(arg)
      local st, r = coroutine.resume(gr, arg)
      if not st then
        if type(r) == "string"
          and r:match("attempt to yield from outside a coroutine")
           or r:match("cannot resume dead coroutine")
          then
            return error("continuation cannot be performed twice")
        else
          return error(r)
        end
      elseif is_vv(r) then
        return r.v
      else
        return mut.handle(r)
      end
    end

    local r = mut.continue()

    if is_uncaught_eff_obj(r) then
      return error(r)
    elseif is_eff_obj(r) then
      return mut.handle(r)
    elseif is_vv(r) then
      return r.v
    else
      return r
    end
  end
end

return {
  Eff = Eff,
  UncaughtEff = UncaughtEff,
  perform = coroutine.yield,
  handler = handler,
}

