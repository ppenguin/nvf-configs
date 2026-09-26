-- silverbullet.nvim setup: spaces and URL from the env, one user token for all spaces.
--   SILVERBULLET_URL:    server root
--   SILVERBULLET_SPACES: space path names under the root (first is default);
--                        if empty, SILVERBULLET_URL is used as a single space
--   SILVERBULLET_TOKEN:  bearer token (server: SB_AUTH_TOKEN), or set per session with <leader>Sk
local M = {}

local token -- session-only override, shared by all spaces

local auth = {
	token = function()
		local t = token or os.getenv("SILVERBULLET_TOKEN")
		if not t or t == "" then
			error("SILVERBULLET_TOKEN not set (or use <leader>Sk)")
		end
		return t
	end,
}

local function build_spaces(url)
	local names = vim.split(os.getenv("SILVERBULLET_SPACES") or "", "%s+", { trimempty = true })
	local spaces = {}
	for _, name in ipairs(names) do
		spaces[name] = { url = url .. "/" .. name, auth = auth, runtime = { enabled = true } }
	end
	if #names == 0 then
		names = { "default" }
		spaces.default = { url = url, auth = auth, runtime = { enabled = true } }
	end
	return names, spaces
end

-- the plugin always uses default_space for new pages/pickers; make it switchable
local function space_command(names, spaces)
	local sb_config = require("silverbullet.config")
	local function set_space(name)
		if not spaces[name] then
			vim.notify("Unknown SilverBullet space: " .. name, vim.log.levels.ERROR)
			return
		end
		sb_config.get().default_space = name
		vim.notify("SilverBullet space: " .. name)
	end
	vim.api.nvim_create_user_command("SilverBulletSpace", function(opts)
		if opts.args ~= "" then
			return set_space(opts.args)
		end
		vim.ui.select(names, {
			prompt = "SilverBullet space (current: " .. sb_config.get().default_space .. ")",
		}, function(choice)
			if choice then
				set_space(choice)
			end
		end)
	end, {
		nargs = "?",
		complete = function()
			return names
		end,
	})
end

local function keymaps()
	vim.keymap.set("n", "<leader>Sp", "<cmd>SilverBulletSpace<cr>", { desc = "SilverBullet switch space" })
	vim.keymap.set("n", "<leader>Sq", "<cmd>SilverBulletQuery<cr>", { desc = "SilverBullet query results" })
	vim.keymap.set("n", "<leader>Sk", function()
		local t = vim.fn.inputsecret("SilverBullet token: ")
		if t ~= "" then
			token = t
		end
	end, { desc = "SilverBullet set token (all spaces)" })

	for lhs, plug in pairs({
		["<leader>Sf"] = "Find",
		["<leader>Ss"] = "Search",
		["<leader>Sb"] = "Backlinks",
		["<leader>Sj"] = "Journal",
		["<leader>So"] = "OpenWeb",
	}) do
		vim.keymap.set("n", lhs, "<Plug>(SilverBullet" .. plug .. ")", { desc = "SilverBullet " .. plug })
	end

	-- <CR>: query results inside ${...}, otherwise follow the link (incl. [[Page@pos]])
	vim.api.nvim_create_autocmd("BufEnter", {
		pattern = "silverbullet://*",
		callback = function(ev)
			vim.keymap.set("n", "<CR>", function()
				require("silverbullet-nvim.query").follow()
			end, { buffer = ev.buf, desc = "Follow SilverBullet link / query" })
		end,
	})
end

function M.setup()
	local url = (os.getenv("SILVERBULLET_URL") or ""):gsub("/+$", "")
	if url == "" then
		return
	end
	local names, spaces = build_spaces(url)
	require("silverbullet").setup({ default_space = names[1], spaces = spaces })

	space_command(names, spaces)
	vim.api.nvim_create_user_command("SilverBulletQuery", function()
		require("silverbullet-nvim.query").pick()
	end, {})
	keymaps()
end

return M
