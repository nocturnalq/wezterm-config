-- Pull in the wezterm API
local wezterm = require 'wezterm'

-- This table will hold the configuration.
local config = {}

-- In newer versions of wezterm, use the config_builder which will
-- help provide clearer error messages
if wezterm.config_builder then
  config = wezterm.config_builder()
end

-- This is where you actually apply your config choices

-- For example, changing the color scheme:
config.color_scheme = 'Gruvbox Dark (Gogh)'
config.font = wezterm.font('Monaco', { weight = 'Bold' })
config.font_size = 14
config.hide_tab_bar_if_only_one_tab = true
config.window_background_opacity = 1.0
config.window_close_confirmation = 'NeverPrompt'
-- for using command key as leader key in neovim
local function is_vim(pane)
	local is_vim_env = pane:get_user_vars().IS_NVIM == 'true'
	if is_vim_env == true then return true end
	-- This gsub is equivalent to POSIX basename(3)
	-- Given "/foo/bar" returns "bar"
	-- Given "c:\\foo\\bar" returns "bar"
	local process_name = string.gsub(pane:get_foreground_process_name(), '(.*[/\\])(.*)', '%2')
	return process_name == 'nvim' or process_name == 'vim'
end

--- cmd+keys that we want to send to neovim.
local super_vim_keys_map = {
    -- Command + s: saving file
	s = utf8.char(0xAA),
    -- Command + e: scroll downwords (ctrl + e analog)
	e = utf8.char(0xAB),
    -- Command + y: scroll upwords (ctrl + y analog)
	y = utf8.char(0xAC),
    -- Command + h: go to prev tab
	h = utf8.char(0xAD),
    -- Command + l: go to next tab
	l = utf8.char(0xAE),
    -- Command + w: close current tab
	w = utf8.char(0xAF),
    -- Command + t: find file toogle (NvimTree)
	t = utf8.char(0xA1),

    -- Command + [: open trouble window
	['['] = utf8.char(0xA2),
    -- Command + ]: close trouble window 
	[']'] = utf8.char(0xA3),

    -- Command + n: copilot last
	n = utf8.char(0xA4),
    -- Command + m: copilot next 
	m = utf8.char(0xA5),

    -- Command + 1: open left bar like jb IDE
	-- ['1'] = utf8.char(0xA6)
}

local function bind_super_key_to_vim(key)
	return {
		key = key,
		mods = 'CMD',
		action = wezterm.action_callback(function(win, pane)
			local char = super_vim_keys_map[key]
			if char and is_vim(pane) then
				-- pass the keys through to vim/nvim
				win:perform_action({
					SendKey = { key = char, mods = nil },
				}, pane)
			else
				win:perform_action({
					SendKey = {
						key = key,
						mods = 'CMD'
					}
				}, pane)
			end
		end)
	}
end

local act = wezterm.action
local keys = {
   -- display tab navigator
  {
    key = 't',
    mods = 'CMD|SHIFT',
    action = act.ShowTabNavigator,
  },

  -- enable rename tab
  {
    key = 'R',
    mods = 'CMD|SHIFT',
    action = act.PromptInputLine {
      description = 'Enter new name for tab',
      action = wezterm.action_callback(function(window, _, line)
        -- line will be `nil` if they hit escape without entering anything
        -- An empty string if they just hit enter
        -- Or the actual line of text they wrote
        if line then
          window:active_tab():set_title(line)
        end
      end),
    },
  },

  -- open wezterm config quicly
  {
    key = ',',
    mods = 'CMD',
    action = act.SpawnCommandInNewTab {
      cwd = os.getenv('WEZTERM_CONFIG_DIR'),
      set_environment_variables = {
        TERM = 'screen-256color',
      },
      args = {
        '/usr/local/bin/nvim',
        os.getenv('WEZTERM_CONFIG_FILE'),
      },
    },
  },

  -- split vertically
  {
    key = 'v',
    mods = 'SHIFT|CMD|OPT',
    action = wezterm.action.SplitHorizontal { domain = 'CurrentPaneDomain' },
  },

  -- split horizontally
  {
    key = 'h',
    mods = 'SHIFT|CMD|OPT',
    action = wezterm.action.SplitVertical {},
  },

    -- Make Option-Left equivalent to Alt-b which many line editors interpret as backward-word
    {
		key="LeftArrow",
		mods="CMD",
		action=wezterm.action{SendString="\x1bb"},
	},
    -- Make Option-Right equivalent to Alt-f; forward-word
    {
		key="RightArrow",
		mods="CMD",
		action=wezterm.action{SendString="\x1bf"},
	},

    bind_super_key_to_vim('s'),
    bind_super_key_to_vim('h'),
    bind_super_key_to_vim('l'),
    bind_super_key_to_vim('w'),
    bind_super_key_to_vim('e'),
    bind_super_key_to_vim('y'),
    bind_super_key_to_vim('t'),
    bind_super_key_to_vim('['),
    bind_super_key_to_vim(']'),
    bind_super_key_to_vim('n'),
    bind_super_key_to_vim('m')
}
config.keys = keys


-- and finally, return the configuration to wezterm
return config


