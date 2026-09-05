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

-- Lazy-require a function from one of the austin/ helper modules.
local function helper(module, name)
	return function()
		require("austin." .. module)[name]()
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
-- vim-style tab cycling, mirroring the C-h / C-l window movement above
map("n", "<C-S-h>", "<cmd>tabprevious<CR>", { desc = "Previous tab" })
map("n", "<C-S-l>", "<cmd>tabnext<CR>", { desc = "Next tab" })

-- ─── SPC a — ai (claude code in a terminal split) ───────────────────────────────
-- The emacs side uses claude-code-ide.el; this drives the CLI directly, so the
-- IDE-only bindings there (send prompt, insert @file, session list) have no
-- counterpart here.
map("n", "<leader>al", function()
	require("austin.ai").start()()
end, { desc = "Launch chat (right)" })
map("n", "<leader>at", helper("ai", "toggle"), { desc = "Toggle window" })
map("n", "<leader>ac", function()
	require("austin.ai").start("--continue")()
end, { desc = "Continue last" })
map("n", "<leader>ar", function()
	require("austin.ai").start("--resume")()
end, { desc = "Resume session" })
map("n", "<leader>aq", helper("ai", "stop"), { desc = "Stop session" })

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
map("n", "<leader>f:", function()
	vim.cmd.source(vim.env.MYVIMRC)
	vim.notify("reloaded init.lua (plugin specs need a restart)")
end, { desc = "Reload config file" })
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
map("n", "<leader>oT", function()
	vim.cmd("tabnew | terminal")
	vim.cmd("startinsert")
end, { desc = "Open terminal (tab)" })

-- ─── SPC p — projects (no project.nvim; ~/coding/{lang}/{project} scan) ─────────
map("n", "<leader>po", helper("project", "switch"), { desc = "Open project" })
map("n", "<leader>pk", helper("project", "kill_buffers"), { desc = "Kill project buffers" })
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
map("n", "<leader>gC", helper("project", "clone"), { desc = "Clone" })
map("n", "<leader>gm", "<cmd>Neogit merge<CR>", { desc = "Merge" })
map("n", "<leader>gr", "<cmd>Neogit rebase<CR>", { desc = "Rebase" })
map("n", "<leader>gt", "<cmd>Neogit tag<CR>", { desc = "Tag" })
map("n", "<leader>ga", gs("stage_buffer"), { desc = "Stage buffer" })
map("n", "<leader>gd", gs("diffthis"), { desc = "Diff buffer" })
map("n", "<leader>gD", "<cmd>Neogit diff<CR>", { desc = "Diff popup" })
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
map("n", "<leader>tw", "<C-w>T", { desc = "Move window to its own tab" })

-- ─── SPC h — help ───────────────────────────────────────────────────────────────
map("n", "<leader>hh", tb("help_tags"), { desc = "Help tags" })
map("n", "<leader>hk", tb("keymaps"), { desc = "Keymaps" })
map("n", "<leader>hc", tb("commands"), { desc = "Commands" })
map("n", "<leader>ho", function()
	require("telescope.builtin").vim_options()
end, { desc = "Options" })
map("n", "<leader>hm", "<cmd>Telescope man_pages<CR>", { desc = "Man pages" })
-- The `hd` describe tree mirrors emacs helpful.el as closely as nvim allows.
map("n", "<leader>hdb", tb("keymaps"), { desc = "Describe bindings" })
map("n", "<leader>hdf", tb("commands"), { desc = "Describe command" })
map("n", "<leader>hdv", tb("vim_options"), { desc = "Describe option" })
map("n", "<leader>hdk", function()
	vim.ui.input({ prompt = "Describe key: " }, function(key)
		if key and key ~= "" then
			vim.cmd("verbose map " .. key)
		end
	end)
end, { desc = "Describe key" })
map("n", "<leader>hds", function()
	if not pcall(vim.cmd.help, vim.fn.expand("<cword>")) then
		vim.lsp.buf.hover()
	end
end, { desc = "Describe symbol at point" })
map("n", "<leader>hdm", function()
	local clients = vim.iter(vim.lsp.get_clients({ bufnr = 0 }))
		:map(function(client)
			return client.name
		end)
		:totable()

	vim.notify(
		string.format(
			"filetype: %s\nlsp: %s",
			vim.bo.filetype ~= "" and vim.bo.filetype or "none",
			#clients > 0 and table.concat(clients, ", ") or "none"
		)
	)
end, { desc = "Describe mode" })

-- ─── SPC w — window ─────────────────────────────────────────────────────────────
map("n", "<leader>wl", "<C-w>v", { desc = "Split right" })
map("n", "<leader>wj", "<C-w>s", { desc = "Split below" })
map("n", "<leader>wq", "<C-w>q", { desc = "Close window" })
map("n", "<leader>wk", "<C-w>c", { desc = "Close window" })
map("n", "<leader>wo", "<C-w>o", { desc = "Close other windows" })
map("n", "<leader>ww", "<C-w>w", { desc = "Other window" })
map("n", "<leader>ws", "<C-w>x", { desc = "Swap with next window" })
-- Same h/j/k/l verbs as the C-h/j/k/l focus movement: focus with control,
-- move the window itself with the leader.
map("n", "<leader>wmh", "<C-w>H", { desc = "Move window left" })
map("n", "<leader>wmj", "<C-w>J", { desc = "Move window down" })
map("n", "<leader>wmk", "<C-w>K", { desc = "Move window up" })
map("n", "<leader>wml", "<C-w>L", { desc = "Move window right" })

