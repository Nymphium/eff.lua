eff.lua, PoC for *Free*
===

ONE-SHOT Algebraic Effects for Lua!

# concept
This is the embedding based on the method from *"Efficient Compilation of algebraic effects and handlers"*.
With using *coroutine*, you don't have to write continuation or `bind` of `Free` monad.

```lua
local program = op.for_({1, 2, 3, 4, 5, 6, 7, 8, 9, 10}, function(v)
  return perform(Double, v) >> function(vv)
    return perform(Write, vv)
  end
end)
```

```lua
local program = function()
  for _, v in ipairs({1, 2, 3, 4, 5, 6, 7, 8, 9, 10}) do
    perform(Write, perform(Double, v))
  end

  return Return(nil)
end
```

# LICENSE
MIT
