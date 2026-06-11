-- Leader keys (must be set before lazy loads plugins; init.lua requires this first).
vim.g.mapleader = " "
vim.g.maplocalleader = " "

-- This file mirrors the single `austin/leader-key` block from the emacs config:
-- one central SPC tree. Bindings use lazy `require(...)` callbacks so they work
-- with lazy-loaded plugins. Group labels are declared in plugins/which-key.lua.
-- Buffer-local LSP setup (highlight, inlay hints) stays in plugins/lsp.lua.

local map = vim.keymap.set

-- Lazy-require a telescope.builtin picker as a callback.
local function tb(name, opts)
	return function()
		require("telescope.builtin")[name](opts or {})
	end
end

-- Lazy-require a gitsigns action as a callback.
local function gs(name)
	return function()
		require("gitsigns")[name]()
	end
end

-- Lazy-require an nvim-dap action as a callback.
local function dap(name)
	return function()
		require("dap")[name]()
	end
end

-- Version-robust diagnostic jump (0.11 `jump` vs 0.10 `goto_*`).
local function diag_jump(dir)
	return function()
		if vim.diagnostic.jump then
			vim.diagnostic.jump({ count = dir, float = true })
		elseif dir > 0 then
			vim.diagnostic.goto_next()
		else
			vim.diagnostic.goto_prev()
		end
	end
end

-- ─── Editor basics ──────────────────────────────────────────────────────────
map("n", "<Esc>", "<cmd>nohlsearch<CR>") -- clear search highlight
map("t", "<Esc><Esc>", "<C-\\><C-n>", { desc = "Exit terminal mode" })
map("n", "<leader>q", vim.diagnostic.setloclist, { desc = "Diagnostics → loclist" })

-- ─── Window movement (emacs: C-h/j/k/l) ───────────────────────────────────────
map("n", "<C-h>", "<C-w><C-h>", { desc = "Focus window left" })
map("n", "<C-l>", "<C-w><C-l>", { desc = "Focus window right" })
map("n", "<C-j>", "<C-w><C-j>", { desc = "Focus window down" })
map("n", "<C-k>", "<C-w><C-k>", { desc = "Focus window up" })

-- ─── Tab movement (emacs: C-<left>/<right>) ────────────────────────────────────
map("n", "<C-Left>", "<cmd>tabprevious<CR>", { desc = "Previous tab" })
map("n", "<C-Right>", "<cmd>tabnext<CR>", { desc = "Next tab" })

-- ─── SPC SPC — switch buffer ────────────────────────────────────────────────────
map("n", "<leader><leader>", tb("buffers"), { desc = "Switch buffer" })

-- ─── SPC b — buffers ────────────────────────────────────────────────────────────
map("n", "<leader>bb", tb("buffers"), { desc = "Switch buffer" })
map("n", "<leader>bk", "<cmd>bdelete<CR>", { desc = "Kill buffer" })
map("n", "<leader>bn", "<cmd>bnext<CR>", { desc = "Next buffer" })
map("n", "<leader>bp", "<cmd>bprevious<CR>", { desc = "Previous buffer" })
map("n", "<leader>br", "<cmd>edit!<CR>", { desc = "Revert buffer" })

-- ─── SPC f — files ──────────────────────────────────────────────────────────────
map("n", "<leader>ff", tb("find_files"), { desc = "Find file" })
map("n", "<leader>fs", tb("find_files"), { desc = "File search (name)" })
map("n", "<leader>fg", tb("live_grep"), { desc = "Grep files" })
map("n", "<leader>fr", tb("oldfiles"), { desc = "Recent files" })
map("n", "<leader>fw", "<cmd>write<CR>", { desc = "Save file" })
map("n", "<leader>fn", function()
	require("telescope.builtin").find_files({ cwd = vim.fn.stdpath("config") })
end, { desc = "Find nvim config file" })
map("n", "<leader>fd", function()
	local dir = vim.fn.input("Create directory: ", vim.fn.expand("%:p:h") .. "/", "dir")
	if dir ~= "" then
		vim.fn.mkdir(dir, "p")
		vim.notify("Created " .. dir)
	end
end, { desc = "Create directory" })
map("n", "<leader>fR", function()
	local old = vim.fn.expand("%:p")
	local new = vim.fn.input("Rename to: ", old, "file")
	if new ~= "" and new ~= old then
		vim.cmd("saveas " .. vim.fn.fnameescape(new))
		vim.fn.delete(old)
		vim.cmd("bdelete #")
	end
end, { desc = "Rename file" })

