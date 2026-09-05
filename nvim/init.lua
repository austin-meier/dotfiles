-- Byte-compile and cache every Lua module. This is the single biggest startup
-- win on Windows, where an uncached `require` is a fresh stat + read that
-- Defender also wants to scan.
vim.loader.enable()

-- Setup Vim options
require("austin/vim-options")
-- Setup keybinds
require("austin/keybinds")
-- Setup autocmds
require("austin/autocommands")

-- Install Lazy package manager
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not (vim.uv or vim.loop).fs_stat(lazypath) then
	local lazyrepo = "https://github.com/folke/lazy.nvim.git"
	local out = vim.fn.system({ "git", "clone", "--filter=blob:none", "--branch=stable", lazyrepo, lazypath })
	if vim.v.shell_error ~= 0 then
		error("Error cloning lazy.nvim:\n" .. out)
	end
end

-- Add lazy to the runtime path
---@type vim.Option
local rtp = vim.opt.rtp
rtp:prepend(lazypath)

-- [[ Configure and install plugins ]]
--  To check the current status of your plugins, run
--    :Lazy
--
--  To update plugins you can run
--    :Lazy update
--
--  Startup budget: nvim is the snappy editor, emacs is the kitchen sink. Every
--  spec in austin/plugins should carry an `event`/`ft`/`cmd`/`keys` trigger
--  unless it genuinely has to run before the first frame (see theme.lua).
--  Check the damage with `:Lazy profile`.
require("lazy").setup({
	spec = {
		{ import = "austin.plugins" },
	},

	-- Don't check for plugin updates on every launch; run :Lazy update manually.
	checker = { enabled = false },

	-- Watching the config dir for spec edits costs libuv watchers at startup and
	-- buys nothing we don't get from restarting after an edit.
	change_detection = { enabled = false },

	-- Probing for luarocks/hererocks spawns processes before the first frame.
	rocks = { enabled = false },

	performance = {
		rtp = {
			-- Dead weight given neo-tree, the built-in gx, and no remote plugins.
			-- matchit/matchparen are deliberately left enabled.
			disabled_plugins = {
				"gzip",
				"netrwPlugin",
				"rplugin",
				"spellfile",
				"tarPlugin",
				"tohtml",
				"tutor",
				"zipPlugin",
			},
		},
	},
})
