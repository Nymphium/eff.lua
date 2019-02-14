local eff = require('eff')
local inst, perform, handler = eff.inst, eff.perform, eff.handler

print([[
monoid
=====]])

do
  local Empty = inst()
  local Concat = inst()

  local empty = function()
    return perform(Empty())
  end

  local concat = function(l, r)
    return perform(Concat(l, r))
  end

  print([[
  number
  -----]])
  do

    local nmonoidh = function(th)
      return handler(Empty,
        function(v) return v end,
        function(k, _)
          return k(0)
        end)(function()
          return handler(Concat,
            function(v) return v end,
            function(k, l, r)
              return k(l + r)
            end)(th)
        end)
    end

    nmonoidh(function()
      print(concat(empty(), 5))
    end)
  end

  print([[
  list
  ----]])
  do

    local lmonoidh = function(th)
      return handler(Empty,
        function(v) return v end,
        function(k)
          return k({})
        end)(function()
        return handler(Concat,
          function(v) return v end,
          function(k, l, r)
            local newt = table.move(l, 0, #l, 0, {})
            table.move(r, 1, #r, #newt + 1, newt)
            return k(newt)
          end)(th)
        end)
    end

    lmonoidh(function()
      local t = empty()

      table.insert(t, 1)

      local tt = {3, 5, 7}

      for _, x in pairs(concat(t, tt)) do
        print(x)
      end
    end)
  end
end

print([[
fmap
===]])

do
  local Map = inst()

  local map = function(f, fa)
    return perform(Map(f, fa))
  end

  print([[
  list
  ----]])
  do

    local lmaph = handler(Map,
      function(v) return v end,
      function(k, f, fa)
        local newt = {}

        for i, x in ipairs(fa) do
          newt[i] = f(x)
        end

        return k(newt)
      end)

    lmaph(function()
      local t = map(function(x) return x * x end, {1, 2, 3, 4, 5})

      for i = 1, #t do
        print(t[i])
      end
    end)
  end

  print([[

  string
  -----]])
  do

    local smaph = handler(Map,
      function(v) return v end,
      function(k, f, s)
        local news = ""

        for c in s:gmatch(".") do
          news = news .. f(c)
        end

        return k(news)
      end)

    smaph(function()
      print(map(function(c) return c .. c end, "hello"))
    end)
  end
end
