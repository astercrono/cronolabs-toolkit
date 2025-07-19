return {
	"linux-cultist/venv-selector.nvim",
	dependencies = { "neovim/nvim-lspconfig", "nvim-telescope/telescope.nvim", "mfussenegger/nvim-dap-python" },
	opts = {
		-- your options go here
		-- name = "venv",
		-- auto_refresh = false
		name = { ".venv", "venv" },
		dap_enabled = true,
	},
	keys = {
		-- keymap to open venvselector to pick a venv.
		{ "<leader>vs", "<cmd>venvselect<cr>" },
		-- keymap to retrieve the venv from a cache (the one previously used for the same project directory).
		{ "<leader>vc", "<cmd>venvselectcached<cr>" },
	},
}
