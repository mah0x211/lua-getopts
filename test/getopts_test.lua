require('luacov')
local unpack = unpack or table.unpack
local stdout = io.stdout
local exit = os.exit
local testcase = require('testcase')
local getopts = require('getopts')

function testcase.before_each()
    io.stdout = stdout
    os.exit = exit
end

function testcase.getopt_arguments()
    -- test that get arguments correctly
    local opts = getopts({
        name = 'test',
    }, {
        foo = {
            alias = 'f',
            is_flag = true,
        },
    }, 'hello', 'world')
    assert.equal(opts, {
        'hello',
        'world',
    })
end

function testcase.getopt_string_value()
    -- test that string argument is parsed correctly
    for _, v in ipairs({
        {
            -- test with long option
            argv = {
                '--foo',
                'bar',
            },
            cmp = {
                foo = 'bar',
            },
        },
        {
            -- test with alias option
            argv = {
                '-f',
                'bar',
            },
            cmp = {
                foo = 'bar',
            },
        },
    }) do
        local opts = getopts({
            name = 'test',
        }, {
            foo = {
                alias = 'f',
                type = 'string',
            },
        }, unpack(v.argv))
        assert.equal(opts, v.cmp)

        -- opt.type is default to 'string'
        opts = getopts({
            name = 'test',
        }, {
            foo = {
                alias = 'f',
                -- type = 'string',
            },
        }, unpack(v.argv))
        assert.equal(opts, v.cmp)
    end
end

function testcase.getopt_boolean_value()
    -- test that boolean argument is parsed correctly
    for _, v in ipairs({
        {
            -- test with long option
            argv = {
                '--foo',
                'true',
            },
            cmp = {
                foo = true,
            },
        },
        {
            -- test with alias option
            argv = {
                '-f',
                'false',
            },
            cmp = {
                foo = false,
            },
        },
    }) do
        local opts = getopts({
            name = 'test',
        }, {
            foo = {
                alias = 'f',
                type = 'boolean',
            },
        }, unpack(v.argv))
        assert.equal(opts, v.cmp)
    end
end

function testcase.getopt_number_value()
    -- test that number argument is parsed correctly
    for _, v in ipairs({
        {
            -- test with long option
            argv = {
                '--foo',
                '123',
            },
            cmp = {
                foo = 123,
            },
        },
        {
            -- test with alias option
            argv = {
                '-f',
                '456',
            },
            cmp = {
                foo = 456,
            },
        },
    }) do
        local opts = getopts({
            name = 'test',
        }, {
            foo = {
                alias = 'f',
                type = 'number',
            },
        }, unpack(v.argv))
        assert.equal(opts, v.cmp)
    end
end

function testcase.getopt_flag_value()
    -- test that flag argument is parsed correctly
    local opts = getopts({
        name = 'test',
    }, {
        foo = {
            alias = 'f',
            is_flag = true,
            required = true,
        },
    }, '-f')
    assert.equal(opts, {
        foo = true,
    })
end

function testcase.getopt_default_value()
    -- test that number argument is parsed correctly
    local opts = getopts({
        name = 'test',
    }, {
        foo = {
            alias = 'f',
            default = 'bar',
        },
    })
    assert.equal(opts, {
        foo = 'bar',
    })
end

function testcase.print_version_and_exit()
    local f = assert(io.tmpfile())
    io.stdout = f
    os.exit = function(code)
        error('exit with code ' .. code)
    end

    -- test that print version and exit
    local err = assert.throws(getopts, {
        name = 'test',
        version = 'v0.1.0-beta',
    }, {
        foo = {
            alias = 'f',
            required = true,
            default = 'bar',
            help = 'foo-help',
        },
        bar = {
            alias = 'b',
            desc = 'bar-description',
        },
    }, '--version')
    io.stdout = stdout
    f:seek('set')
    assert.match(err, 'exit with code 0')
    assert.equal(f:read('*a'), 'v0.1.0-beta\n')
end

function testcase.print_help_and_exit()
    local f = assert(io.tmpfile())
    io.stdout = f
    os.exit = function(code)
        error('exit with code ' .. code)
    end

    -- test that print help and exit
    local err = assert.throws(getopts, {
        name = 'test',
        version = 'v0.1.0-beta',
        params = {
            'param1',
            'param2',
            'param3',
            'param4',
        },
        params_required = 2,
        summary = 'test-summary',
        desc = 'test-description',
    }, {
        foo = {
            alias = 'f',
            required = true,
            help = 'foo-help',
        },
        bar = {
            alias = 'b',
            desc = 'bar-description',
        },
    }, '--help')
    io.stdout = stdout
    f:seek('set')
    assert.match(err, 'exit with code 0')
    assert.equal(f:read('*a'), [==[
test - test-summary

test-description

Version: v0.1.0-beta

Usage:
  test [--bar <string>] --foo <string> param1 param2 [param3 [param4]]
  test --help
  test --version

Options:
  -b, --bar <string>

  bar-description

  -f, --foo <string>  : foo-help
  -h, --help          : show this help message and exit
  -v, --version       : show version and exit

]==])
end

