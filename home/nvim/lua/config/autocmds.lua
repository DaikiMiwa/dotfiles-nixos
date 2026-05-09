local function augroup(name)
	return vim.api.nvim_create_augroup("my." .. name, { clear = true })
end

vim.api.nvim_create_autocmd("TextYankPost", {
	group = augroup("highlight_yank"),
	callback = function()
		vim.highlight.on_yank({ timeout = 200 })
	end,
})

vim.api.nvim_create_autocmd("BufReadPost", {
	group = augroup("restore_cursor"),
	callback = function(event)
		local exclude = { gitcommit = true }
		if exclude[vim.bo[event.buf].filetype] then
			return
		end

		local mark = vim.api.nvim_buf_get_mark(event.buf, '"')
		local line_count = vim.api.nvim_buf_line_count(event.buf)
		if mark[1] > 0 and mark[1] <= line_count then
			pcall(vim.api.nvim_win_set_cursor, 0, mark)
		end
	end,
})

vim.api.nvim_create_autocmd({ "FocusGained", "TermClose", "TermLeave" }, {
	group = augroup("checktime"),
	command = "checktime",
})

vim.api.nvim_create_autocmd("VimResized", {
	group = augroup("resize_splits"),
	command = "tabdo wincmd =",
})

vim.api.nvim_create_autocmd("FileType", {
	group = augroup("close_with_q"),
	pattern = {
		"checkhealth",
		"help",
		"lspinfo",
		"man",
		"qf",
		"query",
		"startuptime",
	},
	callback = function(event)
		vim.keymap.set("n", "q", "<cmd>close<cr>", { buffer = event.buf, desc = "Close window" })
	end,
})

vim.api.nvim_create_autocmd("BufWritePre", {
	group = augroup("mkdir_before_write"),
	callback = function(event)
		if event.match:match("^%w%w+://") then
			return
		end

		local dir = vim.fn.fnamemodify(event.match, ":p:h")
		if dir ~= "" and vim.fn.isdirectory(dir) == 0 then
			vim.fn.mkdir(dir, "p")
		end
	end,
})
