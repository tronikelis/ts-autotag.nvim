local M = {}

---@param node TSNode?
---@param type string[]
---@return TSNode?
function M.find_first_parent(node, type)
	if not node then
		return
	end

	node = node:parent()
	if not node then
		return
	end

	if vim.list_contains(type, node:type()) then
		return node
	end

	return M.find_first_parent(node, type)
end

---@param node TSNode?
---@param type string[]
---@return TSNode?
function M.find_first_child(node, type)
	if not node then
		return
	end

	if vim.list_contains(type, node:type()) then
		return node
	end

	for n in node:iter_children() do
		local found = M.find_first_child(n, type)
		if found then
			return found
		end
	end
end

---@param from TSNode
---@param to TSNode
---@param bufnr integer
function M.copy_buf_contents(from, to, bufnr)
	local from_text = vim.treesitter.get_node_text(from, bufnr)

	local to_range = { to:range(false) }

	local to_indices = {
		start_row = to_range[1],
		start_col = to_range[2],
		end_row = to_range[3],
		end_col = to_range[4],
	}
	local to_len = to_indices.end_col - to_indices.start_col + 1

	-- idk if this is even possible
	if to_indices.start_row ~= to_indices.end_row then
		print("[ts-autotag.nvim] multi row renames not supported")
		return
	end

	local l = vim.api.nvim_buf_get_lines(bufnr, to_indices.start_row, to_indices.start_row + 1, true)[1]

	local renamed = l:sub(1, to_indices.start_col) .. from_text .. l:sub(to_indices.start_col + to_len)

	vim.api.nvim_buf_set_lines(bufnr, to_indices.start_row, to_indices.end_row + 1, true, { renamed })
end

return M
