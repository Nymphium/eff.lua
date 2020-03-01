eff.lua
===

[![Build Status](https://api.travis-ci.org/Nymphium/eff.lua.svg?branch=master)](https://travis-ci.org/Nymphium/eff.lua)

ONE-SHOT Algebraic Effects for Lua!

# installation
```shell-session
$ luarocks --local install eff
```

# usage
`eff` provides four objects, `inst`, `perform` and `handler`.

## effect instantiation and invocation
`inst` generates an effect instance.
`perform` invoke the passed effect.

```lua
local Write = inst() -- instantiation
perform(Write("Hello!")) -- invocation
```

## effect handler
`handler(h)`

`handler` requires a table and returns a _handling function_.
The table has fields, a value handler as `val` and `[Eff]` as an effect handler corresponding to `Eff`.
"Handling an expression with a handler" is translated into an application passing a thunk, containing the expression, to the _handling function_.

```lua
local printh = handler {
  val = function(v) print("printh ended", v) end,
  [Write] = function(k, arg)
      print(arg)
      k()
    end,
  [Read] = function(k)
      return k("baa")
    end
}

printh(function()
  local x = perform(Write("hello"))
  return x
end)

--[[ prints:
hello
printh ended    nil
]]
```

### restriction about continuation
The continuation `effect handler` received is *ONE-SHOT*, in other words, the continuatoin *cannot* run more than twice.

```lua
handler({
  val = function(v) print("printh ended", v) end,
  [Write] = function(k, arg)
      print(arg)
      k()
      k() -- call continuation twice
    end
})(function()
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
