std = "max"
include_files = {
    "getopts.lua",
    "test/*_test.lua",
}
ignore = {
    "assert",
    "121", -- Setting a read-only global variable
    "122", -- Setting a read-only field of a global variable.
}
