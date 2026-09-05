-- Highlight when yanking (copying) text
vim.api.nvim_create_autocmd("TextYankPost", {
	desc = "Highlight when yanking (copying) text",
	group = vim.api.nvim_create_augroup("kickstart-highlight-yank", { clear = true }),
	callback = function()
		vim.highlight.on_yank()
	end,
})

-- ─── SPC e — per-language build / eval ──────────────────────────────────────
-- Buffer-local, the way general.el scopes its `SPC e` blocks with
-- :keymaps '<mode>-map. Clojure is deliberately missing: conjure owns
-- <localleader>e and localleader is SPC, so its tree already lands here.

local spec

--- Built on first use so `austin.build` stays off the startup path.
local function build_spec()
	if spec then
		return spec
	end

	local build = require("austin.build")

	local cc = {
		{ "eb", build.cc_build, "Build (cmake/make/file)" },
		{ "er", build.cc_run, "Compile + run file" },
		{ "ef", build.cc_compile_file, "Compile file" },
		{ "et", build.cc_test, "Test (ctest/make)" },
	}

	local js = {
		{ "er", build.js_script("dev"), "Run (dev server)" },
		{ "ed", build.js_script("dev"), "Dev server" },
		{ "ef", build.js_run_file, "Run file (node)" },
		{ "es", build.js_pick_script, "npm script…" },
	}

	spec = {
		lua = {
			{ "eb", build.lua_source_buffer, "Source buffer" },
			{ "ee", build.lua_eval_line, "Eval line" },
			{ "er", build.lua_eval_selection, "Eval region", "x" },
		},
		rust = {
			{ "eb", build.cargo("build"), "cargo build" },
			{ "er", build.cargo("run"), "cargo run" },
			{ "et", build.cargo("test"), "cargo test" },
		},
		c = cc,
		cpp = cc,
		javascript = js,
		javascriptreact = js,
		typescript = js,
		typescriptreact = js,
	}

	return spec
end

vim.api.nvim_create_autocmd("FileType", {
	desc = "Buffer-local SPC e build/eval tree",
	group = vim.api.nvim_create_augroup("austin-build-maps", { clear = true }),
	pattern = { "lua", "rust", "c", "cpp", "javascript", "javascriptreact", "typescript", "typescriptreact" },
	callback = function(event)
		vim.iter(build_spec()[vim.bo[event.buf].filetype] or {}):each(function(entry)
			local keys, action, desc, mode = unpack(entry)
			vim.keymap.set(mode or "n", "<leader>" .. keys, action, { buffer = event.buf, desc = desc })
		end)
	end,
})
