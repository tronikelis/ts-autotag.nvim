local M = {}

---@class TsAutotag.Config.AutoClose
---@field enabled boolean

---@class TsAutotag.Config
---@field disable_in_macro boolean
---@field opening_node_types string[]
---@field identifier_node_types string[]
---@field auto_rename TsAutotag.Config.AutoRename
---@field auto_close TsAutotag.Config.AutoClose?
---@field filetypes string[]

---@class TsAutotag.Config.AutoRename
---@field enabled boolean
---@field closing_node_types string[]

---@param bufnr? integer
---@param silent? boolean
---@return boolean success
function M.rename(bufnr, silent)
    return require("ts-autotag.rename_tag.input").rename(bufnr, silent)
end

function M.setup(opts)
    opts = opts or {}
    local config = require("ts-autotag.config")
    config.config = vim.tbl_deep_extend("force", config.config, opts)
end

return M
