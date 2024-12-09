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
		"erroneous_end_tag_name",

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

			-- html
			"end_tag",
			"erroneous_end_tag",

			-- templ
			"tag_end",
		},
	},
}

return M
