- [Requirements](#requirements)
- [Usage](#usage)
- [Configuration](#configuration)

# Vertigo

Vertigo helps vertical motions/operations by using labels instead of relative numbers.

## Requirements

To use this plugin, you need :

- to have [Neovim](https://github.com/neovim/neovim)
  [`0.8+`](https://github.com/neovim/neovim/releases) version installed ;
- to add `woosaaahh/vertigo.nvim` in your plugin manager configuration.

Here are some plugin managers :

- [vim-plug](https://github.com/junegunn/vim-plug) ;
- [packer.nvim](https://github.com/wbthomason/packer.nvim) ;
- [paq-nvim](https://github.com/savq/paq-nvim).

## Usage

There are three functions that can be used :

- `vertigo.jump_to_line_above()` to jump on a line above the cursor;
- `vertigo.jump_to_line_below()` to jump on a line below the cursor;
- `vertigo.jump_to_line()` to jump on a line above or below the cursor.

**NOTE** : If you use `vertigo.jump_to_line()`, you will have to press `k` or `j` after
selecting the label. It will help to define which side to choose. 

## Configuration

Here is the default configuration :

```lua
local opts = {
	prefix_keys = { "", ",", ";", ":", "!", "_", "<" },
	-- stylua: ignore
	target_keys = {
		"a", "b", "c", "d", "e", "f", "g", "h", "i", "j", "k", "l", "m",
		"n", "o", "p", "q", "r", "s", "t", "u", "v", "w", "x", "y", "z",
	},
}
```

and here is a configuration sample :

```lua
local vertigo = require("vertigo")

vim.keymap.set({ "n", "o", "x" }, "mk", function()
	vertigo.jump_to_line_above()
end)

vim.keymap.set({ "n", "o", "x" }, "mj", function()
	vertigo.jump_to_line_below()
end)

vim.keymap.set({ "n", "o", "x" }, "mm", function()
	vertigo.jump_to_line()
end)
```	

**NOTE** : There is no need to use the `vertigo.setup()` function.
