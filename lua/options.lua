-- Make line numbers default
vim.opt.number = true
vim.opt.relativenumber = true
vim.opt.mouse = "a"
-- Windows Terminal supports true colour but doesn't set $COLORTERM, so tell Neovim explicitly
vim.opt.termguicolors = true
-- Don't show the mode, since it's already in the status line
--vim.opt.showmode = false

-- Sync clipboard between OS and Neovim.
vim.schedule(function()
	vim.opt.clipboard = "unnamedplus"
end)

-- Enable break indent
vim.opt.breakindent = true
vim.opt.autoindent = true
-- Save undo history
vim.opt.undofile = true

-- Case-insensitive searching UNLESS \C or one or more capital letters in the search term
vim.opt.ignorecase = true
vim.opt.smartcase = true

-- Keep signcolumn on by default
vim.opt.signcolumn = "yes"

-- Decrease update time
vim.opt.updatetime = 250

-- Decrease mapped sequence wait time
-- Displays which-key popup sooner
vim.opt.timeoutlen = 300

-- Configure how new splits should be opened
vim.opt.splitright = true
vim.opt.splitbelow = true

-- Sets how neovim will display certain whitespace characters in the editor.
vim.opt.list = true
vim.opt.listchars = { tab = "» ", trail = "·", nbsp = "␣" }

-- Preview substitutions live, as you type!
vim.opt.inccommand = "split"

-- Show which line your cursor is on
vim.opt.cursorline = true

-- Minimal number of screen lines to keep above and below the cursor.
vim.opt.scrolloff = 10

-- Ask to save instead of failing on :q with unsaved changes
vim.opt.confirm = true

-- Scroll wrapped lines smoothly instead of jumping whole lines
vim.opt.smoothscroll = true

-- Neovim 0.11 turned inline diagnostics off by default; bring them back
vim.diagnostic.config({
	virtual_text = true,
	float = { border = "rounded" },
})