-- ─── SPC : / ; / x — command palette, act, eval ─────────────────────────────────
map("n", "<leader>:", tb("commands"), { desc = "M-x (commands)" })
-- Closest thing to embark-act: the contextual "do something to the thing at
-- point" verb.
map({ "n", "x" }, "<leader>;", vim.lsp.buf.code_action, { desc = "Act on thing at point" })
map("n", "<leader>x", function()
	vim.ui.input({ prompt = "Lua: " }, function(expr)
		if expr and expr ~= "" then
			vim.cmd("lua =" .. expr)
		end
	end)
end, { desc = "Eval lua expression" })
map("n", "<leader>/", function()
	require("telescope.builtin").current_buffer_fuzzy_find(require("telescope.themes").get_dropdown({
		winblend = 10,
		previewer = false,
	}))
end, { desc = "Fuzzy search in current buffer" })

-- ─── SPC e — eval / build (global half) ─────────────────────────────────────────
-- The per-language half is buffer-local, set from FileType autocmds in
-- austin/autocommands.lua. Clojure comes from conjure, which owns
-- <localleader>e and localleader is SPC here.
map("n", "<leader>eR", helper("build", "repeat_last"), { desc = "Recompile last" })
map("n", "<leader>ec", helper("build", "compile"), { desc = "Project compile…" })

-- ─── SPC c — code / LSP (global, mirroring emacs `SPC c`) ────────────────────────
-- actions
map({ "n", "x" }, "<leader>caa", vim.lsp.buf.code_action, { desc = "Code action" })
map("n", "<leader>car", vim.lsp.buf.rename, { desc = "Rename" })
map("n", "<leader>cas", vim.lsp.buf.signature_help, { desc = "Signature help" })
map("n", "<leader>cao", function()
	vim.lsp.buf.code_action({ context = { only = { "source.organizeImports" } }, apply = true })
end, { desc = "Organize imports" })
-- caf (format) is owned by conform in plugins/format.lua
map("n", "<leader>caF", function()
	vim.g.disable_autoformat = not vim.g.disable_autoformat
	vim.notify("format on save: " .. (vim.g.disable_autoformat and "off" or "on"))
end, { desc = "Toggle format on save" })
-- goto
map("n", "<leader>cgd", tb("lsp_definitions"), { desc = "Definition" })
map("n", "<leader>cgD", vim.lsp.buf.declaration, { desc = "Declaration" })
map("n", "<leader>cgi", tb("lsp_implementations"), { desc = "Implementation" })
map("n", "<leader>cgt", tb("lsp_type_definitions"), { desc = "Type definition" })
map("n", "<leader>cgr", tb("lsp_references"), { desc = "References" })
map("n", "<leader>cgs", tb("lsp_document_symbols"), { desc = "Document symbols" })
map("n", "<leader>cgw", tb("lsp_dynamic_workspace_symbols"), { desc = "Workspace symbols" })
-- peek (telescope pickers already preview, so peek and goto share targets)
map("n", "<leader>cpd", tb("lsp_definitions"), { desc = "Peek definition" })
map("n", "<leader>cpi", tb("lsp_implementations"), { desc = "Peek implementation" })
map("n", "<leader>cpr", tb("lsp_references"), { desc = "Peek references" })
-- ui
map("n", "<leader>cud", vim.lsp.buf.hover, { desc = "Hover doc" })
map("n", "<leader>cuj", vim.lsp.buf.hover, { desc = "Glance doc" })
map("n", "<leader>cuh", function()
	vim.iter(vim.api.nvim_list_wins())
		:filter(function(win)
			return vim.api.nvim_win_get_config(win).relative ~= ""
		end)
		:each(function(win)
			pcall(vim.api.nvim_win_close, win, false)
		end)
end, { desc = "Hide doc float" })
map("n", "<leader>cus", function()
	local enabled = vim.diagnostic.config().virtual_text ~= false
	vim.diagnostic.config({ virtual_text = enabled and false or { source = "if_many", spacing = 2 } })
	vim.notify("diagnostic sideline: " .. (enabled and "off" or "on"))
end, { desc = "Toggle diagnostic sideline" })
-- tree (emacs uses lsp-treemacs; telescope is the equivalent surface here)
map("n", "<leader>ctt", tb("lsp_document_symbols"), { desc = "Symbols tree" })
map("n", "<leader>ctd", tb("diagnostics"), { desc = "Errors tree" })
map("n", "<leader>ctr", tb("lsp_references"), { desc = "References tree" })
-- errors
map("n", "<leader>cen", diag_jump(1), { desc = "Next error" })
map("n", "<leader>cep", diag_jump(-1), { desc = "Previous error" })
map("n", "<leader>cel", tb("diagnostics"), { desc = "Error list" })
-- workspace
map("n", "<leader>cwr", "<cmd>LspRestart<CR>", { desc = "Restart LSP" })
map("n", "<leader>cwa", vim.lsp.buf.add_workspace_folder, { desc = "Add workspace folder" })
map("n", "<leader>cwd", vim.lsp.buf.remove_workspace_folder, { desc = "Remove workspace folder" })
map("n", "<leader>cwo", function()
	vim.notify(vim.inspect(vim.lsp.buf.list_workspace_folders()))
end, { desc = "Workspace folders" })
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
map("n", "<leader>cdv", function()
	require("dapui").float_element("scopes", { enter = true })
end, { desc = "Locals" })
map("n", "<leader>cds", function()
	require("dapui").float_element("stacks", { enter = true })
end, { desc = "Sessions / stacks" })
map("n", "<leader>cdt", function()
	require("dap.ui.widgets").hover()
end, { desc = "Value under cursor" })
