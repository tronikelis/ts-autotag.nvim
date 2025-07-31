<h1 align="center">
    ts-autotag.nvim
</h1>

<!--toc:start-->
- [Introduction](#-introduction)
- [Examples](#-examples)
  - [Auto close tag](#auto-close-tag)
  - [Auto rename tag](#auto-rename-tag)
- [Install](#-install)
- [Configuration](#-configuration)
- [Differences between nvim-ts-autotag](#-differences-between-nvim-ts-autotag)
<!--toc:end-->

## Introduction

A minimalist [Neovim](https://neovim.io/) plugin that auto closes & renames html/jsx elements without setting keymaps

## Examples

### Auto close tag

![auto close tag gif](https://github.com/user-attachments/assets/64654405-3748-4164-ae52-911d96c2637a)

### Auto rename tag

![auto rename tag](https://github.com/user-attachments/assets/f09eadf1-8440-45e6-b035-084fd97cc7a3)

## Install

With lazy.nvim

```lua
{
    "tronikelis/ts-autotag.nvim",
    opts = {},
    -- ft = {}, optionally you can load it only in jsx/html
    event = "VeryLazy",
}
```

## Configuration

Default config

```lua
{

	opening_node_types = {
		-- templ
		"tag_start",

		-- xml,
		"STag",

		-- html
		"start_tag",

		-- jsx
		"jsx_opening_element",
	},
	identifier_node_types = {
		-- html
		"tag_name",
		"erroneous_end_tag_name",

		-- xml,
		"Name",

		-- jsx
		"member_expression",
		"identifier",

		-- templ
		"element_identifier",
	},

	disable_in_macro = true,

	auto_close = {
		enabled = true,
	},
	auto_rename = {
		enabled = true,
		closing_node_types = {
			-- jsx
			"jsx_closing_element",

			-- xml,
			"Etag",

			-- html
			"end_tag",
			"erroneous_end_tag",

			-- templ
			"tag_end",
		},
	},
}
```

## Differences between nvim-ts-autotag

- A much more "dumb" and simple solution which just checks child node types under cursor
- Does not override any keymaps, `nvim-ts-autotag` overrides `>` keymap which could break other plugins
