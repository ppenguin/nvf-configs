local vim = vim
local uv = vim.uv

local function notify(message, level)
	vim.notify(message, level or vim.log.levels.INFO, { title = "SOPS" })
end

local function plaintext(bufnr)
	local text = table.concat(vim.api.nvim_buf_get_lines(bufnr, 0, -1, false), "\n")
	if vim.bo[bufnr].endofline then text = text .. "\n" end
	return text
end

local function atomic_replace(path, contents)
	local stat = uv.fs_stat(path)
	local mode = stat and stat.mode % 512 or 384 -- Preserve rwx bits; default 0600.
	local directory = vim.fs.dirname(path)
	local basename = vim.fs.basename(path)
	local temporary
	local fd

	for attempt = 1, 20 do
		temporary = vim.fs.joinpath(
			directory,
			(".%s.sops-%d-%d-%d.tmp"):format(basename, vim.fn.getpid(), uv.hrtime(), attempt)
		)
		fd = uv.fs_open(temporary, "wx", 384)
		if fd then break end
	end
	if not fd then return false, "could not create an encrypted temporary output" end

	local ok, err = pcall(function()
		local written, write_err = uv.fs_write(fd, contents, 0)
		if not written then error(write_err or "write failed") end
		local synced, sync_err = uv.fs_fsync(fd)
		if not synced then error(sync_err or "fsync failed") end
	end)
	uv.fs_close(fd)

	if not ok then
		uv.fs_unlink(temporary)
		return false, tostring(err)
	end

	local chmod_ok, chmod_err = uv.fs_chmod(temporary, mode)
	if not chmod_ok then
		uv.fs_unlink(temporary)
		return false, chmod_err or "chmod failed"
	end

	local renamed, rename_err = uv.fs_rename(temporary, path)
	if not renamed then
		uv.fs_unlink(temporary)
		return false, rename_err or "atomic rename failed"
	end
	return true
end

local function encrypt_and_save(bufnr, original_file)
	local result = vim.system({
		sops_binary,
		"--encrypt",
		"--filename-override",
		original_file,
	}, {
		stdin = plaintext(bufnr),
		text = true,
	}):wait()

	if result.code ~= 0 then
		notify("Encryption failed; original file was not changed:\n" .. vim.trim(result.stderr or ""), vim.log.levels.ERROR)
		return
	end

	local replaced, replace_error = atomic_replace(original_file, result.stdout or "")
	if not replaced then
		notify("Encrypted output could not replace the original:\n" .. replace_error, vim.log.levels.ERROR)
		return
	end

	vim.bo[bufnr].modified = false
	notify("Encrypted and saved " .. original_file)
end

local function sops_edit()
	local bufnr = vim.api.nvim_get_current_buf()
	local original_file = vim.api.nvim_buf_get_name(bufnr)
	if original_file == "" then
		notify("Current buffer has no file name", vim.log.levels.ERROR)
		return
	end
	if vim.b[bufnr].sops_edit_active then
		notify("This buffer is already in SOPS edit mode", vim.log.levels.WARN)
		return
	end
	if vim.bo[bufnr].modified then
		notify("Save or discard current encrypted-buffer changes first", vim.log.levels.ERROR)
		return
	end

	local result = vim.system({ sops_binary, "--decrypt", original_file }, { text = true }):wait()
	if result.code ~= 0 then
		notify("Decryption failed:\n" .. vim.trim(result.stderr or ""), vim.log.levels.ERROR)
		return
	end

	local decrypted = result.stdout or ""
	local has_final_eol = decrypted:sub(-1) == "\n"
	local lines = vim.split(decrypted, "\n", { plain = true })
	if has_final_eol then table.remove(lines) end
	if #lines == 0 then lines = { "" } end

	vim.bo[bufnr].swapfile = false
	vim.bo[bufnr].undofile = false
	vim.bo[bufnr].buftype = "acwrite"
	vim.bo[bufnr].endofline = has_final_eol
	vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, lines)
	vim.bo[bufnr].modified = false
	vim.b[bufnr].sops_edit_active = true

	local group = vim.api.nvim_create_augroup("NvfSopsEdit" .. bufnr, { clear = true })
	vim.api.nvim_create_autocmd("BufWriteCmd", {
		group = group,
		buffer = bufnr,
		desc = "Encrypt SOPS buffer and atomically replace its source",
		callback = function()
			encrypt_and_save(bufnr, original_file)
		end,
	})
	vim.api.nvim_create_autocmd("BufWipeout", {
		group = group,
		buffer = bufnr,
		once = true,
		callback = function()
			pcall(vim.api.nvim_del_augroup_by_id, group)
		end,
	})

	notify("Decrypted in memory; :write encrypts atomically")
end

vim.api.nvim_create_user_command("SopsEdit", sops_edit, {
	desc = "Decrypt the current SOPS file into a protected in-memory buffer",
})
