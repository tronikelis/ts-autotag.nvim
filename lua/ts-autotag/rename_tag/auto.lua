local ts = require("ts-autotag.ts")

local M = {}

local NS_IDEN = vim.api.nvim_create_namespace("ts-autotag.nvim/NS_IDEN")

---@param bufnr integer
local function clear_extmarks(bufnr)
	vim.api.nvim_buf_clear_namespace(bufnr, NS_IDEN, 0, -1)
end

---@param opts vim.api.keyset.set_extmark
local function iden_extmark_opts(opts)
	return vim.tbl_extend("force", {
		invalidate = false,
		hl_group = "TsAutotagDebug",
		right_gravity = false,
		end_right_gravity = true,
	}, opts)
end

---@param bufnr integer
local function update_sibling_extmarks(bufnr)
	local ok, parser = pcall(vim.treesitter.get_parser, bufnr)
	if not ok or not parser then
		return
	end

	local opening_node, closing_node = ts.get_opening_pair(bufnr)
	if not opening_node or not closing_node then
		closing_node, opening_node = ts.get_closing_pair(bufnr)
	end
	if not opening_node or not closing_node then
		return
	end

	if ts.has_error(opening_node) or ts.has_error(closing_node) then
		return
	end

	local opening_node_iden = ts.get_node_iden(opening_node)
	---@type TsAutotag.NodeIndices
	local opening_indices
	if opening_node_iden then
		opening_indices = ts.get_node_indices(opening_node_iden)
	else
		opening_indices = ts.get_node_indices(opening_node)
		opening_indices.start_col = opening_indices.start_col + 1
		opening_indices.end_col = opening_indices.end_col - 1
	end

	local closing_node_iden = ts.get_node_iden(closing_node)
	---@type TsAutotag.NodeIndices
	local closing_indices
	if closing_node_iden then
		closing_indices = ts.get_node_indices(closing_node_iden)
	else
		closing_indices = ts.get_node_indices(closing_node)
		closing_indices.start_col = closing_indices.start_col + 2
		closing_indices.end_col = closing_indices.end_col - 1
	end

	clear_extmarks(bufnr)
	local id = vim.api.nvim_buf_set_extmark(
		bufnr,
		NS_IDEN,
		opening_indices.start_row,
		opening_indices.start_col,
		iden_extmark_opts({
			end_col = opening_indices.end_col,
			end_row = opening_indices.end_row,
		})
	)
	vim.api.nvim_buf_set_extmark(
		bufnr,
		NS_IDEN,
		closing_indices.start_row,
		closing_indices.start_col,
		iden_extmark_opts({
			id = id + 1,
			end_col = closing_indices.end_col,
			end_row = closing_indices.end_row,
		})
	)
end

---@param bufnr integer
local function get_cursor_iden_extmark(bufnr)
	local cursor = vim.api.nvim_win_get_cursor(0)
	local iden_ext = vim.api.nvim_buf_get_extmarks(
		bufnr,
		NS_IDEN,
		{ cursor[1] - 1, cursor[2] },
		{ cursor[1] - 1, cursor[2] },
		{ overlap = true, details = true, limit = 1 }
	)
	if not iden_ext[1] then
		return
	end

	if type(iden_ext[1][1]) == "table" then
		clear_extmarks(bufnr)
		return
	end

	return iden_ext[1]
end

---@param bufnr integer
---@param pair_id_offset integer
local function sync_pair(bufnr, pair_id_offset)
	local ext1 = get_cursor_iden_extmark(bufnr)
	if not ext1 then
		return
	end
	local ext2 = vim.api.nvim_buf_get_extmark_by_id(bufnr, NS_IDEN, ext1[1] + pair_id_offset, {
		details = true,
	})
	if not ext2[1] then
		return
	end

	local text1 = vim.api.nvim_buf_get_text(bufnr, ext1[2], ext1[3], ext1[4].end_row, ext1[4].end_col, {})[1]
	if text1:find("/") or text1:find("<") or text1:find(">") then
		clear_extmarks(bufnr)
		return
	end

	local before, after = text1:match("(.-) (.*)")
	if before and after then
		text1 = before
		vim.api.nvim_buf_set_extmark(
			bufnr,
			NS_IDEN,
			ext1[2],
			ext1[3],
			iden_extmark_opts({
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

function M.setup()
	vim.api.nvim_set_hl(0, "TsAutotagDebug", {
		fg = "White",
		default = true,
	})

	vim.api.nvim_create_autocmd({ "TextChanged", "TextChangedI" }, {
		callback = function(ev)
			sync_pair(ev.buf, 1)
			sync_pair(ev.buf, -1)
		end,
	})

	vim.api.nvim_create_autocmd({ "CursorMoved", "CursorMovedI", "BufEnter" }, {
		callback = vim.schedule_wrap(function(ev)
			if not get_cursor_iden_extmark(ev.buf) then
				update_sibling_extmarks(ev.buf)
			end
		end),
	})
end

return M
