<h1 align="center">
    ts-autotag.nvim
</h1>

## 📃 Introduction

A minimalist [Neovim](https://neovim.io/) plugin that auto closes & renames html/jsx elements without setting keymaps

## 🖥️ Examples

### Auto close tag

![auto close tag gif](https://github.com/user-attachments/assets/64654405-3748-4164-ae52-911d96c2637a)

### Auto rename tag

*WIP*

## 📦 Install

With lazy.nvim

```lua
{
    "tronikelis/ts-autotag.nvim",
    opts = {},
    event = "VeryLazy",
}
```

## 🔧 Configuration

Default config

```lua
{
	auto_rename = true,
	-- <div|> node type on cursor |
	-- one of the children must be of this type
	cursor_node_types = {
		"start_tag",
		"jsx_opening_element",
	},
	-- extract identifier from these types
	identifier_node_types = {
		"tag_name", -- html
		"member_expression", -- jsx <Provider.Context>
		"identifier", -- fallback <div>
	},
	-- don't even try to close if line does not match this pattern
	-- even if it matches this does not mean that it will close
	line_must_match = [[<.*>$]],
}
```
