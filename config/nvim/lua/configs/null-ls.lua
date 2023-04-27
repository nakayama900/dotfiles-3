-- {{{
local async_formatting = function(bufnr)
	bufnr = bufnr or vim.api.nvim_get_current_buf()

	vim.lsp.buf_request(
		bufnr,
		"textDocument/formatting",
		vim.lsp.util.make_formatting_params({}),
		function(err, res, ctx)
			if err then
				local err_msg = type(err) == "string" and err or err.message
				-- you can modify the log message / level (or ignore it completely)
				vim.notify("formatting: " .. err_msg, vim.log.levels.WARN)
				return
			end

			-- don't apply results if buffer is unloaded or has been modified
			if not vim.api.nvim_buf_is_loaded(bufnr) or vim.api.nvim_buf_get_option(bufnr, "modified") then
				return
			end

			if res then
				local client = vim.lsp.get_client_by_id(ctx.client_id)
				vim.lsp.util.apply_text_edits(res, bufnr, client and client.offset_encoding or "utf-16")
				vim.api.nvim_buf_call(bufnr, function()
					vim.cmd("silent noautocmd update")
				end)
			end
		end
	)
end
-- }}}
local null_ls = require("null-ls")

local augroup = vim.api.nvim_create_augroup("LspFormatting", {})

require("null-ls").setup({
	-- you can reuse a shared lspconfig on_attach callback here
	sources = {
		-- null_ls.builtins.diagnostics.semgrep,
		null_ls.builtins.code_actions.proselint,
		-- null_ls.builtins.diagnostics.markdownlint,
		-- null_ls.builtins.diagnostics.textlint,
		null_ls.builtins.diagnostics.vale,
		-- null_ls.builtins.diagnostics.write_good,

		null_ls.builtins.formatting.cbfmt,
		-- null_ls.builtins.diagnostics.cspell,
		-- null_ls.builtins.code_actions.cspell,

		-- Lua
		null_ls.builtins.formatting.stylua,

		-- Deno
		null_ls.builtins.formatting.deno_fmt.with({
			filetypes = {
				"javascript",
				"javascriptreact",
				"json",
				"jsonc",
				"typescript",
				"typescriptreact",
			},
		}),

		-- Rust
		null_ls.builtins.formatting.rustfmt,

		-- Nim
		null_ls.builtins.formatting.nimpretty,

		-- Go
		null_ls.builtins.formatting.gofumpt,
		null_ls.builtins.formatting.golines,
		null_ls.builtins.diagnostics.revive,

		-- Python
		null_ls.builtins.diagnostics.mypy,
		null_ls.builtins.diagnostics.pycodestyle,
		null_ls.builtins.diagnostics.pydocstyle,
		null_ls.builtins.diagnostics.ruff,
		null_ls.builtins.diagnostics.vulture,

		null_ls.builtins.formatting.ruff,
		null_ls.builtins.formatting.yapf,
		null_ls.builtins.formatting.autoflake,
		null_ls.builtins.formatting.black,
		null_ls.builtins.formatting.djhtml,
		null_ls.builtins.formatting.fprettify,
		null_ls.builtins.formatting.pyflyby,
		null_ls.builtins.formatting.reorder_python_imports,

		-- Dart
		null_ls.builtins.formatting.dart_format,

		-- Elixir
		null_ls.builtins.diagnostics.credo,
		null_ls.builtins.formatting.mix,

		--Ruby
		null_ls.builtins.diagnostics.rubocop,
		null_ls.builtins.diagnostics.standardrb,
		null_ls.builtins.formatting.standardrb,
		null_ls.builtins.formatting.erb_format,
		null_ls.builtins.formatting.erb_lint,

		-- Crystal
		null_ls.builtins.formatting.crystal_format,

		-- CSS
		null_ls.builtins.formatting.stylelint,
		null_ls.builtins.formatting.rustywind,
	},
	on_attach = function(client, bufnr)
		if client.supports_method("textDocument/formatting") then
			vim.api.nvim_clear_autocmds({ group = augroup, buffer = bufnr })
			vim.api.nvim_create_autocmd("BufWritePre", {
				group = augroup,
				buffer = bufnr,
				callback = function()
					-- on 0.8, you should use vim.lsp.buf.format({ bufnr = bufnr }) instead
					vim.lsp.buf.format()
				end,
			})
		end
	end,
})
