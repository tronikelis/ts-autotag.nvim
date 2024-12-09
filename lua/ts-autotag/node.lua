local ts = require("ts-autotag.ts")
local config = require("ts-autotag.config")

local M = {}

---@param opts vim.treesitter.get_node.Opts
---@return TSNode?
function M.get_opening_node(opts)
	local current = vim.treesitter.get_node(opts)
	if not current then
		return
	end

	if vim.list_contains(config.config.opening_node_types, current:type()) then
		return current
	end
end

---@param node TSNode?
---@return TSNode?
function M.get_node_iden(node)
	return ts.find_first_child(node, config.config.identifier_node_types)
end

return M
