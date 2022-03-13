---@alias NotificationContent string

---@class NotificationOpts
---@field summary string #An optional title for the notification
---@field app_name string #The optional name of the application sending the notification. Can be blank.
---@field replaces_id integer #The ID of the notification to replace
---@field pregress integer #The optional progress value from 0 to 100

local config = require('notifier.config')

local notifier = {}

---@params opts NotifyOptions
function notifier.setup(opts)
  config = config.set_defaults(opts)

  if config.use_globally then
    vim.notify = config.adapter.notify
  end

  for name, ext_opts in pairs(config.extensions or {}) do
    local loaded, extension = pcall(require, 'notifier.extensions.'..name)

    if loaded then
      pcall(extension.setup, config, ext_opts)
    end
  end
end

---Send a notification
---@param msg NotificationContent
---@param log_level integer
---@param opts NotificationOpts
---@return integer|string|nil #The ID of the sent notification
function notifier.notify(msg, log_level, opts)
  return config.adapter.notify(msg, log_level, opts)
end

return notifier
