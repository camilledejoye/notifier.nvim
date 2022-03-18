# Description

This is a playground for me to work on my Lua skills ;)  
This plugin is tailored for my personal setup and preferences and might hide some notifications you would like to see.  
Therefore it's not recommended to use it, except if you are adventurous!

The basic idea is that even though we can replace `vim.notify` by any function as long as it follows the signature
defined by Neovim, it's still not easily reusable by plugins since the options are not normalized.  
So I played with the idea of leveraging the [Desktop Notifications Specification
](https://specifications.freedesktop.org/notification-spec/notification-spec-latest.html) to define these options.

It's then possible to implement an adapter for any kind of notification system, within Neovim or external.  
Currently there is two builtin adapters:
* [gdbus](https://www.freedesktop.org/software/gstreamer-sdk/data/docs/2012.5/gio/gdbus.html) to send notifications
  using D-Bus messages (to leverage use your desktop notifications for instance)
* [rcarriga/nvim-notify](https://github.com/rcarriga/nvim-notify) to keep the notifications within Neovim

There is also an extension system which was more a way for me to quickly integrate LSP progress messages by keeping
things close.
I'm not sure there is any real need for an extension system as long as the adapter is exposed.

# Requirements

* Neovim >= `v0.6.1`

# Installation

Use your favorite package manager as usual.

# Configuration

```lua
use {
  'camilledejoye/notifier.nvim',
  requires = {
    'nvim-lua/plenary.nvim',
    'rcarriga/nvim-notify',
  },
  config = function()
    require('notifier').setup {
      adapter = require('notifier.adapters.nvim-notify'), -- Which adapter to use
      use_globally = true, -- Will configure `vim.notify` to use the adapter
      extensions = {
        lsp = {
          enabled = true, -- Will show LSP progress messages
          -- You can choose a specific adapter for the extension:
          -- adapter = require('notifier.adapters.nvim-notify'),
        },
      },
    }
  end,
}
```
