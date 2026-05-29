local wezterm = require 'wezterm'
local act = wezterm.action

local is_windows = wezterm.target_triple:find('windows') ~= nil
local is_mac = wezterm.target_triple:find('apple') ~= nil

-- doom-one palette
local C = {
  bg0     = '#1c1f24',
  bg1     = '#21242b',
  bg2     = '#282c34',
  bg3     = '#32363e',
  bg4     = '#3f444a',
  fg      = '#bbc2cf',
  grey    = '#5b6268',
  red     = '#ff6c6b',
  orange  = '#da8548',
  green   = '#98be65',
  teal    = '#4db5bd',
  yellow  = '#ecbe7b',
  blue    = '#51afef',
  violet  = '#a9a1e1',
  magenta = '#c678dd',
  cyan    = '#46d9ff',
  white   = '#abb2bf',
}

-- ─── Tab title ─────────────────────────────────────────────────────────────

wezterm.on('format-tab-title', function(tab, _tabs, _panes, _config, _hover, max_width)
  local title = tab.tab_title ~= '' and tab.tab_title or tab.active_pane.title
  local index = tab.tab_index + 1

  -- Trim long process paths to just the basename
  title = title:gsub('.*[/\\]', '')
  local max_title = max_width - 6
  if #title > max_title then
    title = wezterm.truncate_right(title, max_title) .. '…'
  end

  local sep_r = ''  -- requires Nerd Font / powerline font
  local prefix = tab.is_active and '' or ''

  if tab.is_active then
    return {
      { Background = { Color = C.bg2 } },
      { Foreground = { Color = C.bg1 } },
      { Text = sep_r },
      { Background = { Color = C.bg2 } },
      { Foreground = { Color = C.blue } },
      { Attribute = { Intensity = 'Bold' } },
      { Text = string.format(' %s %d: %s ', prefix, index, title) },
      { Background = { Color = C.bg1 } },
      { Foreground = { Color = C.bg2 } },
      { Text = sep_r },
    }
  else
    return {
      { Background = { Color = C.bg1 } },
      { Foreground = { Color = C.grey } },
      { Text = string.format('  %d: %s  ', index, title) },
    }
  end
end)

-- ─── Status bar ────────────────────────────────────────────────────────────

wezterm.on('update-right-status', function(window, _pane)
  local sep_l = ''  -- requires Nerd Font / powerline font

  local mode = window:active_key_table()
  local mode_str = mode and (' ⌨ ' .. mode:upper() .. ' ') or ''
  local hostname = wezterm.hostname():match('^[^.]+')  -- strip domain
  local time = wezterm.strftime('%H:%M')

  local segments = {}

  if mode_str ~= '' then
    table.insert(segments, { fg = C.bg1, bg = C.yellow, text = mode_str })
  end
  table.insert(segments, { fg = C.bg1, bg = C.blue,   text = '  ' .. hostname .. ' ' })
  table.insert(segments, { fg = C.grey, bg = C.bg3,   text = '  ' .. time .. ' ' })

  local pieces = {}
  for i, seg in ipairs(segments) do
    local prev_bg = i > 1 and segments[i - 1].bg or C.bg1
    table.insert(pieces, { Background = { Color = seg.bg } })
    table.insert(pieces, { Foreground = { Color = prev_bg } })
    table.insert(pieces, { Text = sep_l })
    table.insert(pieces, { Foreground = { Color = seg.fg } })
    table.insert(pieces, { Text = seg.text })
  end

  window:set_right_status(wezterm.format(pieces))
end)

-- ─── Key bindings ──────────────────────────────────────────────────────────

