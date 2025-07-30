local ts = require("ts-autotag.ts")
local config = require("ts-autotag.config")

local M = {}

---@param bufnr integer
---@return boolean
function M.maybe_rename_closing_tag(bufnr)
	local ok, parser = pcall(vim.treesitter.get_parser, bufnr)
	if not ok or not parser then
		return false
	end

	local cursor_row = vim.api.nvim_win_get_cursor(0)[1]
	parser:parse({ cursor_row, cursor_row })

	local closing_node = ts.get_closing_node({ bufnr = bufnr }, 1)
	if not closing_node then
		return false
	end

	local opening_node = ts.first_sibling(closing_node)
	if not opening_node then
		return false
	end
	if not vim.list_contains(config.config.auto_rename.closing_node_types, closing_node:type()) then
		return false
	end

	ts.copy_buf_contents(closing_node, opening_node, bufnr, "<%s>")
	return true
end

---@param bufnr integer
---@return boolean
function M.maybe_rename_opening_tag(bufnr)
	local ok, parser = pcall(vim.treesitter.get_parser, bufnr)
	if not ok or not parser then
		return false
	end

	local cursor_row = vim.api.nvim_win_get_cursor(0)[1]
	parser:parse({ cursor_row, cursor_row })

	local opening_node = ts.get_opening_node({ bufnr = bufnr }, 1)
	if not opening_node then
		return false
	end

	local closing_node = ts.last_sibling(opening_node)
	if not closing_node then
		return false
	end
	if not vim.list_contains(config.config.auto_rename.closing_node_types, closing_node:type()) then
		return false
	end

	ts.copy_buf_contents(opening_node, closing_node, bufnr, "</%s>")
	return true
end

function M.setup()
	---@type TSNode?
	vim.api.nvim_create_autocmd({ "TextChanged", "TextChangedI" }, {
		callback = function(ev)
			if config.config.disable_in_macro and vim.fn.reg_recording() ~= "" then
				return
			end

			if not M.maybe_rename_opening_tag(ev.buf) then
				M.maybe_rename_closing_tag(ev.buf)
			end
		end,
	})
end

return M
