-- Evaluate the ${...} directive under the cursor via SilverBullet's Runtime API
-- (POST <space>/.runtime/lua) and pick one of the linked pages from its result.
-- Results are either objects (pages/tasks with ref/name/page) or rendered
-- markdown strings containing [[links]] (e.g. `select templates.pageItem(p)`).
local M = {}

local function notify(msg, level)
	vim.notify("SilverBullet: " .. msg, level or vim.log.levels.INFO)
end

local function current_space()
	local current = require("silverbullet.state").get(vim.api.nvim_get_current_buf())
	return current and current.space
end

-- index just past the matching closer of a Lua long bracket / quoted string at i, or nil
local function skip_literal(text, i)
	local eq = text:match("^%[(=*)%[", i)
	if eq then
		local _, close = text:find("]" .. eq .. "]", i + #eq + 2, true)
		return close and close + 1 or #text + 1
	end
	local quote = text:sub(i, i)
	if quote == '"' or quote == "'" then
		local j = i + 1
		while j <= #text do
			local c = text:sub(j, j)
			if c == "\\" then
				j = j + 1
			elseif c == quote then
				return j + 1
			end
			j = j + 1
		end
		return j
	end
end

-- end index (the closing brace) of the directive whose "${" starts at start
local function directive_end(text, start)
	local depth, i = 1, start + 2
	while i <= #text do
		local skipped = skip_literal(text, i)
		if skipped then
			i = skipped
		else
			local c = text:sub(i, i)
			if c == "{" then
				depth = depth + 1
			elseif c == "}" then
				depth = depth - 1
				if depth == 0 then
					return i
				end
			end
			i = i + 1
		end
	end
end

-- Lua expression of the (possibly multi-line) ${...} directive around the cursor
function M.directive_at_cursor()
	local text = table.concat(vim.api.nvim_buf_get_lines(0, 0, -1, false), "\n")
	local cursor = vim.api.nvim_win_get_cursor(0)
	local offset = vim.fn.line2byte(cursor[1]) + cursor[2] -- 1-based byte index into text
	local search_from = 1
	while true do
		local start = text:find("${", search_from, true)
		if not start or start > offset then
			return nil
		end
		local stop = directive_end(text, start)
		if not stop then
			return nil
		end
		if text:sub(start - 1, start - 1) ~= "\\" and offset <= stop then
			return text:sub(start + 2, stop - 1)
		end
		search_from = stop + 1
	end
end

function M.eval(space_name, expression)
	local space = require("silverbullet.config").space(space_name)
	local response, err = require("silverbullet.transport.curl").request(space, {
		method = "POST",
		url = space.url .. "/.runtime/lua",
		headers = { ["Content-Type"] = "text/plain; charset=utf-8" },
		body = expression,
	})
	if not response then
		return nil, err
	end
	local ok, decoded = pcall(vim.json.decode, response.body, { luanil = { object = true, array = true } })
	if response.status < 200 or response.status >= 300 then
		local msg = ok and type(decoded) == "table" and decoded.error or response.body
		return nil, ("Runtime API HTTP %d: %s"):format(response.status, msg)
	end
	if not ok or type(decoded) ~= "table" then
		return nil, "unexpected Runtime API response: " .. tostring(response.body):sub(1, 200)
	end
	return decoded.result
end

-- flatten a query result into { target = "Page[@pos]", heading?, text }
local function collect(value, items)
	if type(value) == "string" then
		for _, line in ipairs(vim.split(value, "\n", { trimempty = true })) do
			for _, link in ipairs(require("silverbullet.links").extract(line)) do
				if link.page and link.page ~= "" then
					table.insert(items, { target = link.page, heading = link.heading, text = vim.trim(line) })
				end
			end
		end
	elseif type(value) == "table" and not value._isWidget then
		local target = value.ref
			or (type(value.page) == "string" and value.page .. (value.pos and ("@" .. value.pos) or ""))
			or value.name
		if type(target) == "string" then
			local text = value.text or value.name or target
			table.insert(items, { target = target, text = text == target and text or (target .. "  " .. text) })
		else
			for _, v in (vim.islist(value) and ipairs or pairs)(value) do
				collect(v, items)
			end
		end
	end
	return items
end

local function jump_heading(heading)
	local wanted = vim.trim(heading):lower()
	for lnum, line in ipairs(vim.api.nvim_buf_get_lines(0, 0, -1, false)) do
		local found = line:match("^%s*#+%s+(.-)%s*$")
		if found and found:lower() == wanted then
			vim.api.nvim_win_set_cursor(0, { lnum, 0 })
			return
		end
	end
	notify(("heading %q not found"):format(heading), vim.log.levels.WARN)
end

-- open "Page", "Page@pos" (character offset, as in task refs) or "Page#Heading"
function M.open(space_name, target, heading)
	local page, pos = target:match("^(.-)@(%d+)$")
	page = page or target
	require("silverbullet.buffer").open(space_name, page)
	if pos then
		local lnum = vim.fn.byte2line(tonumber(pos) + 1)
		if lnum > 0 then
			vim.api.nvim_win_set_cursor(0, { lnum, 0 })
		end
	elseif heading then
		jump_heading(heading)
	end
end

local function pick_item(space_name, items)
	local function choose(item)
		if item then
			M.open(space_name, item.target, item.heading)
		end
	end
	local ok_t, pickers = pcall(require, "telescope.pickers")
	if not ok_t then
		return vim.ui.select(items, {
			prompt = "Query results",
			format_item = function(item)
				return item.text
			end,
		}, choose)
	end
	local finders = require("telescope.finders")
	local actions = require("telescope.actions")
	local action_state = require("telescope.actions.state")
	pickers
		.new({}, {
			prompt_title = "SilverBullet query (" .. space_name .. ")",
			finder = finders.new_table({
				results = items,
				entry_maker = function(item)
					return { value = item, display = item.text, ordinal = item.text }
				end,
			}),
			sorter = require("telescope.config").values.generic_sorter({}),
			attach_mappings = function(prompt_bufnr)
				actions.select_default:replace(function()
					local entry = action_state.get_selected_entry()
					actions.close(prompt_bufnr)
					choose(entry and entry.value)
				end)
				return true
			end,
		})
		:find()
end

-- run the directive under the cursor and pick a result
function M.pick(expression)
	local space_name = current_space()
	if not space_name then
		return notify("current buffer is not a SilverBullet page", vim.log.levels.ERROR)
	end
	expression = expression or M.directive_at_cursor()
	if not expression then
		return notify("cursor is not inside a ${...} directive", vim.log.levels.WARN)
	end
	local result, err = M.eval(space_name, expression)
	if err then
		return notify(err, vim.log.levels.ERROR)
	end
	local items = collect(result, {})
	if type(result) == "table" and result._isWidget then
		return notify("directive renders a widget, nothing to follow (use <leader>So for the web UI)")
	elseif #items == 0 then
		return notify("query returned no links: " .. vim.inspect(result):sub(1, 200))
	end
	pick_item(space_name, items)
end

-- <CR>: query results inside ${...}; [[Page@pos]] links; otherwise the plugin's link follow
function M.follow()
	local space_name = current_space()
	if space_name and M.directive_at_cursor() then
		return M.pick()
	end
	local cursor = vim.api.nvim_win_get_cursor(0)
	local link = require("silverbullet.links").at_cursor(vim.api.nvim_get_current_line(), cursor[2])
	if space_name and link and link.page and link.page:match("@%d+$") then
		return M.open(space_name, link.page)
	end
	require("silverbullet.links").follow()
end

return M
