eff.lua
===

ONE-SHOT Algebraic Effects for Lua!

# installation
```shell-session
$ luarocks --local install eff
```

# usage
`eff` provides four objects, `Eff`, `UncaughtEff`, `perform`, `handler`

## effect definition and invocation
`Eff` requires the effect name and returns the effect instance.
`perform` invoke the passed effect.

```lua
local Write = Eff("Write") -- definition
perform(Write("Hello!")) -- invocation
```

## effect handler
`handler(eff, value-handler, effect-handler)`

`handler` requires handling effect `eff`, `value handler`, `effect handler` and returns the closure that requires thunk and run the thunk handling effect.

```lua
local printh = handler(Write,
  function(v) print("printh ended", v) end,
  function(arg, k)
    print(arg)
    k()
  end)

printh(function()
  local x = perform(Write("hello"))
  return x
end)

--[[ prints:
hello
printh ended    nil
]]
```

The continuation `effect handler` received is  *ONE-SHOT*, in other words, the continuatoin *cannot* run twice.

```lua
handler(Write,
function(v) print("printh ended", v) end,
function(arg, k)
  print(arg)
  k()
  k() -- call continuation twice
end)(function()
  perform(Write("Foo"))
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
