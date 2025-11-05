local augroup = vim.api.nvim_create_augroup("ts-autotag.nvim/init_buffer", {})

vim.api.nvim_create_autocmd("FileType", {
    group = augroup,
    callback = function(event)
        local config = require("ts-autotag.config").config
        if vim.tbl_contains(config.filetypes, event.match) then
            if config.auto_rename.enabled then
                require("ts-autotag.rename_tag.auto").init(event.buf)
            end
            if config.auto_close.enabled then
                require("ts-autotag.close_tag").init(event.buf)
            end
        end
    end,
})

vim.api.nvim_create_user_command("TsTagRename", function()
    require("ts-autotag").rename(nil, false)
end, {})
