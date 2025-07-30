local ts = require("ts-autotag.ts")
local config = require("ts-autotag.config")

local M = {}

---@param bufnr integer
function M.maybe_rename_closing_tag(bufnr)
	local ok, parser = pcall(vim.treesitter.get_parser, bufnr)
	if not ok or not parser then
		return
	end

	local cursor_row = vim.api.nvim_win_get_cursor(0)[1]
	parser:parse({ cursor_row, cursor_row }, function()
		local closing_node = ts.get_closing_node({ bufnr = bufnr }, 1)
		if not closing_node then
			return
		end

		local opening_node = ts.first_sibling(closing_node)
		if not opening_node then
			return
		end
		if not vim.list_contains(config.config.auto_rename.closing_node_types, closing_node:type()) then
			return
		end

		ts.copy_buf_contents(closing_node, opening_node, bufnr, "<%s>")
	end)
end

---@param bufnr integer
function M.maybe_rename_opening_tag(bufnr)
	local ok, parser = pcall(vim.treesitter.get_parser, bufnr)
	if not ok or not parser then
		return
	end

	local cursor_row = vim.api.nvim_win_get_cursor(0)[1]
	parser:parse({ cursor_row, cursor_row }, function()
		local opening_node = ts.get_opening_node({ bufnr = bufnr }, 1)
		if not opening_node then
			return
		end

		local closing_node = ts.last_sibling(opening_node)
		if not closing_node then
			return
		end
		if not vim.list_contains(config.config.auto_rename.closing_node_types, closing_node:type()) then
			return
		end

		ts.copy_buf_contents(opening_node, closing_node, bufnr, "</%s>")
	end)
end

---@return number
local function current_ms()
	return vim.uv.hrtime() / 1000 / 1000
end

---@param callback fun()
---@param ms integer
local function throttle(callback, ms)
	local timer = assert(vim.uv.new_timer())
	local time = current_ms()

	return function(...)
		local args = { ... }

		if current_ms() - time > ms then
			callback(unpack(args))
			time = current_ms()
		end
		timer:start(ms, 0, function()
			vim.schedule_wrap(callback)(unpack(args))
		end)
	end
end

function M.setup()
	---@type TSNode?
	vim.api.nvim_create_autocmd({ "TextChanged", "TextChangedI" }, {
		callback = throttle(function(ev)
			if config.config.disable_in_macro and vim.fn.reg_recording() ~= "" then
				return
			end

			if not M.maybe_rename_opening_tag(ev.buf) then
				M.maybe_rename_closing_tag(ev.buf)
			end
		end, 100),
	})
end

return M