local keys = {
  -- Tab navigation (mirrors Emacs C-left / C-right)
  { key = 'LeftArrow',  mods = 'CTRL',       action = act.ActivateTabRelative(-1) },
  { key = 'RightArrow', mods = 'CTRL',       action = act.ActivateTabRelative(1) },

  -- Tab management
  { key = 't', mods = 'CTRL|SHIFT', action = act.SpawnTab('CurrentPaneDomain') },
  { key = 'w', mods = 'CTRL|SHIFT', action = act.CloseCurrentTab({ confirm = true }) },
  { key = 'n', mods = 'CTRL|SHIFT', action = act.PromptInputLine({
    description = 'Rename tab:',
    action = wezterm.action_callback(function(window, _pane, line)
      if line and #line > 0 then window:active_tab():set_title(line) end
    end),
  })},

  -- Direct tab jump (like SPC t 1-9)
  { key = '1', mods = 'CTRL|SHIFT', action = act.ActivateTab(0) },
  { key = '2', mods = 'CTRL|SHIFT', action = act.ActivateTab(1) },
  { key = '3', mods = 'CTRL|SHIFT', action = act.ActivateTab(2) },
  { key = '4', mods = 'CTRL|SHIFT', action = act.ActivateTab(3) },
  { key = '5', mods = 'CTRL|SHIFT', action = act.ActivateTab(4) },
  { key = '6', mods = 'CTRL|SHIFT', action = act.ActivateTab(5) },
  { key = '7', mods = 'CTRL|SHIFT', action = act.ActivateTab(6) },
  { key = '8', mods = 'CTRL|SHIFT', action = act.ActivateTab(7) },
  { key = '9', mods = 'CTRL|SHIFT', action = act.ActivateTab(8) },

  -- Pane splitting (mirrors Emacs SPC w v / SPC w s)
  { key = '\\', mods = 'CTRL|SHIFT', action = act.SplitHorizontal({ domain = 'CurrentPaneDomain' }) },
  { key = '-',  mods = 'CTRL|SHIFT', action = act.SplitVertical({ domain = 'CurrentPaneDomain' }) },

  -- Pane navigation (mirrors Emacs C-h/j/k/l)
  { key = 'h', mods = 'CTRL|SHIFT', action = act.ActivatePaneDirection('Left') },
  { key = 'j', mods = 'CTRL|SHIFT', action = act.ActivatePaneDirection('Down') },
  { key = 'k', mods = 'CTRL|SHIFT', action = act.ActivatePaneDirection('Up') },
  { key = 'l', mods = 'CTRL|SHIFT', action = act.ActivatePaneDirection('Right') },

  -- Pane resize
  { key = 'H', mods = 'CTRL|SHIFT', action = act.AdjustPaneSize({ 'Left',  5 }) },
  { key = 'J', mods = 'CTRL|SHIFT', action = act.AdjustPaneSize({ 'Down',  5 }) },
  { key = 'K', mods = 'CTRL|SHIFT', action = act.AdjustPaneSize({ 'Up',    5 }) },
  { key = 'L', mods = 'CTRL|SHIFT', action = act.AdjustPaneSize({ 'Right', 5 }) },

  -- Zoom pane (mirrors Emacs SPC w m m)
  { key = 'z', mods = 'CTRL|SHIFT', action = act.TogglePaneZoomState },

  -- Close pane (mirrors Emacs SPC w d)
  { key = 'x', mods = 'CTRL|SHIFT', action = act.CloseCurrentPane({ confirm = true }) },

  -- Copy mode — vi/evil bindings apply inside (see key_tables below)
  { key = '[', mods = 'CTRL|SHIFT', action = act.ActivateCopyMode },

  -- Search
  { key = 'f', mods = 'CTRL|SHIFT', action = act.Search('CurrentSelectionOrEmptyString') },

  -- Scrollback
  { key = 'PageUp',   mods = 'SHIFT', action = act.ScrollByPage(-1) },
  { key = 'PageDown', mods = 'SHIFT', action = act.ScrollByPage(1) },
  { key = 'k', mods = 'ALT', action = act.ScrollByLine(-3) },
  { key = 'j', mods = 'ALT', action = act.ScrollByLine(3) },

  -- Font size
  { key = '=', mods = 'CTRL', action = act.IncreaseFontSize },
  { key = '-', mods = 'CTRL', action = act.DecreaseFontSize },
  { key = '0', mods = 'CTRL', action = act.ResetFontSize },

  -- Meta
  { key = 'r', mods = 'CTRL|SHIFT', action = act.ReloadConfiguration },
  { key = 'p', mods = 'CTRL|SHIFT', action = act.ActivateCommandPalette },
}

