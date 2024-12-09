local config = require("ts-autotag.config")
local node = require("ts-autotag.node")

local M = {}

---@param bufnr integer
function M.maybe_close_tag(bufnr)
	local cursor = vim.api.nvim_win_get_cursor(0)

	local ok, parser = pcall(vim.treesitter.get_parser, bufnr)
	if not ok then
		return
	end

	local cursor_row = cursor[1] - 1
	parser:parse({ cursor_row, cursor_row })

	-- get node at cursor position with col - 1, so we are inside the written tag
	local opening_node = node.get_opening_node(bufnr, { cursor[1] - 1, cursor[2] - 1 })

	local opening_node_iden = node.get_node_iden(opening_node)
	local text = not opening_node_iden and "" or vim.treesitter.get_node_text(opening_node_iden, bufnr)
	if not text then
		return
	end

	text = string.format("</%s>", text)

	vim.api.nvim_put({ text }, "", true, false)
	vim.api.nvim_win_set_cursor(0, cursor)
end

function M.setup()
	local prev_line = ""

	vim.api.nvim_create_autocmd("TextChangedI", {
		callback = function(ev)
			if config.config.disable_in_macro and vim.fn.reg_recording() ~= "" then
				return
			end

			local line = vim.api.nvim_get_current_line()
			if #line - #prev_line ~= 1 then
				prev_line = line
				return
			end

			local cursor = vim.api.nvim_win_get_cursor(0)
			local till_cursor = line:sub(1, cursor[2])

			if till_cursor:find(config.config.auto_close.till_cursor_line_match) then
				M.maybe_close_tag(ev.buf)
			end

			prev_line = line
		end,
	})
end

return M
