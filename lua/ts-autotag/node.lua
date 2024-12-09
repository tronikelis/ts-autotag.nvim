local ts = require("ts-autotag.ts")
local config = require("ts-autotag.config")

local M = {}

---@param bufnr integer
---@param pos? integer[]
---@return TSNode?
function M.get_opening_node(bufnr, pos)
	local current = vim.treesitter.get_node({ bufnr = bufnr, pos = pos })
	return ts.find_first_parent(current, config.config.opening_node_types)
end

---@param node TSNode?
---@return TSNode?
function M.get_node_iden(node)
	return ts.find_first_child(node, config.config.identifier_node_types)
end

return M
