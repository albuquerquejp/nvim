return {
	"ellisonleao/gruvbox.nvim",
	priority = 1000,
	opts = {},
	init = function()
		vim.cmd([[colorscheme gruvbox]])
		vim.o.background = "dark"
	end,
}
