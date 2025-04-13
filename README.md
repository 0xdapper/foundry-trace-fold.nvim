# foundry-trace-fold.nvim

A Neovim plugin that provides smart folding for [Foundry](https://github.com/foundry-rs/foundry) traces allowing you to expand and collapse the calls and subcalls as needed.

## Demo

![Demo](https://i.imgur.com/UN43dSh.mp4)

## Installation

Using [lazy.nvim](https://github.com/folke/lazy.nvim):

```lua
{
    "0xdapper/foundry-trace-fold.nvim",
    -- To create the :FoundryFoldToggle command, need to call the setup function
    opts = {}
}
```

## Usage

The plugin provides the following commands:

- `:FoundryFoldToggle` - Toggle folding in current window
- `:FoundryFoldDebugToggle` - Toggle debug mode to show fold levels. (Useful when debugging the plugin)
