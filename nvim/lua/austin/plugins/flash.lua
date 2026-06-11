return { -- Jump anywhere on screen — mirrors the emacs `s` → avy-goto-char-timer binding
	"folke/flash.nvim",
	event = "VeryLazy",
	opts = {},
	-- `s` overrides vim's substitute (matching how evil's `s` was rebound to avy);
	-- use `cl`/`cc` for substitute as in the emacs/evil setup.
	keys = {
		{ "s", mode = { "n", "x", "o" }, function() require("flash").jump() end, desc = "Flash jump" },
		{ "S", mode = { "n", "x", "o" }, function() require("flash").treesitter() end, desc = "Flash Treesitter" },
		{ "r", mode = "o", function() require("flash").remote() end, desc = "Remote Flash" },
		{ "R", mode = { "o", "x" }, function() require("flash").treesitter_search() end, desc = "Treesitter search" },
	},
}