-- ─── SPC o — open ─────────────────────────────────────────────────────────────
map("n", "<leader>of", "<cmd>Neotree toggle<CR>", { desc = "File tree (toggle)" })
map("n", "<leader>od", "<cmd>Neotree reveal<CR>", { desc = "Reveal file in tree" })
map("n", "<leader>oh", "<cmd>Neotree dir=~ reveal<CR>", { desc = "Open home in tree" })
map("n", "<leader>oc", function()
	vim.cmd("edit " .. vim.fn.stdpath("config") .. "/init.lua")
end, { desc = "Open config" })
map("n", "<leader>ot", function()
	vim.cmd("botright split | resize 15 | terminal")
	vim.cmd("startinsert")
end, { desc = "Open terminal below" })

-- ─── SPC p — projects (light; no project.nvim — git-root scoped) ────────────────
map("n", "<leader>p<leader>", tb("buffers"), { desc = "Switch project buffer" })
map("n", "<leader>pf", tb("git_files"), { desc = "Find file in project" })
map("n", "<leader>pg", tb("live_grep"), { desc = "Grep project" })

-- ─── SPC g — git (neogit porcelain + gitsigns hunks) ────────────────────────────
map("n", "<leader>gs", "<cmd>Neogit<CR>", { desc = "Status" })
map("n", "<leader>gc", "<cmd>Neogit commit<CR>", { desc = "Commit" })
map("n", "<leader>gp", "<cmd>Neogit push<CR>", { desc = "Push" })
map("n", "<leader>gP", "<cmd>Neogit pull<CR>", { desc = "Pull" })
map("n", "<leader>gf", "<cmd>Neogit fetch<CR>", { desc = "Fetch" })
map("n", "<leader>gl", "<cmd>Neogit log<CR>", { desc = "Log" })
map("n", "<leader>gb", "<cmd>Neogit branch<CR>", { desc = "Branch" })
map("n", "<leader>ga", gs("stage_buffer"), { desc = "Stage buffer" })
map("n", "<leader>gd", gs("diffthis"), { desc = "Diff buffer" })
map("n", "<leader>ghs", gs("stage_hunk"), { desc = "Stage hunk" })
map("n", "<leader>ghr", gs("reset_hunk"), { desc = "Reset hunk" })
map("n", "<leader>ghp", gs("preview_hunk"), { desc = "Preview hunk" })
map("n", "]h", function()
	require("gitsigns").nav_hunk("next")
end, { desc = "Next git hunk" })
map("n", "[h", function()
	require("gitsigns").nav_hunk("prev")
end, { desc = "Previous git hunk" })

-- ─── SPC t — tabs ───────────────────────────────────────────────────────────────
map("n", "<leader>tn", "<cmd>tabnew<CR>", { desc = "New tab" })
map("n", "<leader>tk", "<cmd>tabclose<CR>", { desc = "Kill tab" })
map("n", "<leader>tl", "<cmd>tabnext<CR>", { desc = "Next tab" })
map("n", "<leader>th", "<cmd>tabprevious<CR>", { desc = "Previous tab" })
map("n", "<leader>tc", "<cmd>tabonly<CR>", { desc = "Close other tabs" })

