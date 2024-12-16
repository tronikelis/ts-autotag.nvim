local ts = require("ts-autotag.ts")
local config = require("ts-autotag.config")

local M = {}

---@param opts vim.treesitter.get_node.Opts
---@param depth integer
---@return TSNode?
function M.get_opening_node(opts, depth)
	local current = vim.treesitter.get_node(opts)
	if not current then
		return
	end

	return ts.find_parent(current, function(n)
		return vim.list_contains(config.config.opening_node_types, n:type())
	end, depth)
end

---@param node TSNode?
---@return TSNode?
function M.get_node_iden(node)
	return ts.find_first_child(node, function(n)
		return vim.list_contains(config.config.identifier_node_types, n:type())
	end)
end

return M
