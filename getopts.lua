--
-- Copyright (C) 2023 Masatoshi Fukunaga
--
-- Permission is hereby granted, free of charge, to any person obtaining a copy
-- of this software and associated documentation files (the "Software"), to deal
-- in the Software without restriction, including without limitation the rights
-- to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
-- copies of the Software, and to permit persons to whom the Software is
-- furnished to do so, subject to the following conditions:
--
-- The above copyright notice and this permission notice shall be included in
-- all copies or substantial portions of the Software.
--
-- THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
-- IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
-- FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.  IN NO EVENT SHALL THE
-- AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
-- LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
-- OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
-- THE SOFTWARE.
--
local ipairs = ipairs
local setmetatable = setmetatable
local type = type
local tostring = tostring
local find = string.find
local format = string.format
local match = string.match
local rep = string.rep
local concat = table.concat
local sort = table.sort
local max = math.max

-- constants
local NAME_PATTERN = '^[a-zA-Z][a-zA-Z0-9_-]*[a-zA-Z0-9]$'

--- is_valid_name
--- @param name string
--- @return boolean ok
local function is_valid_name(name)
    return type(name) == 'string' and find(name, NAME_PATTERN) and true or false
end

--- errorf
--- @param fmt string
--- @param ... any
local function errorf(fmt, ...)
    error(format(fmt, ...), 2)
end

--- @class getopts
--- @field name string
--- @field version? string
--- @field summary? string
--- @field desc? string
--- @field params? string[]
--- @field params_required? integer
--- @field optnames string[]
--- @field options table<string, table>|table<number, table>
--- @field defaults table<string, string|boolean|number>
--- @field requires string[]
--- @field max_optspec_len integer
local GetOpts = {}
GetOpts.__index = GetOpts

--- new
--- @param cmd table
--- | 'name' string
--- | 'version' string?
--- | 'params' string[]?
--- | 'params_required' integer? # number of parameters required
--- | 'summary' string?
--- | 'desc' string? # description
--- @return getopts
local function new(cmd)
    assert(type(cmd.name) == 'string', 'cmd.name must be string')
    assert(type(cmd.version) == 'string' or cmd.version == nil,
           'cmd.version must be string or nil')
    assert(type(cmd.params) == 'table' or cmd.params == nil,
           'cmd.params must be string[] or nil')
    assert(type(cmd.nparam) == 'number' or cmd.nparam == nil,
           'cmd.nparam must be number or nil')
    assert(type(cmd.summary) == 'string' or cmd.summary == nil,
           'cmd.summary must be string or nil')
    assert(type(cmd.desc) == 'string' or cmd.desc == nil,
           'cmd.desc must be string or nil')

    -- verify params
    if cmd.params then
        local nparam = 0
        for i, name in pairs(cmd.params or {}) do
            if type(i) ~= 'number' then
                errorf('cmd.params must be string[] or nil')
            elseif not is_valid_name(name) then
                errorf('cmd.params#%d %q must be the form of %s', i, name,
                       NAME_PATTERN)
            end
            nparam = nparam + 1
        end

        for i = 1, nparam do
            if type(cmd.params[i]) ~= 'string' then
                errorf('cmd.params must be non-sparsed string[]')
            end
        end

        -- verify params_required
        cmd.params_required = cmd.params_required or 0
        if cmd.params_required > nparam then
            errorf(
                'cmd.params_required must be less than or equal to %d (cmd.params length)',
                nparam)
        end
    end

    local self = setmetatable({
        name = cmd.name,
        version = cmd.version,
        params = cmd.params,
        params_required = cmd.params_required,
        summary = cmd.summary,
        desc = cmd.desc,
        optnames = {},
        options = {},
        defaults = {},
        requires = {},
        max_optspec_len = 0,
    }, GetOpts)

    -- add help option by default
    self:setopt('help', {
        alias = 'h',
        is_flag = true,
        help = 'show this help message and exit',
    })

    -- add version option by default if version is specified
    if cmd.version then
        self:setopt('version', {
            alias = 'v',
            is_flag = true,
            help = 'show version and exit',
        })
    end

    return self
end

local VALID_OPT_TYPE = {
    string = true,
    boolean = true,
    number = true,
}

--- @class option
--- @field alias string? # single character
--- @field required boolean? # default false
--- @field is_flag boolean? # default false
--- @field type string? # one of boolean, string, number
--- @field default string|boolean|number? # must be same type as type
--- @field help string? # summary of option
--- @field desc string? # description of option

