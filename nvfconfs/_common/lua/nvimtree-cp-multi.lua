-- https://github.com/nvim-tree/nvim-tree.lua/issues/1549#issuecomment-1732249010
local vim = vim -- fool LSP for less noise

vim.api.nvim_create_autocmd("filetype", {
	pattern = "NvimTree",
	desc = "Mappings for NvimTree",
	callback = function()
		-- Yank marked files
		vim.keymap.set("n", "bgy", function()
			local api = require("nvim-tree.api")
			local marks = api.marks.list()
			if #marks == 0 then
				print("No items marked")
				return
			end
			local absolute_file_paths = ""
			for _, mark in ipairs(marks) do
				absolute_file_paths = absolute_file_paths .. mark.absolute_path .. "\n"
			end
			-- Using system registers for multi-instance support.
			vim.fn.setreg("+", absolute_file_paths)
			print("Yanked " .. #marks .. " items")
		end, { remap = true, buffer = true, desc = "nvim-tree: yank marked paths to clipboard" })

		-- Paste files
		vim.keymap.set("n", "gp", function()
			local api = require("nvim-tree.api")
			local source_paths = {}
			for path in vim.fn.getreg("+"):gmatch("[^\n%s]+") do
				source_paths[#source_paths + 1] = path
			end
			local node = api.tree.get_node_under_cursor()
			local is_folder = node.fs_stat and node.fs_stat.type == "directory" or false
			local target_path = is_folder and node.absolute_path or vim.fn.fnamemodify(node.absolute_path, ":h")
			for _, source_path in ipairs(source_paths) do
				vim.fn.system({ "cp", "-R", source_path, target_path })
			end
			api.tree.reload()
			print("Pasted " .. #source_paths .. " items")
		end, { remap = true, buffer = true, desc = "nvim-tree: paste filepath(s) in system clipboard as file(s) at node" })
	end,
})
