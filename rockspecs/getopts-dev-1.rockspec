package = "getopts"
version = "dev-1"
source = {
    url = "git+https://github.com/mah0x211/lua-getopts.git",
}
description = {
    summary = "parse command options.",
    homepage = "https://github.com/mah0x211/lua-getopts",
    license = "MIT/X11",
    maintainer = "Masatoshi Fukunaga",
}
dependencies = {
    "lua >= 5.1",
}
build = {
    type = "builtin",
    modules = {
        getopts = "getopts.lua",
    },
}
