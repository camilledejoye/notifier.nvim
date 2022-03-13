local notify = {}

function notify.notify(msg, log_level, opts)
  log_level = log_level or 2
  opts = opts or {}

  require('notify').notify(msg, log_level, {
    title = opts.summary or opts.app_name or nil,
    -- I don't even try to handle the progress option since it's not supported yet
    -- @see https://github.com/rcarriga/nvim-notify/issues/43
  })

  -- nvim-notify does not identify each notifications
  return 0
end

return notify
