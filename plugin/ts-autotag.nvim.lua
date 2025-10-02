local augroup = vim.api.nvim_create_augroup("ts-autotag.nvim/init_buffer", {})

vim.api.nvim_create_autocmd("FileType", {
	group = augroup,
	pattern = require("ts-autotag.config").config.filetypes,
	callback = function(ev)
		local config = require("ts-autotag.config")

		if config.config.auto_rename.enabled then
			require("ts-autotag.rename_tag.auto").init(ev.buf)
		end

		if config.config.auto_close.enabled then
			require("ts-autotag.close_tag").init(ev.buf)
		end
	end,
})

vim.api.nvim_create_user_command("TsTagRename", function()
	require("ts-autotag").rename(nil, false)
end, {})