-- macOS: add CMD-based aliases that feel native
if is_mac then
  local mac_keys = {
    { key = 't', mods = 'CMD',       action = act.SpawnTab('CurrentPaneDomain') },
    { key = 'w', mods = 'CMD',       action = act.CloseCurrentTab({ confirm = true }) },
    { key = 'n', mods = 'CMD',       action = act.SpawnWindow },
    { key = '[', mods = 'CMD',       action = act.ActivateTabRelative(-1) },
    { key = ']', mods = 'CMD',       action = act.ActivateTabRelative(1) },
    { key = 'z', mods = 'CMD|SHIFT', action = act.TogglePaneZoomState },
  }
  for i = 1, 9 do
    table.insert(mac_keys, { key = tostring(i), mods = 'CMD', action = act.ActivateTab(i - 1) })
  end
  for _, k in ipairs(mac_keys) do table.insert(keys, k) end
end

-- ─── Copy mode (vi / evil-style) ───────────────────────────────────────────

local copy_mode = {
  { key = 'q',         mods = 'NONE', action = act.CopyMode('Close') },
  { key = 'Escape',    mods = 'NONE', action = act.CopyMode('Close') },
  { key = 'h',         mods = 'NONE', action = act.CopyMode('MoveLeft') },
  { key = 'j',         mods = 'NONE', action = act.CopyMode('MoveDown') },
  { key = 'k',         mods = 'NONE', action = act.CopyMode('MoveUp') },
  { key = 'l',         mods = 'NONE', action = act.CopyMode('MoveRight') },
  { key = 'w',         mods = 'NONE', action = act.CopyMode('MoveForwardWord') },
  { key = 'e',         mods = 'NONE', action = act.CopyMode('MoveForwardWordEnd') },
  { key = 'b',         mods = 'NONE', action = act.CopyMode('MoveBackwardWord') },
  { key = '0',         mods = 'NONE', action = act.CopyMode('MoveToStartOfLine') },
  { key = '$',         mods = 'NONE', action = act.CopyMode('MoveToEndOfLineContent') },
  { key = 'g',         mods = 'NONE', action = act.CopyMode('MoveToScrollbackTop') },
  { key = 'G',         mods = 'NONE', action = act.CopyMode('MoveToScrollbackBottom') },
  { key = 'f',         mods = 'CTRL', action = act.CopyMode('PageDown') },
  { key = 'b',         mods = 'CTRL', action = act.CopyMode('PageUp') },
  { key = 'v',         mods = 'NONE', action = act.CopyMode({ SetSelectionMode = 'Cell' }) },
  { key = 'V',         mods = 'NONE', action = act.CopyMode({ SetSelectionMode = 'Line' }) },
  { key = 'v',         mods = 'CTRL', action = act.CopyMode({ SetSelectionMode = 'Block' }) },
  { key = 'y',         mods = 'NONE', action = act.Multiple({
    act.CopyTo('ClipboardAndPrimarySelection'),
    act.CopyMode('Close'),
  })},
}

-- ─── Config ────────────────────────────────────────────────────────────────

local font_size = is_mac and 14.0 or 12.0

-- Lucida Console is Windows-only; omit it on other platforms to avoid load warnings
local font_families = {}
if is_windows then
  table.insert(font_families, { family = 'Lucida Console', weight = 'Regular' })
end
table.insert(font_families, { family = 'JetBrainsMono Nerd Font', weight = 'Regular' })
table.insert(font_families, { family = 'JetBrains Mono',          weight = 'Regular' })
table.insert(font_families, { family = 'Fira Code',               weight = 'Regular' })
table.insert(font_families, 'Symbols Nerd Font Mono')

