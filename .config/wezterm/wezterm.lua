local wezterm = require 'wezterm'

return {
  -- Appearance
  color_scheme = 'Modus-Vivendi',
  font = wezterm.font 'Iosevka',
  font_size = 16,
  enable_scroll_bar = true,
  enable_tab_bar = false,
  cursor_blink_rate = 400,
  default_cursor_style = "BlinkingBlock",
  cursor_blink_ease_in = "EaseOut",
  cursor_blink_ease_out = "Constant",

  -- Contents
  scrollback_lines = 100000,

  -- Links
  hyperlink_rules = (function()
      local rules = wezterm.default_hyperlink_rules()
      table.insert(rules, {
                     -- Case-insensitive JIRA issue keys with -, space, or _ as separators
                     regex = [[\b([A-Za-z]{2,5})[-_ ](\d+)]],
                     -- Jira accepts wrong case, but needs a dash
                     format = 'https://goproinc.atlassian.net/browse/$1-$2',
      })
      return rules
  end)(),

  -- Input
  keys = {
    -- Keep readline undo
    { key = "mapped:_", mods = "SHIFT|CTRL", action = wezterm.action.DisableDefaultAssignment },
  },
  use_ime = true,
  alternate_buffer_wheel_scroll_speed = 1,

  -- Window manager
  tiling_desktop_environments = {
  'X11 xmonad',
  },

}
