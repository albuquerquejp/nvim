local light, dark = "everforest", "tokyonight-moon"

local function apply(name)
	vim.o.background = name == light and "light" or "dark"
	vim.cmd.colorscheme(name)
end

return {
	{
		"sainnhe/everforest",
		lazy = false,
		priority = 1000,
		init = function()
			vim.g.everforest_background = "soft" -- soft = most paper-like
			vim.g.everforest_enable_italic = 1
			vim.g.everforest_better_performance = 1
		end,
		config = function()
			apply(light)
			vim.keymap.set("n", "<leader>tt", function()
				apply(vim.g.colors_name == light and dark or light)
			end, { desc = "[T]oggle [T]heme light/dark" })
		end,
	},
	{
		"folke/tokyonight.nvim",
		lazy = true,
		opts = {},
	},
}
