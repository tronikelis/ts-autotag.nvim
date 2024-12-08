local ts = require("ts-autotag.ts")

local M = {}

---@param bufnr integer
---@param config TsAutotag.Config
function M.maybe_rename_tag(config, bufnr)
	local cursor = vim.api.nvim_win_get_cursor(0)

	local ok, parser = pcall(vim.treesitter.get_parser, bufnr)
	if not ok then
		return
	end

	parser:parse({ cursor[1] - 1, cursor[2] })

	local opening_node = vim.treesitter.get_node({ bufnr = bufnr })
	if not opening_node then
		return
	end
	if not vim.list_contains(config.opening_node_types, opening_node:type()) then
		return
	end

	local opening_node_id = ts.find_first_child(opening_node, config.identifier_node_types)
	if not opening_node_id then
		return
	end

	local closing_node = ts.find_first_or_last_sibling(opening_node, config.auto_rename.ending_node_types)
	if not closing_node then
		return
	end

	local closing_node_id = ts.find_first_child(closing_node, config.identifier_node_types)
	if not closing_node_id then
		return
	end

	ts.copy_buf_contents(opening_node_id, closing_node_id, bufnr)
end

---@param config TsAutotag.Config
function M.setup(config)
	vim.api.nvim_create_autocmd("InsertLeavePre", {
		callback = function(ev)
			if config.disable_in_macro and vim.fn.reg_recording() ~= "" then
				return
			end

			M.maybe_rename_tag(config, ev.buf)
		end,
	})
end

return M
