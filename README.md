eff.lua
===

[![Build Status](https://api.travis-ci.org/Nymphium/eff.lua.svg?branch=master)](https://travis-ci.org/Nymphium/eff.lua)

ONE-SHOT Algebraic Effects for Lua!

# installation
```shell-session
$ luarocks --local install eff
```

# usage
`eff` provides four objects, `inst`, `perform`, `handler` and `handlers`.

## effect instantiation and invocation
`inst` generates the effect instance.
`perform` invoke the passed effect.

```lua
local Write = inst() -- instantiation
perform(Write("Hello!")) -- invocation
```

## effect handler
`handler(eff, value-handler, effect-handler)`

`handler` requires the handling effect `eff`, `value handler` and `effect handler`, and returns the closure that requires thunk and crush the thunk, with handling `eff`.

```lua
local printh = handler(Write,
  function(v) print("printh ended", v) end,
  function(k, arg)
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

`handlers` can handle multiple effects.
Pass `{INSTANCE, HANDLER}` tuples to the function.

```lua
local someh = handlers(
  function(v) return v end, -- value handler
  {Foo, function(k, v) print("catch Foo") return k(v) end},
  {Bar, function(k, v) print("catch Bar") return k(v) end}
)

-- or you can write like:

local awesomeh = handlers {
  function(v) return v end, -- value handler
  -- this is not `[[Foo]]`, just [Foo]
  [Foo] = function(k, v) print("catch foo") return k(v) end,
  [Bar] = function(k, v) print("catch bar") return k(v) end,
}
```

### limitation about continuation
The continuation `effect handler` received is *ONE-SHOT*, in other words, the continuatoin *cannot* run twice.

```lua
handler(Write,
  function(v) print("printh ended", v) end,
  function(k, arg)
    print(arg)
    k()
    k() -- call continuation twice
  end)
(function()
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
