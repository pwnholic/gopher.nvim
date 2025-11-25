-- Thanks https://github.com/koron/iferr for vim implementation

---@toc_entry Iferr
---@tag gopher.nvim-iferr
---@text
--- `iferr` provides a way to way to automatically insert `if err != nil` check.
--- If you want to change `-message` option of `iferr` tool, see |gopher.nvim-config|
---
---@usage Execute `:GoIfErr` near any `err` variable to insert the check

local c = require "gopher.config"
local u = require "gopher._utils"
local r = require "gopher._utils.runner"
local log = require "gopher._utils.log"
local iferr = {}

function iferr.iferr()
    local curb = vim.fn.wordcount().cursor_bytes
    local pos = u.get_cursor_line()
    local fpath, _ = u.get_current_buffer_info()

    local cmd_args = { "-pos", curb, unpack(c.commands.iferr.flag) }
    if c.iferr.message and type(c.iferr.message) == "string" then
        vim.list_extend(cmd_args, { "-message", c.iferr.message })
    end

    local cmd = u.build_command({ c.commands.iferr.cmd }, cmd_args)

    local rs = r.sync(cmd, {
        stdin = u.readfile_joined(fpath),
    })

    if not u.handle_command_result(rs, "iferr failed") then
        if string.find(rs.stderr or "", "no functions at") then
            u.notify("iferr: no function at " .. curb, vim.log.levels.WARN)
            log.warn("iferr: no function at " .. curb)
        end
        return
    end

    local output = u.remove_empty_lines(vim.split(rs.stdout, "\n"))
    vim.fn.append(pos, output)
    vim.cmd [[silent normal! j=2j]]
    vim.fn.setpos(".", pos)
end

return iferr
