require("nvchad.configs.lspconfig").defaults()

-- cmake completion
local neocmake_capabilities = vim.lsp.protocol.make_client_capabilities()
neocmake_capabilities.textDocument.completion.completionItem.snippetSupport = true
vim.lsp.config("neocmake", {
    capabilities = neocmake_capabilities
})

-- default lsp
local servers = {
    "bashls",
    "clangd", "neocmake",
    "rust_analyzer",
    "ts_ls",
    "svelte",
    "html", "cssls",
    "jsonls",
    "vimls",
    "markdown_oxide",
}
vim.lsp.enable(servers)

-- read :h vim.lsp.config for changing options of lsp servers

