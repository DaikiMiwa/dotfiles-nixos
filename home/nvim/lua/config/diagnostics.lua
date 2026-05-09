local virtual_lines_config = {
	current_line = true,
}

vim.diagnostic.config({
	float = {
		border = "single",
		source = "if_many",
	},
	severity_sort = true,
	underline = true,
	update_in_insert = false,
	virtual_lines = virtual_lines_config,
	virtual_text = false,
})

local function jump(count)
	vim.diagnostic.jump({ count = count, float = true })
end

vim.keymap.set("n", "]d", function()
	jump(1)
end, { desc = "Next diagnostic" })

vim.keymap.set("n", "[d", function()
	jump(-1)
end, { desc = "Previous diagnostic" })

vim.keymap.set("n", "<leader>xd", vim.diagnostic.open_float, { desc = "Line diagnostic" })

vim.keymap.set("n", "<leader>xq", function()
	vim.diagnostic.setqflist({ open = true })
end, { desc = "Diagnostics to quickfix" })

vim.keymap.set("n", "<leader>uv", function()
	local current = vim.diagnostic.config().virtual_lines
	local next_value = current and false or virtual_lines_config
	vim.diagnostic.config({ virtual_lines = next_value })
	vim.notify("diagnostic virtual_lines: " .. tostring(next_value ~= false))
end, { desc = "Toggle diagnostic virtual lines" })