local font_families_italic = {}
if is_windows then
  table.insert(font_families_italic, { family = 'Lucida Console', style = 'Italic' })
end
table.insert(font_families_italic, { family = 'JetBrainsMono Nerd Font', style = 'Italic' })
table.insert(font_families_italic, { family = 'JetBrains Mono',          style = 'Italic' })

local config = {
  -- Renderer: WebGpu is the modern default; falls back gracefully
  front_end = 'WebGpu',

  font = wezterm.font_with_fallback(font_families),
  font_size = font_size,
  line_height = 1.2,
  -- Match Emacs: italicise comments/keywords by allowing italic rendering
  font_rules = {
    {
      italic = true,
      font = wezterm.font_with_fallback(font_families_italic),
    },
  },

  -- Colors
  colors = {
    foreground    = C.fg,
    background    = C.bg2,
    cursor_bg     = C.blue,
    cursor_border = C.blue,
    cursor_fg     = C.bg2,
    selection_fg  = C.bg2,
    selection_bg  = C.blue,

    ansi = {
      C.bg0,    -- black
      C.red,    -- red
      C.green,  -- green
      C.yellow, -- yellow
      C.blue,   -- blue
      C.magenta,-- magenta
      C.cyan,   -- cyan
      C.white,  -- white
    },
    brights = {
      C.grey,   -- bright black
      C.orange, -- bright red
      C.teal,   -- bright green
      C.orange, -- bright yellow
      C.blue,   -- bright blue
      C.violet, -- bright magenta
      C.cyan,   -- bright cyan
      C.fg,     -- bright white
    },

    tab_bar = {
      background   = C.bg1,
      active_tab   = { bg_color = C.bg2,  fg_color = C.blue,   intensity = 'Bold' },
      inactive_tab = { bg_color = C.bg1,  fg_color = C.grey },
      inactive_tab_hover = { bg_color = C.bg3, fg_color = C.fg },
      new_tab       = { bg_color = C.bg1, fg_color = C.grey },
      new_tab_hover = { bg_color = C.bg3, fg_color = C.blue },
    },
  },

  -- Window
  window_decorations = is_mac and 'INTEGRATED_BUTTONS|RESIZE' or 'TITLE|RESIZE',
  window_padding = { left = 12, right = 12, top = 8, bottom = 8 },
  window_background_opacity = 0.96,
  macos_window_background_blur = 20,
  adjust_window_size_when_changing_font_size = false,
  initial_cols = 220,
  initial_rows = 50,

  -- Tab bar
  enable_tab_bar            = true,
  use_fancy_tab_bar         = false,
  tab_bar_at_bottom         = false,
  show_tab_index_in_tab_bar = false,
  tab_max_width             = 36,
  show_new_tab_button_in_tab_bar = true,

  -- Cursor — blinking bar matches Emacs bar cursor
  default_cursor_style    = 'BlinkingBar',
  cursor_blink_ease_in    = 'Constant',
  cursor_blink_ease_out   = 'Constant',
  cursor_blink_rate       = 500,

  -- Bell — visual flash on cursor like Emacs visual-bell
  audible_bell = 'Disabled',
  visual_bell = {
    fade_in_function  = 'EaseIn',
    fade_in_duration_ms  = 80,
    fade_out_function = 'EaseOut',
    fade_out_duration_ms = 80,
    target = 'CursorColor',
  },

  -- Scrollback
  scrollback_lines = 10000,
  enable_scroll_bar = false,

  -- Mouse
  hide_mouse_cursor_when_typing = true,

  -- Hyperlinks
  hyperlink_rules = wezterm.default_hyperlink_rules(),

  -- Keys
  disable_default_key_bindings = false,
  keys = keys,
  key_tables = { copy_mode = copy_mode },
}

-- Windows: prefer pwsh > powershell
if is_windows then
  local pwsh = wezterm.which('pwsh.exe')
  config.default_prog = pwsh and { 'pwsh.exe', '-NoLogo' } or { 'powershell.exe', '-NoLogo' }
end

return config
