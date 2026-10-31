-- dbt models are SQL with Jinja in it, which the SQL parser can't read: one `{{ config(...) }}`
-- turns everything up to the next clean statement into an error node with no highlighting.
-- In dbt projects, parse .sql files as Jinja instead; queries/jinja/injections.scm then
-- highlights the text between the tags as SQL.
local function is_dbt_sql(buf)
	return vim.bo[buf].filetype == "sql" and vim.fs.root(buf, "dbt_project.yml") ~= nil
end

return { -- Highlight, edit, and navigate code
	"nvim-treesitter/nvim-treesitter",
	-- `master` is archived but is the branch that still has `nvim-treesitter.configs`.
	-- Moving to `main` needs a different setup (and the tree-sitter CLI).
	branch = "master",
	build = ":TSUpdate",
	main = "nvim-treesitter.configs",
	opts = {
		ensure_installed = {
			"lua",
			"python",
			"vimdoc",
			"vim",
			"regex",
			"terraform",
			"sql",
			"jinja",
			"jinja_inline",
			"dockerfile",
			"toml",
			"json",
			"go",
			"gitignore",
			"graphql",
			"yaml",
			"markdown",
			"markdown_inline",
			"bash",
			"css",
			"html",
			"rust",
		},
		auto_install = true,
		highlight = {
			enable = true,
			disable = function(lang, buf)
				return lang == "sql" and is_dbt_sql(buf)
			end,
		},
		indent = {
			enable = true,
			disable = function(lang, buf)
				return lang == "sql" and is_dbt_sql(buf)
			end,
		},
	},
	init = function()
		vim.api.nvim_create_autocmd("FileType", {
			desc = "Highlight dbt SQL files with the Jinja parser (SQL injected)",
			group = vim.api.nvim_create_augroup("dbt-jinja-highlight", { clear = true }),
			pattern = "sql",
			callback = function(event)
				if is_dbt_sql(event.buf) then
					pcall(vim.treesitter.start, event.buf, "jinja")
					-- Keep regex SQL highlighting under it for Snowflake syntax the SQL grammar can't parse (QUALIFY, col:path)
					vim.bo[event.buf].syntax = "sql"
				end
			end,
		})
	end,
}
