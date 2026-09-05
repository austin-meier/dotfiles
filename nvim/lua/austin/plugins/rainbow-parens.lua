-- doom-one palette, same hexes as the emacs rainbow-delimiters faces.
local COLORS = {
	RainbowDelimiterBlue = "#51afef",
	RainbowDelimiterGreen = "#98be65",
	RainbowDelimiterViolet = "#a9a1e1",
	RainbowDelimiterYellow = "#ecbe7b",
	RainbowDelimiterCyan = "#46d9ff",
	RainbowDelimiterOrange = "#da8548",
	RainbowDelimiterRed = "#ff6c6b",
}

--- rainbow-delimiters errors when it attaches to a buffer whose tree-sitter
--- parser is missing or failed to build, which is the normal state on a box
--- without a C compiler. Check before attaching rather than catching after.
local function has_working_parser(bufnr)
	local ok, parser = pcall(vim.treesitter.get_parser, bufnr, nil, { error = false })
	return ok and parser ~= nil
end

return {
	"HiPhish/rainbow-delimiters.nvim",
	-- Must come after treesitter: the strategies resolve parsers on attach.
	dependencies = { "nvim-treesitter/nvim-treesitter" },
	event = { "BufReadPost", "BufNewFile" },
	config = function()
		vim.iter(COLORS):each(function(group, fg)
			vim.api.nvim_set_hl(0, group, { fg = fg, default = true })
		end)

		vim.g.rainbow_delimiters = {
			condition = function(bufnr)
				-- The global strategy re-runs on every edit, so skip files big
				-- enough to feel it.
				return has_working_parser(bufnr) and vim.api.nvim_buf_line_count(bufnr) < 10000
			end,
		}
	end,
}
