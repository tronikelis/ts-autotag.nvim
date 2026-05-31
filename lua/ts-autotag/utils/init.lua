local M = {}

function M.disabled(buf)
    local c = require("ts-autotag.config").config
    return c.disable_in_macro
        and (vim.fn.reg_recording() ~= "" or vim.fn.reg_executing() ~= "") or not c.should_attach(buf)
end

return M