-- ─── SPC h — help ───────────────────────────────────────────────────────────────
map("n", "<leader>hh", tb("help_tags"), { desc = "Help tags" })
map("n", "<leader>hk", tb("keymaps"), { desc = "Keymaps" })
map("n", "<leader>hc", tb("commands"), { desc = "Commands" })
map("n", "<leader>ho", function()
	require("telescope.builtin").vim_options()
end, { desc = "Options" })
map("n", "<leader>hm", "<cmd>Telescope man_pages<CR>", { desc = "Man pages" })

-- ─── SPC w — window ─────────────────────────────────────────────────────────────
map("n", "<leader>wl", "<C-w>v", { desc = "Split right" })
map("n", "<leader>wj", "<C-w>s", { desc = "Split below" })
map("n", "<leader>wq", "<C-w>q", { desc = "Close window" })
map("n", "<leader>wk", "<C-w>c", { desc = "Close window" })
map("n", "<leader>wo", "<C-w>o", { desc = "Close other windows" })
map("n", "<leader>ww", "<C-w>w", { desc = "Other window" })

-- ─── SPC : — command palette (emacs M-x) ────────────────────────────────────────
map("n", "<leader>:", tb("commands"), { desc = "M-x (commands)" })

-- ─── SPC c — code / LSP (global, mirroring emacs `SPC c`) ────────────────────────
-- actions
map({ "n", "x" }, "<leader>caa", vim.lsp.buf.code_action, { desc = "Code action" })
map("n", "<leader>car", vim.lsp.buf.rename, { desc = "Rename" })
map("n", "<leader>cas", vim.lsp.buf.signature_help, { desc = "Signature help" })
map("n", "<leader>cao", function()
	vim.lsp.buf.code_action({ context = { only = { "source.organizeImports" } }, apply = true })
end, { desc = "Organize imports" })
-- caf (format) is owned by conform in plugins/format.lua
-- goto
map("n", "<leader>cgd", tb("lsp_definitions"), { desc = "Definition" })
map("n", "<leader>cgD", vim.lsp.buf.declaration, { desc = "Declaration" })
map("n", "<leader>cgi", tb("lsp_implementations"), { desc = "Implementation" })
map("n", "<leader>cgt", tb("lsp_type_definitions"), { desc = "Type definition" })
map("n", "<leader>cgr", tb("lsp_references"), { desc = "References" })
map("n", "<leader>cgs", tb("lsp_document_symbols"), { desc = "Document symbols" })
map("n", "<leader>cgw", tb("lsp_dynamic_workspace_symbols"), { desc = "Workspace symbols" })
-- ui
map("n", "<leader>cud", vim.lsp.buf.hover, { desc = "Hover doc" })
-- errors
map("n", "<leader>cen", diag_jump(1), { desc = "Next error" })
map("n", "<leader>cep", diag_jump(-1), { desc = "Previous error" })
map("n", "<leader>cel", tb("diagnostics"), { desc = "Error list" })
-- workspace
map("n", "<leader>cwr", "<cmd>LspRestart<CR>", { desc = "Restart LSP" })
map("n", "<leader>cwa", vim.lsp.buf.add_workspace_folder, { desc = "Add workspace folder" })
map("n", "<leader>cwd", vim.lsp.buf.remove_workspace_folder, { desc = "Remove workspace folder" })
-- debug (dap)
map("n", "<leader>cdd", dap("continue"), { desc = "Start/continue" })
map("n", "<leader>cdc", dap("continue"), { desc = "Continue" })
map("n", "<leader>cdl", dap("step_over"), { desc = "Step over" })
map("n", "<leader>cdi", dap("step_into"), { desc = "Step into" })
map("n", "<leader>cdo", dap("step_out"), { desc = "Step out" })
map("n", "<leader>cdb", dap("toggle_breakpoint"), { desc = "Toggle breakpoint" })
map("n", "<leader>cdB", function()
	require("dap").set_breakpoint(vim.fn.input("Breakpoint condition: "))
end, { desc = "Conditional breakpoint" })
map("n", "<leader>cdr", dap("restart"), { desc = "Restart" })
map("n", "<leader>cdu", function()
	require("dapui").toggle()
end, { desc = "Toggle debug UI" })
