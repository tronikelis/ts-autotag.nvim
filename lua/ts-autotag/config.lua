local M = {}

---@type TsAutotag.Config
M.config = {
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

return M
