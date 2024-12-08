local M = {}

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

---@param node TSNode
---@param bufnr integer
---@return string[]|nil
function M.extract_node_contents(node, bufnr)
	local range = { node:range(false) }
	local indices = {
		start_row = range[1],
		start_column = range[2],
		end_row = range[3],
		end_column = range[4],
	}

	local lines = vim.api.nvim_buf_get_lines(bufnr, indices.start_row, indices.end_row + 1, true)

	if #lines == 0 then
		return
	end

	if #lines == 1 then
		return { lines[1]:sub(indices.start_column + 1, indices.end_column) }
	end

	---@type string[]
	local contents = {}

	for i, v in ipairs(lines) do
		if i == 1 then
			table.insert(contents, v:sub(indices.start_column + 1))
		elseif i == #lines then
			table.insert(contents, v:sub(1, indices.end_column))
		else
			table.insert(contents, v)
		end
	end

	return contents
end

return M
