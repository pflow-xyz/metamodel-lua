package = "metamodel"
version = "scm-1"
source = {
   url = "github.com/pFlow-dev/metamodel-lua"
}
description = {
   homepage = "https://pflow.dev",
   license = "MIT"
}
dependencies = {}
build = {
   type = "builtin",
   modules = {
      ["src.metamodel"] = "src/metamodel.lua",
   }
}
