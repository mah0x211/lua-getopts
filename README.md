# lua-getopts

[![test](https://github.com/mah0x211/lua-getopts/actions/workflows/test.yml/badge.svg)](https://github.com/mah0x211/lua-getopts/actions/workflows/test.yml)
[![codecov](https://codecov.io/gh/mah0x211/lua-getopts/branch/master/graph/badge.svg)](https://codecov.io/gh/mah0x211/lua-getopts)

parse command options.


## Installation

```
luarocks install getopts
```


## Usage

```lua
local dump = require('dump')
local getopts = require('getopts')

-- command spec
local Command = {
    name = 'mycmd', -- command name
    version = '1.0.0', -- command version (optional)
    params = { -- name of arguments (optional) (default: nil to get any parameters)
        -- if specify the argument names, the number of arguments must be same as the number of names.
        'first',
        'second',
        'third',
    },
    params_required = 2, -- number of required parameters that must be less than or equal to the number of params (optional) (default: 0 to no required parameters)
    summary = 'a sample command', -- command summary (optional)
    desc = [[a sample command that prints the arguments.]], -- command description (optional)
}
-- option spec
local Options = {
    foo = { -- option name
        alias = 'f', -- option alias (optional)
        required = true, -- required option (optional) (default: false)
        is_flag = false, -- enable to get flag (optional) (default: false)
        type = 'string', -- option type that one of 'string', 'number', 'boolean' (optional) (default: 'string' if is_flag is false, 'boolean' if is_flag is true)
        default = 'hello', -- default value that must be same type as type (optional)
        help = 'foo option', -- option description (optional)
        desc = [[a foo option that requires a string value.]], -- option description (optional)
    },
    bar = {
        alias = 'b',
        is_flag = true,
        help = 'bar option',
        desc = [[a bar option flag.]],
    },
}

-- get command line options
local opts = getopts(Command, Options, '-f', 'foo-value', '--bar', 'arg1',
                     'arg2', 'arg3')
print(dump(opts))
-- above code prints the following table:
-- {
--     [1] = "arg1",
--     [2] = "arg2",
--     [3] = "arg3",
--     bar = true,
--     foo = "foo-value"
-- }

-- print help message and exit
-- getopts(Command, Options, '-f', 'foo-value', 'arg1', 'arg2', '--help')
--
-- above code prints the following message:
--
-- mycmd - a sample command
--
-- a sample command that prints the arguments.
--
-- Version: 1.0.0
--
-- Usage:
--   mycmd [--bar] --foo <string> first second [third]
--   mycmd --help
--   mycmd --version
--
-- Options:
--   -b, --bar           : bar option
--
--   a bar option flag.
--
--   -f, --foo <string>  : foo option (default: hello)
--
--   a foo option that requires a string value.
--
--   -h, --help          : show this help message and exit
--   -v, --version       : show version and exit
--

-- print version and exit
-- getopts(Command, Options, '-f', 'foo-value', 'arg1', 'arg2', '--version')
-- above code prints the following message:
--
-- 1.0.0
--
```


## opts = getopts( cmd, options, ... )

returns a table that contains the parsed command line options.

**NOTE**

`--help` option is automatically added to the option specification. And, if the `cmd.version` field is specified, the `--version` option is automatically added to the option specification.

**Parameters**

- `cmd:table`: command specification that contains the following fields;
    - `name:string`: command name.
    - `version?:string`: command version. (optional)
    - `params?:table`: name of parameters. if it is specified, the number of parameters must be same as the number of names. (optional) (default: `nil` to get any parameters)
    - `params_required?:number`: number of required parameters. (optional)
    - `summary?:string`: command summary. (optional)
    - `desc?:string`: command description. (optional)
- `opts:table<name, option>`: option specification that contains the following fields;
    - `name:string`: option name.
    - `option:table`: option specification that contains the following fields;
        - `alias?:string`: option alias that must be one character. (optional)
        - `required?:boolean`: required option. (optional)
        - `is_flag?:boolean`: as a flag option that does not require a value. (optional)
        - `type?:string`: option type that one of `'string'`, `'number'`, `'boolean'`. (optional) (default: `'string'` if `is_flag` is `false`, `'boolean'` if `is_flag` is `true`)
        - `default?:string|number|boolean`: default value that must be same type as `type` field. (optional)
        - `help?:string`: help message. (optional)
        - `desc?:string`: description message. (optional)

**Returns**

- `opts:table`: a table that contains the parsed command line options.


## License

The MIT License (MIT)

