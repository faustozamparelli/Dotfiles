local wezterm = require("wezterm")
local keybindings = {
	{
		key = "1",
		mods = "CMD",
		action = wezterm.action({ SendString = "\x13\x31" }),
	},
	{
		key = "2",
		mods = "CMD",
		action = wezterm.action({ SendString = "\x13\x32" }),
	},
	{
		key = "3",
		mods = "CMD",
		action = wezterm.action({ SendString = "\x13\x33" }),
	},
	{
		key = "4",
		mods = "CMD",
		action = wezterm.action({ SendString = "\x13\x34" }),
	},
	{
		key = "5",
		mods = "CMD",
		action = wezterm.action({ SendString = "\x13\x35" }),
	},
	{
		key = "6",
		mods = "CMD",
		action = wezterm.action({ SendString = "\x13\x36" }),
	},
	{
		key = "7",
		mods = "CMD",
		action = wezterm.action({ SendString = "\x13\x37" }),
	},
	{
		key = "8",
		mods = "CMD",
		action = wezterm.action({ SendString = "\x13\x38" }),
	},
	{
		key = "9",
		mods = "CMD",
		action = wezterm.action({ SendString = "\x13\x39" }),
	},
	{
		key = "l",
		mods = "CMD",
		action = wezterm.action({ SendString = "\x13\x6e" }),
	},
	{
		key = "h",
		mods = "CMD",
		action = wezterm.action({ SendString = "\x13\x70" }),
	},
	{
		key = "h",
		mods = "CMD|SHIFT",
		action = wezterm.action({ SendString = "\x13\x7b" }),
	},
	{
		key = "l",
		mods = "CMD|SHIFT",
		action = wezterm.action({ SendString = "\x13\x7d" }),
	},
	{
		key = "b",
		mods = "CMD",
		action = wezterm.action({ SendString = "\x13\x62" }),
	},
	{
		key = "e",
		mods = "CMD",
		action = wezterm.action({ SendString = "\x13\x77" }),
	},
	{
		key = "h",
		mods = "OPT",
		action = wezterm.action({ SendString = "\x13\x68" }),
	},
	{
		key = "j",
		mods = "OPT",
		action = wezterm.action({ SendString = "\x13\x6a" }),
	},
	{
		key = "k",
		mods = "OPT",
		action = wezterm.action({ SendString = "\x13\x6b" }),
	},
	{
		key = "l",
		mods = "OPT",
		action = wezterm.action({ SendString = "\x13\x6c" }),
	},
	{
		key = "H",
		mods = "OPT",
		action = wezterm.action({ SendString = "\x13\x1b\x5b\x44" }),
	},
	{
		key = "J",
		mods = "OPT",
		action = wezterm.action({ SendString = "\x13\x1b\x5b\x42" }),
	},
	{
		key = "K",
		mods = "OPT",
		action = wezterm.action({ SendString = "\x13\x1b\x5b\x41" }),
	},
	{
		key = "L",
		mods = "OPT",
		action = wezterm.action({ SendString = "\x13\x1b\x5b\x43" }),
	},
	--  {
	--      key = 'H',
	--      mods = 'CMD|OPT|CTRL',
	--      action = wezterm.action{SendString = "\x1b\x5b\x44"},
	--  },
	--  {
	--      key = 'J',
	--      mods = 'CMD|OPT|CTRL',
	--      action = wezterm.action{SendString = "\x13\x5b\x42"},
	--  },
	--  {
	--      key = 'K',
	--      mods = 'CMD|OPT|CTRL',
	--      action = wezterm.action{SendString = "\x13\x5b\x42"},
	--  },
	--  {
	--      key = 'L',
	--      mods = 'CMD|OPT|CTRL',
	--      action = wezterm.action{SendString = "\x13\x5b\x43"},
	--  },
	{
		key = "n",
		mods = "CMD",
		action = wezterm.action({ SendString = "\x13\x76" }),
	},
	{
		key = "r",
		mods = "CMD",
		action = wezterm.action({ SendString = "\x13\x2c" }),
	},
	{
		key = "s",
		mods = "CMD",
		action = wezterm.action({ SendString = "\x13\x73" }),
	},
	{
		key = "t",
		mods = "CMD",
		action = wezterm.action({ SendString = "\x13\x63" }),
	},
	{
		key = "w",
		mods = "CMD",
		action = wezterm.action({ SendString = "\x13\x78" }),
	},
	{
		key = "q",
		mods = "CMD",
		action = wezterm.action({ SendString = "\x13\x77" }),
	},
	{
		key = "c",
		mods = "CMD",
		action = wezterm.action({ CopyTo = "Clipboard" }),
	},
	{
		key = "v",
		mods = "CMD",
		action = wezterm.action({ PasteFrom = "Clipboard" }),
	},
	{
		key = "f",
		mods = "CMD",
		action = wezterm.action({ SendString = "\x1b\x66" }),
	},
	{
		key = "d",
		mods = "CMD",
		action = wezterm.action({ SendString = "\x1b\x64" }),
	},
}

return keybindings
