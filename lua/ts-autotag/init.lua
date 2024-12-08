local close_tag = require("ts-autotag.close_tag")
local config = require("ts-autotag.config")

local M = {}

---@class TsAutotag.Config
---@field auto_rename boolean
---@field cursor_node_types string[]
---@field identifier_node_types string[]
---@field line_must_match string

function M.setup(opts)
	opts = opts or {}
	config.config = vim.tbl_deep_extend("force", config.config, opts)

	close_tag.setup()
end

return M
