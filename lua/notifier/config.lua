local if_nil = vim.F.if_nil

---@class NotifyOptions
---@field adapter fun(msg: NotificationContent, log_level: integer, opts: NotificationOpts) #The
--function used to notify, defaults to `vim.notify`
---@field use_globally boolean #`true` to override `vim.notifiy` with `config.notify`
---@field extensions NotifyExtensionsOptions
local defaults = {
  adapter = require('notifier.adapters.gdbus'),
  use_globally = false,
}

---@class NotifyExtensionsOptions
defaults.extensions = {
  lsp = { enabled = true },
}
-- TODO allow to register extension instead, so that a plugin can register it itself or at
-- least lazily ?

local function set_defaults_extension(name, user_defaults)
  local loaded, ext = pcall(require, 'notifier.extensions.'..name)

  if loaded then
    pcall(ext.set_defaults, user_defaults)
  end
end

local config = {}

function config.set_defaults(user_defaults)
  user_defaults = if_nil(user_defaults, {})

  for name, default in pairs(defaults) do
    if 'table' == type(default) then
      local value = if_nil(user_defaults[name], default)
      config[name] = vim.tbl_deep_extend('force', default, value)
    else
      config[name] = if_nil(user_defaults[name], default)
    end
  end

  -- Set default configuration for registered extensions
  for name, default in pairs(config.extensions or {}) do
    set_defaults_extension(name, default or {})
  end

  return config
end

return config
