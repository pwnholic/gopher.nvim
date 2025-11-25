local c = require "gopher.config"
local log = require "gopher._utils.log"
local utils = {}

-- Constants for better maintainability
utils.CURSOR_LINE_INDEX = 2
utils.BUFFER_INDEX_OFFSET = 1

---@param msg string
---@param lvl? number by default `vim.log.levels.INFO`
function utils.notify(msg, lvl)
  lvl = lvl or vim.log.levels.INFO
  vim.notify(msg, lvl, {
    ---@diagnostic disable-next-line:undefined-field
    title = c.___plugin_name,
  })
  log.debug(msg)
end

---@param path string
---@return string
function utils.readfile_joined(path)
  return table.concat(vim.fn.readfile(path), "\n")
end

---@param t string[]
---@return string[]
function utils.remove_empty_lines(t)
  local res = {}
  for _, line in ipairs(t) do
    if line ~= "" then
      table.insert(res, line)
    end
  end
  return res
end

---@param s string
---@return string
function utils.trimend(s)
  local r, _ = string.gsub(s, "%s+$", "")
  return r
end

-- New utility functions to reduce code duplication

---@return string filepath, number buffer
function utils.get_current_buffer_info()
  return vim.fn.expand "%", vim.api.nvim_get_current_buf()
end

---@param cmd string[]
---@param args string[]
---@return string[]
function utils.build_command(cmd, args)
  local result = vim.deepcopy(cmd)
  for _, arg in ipairs(args) do
    table.insert(result, arg)
  end
  return result
end

---@param rs vim.SystemCompleted|string
---@param operation string
---@param context? string
---@return boolean success
function utils.handle_command_result(rs, operation, context)
  if type(rs) ~= "table" then
    return true -- For backward compatibility
  end

  if rs.code ~= 0 then
    local msg = operation
    if context then
      msg = msg .. " (" .. context .. ")"
    end
    if rs.stderr and rs.stderr ~= "" then
      msg = msg .. ": " .. rs.stderr
    end
    utils.notify(msg, vim.log.levels.ERROR)
    return false
  end

  return true
end

---@return number
function utils.get_cursor_line()
  return vim.fn.getcurpos()[utils.CURSOR_LINE_INDEX]
end

return utils
