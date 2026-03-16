local vim = vim
local last_action = nil

local function make_repeatable(lhs, mode)
	mode = mode or "n"
	local existing = vim.fn.maparg(lhs, mode, false, true)
	if not existing or not existing.callback then
		return
	end
	local fn = existing.callback
	vim.keymap.set(mode, lhs, function()
		last_action = fn
		fn()
	end, { desc = existing.desc })
end

vim.keymap.set("n", ",", function()
	if last_action then
		last_action()
	end
end)

-- we configure the existing keybinds to repeat with ','
make_repeatable("<leader>dc") -- continue
make_repeatable("<leader>db") -- toggle breakpoint
make_repeatable("<leader>dgc") -- cont to cursor
make_repeatable("<leader>dgi") -- step into
make_repeatable("<leader>dgo") -- step out
make_repeatable("<leader>dgj") -- next step
make_repeatable("<leader>dgk") -- step back
make_repeatable("<leader>dvo") -- stack trace up
make_repeatable("<leader>dvi") -- stack trace down
