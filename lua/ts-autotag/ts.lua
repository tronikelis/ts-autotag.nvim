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

---@param from_node TSNode
---@param to_node TSNode
---@param bufnr integer
---@param to_fmt string
function M.copy_buf_contents(from_node, to_node, bufnr, to_fmt)
	local from_iden = M.get_node_iden(from_node)
	local to_iden = M.get_node_iden(to_node)

	local from_text = ""
	if from_iden then
		from_text = vim.treesitter.get_node_text(from_iden, bufnr)
	end
	local to_text = ""
	if to_iden then
		to_text = vim.treesitter.get_node_text(to_iden, bufnr)
	end

	if from_text == to_text then -- bail out early
		return
	end

	local to = to_iden or to_node

	local to_range = { to:range(false) }

	local to_indices = {
		start_row = to_range[1],
		start_col = to_range[2],
		end_row = to_range[3],
		end_col = to_range[4],
	}
	-- idk if this is even possible
	if to_indices.start_row ~= to_indices.end_row then
		print("[ts-autotag.nvim] multi row renames not supported")
		return
	end

	local l = vim.api.nvim_buf_get_lines(bufnr, to_indices.start_row, to_indices.start_row + 1, true)[1]

	local renamed = l:sub(1, to_indices.start_col)
	if not to_iden then
		renamed = renamed .. string.format(to_fmt, from_text)
	else
		renamed = renamed .. from_text
	end
	renamed = renamed .. l:sub(to_indices.start_col + to:byte_length() + 1)

	vim.api.nvim_buf_set_lines(bufnr, to_indices.start_row, to_indices.end_row + 1, true, { renamed })
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

return M
