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
		},
		indent = { enable = true },
	},
}
