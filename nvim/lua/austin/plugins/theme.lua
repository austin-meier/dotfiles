return {
	-- Faithful port of Doom Emacs' doom-one — matches the palette used across
	-- starship, fzf, and wezterm (bg #1c1f24, blue #51afef, green #98be65, …).
	"NTBBloodbath/doom-one.nvim",
	priority = 1000, -- Load before all other start plugins.
	config = function()
		-- These must be set before the colorscheme is applied.
		vim.g.doom_one_terminal_colors = true
		vim.g.doom_one_cursor_coloring = true
		vim.g.doom_one_italic_comments = true -- match emacs (font-lock-comment-face is italic)
		vim.g.doom_one_enable_treesitter = true
		vim.g.doom_one_diagnostics_text_color = false
		vim.g.doom_one_transparent_background = false

		-- Plugin integrations actually in this config
		vim.g.doom_one_plugin_telescope = true
		vim.g.doom_one_plugin_whichkey = true
		vim.g.doom_one_plugin_nvim_tree = true
		vim.g.doom_one_plugin_indent_blankline = true

		-- Load the colorscheme.
		vim.cmd.colorscheme("doom-one")
	end,
}
