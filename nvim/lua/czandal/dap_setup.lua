local dap = require("dap")

-- Adapter setup for CodeLLDB executable
dap.adapters.codelldb = {
  type = "server",
  port = "${port}",
  executable = {
    command = "codelldb", -- installed by Mason (see lazy/lsp.lua)
    args = { "--port", "${port}" },
  },
}

-- Example launch configuration for Zig or C/C++ programs
dap.configurations.zig = {
  {
    name = "Launch",
    type = "codelldb",
    request = "launch",
    program = function()
      return vim.fn.input("Path to executable: ", vim.fn.getcwd() .. "/zig-out/bin/", "file")
    end,
    cwd = "${workspaceFolder}",
    stopOnEntry = false,
    args = {},
  },
}

local dapui = require('dapui');
dapui.setup()
