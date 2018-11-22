package = "eff"
version = "2.0-3"
source = {
   url = "git://github.com/Nymphium/eff.lua",
   tag = "v2.0"
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
