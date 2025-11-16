vim.opt.encoding = "utf-8"
-- make sure the spellfile directory exists, sometimes nvim fails to create it
-- when downloading spellfiles
-- if NetRW is disabled, downloading of spellfiles fails!
-- See the comment in the filesystem_browsing.lua file in the Oil plugin section.
vim.fn.mkdir(vim.fn.stdpath("data") .. "site/spell", "p")
vim.opt.spell = false
vim.opt.spelllang = { "en_us", "pl" }
