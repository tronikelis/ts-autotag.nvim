local M = {}

---@return boolean
function M.is_disabled_executing_macro()
    return M.config.disable_in_macro and (vim.fn.reg_recording() ~= "" or vim.fn.reg_executing() ~= "")
end

---@type TsAutotag.Config
M.config = {
    opening_node_types = {
        -- templ
        "tag_start",

        -- xml,
        "STag",

        -- html
        "start_tag",

        -- jsx
        "jsx_opening_element",
    },
    identifier_node_types = {
        -- html
        "tag_name",
        "erroneous_end_tag_name",

        -- xml,
        "Name",

        -- jsx
        "member_expression",
        "identifier",

        -- templ
        "element_identifier",
    },

    filetypes = {
        "typescript",
        "javascript",
        "typescriptreact",
        "javascriptreact",
        "xml",
        "html",
        "templ",
        "php",
    },

    disable_in_macro = true,

    auto_close = {
        enabled = true,
    },
    auto_rename = {
        enabled = false,
        closing_node_types = {
            -- jsx
            "jsx_closing_element",

            -- xml,
            "ETag",

            -- html
            "end_tag",
            "erroneous_end_tag",

            -- templ
            "tag_end",
        },
    },

    should_attach = function()
        return true
    end,
}

return M
