vim.opt.number = true
vim.opt.expandtab = true -- タブをスペースに変換
vim.opt.shiftwidth = 2 -- インデント幅
vim.opt.tabstop = 2 -- タブ幅
vim.opt.softtabstop = 2 -- 編集時のタブ幅

vim.filetype.add({
	extension = {
		astro = "astro",
	},
})

-- HTML, CSS, JS などをまとめて設定
vim.api.nvim_create_autocmd("FileType", {
	pattern = {
		"astro",
		"css",
		"html",
		"javascript",
		"javascriptreact",
		"lua",
		"markdown",
		"mdx",
		"typescript",
		"typescriptreact",
	},
	callback = function()
		vim.opt_local.expandtab = true
		vim.opt_local.shiftwidth = 2
		vim.opt_local.tabstop = 2
		vim.opt_local.softtabstop = 2
	end,
})

-- Python
vim.api.nvim_create_autocmd("FileType", {
	pattern = { "python" },
	callback = function()
		vim.opt_local.expandtab = true
		vim.opt_local.shiftwidth = 4
		vim.opt_local.tabstop = 4
		vim.opt_local.softtabstop = 4
	end,
})

vim.keymap.set(
	"n",
	"?",
	"<cmd>silent vimgrep//gj%|copen<cr>",
	{ desc = "Populate latest search result to quickfix list" }
)

local function executable(command)
	return vim.fn.executable(command) == 1
end

local function set_clipboard(name, copy_command, paste_command)
	vim.g.clipboard = {
		name = name,
		copy = {
			["+"] = copy_command,
			["*"] = copy_command,
		},
		paste = {
			["+"] = paste_command,
			["*"] = paste_command,
		},
		cache_enabled = 0,
	}
end

local wsl_clip = "/mnt/c/Windows/System32/clip.exe"
local wsl_powershell = "/mnt/c/Windows/System32/WindowsPowerShell/v1.0/powershell.exe"

if executable(wsl_clip) and executable(wsl_powershell) then
	set_clipboard(
		"wsl-clipboard",
		wsl_clip,
		wsl_powershell .. ' -NoLogo -NoProfile -Command "[Console]::Out.Write((Get-Clipboard -Raw))"'
	)
elseif executable("pbcopy") and executable("pbpaste") then
	set_clipboard("macos-clipboard", "pbcopy", "pbpaste")
elseif executable("wl-copy") and executable("wl-paste") then
	set_clipboard("wayland-clipboard", "wl-copy", "wl-paste --no-newline")
elseif executable("xclip") then
	set_clipboard("xclip-clipboard", "xclip -selection clipboard", "xclip -selection clipboard -o")
elseif executable("xsel") then
	set_clipboard("xsel-clipboard", "xsel --clipboard --input", "xsel --clipboard --output")
end

vim.keymap.set("n", "<leader>y", '"+y', { desc = "Yank to system clipboard" })
vim.keymap.set("v", "<leader>y", '"+y', { desc = "Yank to system clipboard" })
vim.keymap.set("n", "<leader>Y", '"+Y', { desc = "Yank line to system clipboard" })

local english_dictionary_candidates = {
	vim.fn.expand("~/.nix-profile/share/dict/wamerican.txt"),
	"/run/current-system/sw/share/dict/wamerican.txt",
}

for _, dictionary in ipairs(english_dictionary_candidates) do
	if vim.fn.filereadable(dictionary) == 1 then
		vim.opt.dictionary:append(dictionary)
		break
	end
end

vim.keymap.set("i", "<C-k>", "<C-x><C-k>", { desc = "Complete from English dictionary" })
