local ts = require("ts-autotag.ts")

local M = {}

---@param node TSNode
---@return boolean
local function has_error(node)
	local parent = node:parent()
	if not parent then
		return true
	end

	return parent:has_error()
end

---@param bufnr integer
---@param silent boolean
---@return TSNode?, TSNode?, boolean?
local function get_pair(bufnr, silent)
	local ok, parser = pcall(vim.treesitter.get_parser, bufnr)
	if not ok or not parser then
		if not silent then
			print("TS parser not found")
		end
		return
	end

	local cursor_row = vim.api.nvim_win_get_cursor(0)[1] - 1
	parser:parse({ cursor_row, cursor_row })

	local from, to = ts.get_opening_pair(bufnr)
	if from and to then
		if has_error(from) or has_error(to) then
			if not silent then
				print("TS has syntax errors")
			end
			return
		end
		return from, to, false
	end

	from, to = ts.get_closing_pair(bufnr)
	if from and to then
		if has_error(from) or has_error(to) then
			if not silent then
				print("TS has syntax errors")
			end
			return
		end
		return from, to, true
	end

	if not silent then
		print("TS node not found")
	end
end

---@param bufnr integer
---@param indices TsAutotag.NodeIndices
---@param text string
local function set_indices_text(bufnr, indices, text)
	local old =
		vim.api.nvim_buf_get_text(bufnr, indices.start_row, indices.start_col, indices.end_row, indices.end_col, {})
	if old == text then
		return
	end

	vim.api.nvim_buf_set_text(bufnr, indices.start_row, indices.start_col, indices.end_row, indices.end_col, { text })
end

---@param bufnr? integer
---@param silent? boolean
---@return boolean success
function M.rename(bufnr, silent)
	bufnr = bufnr or vim.api.nvim_get_current_buf()
	if silent == nil then
		silent = false
	end

	local from = get_pair(bufnr, silent)
	if not from then
		return false
	end

	local from_text = ""
	local from_iden = ts.get_node_iden(from)
	if from_iden then
		from_text = vim.treesitter.get_node_text(from_iden, bufnr)
	end

	vim.ui.input({ prompt = "Tag: ", default = from_text }, function(input)
		if not input then
			return
		end

		local a, b, reverse = get_pair(bufnr, silent)
		if not a or not b then
			return
		end

		local a_indices = ts.get_node_indices(a)
		local b_indices = ts.get_node_indices(b)

		local a_text = input
		local b_text = input

		local a_iden = ts.get_node_iden(a)
		if a_iden then
			a_indices = ts.get_node_indices(a_iden)
		else
			if reverse then
				a_text = string.format("</%s>", a_text)
			else
				a_text = string.format("<%s>", a_text)
			end
		end

		local b_iden = ts.get_node_iden(b)
		if b_iden then
			b_indices = ts.get_node_indices(b_iden)
		else
			if not reverse then
				b_text = string.format("</%s>", b_text)
			else
				b_text = string.format("<%s>", b_text)
			end
		end

		set_indices_text(bufnr, a_indices, a_text)

		if a_indices.start_row == b_indices.start_row and a_indices.start_col < b_indices.start_col then
			local a_diff = a_indices.end_col - a_indices.start_col
			a_diff = #a_text - a_diff
			b_indices.start_col = b_indices.start_col + a_diff
			b_indices.end_col = b_indices.end_col + a_diff
		end

		set_indices_text(bufnr, b_indices, b_text)
	end)

	return true
end

return M
