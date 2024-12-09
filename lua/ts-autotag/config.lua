local M = {}

---@type TsAutotag.Config
M.config = {
	opening_node_types = {
		-- templ
		"tag_start",

		-- html
		"start_tag",

		-- jsx
		"jsx_opening_element",
	},
	identifier_node_types = {
		-- html
		"tag_name",

		-- jsx
		"member_expression",
		"identifier",

		-- templ
		"element_identifier",
	},

	disable_in_macro = true,

	auto_close = {
		enabled = true,
		-- don't even try to close if line till cursor does not match this pattern
		-- even if it matches this does not mean that it will close
		-- you can think of $ being the cursor
		till_cursor_line_match = [[<.*>$]],
	},
	auto_rename = {
		enabled = true,
		ending_node_types = {
			-- jsx
			"jsx_closing_element",

			-- html
			"end_tag",

			-- templ
			"tag_end",
		},
	},
}

return M
