local notify = require('notify').notify
local extension = {}
local unicode_blocks = { '▏', '▎', '▍', '▌', '▋', '▊', '▉', '█' }

local function index_with_value(t)
  local i = {}
  for k = 1, #t do
    table.insert(i, k)
  end

  return function()
    local k = table.remove(i)
    if k ~= nil then
      return k, t[k]
    end
  end
end

local function progress_bar(percentage)
  local bar = ''
  -- multiply by 2 to make the bar twice as big
  local percentage_done = percentage * 2
  local percentage_remaining = 200 - percentage_done

  for value, char in index_with_value(unicode_blocks) do
    local number = math.floor(percentage_done / value)
    percentage_done = math.fmod(percentage_done, value)
    for _ = 1, number do
      bar = bar .. char
    end
  end

  for _ = 1, math.floor(percentage_remaining / #unicode_blocks) do
    bar = bar .. ' '
  end

  return string.format('[ %s ] %.2f %%', bar, percentage)
end

function extension.notify(msg, log_level, opts)
  log_level = log_level or 2
  opts = opts or {}

  local notify_opts = {
    title = opts.summary or opts.app_name or nil,
  }

  if 0 ~= opts.replaces_id then
    notify_opts.replace = opts.replaces_id
  end

  if 100 == opts.progress then
    notify_opts.icon = ''
    notify_opts.timeout = 2000 -- Must be reset otherwise keep original value
    notify_opts.hide_from_history = false
  elseif nil ~= opts.progress then
    notify_opts.timeout = false
    notify_opts.hide_from_history = true
    msg = msg .. '\n' .. progress_bar(opts.progress)
  end

  return notify(msg, log_level, notify_opts).id
end

return extension
