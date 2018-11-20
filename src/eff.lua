local Eff = function(eff)
  local _Eff = {cls = "Eff", eff = eff}

  return setmetatable({--[[arg = nil]]}, {
    __index = _Eff,

    __tostring = function(self)
      return self.eff
    end,

    __call = function(self, ...)
      self.arg = {...}
      return self
    end,
  })
end


local show_error = function(eff)
  return function(err)
    if err:match("attempt to yield from outside a coroutine") then
      return ("uncaught effect `%s`"):format(eff)
    else
      return err
    end
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
      if type(r) ~= "table" or (r.cls ~= "Eff" and r.cls ~= "UncaughtEff") then
        return vh(r)
      end

      if r.cls == "Eff" then
        if eff == r.eff then
          return effh(mut.continue, table.unpack(r.arg))
        else
          return UncaughtEff(r, mut.continue)
        end

      elseif r.cls == "UncaughtEff" then
        if eff == r.eff.eff then
          return effh(r.eff.continue, table.unpack(r.eff.arg))
          -- return effh(r.eff.arg, r.eff.continue)
        else
          -- rethrow
          return r
        end

      else
        return r
      end
    end

    mut.continue = function(arg)
      local st, r = coroutine.resume(gr, arg)
      if not st then
        return error("continuation cannot be performed twice")
      else
        return mut.handle(r)
      end
    end

    local rco = coroutine.create(mut.continue)
    local st, r = coroutine.resume(rco)

    if not st then
      return error(r)
    end

    if type(r) ~= "table" or (r.cls ~= "Eff" and r.cls ~= "UncaughtEff") then
      return r
    else
      return mut.handle(r)
    end
  end
end

return {
  Eff = Eff,
  UncaughtEff = UncaughtEff,
  perform = coroutine.yield,
  handler = handler,
}

