package = "eff"
version = "1.0-1"
source = {
   url = "git://github.com/Nymphium/eff.lua",
   tag = "v1.0"
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
