---@alias Message ProgressMessage|StatusMessage|OneTimeMessage

---@class ProgressMessage
---@field name string #Client's name
---@field title string #Title, defaults to 'empty title' if not provided
---@field message string|nil
---@field percentage integer #Comprised between 0 and 100
---@field progress boolean #Always `true`
---@field token string|integer #Unique identifier for the progress
---@field done boolean #`true` if it's the last message for this progress

---@class StatusMessage
---@field name string #Client's name
---@field content string|nil
---@field uri string
---@field status boolean #Always `true`

---@class OneTimeMessage
---@field name string #Client's name
---@field content string|nil

-- Duplicate from /usr/share/nvim/runtime/lua/vim/lsp/util.lua
-- Because I need the token and done status but Neovim does not return it
local function get_progress_messages()
  local new_messages = {}
  local msg_remove = {}
  local progress_remove = {}

  for _, client in ipairs(vim.lsp.get_active_clients()) do
    local messages = client.messages
    local data = messages
    for token, ctx in pairs(data.progress) do
      local new_report = {
        name = data.name,
        title = ctx.title or 'empty title',
        message = ctx.message,
        percentage = ctx.percentage,
        progress = true,
        token = token,
        done = ctx.done,
      }
      table.insert(new_messages, new_report)

      if ctx.done then
        table.insert(progress_remove, { client = client, token = token })
      end
    end

    for i, msg in ipairs(data.messages) do
      if msg.show_once then
        msg.shown = msg.shown + 1
        if msg.shown > 1 then
          table.insert(msg_remove, { client = client, idx = i })
        end
      end

      table.insert(new_messages, { name = data.name, content = msg.content })
    end

    if next(data.status) ~= nil then
      table.insert(new_messages, {
        name = data.name,
        content = data.status.content,
        uri = data.status.uri,
        status = true,
      })
    end
    for _, item in ipairs(msg_remove) do
      table.remove(client.messages, item.idx)
    end

    for _, item in ipairs(progress_remove) do
      client.messages.progress[item.token] = nil
    end
  end

  return new_messages
end

local notification_ids = {}
-- Adapter to use to send the notification
local adapter = vim

local lsp = {}

---Filter messages from `sumneko_lua` to not show "empty" notifications when saving a file
local function ignore_sumneko_empty_messages(message)
  if 'sumneko_lua' ~= message.name then
    return true
  end

  return 0 ~= message.percentage
end

---Quick fix to ignore null-ls messages which have no interest for me right now and just
---flood me with notifications
local function ignore_null_ls(message)
  return 'null-ls' ~= message.name
end

---List of function used to filter the message to notify
lsp.filters = {
  ignore_sumneko_empty_messages,
  ignore_null_ls,
}

---Decide if a message notification should be skipped or not
---@return boolean #`true` to skip the message, `false` to show a notification
---@see self.filters #List of filters used to decide which message to skip
function lsp.skip_message(message)
  for _, filter in ipairs(lsp.filters) do
    if not filter(message) then
      return true
    end
  end

  return false
end

---Make the arguments which will be provided to `vim.notify()` for a message
---@param message Message
---@return NotificationContent msg
---@return integer log_level
---@return NotificationOpts opts
---@see vim.notifiy(msg, log_level, opts)
function lsp.make_notify_params(message)
  local summary = 'empty title' == (message.title or 'empty title') and message.name
    or ('[%s] %s'):format(message.name, message.title)
  local body = message.message or (message.done and 'Done') or message.content
  local replaces_id = message.token and notification_ids[message.token] or 0
  local log_level = 2
  local opts = {
    summary = summary,
    app_name = message.name,
    replaces_id = replaces_id,
  }

  if message.progress and nil ~= message.percentage then
    -- Depending on the server computation the end message might not be at 100%
    -- To have a cleaner output I force it here
    opts.progress = message.done and 100 or message.percentage
  end

  return body, log_level, opts
end

---Show LSP messages receives through `$/progress` using `vim.notify`
---@see vim.notify(msg, log_level, opts)
---@see self.skip_message(message: Message)
function lsp.notify_messages()
  for _, message in ipairs(get_progress_messages()) do
    if not lsp.skip_message(message) then
      local notification_id = adapter.notify(lsp.make_notify_params(message))

      if message.token then
        notification_ids[message.token] = notification_id
      end
    end
  end
end

---Setup the LSP notification extension
---@param opts NotifyOptions
---@param ext_opts NotifyLspOptions
function lsp.setup(opts, ext_opts)
  if not ext_opts.enabled then
    return
  end

  adapter = ext_opts.adapter or opts.adapter

  vim.cmd([[
  augroup notify_lsp_messages
    autocmd!
    autocmd User LspProgressUpdate lua require('notifier.extensions.lsp').notify_messages()
  augroup END
  ]])
end

return lsp