function testcase.fail_with_too_many_parameters()
    local f = assert(io.tmpfile())
    io.stdout = f
    os.exit = function(code)
        error('exit with code ' .. code)
    end

    -- test that exit with error when required argument is not specified
    local err = assert.throws(getopts, {
        name = 'test',
        params = {
            'param1',
            'param2',
        },
    }, {
        foo = {
            alias = 'f',
        },
    }, 'hello', 'getopts', 'world')
    io.stdout = stdout
    f:seek('set')
    assert.match(err, 'exit with code -1')
    assert.match(f:read('*a'), 'too many parameters')
end

function testcase.fail_without_required_parameters()
    local f = assert(io.tmpfile())
    io.stdout = f
    os.exit = function(code)
        error('exit with code ' .. code)
    end

    -- test that exit with error when required argument is not specified
    local err = assert.throws(getopts, {
        name = 'test',
        params_required = 2,
    }, {
        foo = {
            alias = 'f',
        },
    }, 'hello')
    io.stdout = stdout
    f:seek('set')
    assert.match(err, 'exit with code -1')
    assert.match(f:read('*a'),
                 'parameters must be specified at least 2 required')
end

function testcase.fail_without_required_argument()
    local f = assert(io.tmpfile())
    io.stdout = f
    os.exit = function(code)
        error('exit with code ' .. code)
    end

    -- test that exit with error when required argument is not specified
    local err = assert.throws(getopts, {
        name = 'test',
    }, {
        foo = {
            alias = 'f',
            required = true,
        },
    })
    io.stdout = stdout
    f:seek('set')
    assert.match(err, 'exit with code -1')
    assert.match(f:read('*a'), 'required option: \"--foo\" is not specified')
end

function testcase.fail_with_invalid_prefix()
    local f = assert(io.tmpfile())
    io.stdout = f
    os.exit = function(code)
        error('exit with code ' .. code)
    end

    -- test that exit with error if option prefix is not '-' or '--'
    local err = assert.throws(getopts, {
        name = 'test',
    }, {
        foo = {
            alias = 'f',
        },
    }, '---foo', 'bar')
    io.stdout = stdout
    f:seek('set')
    assert.match(err, 'exit with code -1')
    assert.match(f:read('*a'), 'unknown option: \"---foo\"')
end

function testcase.fail_with_unknown_option()
    local f = assert(io.tmpfile())
    io.stdout = f
    os.exit = function(code)
        error('exit with code ' .. code)
    end

    -- test that exit with error if unknown option is specified
    local err = assert.throws(getopts, {
        name = 'test',
    }, {
        foo = {
            alias = 'f',
        },
    }, '--bar', 'baz')
    io.stdout = stdout
    f:seek('set')
    assert.match(err, 'exit with code -1')
    assert.match(f:read('*a'), 'unknown option: \"--bar\"')
end

function testcase.fail_without_option_value()
    local f = assert(io.tmpfile())
    io.stdout = f
    os.exit = function(code)
        error('exit with code ' .. code)
    end

    -- test that exit with error if option value is not specified
    local err = assert.throws(getopts, {
        name = 'test',
    }, {
        foo = {
            alias = 'f',
        },
    }, '--foo')
    io.stdout = stdout
    f:seek('set')
    assert.match(err, 'exit with code -1')
    assert.match(f:read('*a'), 'option \"--foo\" value is not specified')
end

function testcase.fail_with_invalid_number_value()
    local f = assert(io.tmpfile())
    io.stdout = f
    os.exit = function(code)
        error('exit with code ' .. code)
    end

    -- test that exit with error if option value is not number
    local err = assert.throws(getopts, {
        name = 'test',
    }, {
        foo = {
            alias = 'f',
            type = 'number',
        },
    }, '--foo', 'hello')
    io.stdout = stdout
    f:seek('set')
    assert.match(err, 'exit with code -1')
    assert.match(f:read('*a'), 'option \"--foo\" value \"hello\" is not number')
end

function testcase.fail_with_invalid_boolean_value()
    local f = assert(io.tmpfile())
    io.stdout = f
    os.exit = function(code)
        error('exit with code ' .. code)
    end

    -- test that exit with error if option value is not boolean
    local err = assert.throws(getopts, {
        name = 'test',
    }, {
        foo = {
            alias = 'f',
            type = 'boolean',
        },
    }, '--foo', 'hello')
    io.stdout = stdout
    f:seek('set')
    assert.match(err, 'exit with code -1')
    assert.match(f:read('*a'), 'option \"--foo\" value \"hello\" is not boolean')
end

function testcase.fail_with_option_specified_twice()
    local f = assert(io.tmpfile())
    io.stdout = f
    os.exit = function(code)
        error('exit with code ' .. code)
    end

    -- test that exit with error if option value is not boolean
    local err = assert.throws(getopts, {
        name = 'test',
    }, {
        foo = {
            alias = 'f',
        },
    }, '--foo', 'hello', '--foo', 'world')
    io.stdout = stdout
    f:seek('set')
    assert.match(err, 'exit with code -1')
    assert.match(f:read('*a'), 'option \"--foo\" is specified twice')
end

