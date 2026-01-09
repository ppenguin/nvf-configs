local vim = vim
local conform = require("conform")

local function set_nix_formatter(formatter)
	-- mutate Conform config in-place
	conform.formatters_by_ft = conform.formatters_by_ft or {}
	conform.formatters_by_ft.nix = { formatter }

	vim.notify("Nix formatter set to: " .. formatter, vim.log.levels.INFO, { title = "Conform" })
end

vim.api.nvim_create_user_command("FormatNixUseAlejandra", function()
	set_nix_formatter("alejandra")
end, {})

vim.api.nvim_create_user_command("FormatNixUseNixfmt", function()
	set_nix_formatter("nixfmt")
end, {})
