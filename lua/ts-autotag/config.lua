local M = {}

---@type TsAutotag.Config
M.config = {
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
		"identifier", -- jsx <div>

		"erroneous_end_tag_name", -- closing broken html for renaming
	},

	disable_in_macro = true,

	auto_close = {
		enabled = true,
		-- don't even try to close if line till cursor does not match this pattern
		-- even if it matches this does not mean that it will close
		till_cursor_line_match = [[<.*>$]],
	},
	auto_rename = {
		enabled = true,
		ending_node_types = {
			"jsx_closing_element",
			"end_tag",
			"erroneous_end_tag",
		},
	},
}

return M
