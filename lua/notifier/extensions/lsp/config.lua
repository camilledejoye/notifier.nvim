local if_nil = vim.F.if_nil

---@class NotifyLspOptions
---@field enabled boolean #`true` to notify the messages provided by the builtin LSP client
local defaults = {
  enabled = true,
  adapter = nil,
}

local config = {}

function config.set_defaults(user_defaults)
  user_defaults = if_nil(user_defaults, {})

  for name, default in pairs(defaults) do
    if 'table' == type(default) then
      local value = if_nil(user_defaults[name], default)
      config[name] = vim.tbl_extend('force', default, value)
    else
      config[name] = if_nil(user_defaults[name], default)
    end
  end

  return config
end

return config
