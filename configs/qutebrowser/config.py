# qutebrowser config — cachyOS-setup (primary browser, Super+b)
# Installed by setup.sh step 5 to ~/.config/qutebrowser/config.py.
# IMPORTANT: autoconfig.yml (settings made via :set inside qutebrowser) is
# only loaded because of the config.load_autoconfig() call below. Without it,
# everything in autoconfig.yml (dark scheme, :aliases) would be ignored.
# Refresh this dir from the live install any time:
#   bash scripts/export-browser-configs.sh

config.load_autoconfig()

# Dark pages to match the monochrome setup (see autoconfig.yml:
# colors.webpage.preferred_color_scheme = dark).
c.colors.webpage.darkmode.enabled = True
c.colors.webpage.darkmode.policy.images = 'never'

# Adblocking (needs python-adblock, installed by scripts/install.sh).
c.content.blocking.enabled = True
c.content.blocking.method = 'adblock'
# Filter lists beyond the qutebrowser defaults (EasyList + EasyPrivacy):
# annoyances/cookie walls + uBlock Origin's own filters. Refresh with
# `:adblock-update` inside qutebrowser (also auto-refreshed periodically).
# NOTE: no list blocks YouTube *video* ads (served from YouTube's own
# domains) — those are handled by the greasemonkey userscript below
# (configs/qutebrowser/greasemonkey/).
c.content.blocking.adblock.lists = [
    'https://easylist.to/easylist/easylist.txt',
    'https://easylist.to/easylist/easyprivacy.txt',
    'https://secure.fanboy.co.nz/fanboy-annoyance.txt',
    'https://raw.githubusercontent.com/uBlockOrigin/uAssets/master/filters/filters.txt',
]

# External editor = same stack as everywhere else (alacritty + nvim).
c.editor.command = ['alacritty', '-e', 'nvim', '{}']

# Fonts match dwm/alacritty (JetBrainsMono Nerd Font).
c.fonts.default_family = 'JetBrainsMono Nerd Font'
c.fonts.default_size = '10pt'

# Sane session/download defaults.
c.auto_save.session = True
c.confirm_quit = ['multiple-tabs']
c.downloads.location.directory = '~/Downloads'

# --- 1. dark UI theme (monochrome, matches dwm/alacritty/dunst) ---
# Webpage content darkening is the darkmode block above + preferred_color_scheme
# in autoconfig.yml; everything below themes qutebrowser's own chrome.
BG = '#111111'
BG_ALT = '#1a1a1a'
BG_SEL = '#333333'
FG = '#eeeeee'
FG_DIM = '#bbbbbb'
ACCENT = '#777777'  # same gray as the dwm accent
GOOD = '#888888'
WARN = '#cccccc'
BAD = '#ffffff'

c.colors.webpage.bg = BG
c.colors.webpage.preferred_color_scheme = 'dark'  # mirrors autoconfig.yml

# completion popup (:, /, ?)
c.colors.completion.fg = FG_DIM
c.colors.completion.odd.bg = BG
c.colors.completion.even.bg = BG_ALT
c.colors.completion.category.fg = FG
c.colors.completion.category.bg = BG_SEL
c.colors.completion.category.border.top = BG_SEL
c.colors.completion.category.border.bottom = BG_SEL
c.colors.completion.item.selected.fg = FG
c.colors.completion.item.selected.bg = BG_SEL
c.colors.completion.item.selected.border.top = BG_SEL
c.colors.completion.item.selected.border.bottom = BG_SEL
c.colors.completion.item.selected.match.fg = FG
c.colors.completion.match.fg = FG
c.colors.completion.scrollbar.fg = ACCENT
c.colors.completion.scrollbar.bg = BG

# context menu (3.7 group: menu/selected/disabled only — no base bg/fg keys)
c.colors.contextmenu.menu.bg = BG
c.colors.contextmenu.menu.fg = FG_DIM
c.colors.contextmenu.selected.bg = BG_SEL
c.colors.contextmenu.selected.fg = FG
c.colors.contextmenu.disabled.bg = BG
c.colors.contextmenu.disabled.fg = ACCENT

# downloads bar
c.colors.downloads.bar.bg = BG
c.colors.downloads.start.fg = BG
c.colors.downloads.start.bg = ACCENT
c.colors.downloads.stop.fg = BG
c.colors.downloads.stop.bg = GOOD
c.colors.downloads.error.fg = BAD
c.colors.downloads.error.bg = BG

# hints (f-style overlays; no border key in 3.x)
c.colors.hints.fg = BG
c.colors.hints.bg = WARN
c.colors.hints.match.fg = FG_DIM

# keyhint popup
c.colors.keyhint.fg = FG_DIM
c.colors.keyhint.bg = BG
c.colors.keyhint.suffix.fg = FG

