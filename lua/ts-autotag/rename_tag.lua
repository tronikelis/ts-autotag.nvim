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

	local node_left = vim.treesitter.get_node({ bufnr = bufnr })
	vim.print({ node_left = node_left:type() })
	if not node_left then
		return
	end
	if not vim.list_contains(config.cursor_node_types, node_left:type()) then
		return
	end

	local node_left_identifier = ts.find_first_child(node_left, config.identifier_node_types)
	vim.print({ node_left_identifier = node_left_identifier:type() })
	if not node_left_identifier then
		return
	end

	local new_name = vim.treesitter.get_node_text(node_left_identifier, bufnr)

	local node_left_parent = ts.find_first_parent(node_left, { "element", "jsx_element" })
	if not node_left_parent then
		return
	end

	vim.print({ node_left_parent = node_left_parent:type() })

	local ending_node = node_left_parent:child(node_left_parent:child_count() - 1)
	vim.print({ ending_node = ending_node:type() })
	if not ending_node then
		return
	end
	if not vim.list_contains(config.auto_rename.ending_node_types, ending_node:type()) then
		return
	end

	local ending_node_identifier = ts.find_first_child(ending_node, config.identifier_node_types)
	if not ending_node_identifier then
		return
	end

	ts.copy_buf_contents(node_left_identifier, ending_node_identifier, bufnr)
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
