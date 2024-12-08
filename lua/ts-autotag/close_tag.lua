local ts = require("ts-autotag.ts")

local M = {}

---@param config TsAutotag.Config
---@param bufnr integer
function M.maybe_close_tag(config, bufnr)
	local cursor = vim.api.nvim_win_get_cursor(0)
	-- get node at cursor position with col - 1, so we are inside the written tag
	local node_pos = { cursor[1] - 1, cursor[2] - 1 }

	local ok, parser = pcall(vim.treesitter.get_parser, bufnr)
	if not ok then
		return
	end

	parser:parse(node_pos)

	local before_cursor = vim.treesitter.get_node({ bufnr = bufnr, pos = node_pos })
	if not before_cursor then
		return
	end

	if not vim.list_contains(config.cursor_node_types, before_cursor:type()) then
		return
	end

	local identifier = ts.find_first_child(before_cursor, config.identifier_node_types)
	local tag = not identifier and "" or vim.treesitter.get_node_text(identifier, bufnr)
	if not tag then
		return
	end

	tag = string.format("</%s>", tag)

	vim.api.nvim_put({ tag }, "", true, false)
	vim.api.nvim_win_set_cursor(0, cursor)
end

---@param config TsAutotag.Config
function M.setup(config)
	local prev_line = ""

	vim.api.nvim_create_autocmd("TextChangedI", {
		callback = function(ev)
			if config.disable_in_macro and vim.fn.reg_recording() ~= "" then
				return
			end

			local line = vim.api.nvim_get_current_line()
			if #line - #prev_line ~= 1 then
				prev_line = line
				return
			end

			local cursor = vim.api.nvim_win_get_cursor(0)
			local till_cursor = line:sub(1, cursor[2])

			if till_cursor:find(config.auto_close.till_cursor_line_match) then
				M.maybe_close_tag(config, ev.buf)
			end

			prev_line = line
		end,
	})
end

return M
