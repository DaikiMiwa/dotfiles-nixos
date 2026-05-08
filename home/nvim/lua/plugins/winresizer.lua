return {
	"simeji/winresizer",
	cmd = {
		"WinResizerStartFocus",
		"WinResizerStartMove",
		"WinResizerStartResize",
	},
	keys = {
		{
			"<C-e>",
			"<cmd>WinResizerStartResize<cr>",
			desc = "Start window resize",
		},
	},
}
