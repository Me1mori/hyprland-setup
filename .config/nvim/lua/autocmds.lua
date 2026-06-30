require "nvchad.autocmds"

vim.api.nvim_create_autocmd("VimEnter", {
  callback = function()
    local arg = vim.fn.argv(0)

    if not arg or arg == "" then
      return
    end

    if vim.fn.isdirectory(arg) == 1 then
      vim.schedule(function()
        vim.cmd("NvimTreeToggle")
      end)
    end
  end,
})
