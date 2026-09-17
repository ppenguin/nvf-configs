local vim = vim
local dap = require("dap")
local last_action = nil
local comma_active = false

local function make_repeatable(lhs, mode)
	mode = mode or "n"
	local existing = vim.fn.maparg(lhs, mode, false, true)
	if not existing or not existing.callback then return end

	local action = existing.callback
	vim.keymap.set(mode, lhs, function()
		last_action = action
		action()
	end, { desc = existing.desc })
end

local function activate_comma()
	if comma_active then return end
	comma_active = true
	last_action = nil
	vim.keymap.set("n", ",", function()
		if last_action then last_action() end
	end, { desc = "Repeat last DAP action" })
end

local function deactivate_comma()
	vim.schedule(function()
		if dap.session() ~= nil or not comma_active then return end
		pcall(vim.keymap.del, "n", ",")
		comma_active = false
		last_action = nil
	end)
end

local listener = "nvf_repeat_key"
dap.listeners.after.event_initialized[listener] = activate_comma
dap.listeners.after.event_terminated[listener] = deactivate_comma
dap.listeners.after.event_exited[listener] = deactivate_comma
dap.listeners.after.disconnect[listener] = deactivate_comma

-- Wrap nvf's existing DAP mappings so their callbacks become repeatable while
-- a debug session is active. Deleting the temporary comma mapping restores
-- Vim's native reverse f/t repeat outside DAP.
make_repeatable("<leader>dc")
make_repeatable("<leader>db")
make_repeatable("<leader>dgc")
make_repeatable("<leader>dgi")
make_repeatable("<leader>dgo")
make_repeatable("<leader>dgj")
make_repeatable("<leader>dgk")
make_repeatable("<leader>dvo")
make_repeatable("<leader>dvi")
