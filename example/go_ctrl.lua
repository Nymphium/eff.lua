local eff = require('eff')
local perform, handler, handlers, inst = eff.perform, eff.handler, eff.handlers, eff.inst

-- `push` values and fetch its `history`
local Push = inst()
local History = inst()

local table_shallow_copy = function(t)
  return table.move(t, 1, #t, 1, {})
end

-- parameter-passing style
local runHistory = function(th)
  local h = handlers(
    function(v) return function(h) return v, h end end,
    {Push, function(k, c)
      return function(h)
        local h_ = table_shallow_copy(h)
        table.insert(h_, c)
        return k()(h_)
      end
    end},
    {History, function(k)
      return function(h)
        return k(h)(h)
      end
    end})

  return h(th)({})
end

-- go control operators
local Defer = inst()
local defer = function(f)
  return perform(Defer(f))
end

local Panic = inst()
local panic = function(err)
  return perform(Panic(err))
end

local Recover = inst()
local recover = function()
  return perform(Recover())
end

local runGoCtrl
do
  -- gets `rec` and create handler returning `rec`
  local runRecover0 = function(rec)
    return handler(Recover,
      function(v) return v end,
      function(k)
        return k(rec)
      end)
  end

  local runDeferV = function(v)
    -- fetch registered fuctions
    local defers = perform(History())

    for i = #defers, 1, -1 do
      defers[i]()
    end

    return v
  end

  -- register defer functions
  local runDefer = handler(Defer,
    function(v)
      -- if normally runs, `recover` returns nil
      runRecover0()(runDeferV)

      return v
    end,
    function(k, f)
      perform(Push(f))
      return k()
    end)

  -- panic
  local runPanic = handler(Panic,
    function(v) return v end,
    function(_, err)
      local h = perform(History())

      -- if `defer` ed
      if #h > 0 then
        -- make recover-handler return `err`
        return runRecover0(err)(runDeferV --[[ Originally, Go passes "mzero" to `runDeferV` ]])
      else
        -- emerge builtin error
        error(err)
      end
    end)

  runGoCtrl = function(th)
    -- handler-stack sensitive: history-handler must be outmost
    return runHistory(function()
      -- panic-handler must be outer than defer-handler
      return runPanic(function()
        return runDefer(th)
      end)
    end)
  end
end

runGoCtrl(function()
  defer(function() print("!") end)
  defer(function() io.write("world") end)
  defer(function()
    local err = recover()
    if err then
      print("recover panic")
      io.write(("%s, "):format(err))
    end
  end)

  panic("hello")

  print("ok") -- never reach
end)
