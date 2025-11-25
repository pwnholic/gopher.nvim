local r = require "gopher._utils.runner"
local c = require("gopher.config").commands
local u = require "gopher._utils"
local gocmd = {}

---@param args string[]
---@return string[]
local function if_get(args)
  for i, arg in ipairs(args) do
    -- Extract URL path if it's a URL, otherwise keep as is
    local cleaned = arg:match "^https?://(.*)$" or arg
    if cleaned ~= arg then
      args[i] = cleaned
    end
  end
  return args
end

---@param args unknown[]
---@return string[]
local function if_generate(args)
  if #args == 1 and args[1] == "%" then
    args[1] = vim.fn.expand "%"
  end
  return args
end

---@param subcmd string
---@param args string[]
---@return string
function gocmd.run(subcmd, args)
  if #args == 0 and subcmd ~= "generate" then
    error "please provide any arguments"
  end

  -- Process arguments based on subcommand
  if subcmd == "get" then
    args = if_get(args)
  elseif subcmd == "generate" then
    args = if_generate(args)
  end

  local cmd = u.build_command({ c.go }, { subcmd, unpack(args) })
  local rs = r.sync(cmd)

  if not u.handle_command_result(rs, "go " .. subcmd .. " failed") then
    error("go " .. subcmd .. " failed")
  end

  u.notify(c.go .. " " .. subcmd .. " ran successful")
  return rs.stdout
end

return gocmd
