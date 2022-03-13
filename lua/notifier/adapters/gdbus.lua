local gdbus = {}

-- https://specifications.freedesktop.org/notification-spec/notification-spec-latest.html#commands
function gdbus.notify(msg, log_level, opts)
  log_level = log_level or 2
  opts = opts or {}
  -- Match vim.lsp.log_levels to notify-send urgency
  local urgency = log_level < 2 and 1 or log_level < 3 and 2 or 3
  local timeout = -1 -- In ms, 0 = never expire, -1 = default server configuration
  local summary = opts.summary or msg
  local body = opts.summary and msg or nil
  local hints = {
    format = function(self)
      local items = {}

      for key, value in pairs(self) do
        if 'format' ~= key then
          local item = 'number' == type(value) and ('"%s": <int32 %d>'):format(key, value)
            or ('"%s": <"%s">'):format(key, value)
          table.insert(items, item)
        end
      end

      return ('{ %s }'):format(table.concat(items, ', '))
    end,
    urgency = urgency,
    ['desktop-entry'] = 'Neovim',
    -- TODO download an icon to put in stdpath('data') ?
    ['image-path'] = 'file:///usr/share/icons/Sardi-Ghost-Flexible/scalable/apps/neovim.svg',
  }

  -- TODO check if it's dunst first or add a method plug into the construction of
  -- arguments and add cusom hints
  if opts.progress then
    hints.value = opts.progress
  end

  local args = {
    'call',
    '--session',
    '--dest=org.freedesktop.Notifications',
    '--object-path=/org/freedesktop/Notifications',
    '--method=org.freedesktop.Notifications.Notify',
    opts.app_name or 'Neovim',
    opts.replaces_id or 0, -- 0 = don't replace any notification
    '', -- app_icon
    summary,
    body or '',
    '[]', -- actions
    hints:format(),
    ('int32 %d'):format(timeout),
  }

  -- Prevent the cursor from blinking on each notification
  local output = require('plenary.job')
    :new({
      command = 'gdbus',
      args = args,
    })
    :sync()

  return output[1]:match('uint32 (%d+)')
end

return gdbus
