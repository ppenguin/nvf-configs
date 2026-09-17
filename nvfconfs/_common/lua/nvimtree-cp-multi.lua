local vim = vim

local function notify(message, level)
	vim.notify(message, level or vim.log.levels.INFO, { title = "nvim-tree copy" })
end

local function clipboard_paths()
	local paths = {}
	for line in vim.fn.getreg("+"):gmatch("[^\r\n]+") do
		if line ~= "" then table.insert(paths, line) end
	end
	return paths
end

vim.api.nvim_create_autocmd("FileType", {
	pattern = "NvimTree",
	desc = "Mappings for NvimTree",
	callback = function(event)
		vim.keymap.set("n", "bgy", function()
			local api = require("nvim-tree.api")
			local marks = api.marks.list()
			if #marks == 0 then
				notify("No items marked", vim.log.levels.WARN)
				return
			end

			local paths = {}
			for _, mark in ipairs(marks) do
				table.insert(paths, mark.absolute_path)
			end
			vim.fn.setreg("+", table.concat(paths, "\n") .. "\n")
			notify("Yanked " .. #paths .. " items")
		end, { remap = true, buffer = event.buf, desc = "nvim-tree: yank marked paths to clipboard" })

		vim.keymap.set("n", "gp", function()
			local api = require("nvim-tree.api")
			local sources = clipboard_paths()
			if #sources == 0 then
				notify("Clipboard contains no paths", vim.log.levels.WARN)
				return
			end

			local node = api.tree.get_node_under_cursor()
			if not node or not node.absolute_path then
				notify("No destination node under cursor", vim.log.levels.ERROR)
				return
			end

			local node_stat = node.fs_stat or vim.uv.fs_stat(node.absolute_path)
			local target = node_stat and node_stat.type == "directory"
				and node.absolute_path
				or vim.fs.dirname(node.absolute_path)
			if not target or not vim.uv.fs_stat(target) then
				notify("Destination directory does not exist", vim.log.levels.ERROR)
				return
			end

			local copied, skipped, failed = 0, 0, {}
			for _, source in ipairs(sources) do
				local source_stat = vim.uv.fs_stat(source)
				if not source_stat then
					table.insert(failed, source .. ": source does not exist")
				else
					local destination = vim.fs.joinpath(target, vim.fs.basename(source))
					local proceed = true
					if vim.uv.fs_stat(destination) then
						local choice = vim.fn.confirm(
							("Destination exists:\n%s\n\nOverwrite or merge it?"):format(destination),
							"&Overwrite / merge\n&Skip\n&Cancel remaining",
							2
						)
						if choice == 2 then
							skipped = skipped + 1
							proceed = false
						elseif choice ~= 1 then
							skipped = skipped + (#sources - copied - skipped - #failed)
							break
						end
					end

					if proceed then
						local result = vim.system({ "cp", "-R", source, target }, { text = true }):wait()
						if result.code == 0 then
							copied = copied + 1
						else
							local detail = vim.trim(result.stderr or "")
							table.insert(failed, source .. (detail ~= "" and ": " .. detail or ": copy failed"))
						end
					end
				end
			end

			api.tree.reload()
			local summary = ("Copied %d, skipped %d, failed %d"):format(copied, skipped, #failed)
			if #failed > 0 then
				notify(summary .. "\n" .. table.concat(failed, "\n"), vim.log.levels.ERROR)
			else
				notify(summary)
			end
		end, {
			remap = true,
			buffer = event.buf,
			desc = "nvim-tree: paste clipboard paths at node",
		})
	end,
})
