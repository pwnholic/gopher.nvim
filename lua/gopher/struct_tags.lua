---@toc_entry Modify struct tags
---@tag gopher.nvim-struct-tags
---@text
--- `struct_tags` is utilizing the `gomodifytags` tool to add or remove tags to struct fields.
---
---@usage
--- How to add/remove tags to struct fields:
--- 1. Place cursor on the struct
--- 2. Run `:GoTagAdd json` to add json tags to struct fields
--- 3. Run `:GoTagRm json` to remove json tags to struct fields
---
--- To clear all tags from struct run: `:GoTagClear`
---
--- NOTE: if you don't specify the tag it will use `json` as default
---
--- Example:
--- >go
---    // before
---    type User struct {
---    // ^ put your cursor here
---    // run `:GoTagAdd yaml`
---        ID int
---        Name string
---    }
---
---    // after
---    type User struct {
---        ID int      `yaml:id`
---        Name string `yaml:name`
---    }
--- <

local ts = require "gopher._utils.ts"
local r = require "gopher._utils.runner"
local c = require "gopher.config"
local u = require "gopher._utils"
local log = require "gopher._utils.log"

---@dochide
---@class gopher.StructTagInput
---@field tags string[] User provided tags
---@field range? gopher.StructTagRange  (optional)

---@dochide
---@class gopher.StructTagRange
---@field start number
---@field end_ number

local struct_tags = {}

-- Helper functions for better organization

---@param args string[]
---@return string
local function format_user_tags(args)
    return #args == 0 and c.gotag.default_tag or table.concat(args, ",")
end

---@param args table
---@return table
local function build_command_args(base_args, location_args, user_args)
    return vim.list_extend(vim.list_extend(base_args, location_args), user_args)
end

---@param res table
---@return string[]
local function process_response_lines(res)
    local lines = res.lines or {}
    return vim.tbl_map(u.trimend, lines)
end

---@param action string
---@param opts? gopher.StructTagInput
---@param user_args string[]
local function handle_tag_action(action, opts, user_args)
    log.debug(string.format("%s tags", action), opts)

    local fpath, bufnr = u.get_current_buffer_info()
    local st = ts.get_struct_under_cursor(bufnr)

    if not st and not (opts and opts.range) then
        u.notify("No struct found under cursor and no range specified", vim.log.levels.ERROR)
        return
    end

    -- Build command arguments
    local base_args = {
        "-transform",
        c.gotag.transform,
        "-format",
        c.commands.gomodifytags.format or "json",
        "-file",
        fpath,
        "-w",
    }

    -- Add flags safely
    if c.commands.gomodifytags.flag and #c.commands.gomodifytags.flag > 0 then
        vim.list_extend(base_args, c.commands.gomodifytags.flag)
    end

    -- Determine location (range or struct)
    local location_args
    if opts and (opts.range or (st and st.is_varstruct)) then
        local range = opts.range or st
        location_args = { "-line", string.format("%d,%d", range.start, range.end_) }
    elseif st then
        location_args = { "-struct", st.name }
    else
        u.notify("Unable to determine struct location", vim.log.levels.ERROR)
        return
    end

    local cmd = u.build_command(
        { c.commands.gomodifytags.cmd },
        build_command_args(base_args, location_args, user_args)
    )

    local rs = r.sync(cmd)
    if not u.handle_command_result(rs, string.format("failed to %s tags", action)) then
        return
    end

    local ok, res = pcall(vim.json.decode, rs.stdout)
    if not ok or not res then
        u.notify("Failed to decode command response", vim.log.levels.ERROR)
        return
    end

    if res.errors and #res.errors > 0 then
        local msg = string.format("failed to %s tags: %s", action, vim.inspect(res.errors))
        log.error("tags: " .. msg)
        u.notify(msg, vim.log.levels.ERROR)
        return
    end

    local trimmed_lines = process_response_lines(res)

    vim.api.nvim_buf_set_lines(
        bufnr,
        res.start - u.BUFFER_INDEX_OFFSET,
        res.start - u.BUFFER_INDEX_OFFSET + #trimmed_lines,
        true,
        trimmed_lines
    )
end

-- Public API

-- Adds tags to a struct under the cursor
-- See |gopher.nvim-struct-tags|
---@param opts gopher.StructTagInput
function struct_tags.add(opts)
    if not opts then
        u.notify("opts parameter is required", vim.log.levels.ERROR)
        return
    end

    local user_tags = format_user_tags(opts.tags or {})
    handle_tag_action("add", opts, { "-add-tags", user_tags })
end

-- Removes tags from a struct under the cursor
-- See `:h gopher.nvim-struct-tags`
---@param opts gopher.StructTagInput
function struct_tags.remove(opts)
    if not opts then
        u.notify("opts parameter is required", vim.log.levels.ERROR)
        return
    end

    local user_tags = format_user_tags(opts.tags or {})
    handle_tag_action("remove", opts, { "-remove-tags", user_tags })
end

-- Removes all tags from a struct under the cursor
-- See `:h gopher.nvim-struct-tags`
function struct_tags.clear()
    handle_tag_action("clear", nil, { "-clear-tags" })
end

return struct_tags
