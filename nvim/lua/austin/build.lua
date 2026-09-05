--- `SPC e` — mode-local build / run / eval, mirroring the per-language `SPC e`
--- trees in the emacs config. Every helper returns a callback so the keymaps
--- read the same way the telescope/gitsigns/dap helpers in keybinds.lua do.
---
--- Clojure is deliberately absent: conjure already owns `<localleader>e`, and
--- localleader is SPC here, so its tree lands on `SPC e` for free.

local M = {}

local last = {}

--- Run a command in a terminal split. `lcd` is window-local, so the terminal
--- inherits the project root without touching the rest of the session and
--- without shell-specific `cd &&` chaining.
local function terminal(dir, cmd)
	last = { dir = dir, cmd = cmd }

	vim.cmd("botright split | resize 15")
	vim.cmd.lcd(dir)
	vim.cmd.terminal(cmd)
	vim.cmd("startinsert")
end

local function root(markers)
	return vim.fs.root(0, markers) or vim.fn.getcwd()
end

local function file()
	return vim.fn.expand("%:p")
end

--- Repeat the last `SPC e` command, wherever you are now.
function M.repeat_last()
	if not last.cmd then
		vim.notify("no previous build command", vim.log.levels.WARN)
		return
	end
	terminal(last.dir, last.cmd)
end

--- Prompt for an arbitrary command in the project root (emacs `project-compile`).
function M.compile()
	vim.ui.input({ prompt = "Compile: ", default = last.cmd }, function(cmd)
		if cmd and cmd ~= "" then
			terminal(root({ ".git" }), cmd)
		end
	end)
end

function M.cargo(subcommand)
	return function()
		terminal(root({ "Cargo.toml" }), "cargo " .. subcommand)
	end
end

local CC_MARKERS = { "CMakeLists.txt", "Makefile", "compile_commands.json", ".git" }

--- CMake first, then Makefile, then a bare single-file compile. The cmake path
--- always exports compile_commands.json because clangd resolves includes from it.
function M.cc_build()
	local dir = root(CC_MARKERS)

	if vim.uv.fs_stat(dir .. "/CMakeLists.txt") then
		terminal(dir, "cmake -S . -B build -DCMAKE_EXPORT_COMPILE_COMMANDS=ON && cmake --build build")
	elseif vim.uv.fs_stat(dir .. "/Makefile") then
		terminal(dir, "make")
	else
		M.cc_compile_file()
	end
end

function M.cc_compile_file()
	local source = file()
	local out = vim.fn.fnamemodify(source, ":r")
	local compiler = vim.bo.filetype == "cpp" and "c++" or "cc"

	terminal(vim.fn.fnamemodify(source, ":h"), string.format("%s %s -o %s", compiler, source, out))
end

function M.cc_run()
	local out = vim.fn.fnamemodify(file(), ":r")
	local compiler = vim.bo.filetype == "cpp" and "c++" or "cc"

	terminal(vim.fn.fnamemodify(file(), ":h"), string.format("%s %s -o %s && %s", compiler, file(), out, out))
end

function M.cc_test()
	local dir = root(CC_MARKERS)
	local cmd = vim.uv.fs_stat(dir .. "/build") and "ctest --test-dir build --output-on-failure" or "make test"

	terminal(dir, cmd)
end

local function package_scripts(dir)
	local ok, contents = pcall(vim.fn.readfile, dir .. "/package.json")
	if not ok then
		return {}
	end

	local decoded, manifest = pcall(vim.json.decode, table.concat(contents, "\n"))
	return (decoded and manifest and manifest.scripts) or {}
end

function M.js_script(name)
	return function()
		local dir = root({ "package.json" })
		local scripts = package_scripts(dir)

		if not scripts[name] then
			vim.notify(string.format("no %q script in package.json", name), vim.log.levels.WARN)
			return
		end
		terminal(dir, "npm run " .. name)
	end
end

--- Pick any script out of package.json (emacs `austin/js-npm-script`).
function M.js_pick_script()
	local dir = root({ "package.json" })
	local names = vim.tbl_keys(package_scripts(dir))

	if vim.tbl_isempty(names) then
		vim.notify("no scripts in package.json", vim.log.levels.WARN)
		return
	end

	table.sort(names)
	vim.ui.select(names, { prompt = "npm run: " }, function(choice)
		if choice then
			terminal(dir, "npm run " .. choice)
		end
	end)
end

function M.js_run_file()
	terminal(vim.fn.fnamemodify(file(), ":h"), "node " .. file())
end

--- Source the current lua buffer (emacs `eval-buffer`).
function M.lua_source_buffer()
	vim.cmd.source("%")
	vim.notify("sourced " .. vim.fn.expand("%:t"))
end

function M.lua_eval_line()
	vim.cmd("lua " .. vim.api.nvim_get_current_line())
end

function M.lua_eval_selection()
	vim.cmd("'<,'>lua")
end

return M
