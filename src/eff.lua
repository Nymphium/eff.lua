local Eff = function(eff)
  local _Eff = {cls = "Eff", eff = eff}

  return setmetatable({--[[arg = nil]]}, {
    __index = _Eff,

    __tostring = function(self)
      return self.eff
    end,

    __call = function(self, arg)
      self.arg = arg
      return self
    end,
  })
end

local UncaughtEff
do
  local _UE = {cls = "UncaughtEff"}

  UncaughtEff = setmetatable(_UE, {
    __tostring = function(self)
      return self.cls
    end,

    __call = function(_, eff, continue)
      return error(setmetatable({eff = eff, continue = continue}, {
        __tostring = function()
          return ("uncaught effect `%s`\n%s"):format(eff, debug.traceback())
        end
      }))
    end
  })
end

local handler = function(eff, vh, effh)
  eff = tostring(eff)
  local exn

  return function(f)
    local gr = coroutine.create(f);

    -- for mutual recursion
    local mut = {
      handle = nil,
      continue = nil
    }

    mut.handle = function(r)
      if type(r) ~= "table" or not r.cls == "Eff" then
        return vh(r)
      end

      if eff == r.eff then
        return effh(r.arg, mut.continue)
      else
        return UncaughtEff(r, mut.continue)
      end
    end

    local function handle_leaked(th)
      return xpcall(th, function(e)
        if type(e) == "table" and e.cls == UncaughtEff.cls then
          if e.eff.eff == eff then
            return handle_leaked(function() return effh(e.eff.arg, e.continue) end)
          else
            return error(e)
          end
        else
          -- *true* error
          exn = e
          return
        end
      end)
    end

    mut.continue = function(arg)
      return handle_leaked(function()
        local st, r = coroutine.resume(gr, arg)
        if not st then
          return error("continuation cannot be performed twice")
        else
          return mut.handle(r)
        end
      end)
    end

    local ret = mut.continue()
    if exn then
      return error(exn)
    else
      return ret
    end
  end
end

return {
  Eff = Eff,
  UncaughtEff = UncaughtEff,
  perform = coroutine.yield,
  handler = handler,
}

