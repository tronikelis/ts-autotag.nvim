local M = {}

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

---@param node TSNode?
---@param type string[]
---@return TSNode?
local function find_first_child(node, type)
	if not node then
		return
	end

	if vim.list_contains(type, node:type()) then
		return node
	end

	for n in node:iter_children() do
		local found = find_first_child(n, type)
		if found then
			return found
		end
	end
end

---@param node TSNode
---@param bufnr integer
---@return string[]|nil
local function extract_node_contents(node, bufnr)
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

local function maybe_close_tag(bufnr)
	local cursor = vim.api.nvim_win_get_cursor(0)
	-- get node at cursor position with col - 1, so we are inside the written tag
	local node_pos = { cursor[1] - 1, cursor[2] - 1 }

	vim.treesitter.get_parser(bufnr):parse(node_pos)

	local before_cursor = vim.treesitter.get_node({ bufnr = bufnr, pos = node_pos })
	if not before_cursor then
		return
	end

	if not vim.list_contains(M.config.cursor_node_types, before_cursor:type()) then
		return
	end

	local identifier = find_first_child(before_cursor, M.config.identifier_node_types)
	local tag = not identifier and { "" } or extract_node_contents(identifier, bufnr)
	if not tag then
		return
	end

	tag[1] = "</" .. tag[1]
	tag[#tag] = tag[#tag] .. ">"

	vim.api.nvim_put(tag, "", true, false)
	vim.api.nvim_win_set_cursor(0, { cursor[1] + #tag - 1, cursor[2] })
end

function M.setup(opts)
	opts = opts or {}
	M.config = vim.tbl_deep_extend("force", M.config, opts)

	local prev_line = ""

	vim.api.nvim_create_autocmd("TextChangedI", {
		callback = function(ev)
			local line = vim.api.nvim_get_current_line()

			if #line - #prev_line == 1 and line:find(M.config.line_must_match) then
				maybe_close_tag(ev.buf)
			end

			prev_line = line
		end,
	})
end

return M
