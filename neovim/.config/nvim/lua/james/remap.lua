--[[
    This file contains key mappings for Neovim using Lua.
    
    Key Mappings:
    - <leader>pv: Opens the Ex command-line mode in normal mode.
    - <leader>to: Toggles the terminal in normal mode.
    
    Functions:
    - vim.keymap.set(mode, lhs, rhs, opts): Sets a key mapping in Neovim.
        - mode: The mode in which the key mapping is active (e.g., "n" for normal mode).
        - lhs: The left-hand side of the key mapping (the key combination).
        - rhs: The right-hand side of the key mapping (the command to execute).
        - opts: Optional parameters for the key mapping.
]]

-- Map <leader>pv to open the Ex command-line mode in normal mode
vim.keymap.set("n", "<leader>pv", vim.cmd.Ex)

-- Map <leader>to to toggle the terminal in normal mode
vim.keymap.set("n", "<leader>to", vim.cmd.ToggleTerm)

-- Map <leader>pv to open the Ex command-line mode in normal mode
vim.keymap.set("n", "<leader>pv", vim.cmd.Ex)

-- Terminal Maps
-- Map <leader>to to toggle the terminal in normal mode
vim.keymap.set("n", "<leader>to", vim.cmd.ToggleTerm)

-- Copilot Maps
-- Map <leader>Cod to generate docs from copilot
vim.keymap.set("n", "<leader>Cod", vim.cmd.CopilotChatDocs)

-- Copilot Explain Section
vim.keymap.set("n", "<leader>Coe", vim.cmd.CopilotChatDocs)

-- Copilot Chat Commit
vim.keymap.set("n", "<leader>Coc", vim.cmd.CopilotChatCommitStaged)
