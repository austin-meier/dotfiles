return {
	"nvim-lualine/lualine.nvim",
	event = "VeryLazy",
	dependencies = { "nvim-tree/nvim-web-devicons" },
	opts = {
		options = {
			theme = "auto",
			icons_enabled = vim.g.have_nerd_font,
			section_separators = "",
			component_separators = "|",
		},
	},
}
