local function ensure_installed(repo)
  local name         = repo:match(".+/(.+)$")
  local install_path = "spec/support/" .. name

  vim.opt.rtp:prepend(install_path)

  if not vim.loop.fs_stat(install_path) then
    print("* Downloading " .. name .. " to '" .. install_path .. "/'")
    vim.fn.system({ "git", "clone", "git@github.com:" .. repo .. ".git", install_path })
  end
end

if os.getenv("CI") then
  vim.opt.runtimepath:append "."
  vim.cmd([[runtime! plugin/plenary.vim]])
  vim.cmd([[runtime! plugin/nvim-treesitter.lua]])

  require("nvim-treesitter.configs").setup({ indent = { enable = true } })
else
  ensure_installed("nvim-lua/plenary.nvim")
  ensure_installed("nvim-treesitter/nvim-treesitter")
end

require('plenary.test_harness').test_directory('spec/filetypes')
