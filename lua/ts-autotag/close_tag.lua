local config = require("ts-autotag.config")
local ts = require("ts-autotag.ts")

local M = {}

function M.maybe_close_tag(bufnr)
	local cursor = vim.api.nvim_win_get_cursor(0)
	-- get node at cursor position with col - 1, so we are inside the written tag
	local node_pos = { cursor[1] - 1, cursor[2] - 1 }

	vim.treesitter.get_parser(bufnr):parse(node_pos)

	local before_cursor = vim.treesitter.get_node({ bufnr = bufnr, pos = node_pos })
	if not before_cursor then
		return
	end

	if not vim.list_contains(config.config.cursor_node_types, before_cursor:type()) then
		return
	end

	local identifier = ts.find_first_child(before_cursor, config.config.identifier_node_types)
	local tag = not identifier and { "" } or ts.extract_node_contents(identifier, bufnr)
	if not tag then
		return
	end

	tag[1] = "</" .. tag[1]
	tag[#tag] = tag[#tag] .. ">"

	vim.api.nvim_put(tag, "", true, false)
	vim.api.nvim_win_set_cursor(0, { cursor[1] + #tag - 1, cursor[2] })
end

function M.setup()
	local prev_line = ""

	vim.api.nvim_create_autocmd("TextChangedI", {
		callback = function(ev)
			local line = vim.api.nvim_get_current_line()

			if #line - #prev_line == 1 and line:find(config.config.line_must_match) then
				M.maybe_close_tag(ev.buf)
			end

			prev_line = line
		end,
	})
end

return M
