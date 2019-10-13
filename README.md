eff.lua
===

ONE-SHOT Algebraic Effects for Lua!

# installation
```shell-session
$ luarocks --local install eff
```

# usage
`eff` provides three objects, `inst`, `perform` and `handler`.

## effect instantiation and invocation
`inst` generates the effect instance.
`perform` invoke the passed effect.

```lua
local Write = inst() -- instantiation
perform(Write, "Hello!") -- invocation
```

## effect handler
`handler(eff, value-handler, effect-handler)`

`handler` requires the handling effect `eff`, `value handler` and `effect handler`, and returns the closure that requires thunk and crush the thunk, with handling `eff`.

```lua
local printh = handler(Write,
  function(v) print("printh ended", v) end,
  function(arg, k)
    print(arg)
    k()
  end)

printh(function()
  local x = perform(Write, "hello")
  return x
end)

--[[ prints:
hello
printh ended    nil
]]
```

### limitation about continuation
The continuation `effect handler` received is *ONE-SHOT*, in other words, the continuatoin *cannot* run twice.

```lua
handler(Write,
  function(v) print("printh ended", v) end,
  function(arg, k)
    print(arg)
    k()
    k() -- call continuation twice
  end)
(function()
  perform(Write, "Foo")
end)

--[[prints
lua: ./eff.lua:91: ./eff.lua:82: continuation cannot be performed twice
stack traceback:
        [C]: in function 'error'
        ./eff.lua:91: in local 'printh'
        ../example/example.lua:28: in main chunk
        [C]: in ?
]]
```

# LICENSE
MIT
