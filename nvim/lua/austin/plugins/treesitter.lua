--- Parsers are compiled on this machine, so with no compiler on PATH every
--- install attempt fails and takes rainbow-delimiters down with it. Fresh
--- Windows boxes land here: install zig (`winget install zig.zig`) or the MSVC
--- build tools, then `:TSUpdate`.
local function has_compiler()
	return vim.iter({ "cc", "gcc", "clang", "cl", "zig" }):any(function(exe)
		return vim.fn.executable(exe) == 1
	end)
end

local COMPILER_AVAILABLE = has_compiler()

local PARSERS = {
	"bash",
	"c",
	"diff",
	"html",
	"lua",
	"luadoc",
	"markdown",
	"markdown_inline",
	"query",
	"vim",
	"vimdoc",
	"clojure",
	"rust",
	"java",
	"php",
}

return { -- Highlight, edit, and navigate code
	"nvim-treesitter/nvim-treesitter",
	event = { "BufReadPost", "BufNewFile" },
	branch = "master", -- The `main` branch is a rewrite that drops the `configs` API used below.
	build = ":TSUpdate",
	-- [[ Configure Treesitter ]] See `:help nvim-treesitter`
	opts = {
		ensure_installed = COMPILER_AVAILABLE and PARSERS or {},
		-- Autoinstall languages that are not installed
		auto_install = COMPILER_AVAILABLE,
		highlight = {
			enable = true,
			-- Some languages depend on vim's regex highlighting system (such as Ruby) for indent rules.
			--  If you are experiencing weird indenting issues, add the language to
			--  the list of additional_vim_regex_highlighting and disabled languages for indent.
			additional_vim_regex_highlighting = { "ruby" },
		},
		indent = { enable = true, disable = { "ruby" } },
	},
	-- There are additional nvim-treesitter modules that you can use to interact
	-- with nvim-treesitter. You should go explore a few and see what interests you:
	--
	--    - Incremental selection: Included, see `:help nvim-treesitter-incremental-selection-mod`
	--    - Show your current context: https://github.com/nvim-treesitter/nvim-treesitter-context
	--    - Treesitter + textobjects: https://github.com/nvim-treesitter/nvim-treesitter-textobjects
	config = function(_, opts)
		require("nvim-treesitter.configs").setup(opts)

		if not COMPILER_AVAILABLE then
			vim.notify_once(
				"nvim-treesitter: no C compiler on PATH, parser installs are disabled.\n"
					.. "Install zig or the MSVC build tools, then run :TSUpdate.",
				vim.log.levels.WARN
			)
		end
	end,
}
