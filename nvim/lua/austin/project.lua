--- `SPC p` project helpers. Emacs uses project.el; there's no project plugin
--- here on purpose, and the layout is fixed (~/coding/{language}/{project}),
--- so a directory scan does the job without one.

local CODING_ROOT = vim.fs.normalize("~/coding")

local M = {}

local function projects()
	return vim.iter(vim.fs.dir(CODING_ROOT, { depth = 2 }))
		:filter(function(name, type)
			return type == "directory" and name:find("/") ~= nil
		end)
		:map(function(name)
			return name
		end)
		:totable()
end

--- Pick a project, make it the tab-local cwd, then open the file picker.
function M.switch()
	vim.ui.select(projects(), { prompt = "Project: " }, function(choice)
		if not choice then
			return
		end
		vim.cmd.tcd(CODING_ROOT .. "/" .. choice)
		require("telescope.builtin").find_files()
	end)
end

--- Clone a repo into the coding root (emacs magit-clone; neogit has no clone
--- popup, so this shells out).
function M.clone()
	vim.ui.input({ prompt = "Clone URL: " }, function(url)
		if not url or url == "" then
			return
		end

		vim.cmd("botright split | resize 15")
		vim.cmd.lcd(CODING_ROOT)
		vim.cmd.terminal("git clone " .. vim.fn.shellescape(url))
		vim.cmd("startinsert")
	end)
end

--- Kill every loaded buffer under the current project root.
function M.kill_buffers()
	local root = vim.fn.getcwd()

	vim.iter(vim.api.nvim_list_bufs())
		:filter(function(buf)
			return vim.api.nvim_buf_is_loaded(buf) and vim.startswith(vim.api.nvim_buf_get_name(buf), root)
		end)
		:each(function(buf)
			pcall(vim.api.nvim_buf_delete, buf, {})
		end)
end

return M
