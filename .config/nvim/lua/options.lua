require "nvchad.options"

-- add yours here!

-- local o = vim.o
-- o.cursorlineopt ='both' -- to enable cursorline!

-- Configuraciones estéticas para Vimsence (Rich Presence)
vim.g.vimsence_client_id = "439485121000210432"
vim.g.vimsence_editing_details = "Editando: {}"
vim.g.vimsence_editing_state = "En el archivo: {}"

vim.api.nvim_create_autocmd("VimEnter", {
  callback = function()
    if vim.fn.argc() == 1 then
      local arg = vim.fn.argv(0)
      -- Validar explícitamente que es "string"
      if type(arg) == "string" then
        if vim.fn.isdirectory(arg) == 1 then
          vim.cmd("cd " .. arg)
        elseif vim.fn.filereadable(arg) == 1 then
          local dir = vim.fn.fnamemodify(arg, ":p:h")
          if vim.fn.getcwd() == vim.fn.expand("~") then
            vim.cmd("cd " .. dir)
          end
        end
      end
    end
  end,
})

