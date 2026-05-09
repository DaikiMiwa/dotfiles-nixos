local function map(mode, lhs, rhs, desc, opts)
	opts = opts or {}
	opts.desc = desc
	vim.keymap.set(mode, lhs, rhs, opts)
end

local function toggle_option(name)
	vim.opt_local[name] = not vim.opt_local[name]:get()
	vim.notify(name .. ": " .. tostring(vim.opt_local[name]:get()))
end

local function run_list_command(command, fallback_message)
	local ok = pcall(vim.cmd, command)
	if not ok then
		vim.notify(fallback_message, vim.log.levels.WARN)
	end
end

map("n", "<Esc>", "<cmd>nohlsearch<cr>", "Clear search highlight")
map("n", "<leader>w", "<cmd>write<cr>", "Write file")
map("n", "<leader>q", "<cmd>quit<cr>", "Quit window")

map("n", "<C-h>", "<C-w>h", "Focus left window")
map("n", "<C-j>", "<C-w>j", "Focus lower window")
map("n", "<C-k>", "<C-w>k", "Focus upper window")
map("n", "<C-l>", "<C-w>l", "Focus right window")

map("n", "]q", function()
	run_list_command("cnext", "No next quickfix item")
end, "Next quickfix item")
map("n", "[q", function()
	run_list_command("cprevious", "No previous quickfix item")
end, "Previous quickfix item")
map("n", "]l", function()
	run_list_command("lnext", "No next location item")
end, "Next location item")
map("n", "[l", function()
	run_list_command("lprevious", "No previous location item")
end, "Previous location item")

map("n", "<leader>uw", function()
	toggle_option("wrap")
end, "Toggle wrap")
map("n", "<leader>us", function()
	toggle_option("spell")
end, "Toggle spell")
map("n", "<leader>ul", function()
	toggle_option("list")
end, "Toggle whitespace")
map("n", "<leader>ur", function()
	toggle_option("relativenumber")
end, "Toggle relative number")

map("t", "<Esc><Esc>", "<C-\\><C-n>", "Exit terminal mode")
