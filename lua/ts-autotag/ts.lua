local config = require("ts-autotag.config")

local M = {}

---@param opts vim.treesitter.get_node.Opts
---@param types string[]
---@param depth integer
---@return TSNode?
function M.get_node(opts, types, depth)
	local current = vim.treesitter.get_node(opts)
	if not current then
		return
	end

	return M.find_parent(current, function(n)
		return vim.list_contains(types, n:type())
	end, depth)
end

---@param opts vim.treesitter.get_node.Opts
---@param depth integer
---@return TSNode?
function M.get_opening_node(opts, depth)
	return M.get_node(opts, config.config.opening_node_types, depth)
end

---@param opts vim.treesitter.get_node.Opts
---@param depth integer
---@return TSNode?
function M.get_closing_node(opts, depth)
	return M.get_node(opts, config.config.auto_rename.closing_node_types, depth)
end

---@param node TSNode?
---@return TSNode?
function M.get_node_iden(node)
	return M.find_first_child(node, function(n)
		return vim.list_contains(config.config.identifier_node_types, n:type())
	end)
end

---@param node TSNode?
---@param predicate fun(node: TSNode): boolean
---@param depth integer
---@return TSNode?
function M.find_parent(node, predicate, depth)
	if not node then
		return
	end

	if predicate(node) then
		return node
	end

	if depth == 0 then
		return
	end
	depth = depth - 1

	return M.find_parent(node:parent(), predicate, depth)
end

---@param node TSNode?
---@param predicate fun(node: TSNode): boolean
---@return TSNode?
function M.find_first_child(node, predicate)
	if not node then
		return
	end

	if predicate(node) then
		return node
	end

	for n in node:iter_children() do
		local found = M.find_first_child(n, predicate)
		if found then
			return found
		end
	end
end

---@class TsAutotag.NodeIndices
---@field start_row integer
---@field start_col integer
---@field end_row integer
---@field end_col integer

---@param node TSNode
---@return TsAutotag.NodeIndices
function M.get_node_indices(node)
	local range = { node:range(false) }
	return {
		start_row = range[1],
		start_col = range[2],
		end_row = range[3],
		end_col = range[4],
	}
end

---@param node TSNode
---@return TSNode?
function M.first_sibling(node)
	local parent = node:parent()
	if not parent then
		return
	end

	local child_count = parent:child_count()
	if child_count == 1 then -- there are no siblings
		return
	end

	return parent:child(0)
end

---@param node TSNode
---@return TSNode?
function M.last_sibling(node)
	local parent = node:parent()
	if not parent then
		return
	end

	local child_count = parent:child_count()
	if child_count == 1 then -- there are no siblings
		return
	end

	return parent:child(child_count - 1)
end

---@param bufnr integer
---@return TSNode?, TSNode?
function M.get_opening_pair(bufnr)
	local opening_node = M.get_opening_node({ bufnr = bufnr }, 1)
	if not opening_node then
		return
	end

	local sibling = M.last_sibling(opening_node)
	if not sibling then
		return
	end
	if not vim.list_contains(config.config.auto_rename.closing_node_types, sibling:type()) then
		return
	end

	return opening_node, sibling
end

---@param bufnr integer
---@return TSNode?, TSNode?
function M.get_closing_pair(bufnr)
	local closing_node = M.get_closing_node({ bufnr = bufnr }, 1)
	if not closing_node then
		return
	end

	local sibling = M.first_sibling(closing_node)
	if not sibling then
		return
	end
	if not vim.list_contains(config.config.opening_node_types, sibling:type()) then
		return
	end

	return closing_node, sibling
end

return M
