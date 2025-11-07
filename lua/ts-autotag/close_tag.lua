local ts = require("ts-autotag.ts")
local config = require("ts-autotag.config")

local M = {}

---@param bufnr integer
local function maybe_close_tag(bufnr)
    local ok, parser = pcall(vim.treesitter.get_parser, bufnr)
    if not ok or not parser then
        return
    end

    local cursor = vim.api.nvim_win_get_cursor(0)

    local cursor_row = cursor[1] - 1
    parser:parse({ cursor_row, cursor_row })

    -- get node at cursor position with col - 1, so we are inside the written tag
    local opening_node = ts.get_opening_node({ bufnr = bufnr, pos = { cursor[1] - 1, cursor[2] - 1 } }, 0)
    if not opening_node then
        return
    end

    local opening_node_iden = ts.get_node_iden(opening_node)
    local text = not opening_node_iden and "" or vim.treesitter.get_node_text(opening_node_iden, bufnr)
    if not text then
        return
    end

    text = string.format("</%s>", text)

    vim.api.nvim_put({ text }, "", false, false)
    vim.api.nvim_win_set_cursor(0, cursor)
end

vim.on_key(function(_, typed)
    local buf = vim.api.nvim_get_current_buf()
    if not vim.b[buf].__autotag_close_tag_enabled then
        return
    end

    if typed ~= ">" or vim.api.nvim_get_mode().mode ~= "i" then
        return
    end
    if config.config.disable_in_macro and vim.fn.reg_recording() ~= "" then
        return
    end

    vim.schedule(function()
        maybe_close_tag(buf)
    end)
end, vim.api.nvim_create_namespace("ts-autotag.nvim/close_tag_init"))

---@param buf integer
function M.init(buf)
    vim.b[buf].__autotag_close_tag_enabled = true
end

return M
