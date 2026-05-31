local M = {}

function M.disabled()
    return require("ts-autotag.config").config.disable_in_macro
        and (vim.fn.reg_recording() ~= "" or vim.fn.reg_executing() ~= "")
end

return M
