local M = {}

---@param language string
local function check_ts_language(language)
    local ok, parser = pcall(vim.treesitter.get_parser, nil, language)
    if not ok or not parser then
        vim.health.warn(string.format("%s parser not found", language))
    else
        vim.health.ok(string.format("%s parser found", language))
    end
end

function M.check()
    local config = require("ts-autotag.config").config

    vim.health.start("TS parsers:")

    local languages = vim.iter(config.filetypes)
        :map(function(v)
            return vim.treesitter.language.get_lang(v)
        end)
        :totable()

    for i, lang in ipairs(languages) do
        if not lang then
            vim.health.error(string.format("%s filetype does not have associated ts language", config.filetypes[i]))
        end
    end

    vim.iter(languages)
        :unique()
        :filter(function(v)
            return not not v
        end)
        :each(check_ts_language)
end

return M
