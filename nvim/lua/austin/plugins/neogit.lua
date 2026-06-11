return { -- Magit-style git porcelain — mirrors the emacs `SPC g` (magit) tree
	"NeogitOrg/neogit",
	dependencies = {
		"nvim-lua/plenary.nvim",
		"nvim-telescope/telescope.nvim", -- used for selection prompts
	},
	cmd = "Neogit", -- lazy-load when first opened via the SPC g bindings
	opts = {},
}
