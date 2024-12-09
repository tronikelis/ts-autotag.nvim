local ts = require("ts-autotag.ts")
local config = require("ts-autotag.config")
local node = require("ts-autotag.node")

local M = {}

---@param bufnr integer
function M.maybe_rename_tag(bufnr)
	local ok, parser = pcall(vim.treesitter.get_parser, bufnr)
	if not ok then
		return
	end

	local cursor_row = vim.api.nvim_win_get_cursor(0)[1] - 1
	parser:parse({ cursor_row, cursor_row })

	local opening_node = node.get_opening_node({ bufnr = bufnr })
	if not opening_node then
		return
	end

	local opening_node_iden = node.get_node_iden(opening_node)
	if not opening_node_iden then
		return
	end

	local closing_node_iden =
		node.get_node_iden(ts.find_first_or_last_sibling(opening_node, config.config.auto_rename.closing_node_types))
	if not closing_node_iden then
		return
	end

	ts.copy_buf_contents(opening_node_iden, closing_node_iden, bufnr)
end

function M.setup()
	---@type TSNode?
	vim.api.nvim_create_autocmd("InsertLeavePre", {
		callback = function(ev)
			if config.config.disable_in_macro and vim.fn.reg_recording() ~= "" then
				return
			end

			M.maybe_rename_tag(ev.buf)
		end,
	})
end

return M
