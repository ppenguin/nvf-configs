local vim = vim -- fool LSP for less noise

function sops_edit()
    -- Get the current buffer's file path
    local original_file = vim.api.nvim_buf_get_name(0)

    -- Extract the basename of the file and prepend it with an underscore
    local basename = vim.fn.fnamemodify(original_file, ":t")
    local dirname = vim.fn.fnamemodify(original_file, ":h")
    local temp_file = vim.fn.fnamemodify(dirname .. "/_" .. basename, ":p")

    -- Decrypt the original file to the temp file using sops
    os.execute(string.format("sops -d %s > %s", vim.fn.shellescape(original_file), vim.fn.shellescape(temp_file)))

    -- Replace the buffer contents with the decrypted temp file
    vim.cmd(string.format("e %s", vim.fn.fnameescape(temp_file)))

    -- Set up an autocmd to handle encrypting the file when the buffer is closed
    vim.cmd(string.format([[
        augroup SopsEncrypt
            autocmd!
            autocmd BufWritePre <buffer> lua encrypt_and_save(%q, %q)
            autocmd BufUnload <buffer> silent! !rm %s
            autocmd BufWinLeave <buffer> silent! !rm %s
        augroup END
    ]], original_file, temp_file, vim.fn.shellescape(temp_file), vim.fn.shellescape(temp_file)))
end

-- Function to encrypt the temp file and write it to the original file
function encrypt_and_save(original_file, temp_file)
    -- Explicitly save the buffer to ensure it's written to the temp file
    vim.cmd("write")

    -- Prepare the sops command to encrypt the file and capture stderr
    local cmd = string.format("sops -e %s > %s 2> /tmp/sops_encrypt_err.log", vim.fn.shellescape(temp_file),
        vim.fn.shellescape(original_file))

    -- Execute the command
    local result = os.execute(cmd)

    -- Read the stderr output
    local err_log = io.open("/tmp/sops_encrypt_err.log", "r")
    if err_log then
        local err_output = err_log:read("*all")
        err_log:close()

        -- If there's an error, print it to the Neovim command line
        if err_output ~= "" then
            vim.cmd(string.format("echohl ErrorMsg | echom 'sops encryption error: %s' | echohl None",
                vim.fn.escape(err_output, "'")))
        end
    end

    -- If the command was successful, mark the buffer as not modified
    if result == 0 then
        vim.api.nvim_buf_set_option(0, 'modified', false)
    end
end

-- Bind the function to a command or a keymap if desired
vim.cmd("command! SopsEdit lua sops_edit()")
