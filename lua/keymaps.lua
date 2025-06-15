vim.g.mapleader = " "
vim.g.maplocalleader = " "

local opts = { noremap = true, silent = true }
-- Clear highlights on search when pressing <Esc> in normal mode
vim.keymap.set("n", "<Esc>", "<cmd>nohlsearch<CR>")

-- Diagnostic keymaps
vim.keymap.set("n", "<leader>q", vim.diagnostic.setloclist, { desc = "Open diagnostic [Q]uickfix list" })

-- Exit terminal mode in the builtin terminal with a shortcut that is a bit easier
vim.keymap.set("t", "<Esc><Esc>", "<C-\\><C-n>", { desc = "Exit terminal mode" })

-- Disable arrow keys in normal mode
vim.keymap.set("n", "<left>", '<cmd>echo "Use h to move!!"<CR>')
vim.keymap.set("n", "<right>", '<cmd>echo "Use l to move!!"<CR>')
vim.keymap.set("n", "<up>", '<cmd>echo "Use k to move!!"<CR>')
vim.keymap.set("n", "<down>", '<cmd>echo "Use j to move!!"<CR>')

-- Keybinds to make split navigation easier.
vim.keymap.set("n", "<C-h>", "<C-w><C-h>", { desc = "Move focus to the left window" })
vim.keymap.set("n", "<C-l>", "<C-w><C-l>", { desc = "Move focus to the right window" })
vim.keymap.set("n", "<C-j>", "<C-w><C-j>", { desc = "Move focus to the lower window" })
vim.keymap.set("n", "<C-k>", "<C-w><C-k>", { desc = "Move focus to the upper window" })

-- Buffers
vim.keymap.set("n", "<Tab>", ":bnext<CR>", opts)
vim.keymap.set("n", "<S-Tab>", ":bprevious<CR>", opts)
vim.keymap.set("n", "<leader>x", ":bdelete!<CR>", opts) -- close buffer

-- close all buffers except the current one
vim.keymap.set("n", "<leader>bo", function()
	local cur = vim.api.nvim_get_current_buf()
	for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
		if bufnr ~= cur and vim.fn.buflisted(bufnr) == 1 then
			vim.api.nvim_buf_delete(bufnr, { force = true })
		end
	end
end, vim.tbl_extend("force", opts, { desc = "Buffer: close Others" }))

-- delete every listed buffer
vim.keymap.set(
	"n",
	"<leader>ba",
	"<cmd>bufdo bdelete!<CR>",
	{ noremap = true, silent = true, desc = "Buffer: delete All" }
)
