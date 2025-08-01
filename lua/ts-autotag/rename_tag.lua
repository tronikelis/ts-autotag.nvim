local ts = require("ts-autotag.ts")
local config = require("ts-autotag.config")

local M = {}

local NS_EXT = vim.api.nvim_create_namespace("ts-autotag.nvim/sibling_ext")

---@param bufnr integer
---@return TSNode?, TSNode?
local function get_opening_pair(bufnr)
	local opening_node = ts.get_opening_node({ bufnr = bufnr }, 1)
	if not opening_node then
		return
	end

	local sibling = ts.last_sibling(opening_node)
	if not sibling then
		return
	end
	if not vim.list_contains(config.config.auto_rename.closing_node_types, sibling:type()) then
		return
	end

	return opening_node, sibling
end

---@param bufnr integer
---@return TSNode?, TSNode?
local function get_closing_pair(bufnr)
	local closing_node = ts.get_closing_node({ bufnr = bufnr }, 1)
	if not closing_node then
		return
	end

	local sibling = ts.first_sibling(closing_node)
	if not sibling then
		return
	end
	if not vim.list_contains(config.config.opening_node_types, sibling:type()) then
		return
	end

	return closing_node, sibling
end

---@param opts vim.api.keyset.set_extmark
local function extmark_opts(opts)
	return vim.tbl_extend("force", {
		hl_group = "TsAutotagDebug",
		right_gravity = false,
		end_right_gravity = true,
	}, opts)
end

---@param bufnr integer
---@param on_parse function
local function update_sibling_extmarks(bufnr, on_parse)
	local ok, parser = pcall(vim.treesitter.get_parser, bufnr)
	if not ok or not parser then
		return
	end

	local cursor_row = vim.api.nvim_win_get_cursor(0)[1] - 1
	parser:parse({ cursor_row, cursor_row }, function()
		local opening_node, closing_node = get_opening_pair(bufnr)
		if not opening_node or not closing_node then
			closing_node, opening_node = get_closing_pair(bufnr)
		end
		if not opening_node or not closing_node then
			on_parse()
			return
		end

		local opening_node_iden = ts.get_node_iden(opening_node)
		if not opening_node_iden then
			on_parse()
			return
		end
		local opening_indices = ts.get_node_indices(opening_node_iden)

		local closing_node_iden = ts.get_node_iden(closing_node)
		if not closing_node_iden then
			on_parse()
			return
		end
		local closing_indices = ts.get_node_indices(closing_node_iden)

		vim.api.nvim_buf_clear_namespace(bufnr, NS_EXT, 0, -1)
		local id = vim.api.nvim_buf_set_extmark(
			bufnr,
			NS_EXT,
			opening_indices.start_row,
			opening_indices.start_col,
			extmark_opts({
				end_col = opening_indices.end_col,
				end_row = opening_indices.end_row,
			})
		)
		vim.api.nvim_buf_set_extmark(
			bufnr,
			NS_EXT,
			closing_indices.start_row,
			closing_indices.start_col,
			extmark_opts({
				id = id + 1,
				end_col = closing_indices.end_col,
				end_row = closing_indices.end_row,
			})
		)

		on_parse()
	end)
end

---@param bufnr integer
local function get_cursor_extmarks(bufnr)
	local cursor = vim.api.nvim_win_get_cursor(0)
	local ext = vim.api.nvim_buf_get_extmarks(
		bufnr,
		NS_EXT,
		{ cursor[1] - 1, cursor[2] },
		{ cursor[1] - 1, cursor[2] },
		{ overlap = true, details = true, limit = 1 }
	)
	if not ext[1] then
		return
	end

	return ext[1]
end

---@param bufnr integer
---@param pair_id_offset integer
local function sync_pair(bufnr, pair_id_offset)
	local ext1 = get_cursor_extmarks(bufnr)
	if not ext1 then
		return
	end
	local ext2 = vim.api.nvim_buf_get_extmark_by_id(bufnr, NS_EXT, ext1[1] + pair_id_offset, {
		details = true,
	})
	if not ext2[1] then
		return
	end

	local text1 = vim.api.nvim_buf_get_text(bufnr, ext1[2], ext1[3], ext1[4].end_row, ext1[4].end_col, {})[1]
	local before, after = text1:match("(.-) (.*)")
	if before and after then
		text1 = before
		vim.api.nvim_buf_set_extmark(
			bufnr,
			NS_EXT,
			ext1[2],
			ext1[3],
			extmark_opts({
				id = ext1[1],
				end_col = assert(ext1[4]).end_col - #after,
				end_row = assert(ext1[4]).end_row,
			})
		)
	end

	local text2 = vim.api.nvim_buf_get_text(bufnr, ext2[1], ext2[2], ext2[3].end_row, ext2[3].end_col, {})[1]
	if text1 == text2 then
		return
	end

	vim.api.nvim_buf_set_text(bufnr, ext2[1], ext2[2], ext2[3].end_row, ext2[3].end_col, { text1 })
end

---@param bufnr integer
local function sync(bufnr)
	local stale_cursor = vim.api.nvim_win_get_cursor(0)
	update_sibling_extmarks(bufnr, function()
		local cursor = vim.api.nvim_win_get_cursor(0)
		vim.api.nvim_win_set_cursor(0, stale_cursor)
		sync_pair(bufnr, 1)
		sync_pair(bufnr, -1)
		vim.api.nvim_win_set_cursor(0, cursor)
	end)
end

---@param bufnr integer
local function init(bufnr)
	local ok, parser = pcall(vim.treesitter.get_parser, bufnr)
	if not ok or not parser then
		return
	end

	local timer = assert(vim.uv.new_timer())
	---@param count integer
	local function check(count)
		if count > 50 then
			timer:stop()
			timer:close()
			return
		end

		local cursor_row = vim.api.nvim_win_get_cursor(0)[1] - 1
		if parser:is_valid(false, { cursor_row, cursor_row }) then
			sync(bufnr)
			timer:stop()
			timer:close()
			return
		end

		timer:start(
			100,
			0,
			vim.schedule_wrap(function()
				check(count + 1)
			end)
		)
	end
	check(0)
end

function M.setup()
	vim.api.nvim_set_hl(0, "TsAutotagDebug", {
		default = true,
	})

	if vim.api.nvim_buf_is_loaded(0) then
		init(vim.api.nvim_get_current_buf())
	end
	vim.api.nvim_create_autocmd("BufRead", {
		callback = function(ev)
			init(ev.buf)
		end,
	})

	vim.api.nvim_create_autocmd({ "CursorMoved", "CursorMovedI" }, {
		callback = function(ev)
			sync(ev.buf)
		end,
	})
end

return M
