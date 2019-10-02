package = "eff"
version = "4.1-2"
source = {
   url = "git://github.com/Nymphium/eff.lua",
   tag = "v4.1"
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
      eff = "eff.lua/src/eff.lua"
   }
}