--- setopt
--- @param name string
--- @param opt option
function GetOpts:setopt(name, opt)
    local spec = ''

    if not is_valid_name(name) then
        errorf(format 'option name %q must be the form of %s', name,
               NAME_PATTERN)
    elseif type(opt) ~= 'table' then
        errorf('%s option must be table', name)
    end

    if opt.alias then
        if type(opt.alias) ~= 'string' then
            errorf('%s.alias %q must be string', name, tostring(opt.alias))
        elseif #opt.alias ~= 1 then
            errorf('%s.alias %q must be single character', name, opt.alias)
        elseif self.options[opt.alias] then
            errorf('%s.alias %q is already used by %q option', name, opt.alias,
                   self.options[opt.alias])
        end
        spec = '-' .. opt.alias .. ', '
    end
    local usage = '--' .. name
    spec = spec .. '--' .. name

    if opt.required ~= nil and type(opt.required) ~= 'boolean' then
        errorf('%s.required must be boolean', name)
    end

    if opt.is_flag == nil or opt.is_flag == false then
        if opt.type == nil then
            opt.type = 'string'
        elseif type(opt.type) ~= 'string' then
            errorf('%s.type must be string', name)
        elseif not VALID_OPT_TYPE[opt.type] then
            errorf('%s.type must be one of boolean, string, number', name)
        end
        usage = usage .. ' <' .. opt.type .. '>'
        spec = spec .. ' <' .. opt.type .. '>'

        if opt.default ~= nil then
            if type(opt.default) ~= opt.type then
                errorf('%s.default must be %s', name, opt.type)
            end
        end

    elseif type(opt.is_flag) ~= 'boolean' then
        errorf('%s.is_flag must be boolean', name)
    elseif opt.type ~= nil then
        errorf('%s.type cannot be set when %s.is_flag is true', name, name)
    elseif opt.default ~= nil then
        errorf('%s.default cannot be set when %s.is_flag is true', name, name)
    end

    local help = opt.help
    if help ~= nil then
        if type(help) ~= 'string' then
            errorf('opts.%s.help must be string', name)
        elseif opt.default then
            -- append about default value to help
            help = help .. ' (default: ' .. tostring(opt.default) .. ')'
        end
    end

    if opt.desc ~= nil and type(opt.desc) ~= 'string' then
        errorf('%s.desc must be string', name)
    end

    self.max_optspec_len = max(self.max_optspec_len, #spec)
    self.optnames[#self.optnames + 1] = name
    self.options[name] = {
        name = name,
        alias = opt.alias,
        required = opt.required,
        type = opt.type,
        is_flag = opt.is_flag,
        default = opt.default,
        help = help,
        desc = opt.desc,
        usage = usage,
        spec = spec,
    }
    if opt.alias then
        self.options[opt.alias] = self.options[name]
    end

    if opt.default then
        self.defaults[name] = opt.default
    end

    if opt.required then
        self.requires[#self.requires + 1] = name
    end
end

--- setopts
--- @param opts table
--- @return getopts
function GetOpts:setopts(opts)
    assert(type(opts) == 'table', 'opts must be table')
    for name, opt in pairs(opts) do
        self:setopt(name, opt)
    end

    return self
end

--- tomultiline
--- @param s string
--- @param ncol number
--- @return string[] multiline
local function tomultiline(s, ncol)
    assert(type(s) == 'string', 's must be string')
    assert(type(ncol) == 'number', 'ncol must be number')

    local lines = {}
    -- split each ncol characters
    for i = 1, #s, ncol do
        lines[#lines + 1] = s:sub(i, i + ncol - 1)
    end
    return lines
end

--- usage
function GetOpts:usage()
    sort(self.optnames, function(a, b)
        return a < b
    end)

    local maxcol = 76

    local usage_padding = '  '
    local usages = {
        usage_padding .. self.name,
    }
    local add_usage = function(opt_usage, required)
        if not required then
            opt_usage = '[' .. opt_usage .. ']'
        end
        if #usages[#usages] > maxcol then
            usages[#usages + 1] = usage_padding
        end
        usages[#usages] = usages[#usages] .. ' ' .. opt_usage
    end

    local max_optspec_len = self.max_optspec_len + 2
    local options = {}
    local add_option = function(opt_spec, help, desc)
        -- build options message
        opt_spec = '  ' .. opt_spec
        if help then
            opt_spec = opt_spec .. rep(' ', max_optspec_len - #opt_spec)
            local help_padding = rep(' ', #opt_spec)
            local delim = '  : '
            local helplen = #opt_spec + #delim
            local mlines = tomultiline(help, maxcol - helplen)
            opt_spec = opt_spec .. delim ..
                           concat(mlines, '\n' .. help_padding .. delim)
        end
        options[#options + 1] = opt_spec
        if desc then
            options[#options + 1] = '\n  ' .. desc .. '\n'
        end
    end

    -- build usage and options messages
    for _, name in ipairs(self.optnames) do
        local opt = self.options[name]
        if opt.name ~= 'help' and opt.name ~= 'version' then
            add_usage(opt.usage, opt.required)
        end
        add_option(opt.spec, opt.help, opt.desc)
    end

    -- add parameters usage
    if not self.params then
        -- accept any parameters
        add_usage('...', false)
    elseif #self.params > 0 then
        -- accept specified parameters
        for i = 1, self.params_required do
            add_usage(self.params[i], true)
        end

        if self.params_required < #self.params then
            add_usage(
                '[' .. concat(self.params, ' [', self.params_required + 1) ..
                    rep(']', #self.params - self.params_required), true)
        end
    end

    -- print usage
    io.stdout:write('Usage:\n')
    io.stdout:write(concat(usages, '\n'), '\n')
    -- print help usage
    usages = {
        usage_padding .. self.name,
    }
    add_usage(self.options.help.usage, true)
    io.stdout:write(concat(usages, '\n'), '\n')
    -- print version usage
    if self.options.version then
        usages = {
            usage_padding .. self.name,
        }
        add_usage(self.options.version.usage, true)
        io.stdout:write(concat(usages, '\n'), '\n')
    end

    io.stdout:write(concat({
        '',
        'Options:',
        concat(options, '\n'),
        '',
    }, '\n'), '\n')
end

--- version prints version and exit
function GetOpts:print_version()
    io.stdout:write(self.version, '\n')
    os.exit(0)
end

--- help prints usage and exit
function GetOpts:print_help()
    if self.summary then
        io.stdout:write(self.name .. ' - ' .. self.summary, '\n\n')
    else
        io.stdout:write(self.name, '\n\n')
    end

    if self.desc then
        io.stdout:write(self.desc, '\n\n')
    end

    if self.version then
        io.stdout:write('Version: ' .. self.version, '\n\n')
    end

    self:usage()
    os.exit(0)
end

--- failure prints error message and usage, then exit
--- @param ... any
function GetOpts:failure(...)
    io.stdout:write(format(...), '\n\n')
    self:usage()
    os.exit(-1)
end

--- parse
--- @param ... string
function GetOpts:parse(...)
    -- set required options
    local requires = {}
    for _, name in ipairs(self.requires) do
        requires[name] = true
    end

    -- parse arguments
    local args = {}
    local narg = select('#', ...)
    local argv = {
        ...,
    }
    local i = 0
    while i < narg do
        i = i + 1
        local arg = argv[i]
        local prefix, key = match(arg, '^(-+)([^-]*)')

        if not prefix then
            if self.params and #self.params <= #args then
                -- too many parameters
                self:failure('too many parameters')
            end
            args[#args + 1] = arg
        elseif #prefix > 2 then
            self:failure('unknown option: %q', arg)
        else
            local opt = self.options[key]
            if not opt then
                self:failure('unknown option: %q', arg)
            end
            local name = opt.name

            -- set true to flag option
            local val = true --- @type any
            if not opt.is_flag then
                -- get non-flag option value from next argument
                i = i + 1
                val = argv[i]
                if not val then
                    -- non-flag option must have value
                    self:failure('option %q value is not specified', arg)
                end

                -- convert value type to opt.type
                if opt.type == 'number' then
                    local num = tonumber(val)
                    if not num then
                        self:failure('option %q value %q is not number', arg,
                                     val)
                    end
                    val = num
                elseif opt.type == 'boolean' then
                    if val == 'true' or val == 'yes' or val == 'y' then
                        val = true
                    elseif val == 'false' or val == 'no' or val == 'n' then
                        val = false
                    else
                        self:failure('option %q value %q is not boolean', arg,
                                     val)
                    end
                end
            end

            if args[name] then
                -- option cannot be specified twice
                self:failure('option %q is specified twice', arg)
            end

            args[name] = val
            -- got required option
            if requires[name] then
                requires[name] = nil
            end
        end
    end

    -- print help and exit
    if args.help then
        self:print_help()
    end

    -- print version and exit
    if args.version then
        self:print_version()
    end

    -- set default values
    for name, val in pairs(self.defaults) do
        if args[name] == nil then
            args[name] = val
            if requires[name] then
                requires[name] = nil
            end
        end
    end

    -- check required options
    for name, _ in pairs(requires) do
        self:failure('required option: %q is not specified', '--' .. name)
    end

    -- check required parameters
    if self.params_required and #args < self.params_required then
        self:failure('parameters must be specified at least %d required',
                     self.params_required)
    end

    return args
end

--- parse
--- @param cmd table
--- | 'name'    | string   | required |
--- | 'version' | string   | optional |
--- | 'params'   | string[]  | optional |
--- | 'params_required'  | integer  | optional |
--- | 'summary' | string   | optional |
--- | 'desc' | string   | optional |
--- @param opts table<string, option>
--- @param ... string
--- @return table args
local function parse(cmd, opts, ...)
    return new(cmd):setopts(opts):parse(...)
end

return parse