# messages (error/warning/info bars)
c.colors.messages.error.fg = FG
c.colors.messages.error.bg = BG_SEL
c.colors.messages.error.border = BAD
c.colors.messages.warning.fg = FG
c.colors.messages.warning.bg = BG_SEL
c.colors.messages.warning.border = WARN
c.colors.messages.info.fg = FG_DIM
c.colors.messages.info.bg = BG
c.colors.messages.info.border = BG_SEL

# prompts (statusbar command line)
c.colors.prompts.fg = FG_DIM
c.colors.prompts.bg = BG
c.colors.prompts.border = BG_SEL
c.colors.prompts.selected.bg = BG_SEL
c.colors.prompts.selected.fg = FG

# statusbar
c.colors.statusbar.normal.fg = FG_DIM
c.colors.statusbar.normal.bg = BG
c.colors.statusbar.insert.fg = BG
c.colors.statusbar.insert.bg = FG_DIM
c.colors.statusbar.passthrough.fg = BG
c.colors.statusbar.passthrough.bg = ACCENT
c.colors.statusbar.private.fg = FG_DIM
c.colors.statusbar.private.bg = BG_ALT
c.colors.statusbar.command.fg = FG
c.colors.statusbar.command.bg = BG
c.colors.statusbar.command.private.fg = FG_DIM
c.colors.statusbar.command.private.bg = BG_ALT
c.colors.statusbar.caret.fg = BG
c.colors.statusbar.caret.bg = WARN
c.colors.statusbar.caret.selection.fg = BG
c.colors.statusbar.caret.selection.bg = WARN
c.colors.statusbar.progress.bg = ACCENT
c.colors.statusbar.url.fg = FG_DIM
c.colors.statusbar.url.success.http.fg = FG_DIM
c.colors.statusbar.url.success.https.fg = FG
c.colors.statusbar.url.error.fg = BAD
c.colors.statusbar.url.warn.fg = WARN
c.colors.statusbar.url.hover.fg = FG

# tab bar
c.colors.tabs.bar.bg = BG
c.colors.tabs.even.fg = FG_DIM
c.colors.tabs.even.bg = BG
c.colors.tabs.odd.fg = FG_DIM
c.colors.tabs.odd.bg = BG_ALT
c.colors.tabs.selected.even.fg = FG
c.colors.tabs.selected.even.bg = BG_SEL
c.colors.tabs.selected.odd.fg = FG
c.colors.tabs.selected.odd.bg = BG_SEL
c.colors.tabs.pinned.even.fg = FG_DIM
c.colors.tabs.pinned.even.bg = BG_SEL
c.colors.tabs.pinned.odd.fg = FG_DIM
c.colors.tabs.pinned.odd.bg = BG_SEL
c.colors.tabs.pinned.selected.even.fg = FG
c.colors.tabs.pinned.selected.even.bg = BG_SEL
c.colors.tabs.pinned.selected.odd.fg = FG
c.colors.tabs.pinned.selected.odd.bg = BG_SEL
c.colors.tabs.indicator.start = ACCENT
c.colors.tabs.indicator.stop = GOOD
c.colors.tabs.indicator.error = BAD

# tooltips
c.colors.tooltip.fg = FG_DIM
c.colors.tooltip.bg = BG_ALT

# --- 2. Google as the default search engine (was DuckDuckGo) ---
# Applies to `o`/`O` input without a URL, and `:open <text>`.
c.url.searchengines = {'DEFAULT': 'https://www.google.com/search?q={}'}

# --- 3. `tt` toggles the tab bar + statusbar together ---
# `tt` is free in qutebrowser's defaults (t-prefix = toggles, same family as
# `tsh`/`tph`/...); each press flips both bars between always and never.
config.bind('tt', 'config-cycle tabs.show always never;; config-cycle statusbar.show always never')

# --- 4. local startpage (never a blank screen) + minimal/perf tuning ---
import pathlib
# Resolves next to this file both in the repo and at ~/.config/qutebrowser.
# NOTE: absolute() and NOT resolve() — isolated profiles symlink this very
# file, and startpage.html reads the profile name from its own URL, so the
# symlinked path (.../qutebrowser-<name>/config/...) must survive here.
STARTPAGE = pathlib.Path(__file__).absolute().parent.joinpath('startpage.html').as_uri()
c.url.start_pages = [STARTPAGE]
c.url.default_page = STARTPAGE
# Closing the last tab shows the startpage instead of about:blank.
c.tabs.last_close = 'startpage'
# Tab bar only when there is more than one tab (`tt` still toggles always/never).
c.tabs.show = 'multiple'
# No auto-playing media (click-to-play still works) — less noise, less CPU.
c.content.autoplay = False
# Restore only the visible tab on launch; the rest load on first view.
c.session.lazy_restore = True
# Completion popup shrinks to its content instead of full width.
c.completion.shrink = True
