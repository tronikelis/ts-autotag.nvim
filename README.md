<h1 align="center">
    ts-autotag.nvim
</h1>

<!--toc:start-->
- [Introduction](#introduction)
- [Examples](#examples)
  - [Auto close tag](#auto-close-tag)
  - [Manual rename tag](#manual-rename-tag)
  - [Auto live rename tag](#auto-live-rename-tag)
- [Install](#install)
- [Configuration](#configuration)
- [Differences between nvim-ts-autotag](#differences-between-nvim-ts-autotag)
<!--toc:end-->

## Introduction

A minimalist [Neovim](https://neovim.io/) plugin that auto closes & renames html/jsx elements without setting keymaps

## Examples

### Auto close tag

![auto close tag gif](https://github.com/user-attachments/assets/64654405-3748-4164-ae52-911d96c2637a)

### Manual rename tag

> [!NOTE]
> Keymaps are not set by default, you have to set them yourself like so

```lua
vim.keymap.set("n", "<leader>rn", function()
	-- it returns success status, thus you can fallback like so
	if not require("ts-autotag").rename() then
		vim.lsp.buf.rename()
	end
end)
```

Or you can use a user command `:TsTagRename`

![manual rename tag gif](https://github.com/user-attachments/assets/0897a3e0-e81d-4be5-8a9c-c8ae98b81b31)

### Auto live rename tag

> [!NOTE]
> Feature is not enabled by default, enable with auto_rename.enabled = true

![auto rename tag gif](https://github.com/user-attachments/assets/ae6f17ab-6108-4805-b86a-ccd047df9ab9)

## Install

Install with your favorite plugin manager

Calling `setup()` is optional, only if you want to override default settings,
for example enabling auto live rename

Plugin is lazy loaded by default

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

	-- plugin will be initialized on these filetypes
	filetypes = {
		"typescript",
		"javascript",
		"typescriptreact",
		"javascriptreact",
		"xml",
		"html",
		"templ",
	},

	auto_close = {
		enabled = true,
	},
	auto_rename = {
		enabled = false,
		closing_node_types = {
			-- jsx
			"jsx_closing_element",

			-- xml,
			"ETag",

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
