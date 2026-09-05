--- `SPC a` — Claude Code in a terminal split. The emacs config uses
--- claude-code-ide.el; nothing equivalent here is worth the startup cost, so
--- this drives the CLI in a managed terminal buffer instead.

local M = {}

local session = {}

local function window_showing(buf)
	return vim.iter(vim.api.nvim_list_wins()):find(function(win)
		return vim.api.nvim_win_get_buf(win) == buf
	end)
end

local function open_split(buf)
	vim.cmd("botright vsplit")
	vim.cmd("vertical resize " .. math.floor(vim.o.columns * 0.4))
	vim.api.nvim_win_set_buf(0, buf)
	vim.cmd("startinsert")
end

local function alive(buf)
	return buf ~= nil and vim.api.nvim_buf_is_valid(buf)
end

--- Start a fresh session. `args` is appended to the `claude` invocation.
function M.start(args)
	return function()
		if vim.fn.executable("claude") == 0 then
			vim.notify("claude is not on PATH", vim.log.levels.ERROR)
			return
		end

		vim.cmd("botright vsplit")
		vim.cmd("vertical resize " .. math.floor(vim.o.columns * 0.4))
		vim.cmd.terminal(args and ("claude " .. args) or "claude")
		session.buf = vim.api.nvim_get_current_buf()
		vim.cmd("startinsert")
	end
end

--- Show the session if it's hidden, hide it if it's visible, start one if there
--- isn't one yet.
function M.toggle()
	if not alive(session.buf) then
		M.start()()
		return
	end

	local win = window_showing(session.buf)
	if win then
		vim.api.nvim_win_close(win, false)
	else
		open_split(session.buf)
	end
end

--- Close the session for good.
function M.stop()
	if alive(session.buf) then
		vim.api.nvim_buf_delete(session.buf, { force = true })
	end
	session.buf = nil
end

return M
