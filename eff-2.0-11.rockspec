package = "eff"
version = "2.0-11"
source = {
   url = "git://github.com/Nymphium/eff.lua",
   tag = "topic/luarocks"
}
description = {
   summary = "ONE-SHOT algebraic effects for Lua!",
   homepage = "https://github.com/Nymphium/eff.lua",
   license = "MIT"
}
dependencies = {}
build = {
   type = "builtin",
   modules = {
      -- eff = "eff.lua/src/eff.lua"
   },
   install = {
      lua = {
         ["eff"] = [[eff.lua/src/eff.lua]]
      }
   }
}
