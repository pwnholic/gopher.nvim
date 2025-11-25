---@toc_entry Generating unit tests boilerplate
---@tag gopher.nvim-gotests
---@text gotests is utilizing the `gotests` tool to generate unit tests boilerplate.
---@usage
--- - Generate unit test for specific function/method:
---   1. Place your cursor on the desired function/method.
---   2. Run `:GoTestAdd`
---
--- - Generate unit tests for *all* functions/methods in current file:
---   - run `:GoTestsAll`
---
--- - Generate unit tests *only* for *exported(public)* functions/methods:
---   - run `:GoTestsExp`
---
--- You can also specify the template to use for generating the tests. See |gopher.nvim-config|
--- More details about templates can be found at: https://github.com/cweill/gotests
---
--- If you prefer named tests, you can enable them in |gopher.nvim-config|.

local c = require "gopher.config"
local ts_utils = require "gopher._utils.ts"
local r = require "gopher._utils.runner"
local u = require "gopher._utils"
local log = require "gopher._utils.log"
local gotests = {}

---@param args string[]
---@dochide
local function add_test(args)
    local extra_args = {}

    if c.gotests.named then
        table.insert(extra_args, "-named")
    end

    if c.gotests.template_dir then
        vim.list_extend(extra_args, { "-template_dir", c.gotests.template_dir })
    end

    if c.gotests.template ~= "default" then
        vim.list_extend(extra_args, { "-template", c.gotests.template })
    end

    vim.list_extend(extra_args, { "-w", vim.fn.expand "%" })

    local cmd = u.build_command({ c.commands.gotests.cmd }, vim.list_extend(args, extra_args))
    log.debug("generating tests with cmd: ", cmd)

    local rs = r.sync(cmd)
    if not u.handle_command_result(rs, "gotests failed") then
        return
    end

    u.notify "unit test(s) generated"
end

-- generate unit test for one function
function gotests.func_test()
    local _, bufnr = u.get_current_buffer_info()
    local func = ts_utils.get_func_under_cursor(bufnr)
    add_test { "-only", func.name }
end

-- generate unit tests for all functions in current file
function gotests.all_tests()
    add_test { "-all" }
end

-- generate unit tests for all exported functions
function gotests.all_exported_tests()
    add_test { "-exported" }
end

return gotests
