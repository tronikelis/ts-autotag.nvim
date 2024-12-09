local ts = require("ts-autotag.ts")
local config = require("ts-autotag.config")
local node = require("ts-autotag.node")

local M = {}

---@param bufnr integer
---@param closing_node_iden TSNode
function M.maybe_rename_tag(bufnr, closing_node_iden)
	local opening_node_iden = node.get_node_iden(node.get_opening_node({ bufnr = bufnr }))
	if not opening_node_iden then
		return
	end

	ts.copy_buf_contents(opening_node_iden, closing_node_iden, bufnr)
end

function M.setup()
	---@type TSNode?
	local closing_node_iden = nil

	vim.api.nvim_create_autocmd("CursorMoved", {
		callback = function(ev)
			closing_node_iden = nil

			if config.config.disable_in_macro and vim.fn.reg_recording() ~= "" then
				return
			end

			local bufnr = ev.buf

			local ok = pcall(vim.treesitter.get_parser, bufnr)
			if not ok then
				return
			end

			closing_node_iden = node.get_node_iden(
				ts.find_first_or_last_sibling(
					node.get_opening_node({ bufnr = bufnr }),
					config.config.auto_rename.ending_node_types
				)
			)
		end,
	})

	vim.api.nvim_create_autocmd("InsertLeavePre", {
		callback = function(ev)
			if config.config.disable_in_macro and vim.fn.reg_recording() ~= "" then
				return
			end

			local bufnr = ev.buf

			if closing_node_iden then
				M.maybe_rename_tag(bufnr, closing_node_iden)
			end
		end,
	})
end

return M
