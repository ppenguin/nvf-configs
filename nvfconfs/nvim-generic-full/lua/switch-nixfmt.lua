local vim = vim
-- Function to execute a command and return its output
local function execute_command(cmd)
	local res = vim.system(cmd, { text = true }):wait()
	if res.code ~= 0 then
		return nil, res.stderr
	end
	return res.stdout
end

-- Function to set the formatter in nil
local function set_nil_formatter(formatter)
	local clients = vim.lsp.get_clients()
	for _, client in ipairs(clients) do
		if client.name == "nil" then
			-- Print the current command value for debugging
			local current_command = client.config.settings
				and client.config.settings["nil"]
				and client.config.settings["nil"].formatting
				and client.config.settings["nil"].formatting.command

			if current_command then
				-- print("Current command:", current_command[1])
				-- Check the output of the current formatter with --version
				local version_output = execute_command({ current_command[1], "--version" })
				if version_output == "" then
					print("Executable not found for:", current_command[1])
				else
					print("Current formatter:", version_output)
				end
			else
				print("No current command found.")
			end

			-- Check if the formatter is already set
			if current_command and current_command[1] == formatter then
				print("Formatter is already set to: " .. formatter)
				return
			end

			-- Set formatter in the client's configuration
			client.config.settings = client.config.settings or {}
			client.config.settings["nil"] = client.config.settings["nil"] or {}
			client.config.settings["nil"].formatting = client.config.settings["nil"].formatting or {}

			-- Assign command based on the formatter
			if formatter == "alejandra" then
				client.config.settings["nil"].formatting.command = { "alejandra", "--quiet" }
			elseif formatter == "nixfmt" then
				client.config.settings["nil"].formatting.command = { "nixfmt" }
			else
				print("No choice available for formatter " .. formatter .. "! Ignoring...")
			end

			-- Print the updated command value for debugging
			-- print("Updated command to:", client.config.settings["nil"].formatting.command[1])

			-- Check the output of the new formatter with --version
			local new_version_output = execute_command({ client.config.settings["nil"].formatting.command[1], "--version" })
			if new_version_output == "" then
				print("Executable not found for:", client.config.settings["nil"].formatting.command[1])
			else
				print("Updated formatter:", new_version_output)
			end

			client.notify("workspace/didChangeConfiguration", { settings = client.config.settings })

			print("Formatter switched to: " .. formatter)

			-- Format the current buffer immediately after switching
			vim.lsp.buf.format({ async = true }) -- Use async formatting
			return
		end
	end
	print("nil not active")
end

-- Commands to switch between formatters
vim.api.nvim_create_user_command("FormatNixUseNixfmt", function()
	set_nil_formatter("nixfmt")
end, {})
vim.api.nvim_create_user_command("FormatNixUseAlejandra", function()
	set_nil_formatter("alejandra")
end, {})
