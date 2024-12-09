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
	local opening_node = node.get_opening_node({ bufnr = bufnr, pos = { cursor[1] - 1, cursor[2] - 1 } })
	if not opening_node then
		return
	end

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
	vim.on_key(function(_, typed)
		if typed ~= ">" or vim.api.nvim_get_mode().mode ~= "i" then
			return
		end

		local buf = vim.api.nvim_get_current_buf()
		vim.schedule(function()
			M.maybe_close_tag(buf)
		end)
	end)
end

return M
