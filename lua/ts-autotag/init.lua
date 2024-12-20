local close_tag = require("ts-autotag.close_tag")
local rename_tag = require("ts-autotag.rename_tag")
local config = require("ts-autotag.config")

local M = {}

---@class TsAutotag.Config.AutoClose
---@field enabled boolean

---@class TsAutotag.Config
---@field disable_in_macro boolean
---@field opening_node_types string[]
---@field identifier_node_types string[]
---@field auto_rename TsAutotag.Config.AutoRename
---@field auto_close TsAutotag.Config.AutoClose?

---@class TsAutotag.Config.AutoRename
---@field enabled boolean
---@field closing_node_types string[]

function M.setup(opts)
	opts = opts or {}
	config.config = vim.tbl_deep_extend("force", config.config, opts)

	if config.config.auto_close.enabled then
		close_tag.setup()
	end

	if config.config.auto_rename.enabled then
		rename_tag.setup()
	end
end

return M
