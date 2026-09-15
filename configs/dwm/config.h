/* See LICENSE file for copyright and license details. */

/* XF86 media/laptop keysyms (Print, XF86XK_Audio*, XF86XK_MonBrightness*, ...) */
#include <X11/XF86keysym.h>

/* appearance */
static const unsigned int borderpx = 1;
static const unsigned int snap = 32;
static const int showbar = 0; /* statusline hidden by default — Super+F12 toggles it */
static const int topbar = 1;
static const char *fonts[] = { "JetBrainsMono Nerd Font:size=10" };
static const char dmenufont[] = "JetBrainsMono Nerd Font:size=10";
static const char col_gray1[] = "#111111";
static const char col_gray2[] = "#333333";
static const char col_gray3[] = "#bbbbbb";
static const char col_gray4[] = "#eeeeee";
static const char col_cyan[] = "#777777"; /* monochrome accent — was blue, now gray */
static const char *colors[][3] = {
    [SchemeNorm] = { col_gray3, col_gray1, col_gray2 },
    [SchemeSel]  = { col_gray4, col_cyan,  col_cyan  },
};

/* tagging — 10 tags (1-8 coding, 9 browser, 10 editor) */
static const char *tags[] = { "1", "2", "3", "4", "5", "6", "7", "8", "9", "10" };

static const Rule rules[] = {
    /* class            instance  title  tags mask  isfloating  monitor */
    { "Gimp",           NULL,     NULL,  0,         1,          -1 },
    /* no auto-tag for browsers/Zed — user requested free placement (was tag 9/10) */
    { "Devdocs",        NULL,     NULL,  0,         0,          -1 },
};

/* layout(s) */
static const float mfact = 0.55;
static const int nmaster = 1;
static const int resizehints = 0;
static const int lockfullscreen = 1;
static const int refreshrate = 120; /* dwm >= 6.5 */

static const Layout layouts[] = {
    { "", tile },   /* tile — icon  (fa-th, Nerd Font) was []= */
    { "", NULL },   /* floating — icon  (fa-window-restore) was ><> */
    { "", monocle }, /* monocle — icon  (fa-window-maximize) was [M] */
};

#define MODKEY Mod4Mask /* Super key */

#define TAGKEYS(KEY, TAG)                                                   \
    { MODKEY,                       KEY, view,       {.ui = 1 << TAG} },    \
    { MODKEY|ControlMask,           KEY, toggleview, {.ui = 1 << TAG} },    \
    { MODKEY|ShiftMask,             KEY, tag,        {.ui = 1 << TAG} },    \
    { MODKEY|ControlMask|ShiftMask, KEY, toggletag,  {.ui = 1 << TAG} },

#define SHCMD(cmd) { .v = (const char*[]){ "/bin/sh", "-c", cmd, NULL } }

#ifndef LENGTH
#define LENGTH(X) (sizeof X / sizeof X[0])
#endif

/* custom helpers — must be before keys[] so dwm.c sees them */
/* Smart tag navigation (keyboard Super+Ctrl+Left/Right AND 3-finger gestures):
   - NO wrap-around: on tag 1, prev stays; on tag 10, next stays.
   - Skips empty tags in both directions (jumps to nearest tag with windows).
   - From the last occupied tag, next is allowed exactly once (onto the next
     empty tag) and then locks: further next while standing on an empty tag
     with nothing occupied ahead does nothing. Same mirrored for prev.
   Gestures are INVERTED (swipe left = next, swipe right = prev). */
void shiftview(const Arg *arg);
void shiftview(const Arg *arg) {
    Arg a;
    unsigned int cur, occ = 0, ref, j;
    unsigned int n = LENGTH(tags);
    Client *c;
    if (!selmon) return;
    if (n == 0) return;
    cur = selmon->tagset[selmon->seltags];
    /* "all" view (~0) or empty mask: fall back to first/last tag */
    if (cur == 0 || cur == ((1u << n) - 1)) {
        a.ui = (arg->i > 0) ? 1u << 0 : 1u << (n - 1);
        view(&a);
        return;
    }
    /* reference tag: highest viewed tag when moving next,
       lowest viewed tag when moving prev */
    if (arg->i > 0) {
        ref = 0;
        for (j = 0; j < n; j++)
            if (cur & (1u << j))
                ref = j;
    } else {
        ref = n - 1;
        for (j = 0; j < n; j++)
            if (cur & (1u << j)) {
                ref = j;
                break;
            }
    }
    /* occupancy of each tag on this monitor (any client counts) */
    for (c = selmon->clients; c; c = c->next)
        occ |= (c->tags & ((1u << n) - 1));
    if (arg->i > 0) {
        /* nearest occupied tag ahead (skips empties) */
        for (j = ref + 1; j < n; j++)
            if (occ & (1u << j)) {
                a.ui = 1u << j;
                view(&a);
                return;
            }
        /* nothing occupied ahead: one step past the last occupied tag,
           then lock (stay) while on an empty tag */
        if ((occ & (1u << ref)) && ref + 1 < n) {
            a.ui = 1u << (ref + 1);
            view(&a);
        }
        return;
    } else {
        /* nearest occupied tag behind (skips empties) */
        for (j = ref; j-- > 0;)
            if (occ & (1u << j)) {
                a.ui = 1u << j;
                view(&a);
                return;
            }
        /* nothing occupied behind: one step before the first occupied tag,
           then lock (stay) while on an empty tag */
        if ((occ & (1u << ref)) && ref > 0) {
            a.ui = 1u << (ref - 1);
            view(&a);
        }
        return;
    }
}

void togglefullscreen(const Arg *arg);
void togglefullscreen(const Arg *arg) {
    if (selmon->sel)
        setfullscreen(selmon->sel, !selmon->sel->isfullscreen);
}

/* simple Hyprland-like group: toggle monocle + remember previous layout
   Group = show all windows on current tag tabbed (monocle), ungroup = tile */
void togglegroup(const Arg *arg) {
    if (selmon->lt[selmon->sellt] == &layouts[2]) { // monocle = grouped
        setlayout(&((Arg){.v = &layouts[0]})); // tile = ungrouped
    } else {
        setlayout(&((Arg){.v = &layouts[2]})); // monocle = grouped/tabbed
    }
}

/* commands */
static char dmenumon[2] = "0"; /* referenced by spawn() in dwm.c even when unbound */
static const char *dmenucmd[] = { "dmenu_run", "-m", dmenumon, "-fn", dmenufont, "-nb", col_gray1, "-nf", col_gray3, "-sb", col_cyan, "-sf", col_gray4, NULL };
static const char *termcmd[]   = { "alacritty", NULL };
static const char *bravecmd[]  = { "brave", NULL };
static const char *zencmd[]    = { "zen-browser", NULL };
static const char *editorcmd[] = { "zeditor", NULL };   /* zed package binary is "zeditor" (+ ~/.bin/zed shim for terminal) */
static const char *filemgrcmd[] = { "alacritty", "-e", "lf", NULL };
static const char *sysmoncmd[] = { "alacritty", "-e", "btop", NULL };
static const char *lazygitcmd[] = { "alacritty", "-e", "lazygit", NULL };

/* --- media / laptop function-key commands --- */
/* All volume/brightness commands poke statusbar via USR1 for instant feedback (see statusbar.sh trap) */
static const char *volupcmd[]    = { "sh", "-c", "wpctl set-volume -l 1.5 @DEFAULT_AUDIO_SINK@ 5%+; pkill -USR1 dwm-statusbar 2>/dev/null; pkill -USR1 statusbar.sh 2>/dev/null; true", NULL };
static const char *voldncmd[]    = { "sh", "-c", "wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-; pkill -USR1 dwm-statusbar 2>/dev/null; pkill -USR1 statusbar.sh 2>/dev/null; true", NULL };
static const char *volmutecmd[]  = { "sh", "-c", "wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle; pkill -USR1 dwm-statusbar 2>/dev/null; pkill -USR1 statusbar.sh 2>/dev/null; true", NULL };
static const char *micmutecmd[]  = { "sh", "-c", "wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle; pkill -USR1 dwm-statusbar 2>/dev/null; pkill -USR1 statusbar.sh 2>/dev/null; true", NULL };
static const char *brupcmd[]     = { "sh", "-c", "brightnessctl set 5%+ >/dev/null; pkill -USR1 dwm-statusbar 2>/dev/null; pkill -USR1 statusbar.sh 2>/dev/null; true", NULL };
static const char *brdncmd[]     = { "sh", "-c", "brightnessctl set 5%- >/dev/null; pkill -USR1 dwm-statusbar 2>/dev/null; pkill -USR1 statusbar.sh 2>/dev/null; true", NULL };
static const char *mediaplaycmd[] = { "playerctl", "play-pause", NULL };
static const char *medianextcmd[] = { "playerctl", "next", NULL };
static const char *mediaprevcmd[] = { "playerctl", "previous", NULL };
static const char *mediastopcmd[] = { "playerctl", "stop", NULL };
static const char *screenshotcmd[] = { "sh", "-c", "mkdir -p ~/Pictures && maim ~/Pictures/shot-$(date +%Y%m%d-%H%M%S).png && notify-send -t 1500 'Screenshot' 'saved to ~/Pictures'", NULL };
static const char *selscreenshotcmd[] = { "sh", "-c", "mkdir -p ~/Pictures && maim -s ~/Pictures/shot-$(date +%Y%m%d-%H%M%S).png && notify-send -t 1500 'Screenshot' 'selection saved to ~/Pictures'", NULL };
static const char *lockcmd[]    = { "screen-lock", NULL };   /* slock black: lock screen, apps keep running */
static const char *sleepcmd[]    = { "systemctl", "suspend", NULL };
static const char *displaycmd[]  = { "sh", "-c", "xrandr --auto", NULL };
static const char *calccmd[]     = { "alacritty", "-e", "sh", "-c", "echo 'calc — enter expressions, Ctrl+D to exit'; bc -l", NULL };

static const Key keys[] = {
    /* modifier            key          function        argument */
    { MODKEY,              XK_Return,   spawn,          {.v = termcmd } },          /* Super+Enter -> terminal (was zoom) */
    { MODKEY|ShiftMask,    XK_Return,   spawn,          {.v = termcmd } },          /* Super+Shift+Enter -> terminal (alternate, both work) */
    { MODKEY|ControlMask,  XK_Return,   zoom,           {0} },          /* alternate zoom (was Super+Enter) */
    { MODKEY,              XK_b,        spawn,          {.v = bravecmd } },
    { MODKEY|ShiftMask,    XK_b,        spawn,          {.v = zencmd } },
    { MODKEY,              XK_e,        spawn,          {.v = editorcmd } },
    { MODKEY,              XK_g,        spawn,          {.v = filemgrcmd } },
    { MODKEY|ShiftMask,    XK_g,        spawn,          {.v = lazygitcmd } },
    { MODKEY|ShiftMask,    XK_s,        spawn,          {.v = sysmoncmd } },
    { MODKEY,              XK_F12,      togglebar,      {0} },          /* show/hide statusline */

    /* --- laptop function keys (media, volume, brightness, screenshots) --- */
    { 0,                   XF86XK_AudioRaiseVolume, spawn, {.v = volupcmd } },
    { 0,                   XF86XK_AudioLowerVolume, spawn, {.v = voldncmd } },
    { 0,                   XF86XK_AudioMute,        spawn, {.v = volmutecmd } },
    { 0,                   XF86XK_AudioMicMute,     spawn, {.v = micmutecmd } },
    { 0,                   XF86XK_MonBrightnessUp,  spawn, {.v = brupcmd } },
    { 0,                   XF86XK_MonBrightnessDown,spawn, {.v = brdncmd } },
    { 0,                   XF86XK_AudioPlay,        spawn, {.v = mediaplaycmd } },
    { 0,                   XF86XK_AudioPause,       spawn, {.v = mediaplaycmd } },
    { 0,                   XF86XK_AudioNext,        spawn, {.v = medianextcmd } },
    { 0,                   XF86XK_AudioPrev,        spawn, {.v = mediaprevcmd } },
    { 0,                   XF86XK_AudioStop,        spawn, {.v = mediastopcmd } },
    { 0,                   XF86XK_Display,          spawn, {.v = displaycmd } },
    { 0,                   XF86XK_Sleep,            spawn, {.v = sleepcmd } },
    { 0,                   XF86XK_ScreenSaver,      spawn, {.v = lockcmd } },
    { 0,                   XF86XK_Calculator,       spawn, {.v = calccmd } },
    { 0,                   XF86XK_TouchpadToggle,   spawn, SHCMD("id=$(xinput list --id-only \"$(xinput list --name-only 2>/dev/null | grep -im1 -i touchpad)\" 2>/dev/null); [ -n \"$id\" ] && xinput toggle \"$id\"") },
    { 0,                   XK_Print,                spawn, {.v = screenshotcmd } },
    { ShiftMask,           XK_Print,                spawn, {.v = selscreenshotcmd } },
    { MODKEY|ShiftMask,    XK_x,                    spawn, {.v = lockcmd } },   /* lock screen, apps keep running */

    /* --- Super clipboard: Super+C/X/V -> copy/cut/paste everywhere, terminal-safe --- */
    /* Alacritty already handles Super+C/V natively; this covers browsers/Zed/others */
    /* Try /usr/local/bin first (privileged install), fallback to ~/.local/bin */
    { MODKEY,              XK_c,                    spawn, SHCMD("super-clipboard c 2>/dev/null || $HOME/.local/bin/super-clipboard c") },
    { MODKEY,              XK_x,                    spawn, SHCMD("super-clipboard x 2>/dev/null || $HOME/.local/bin/super-clipboard x") },
    { MODKEY,              XK_v,                    spawn, SHCMD("super-clipboard v 2>/dev/null || $HOME/.local/bin/super-clipboard v") },

    /* --- tag switching: Super+Ctrl+Left/Right = smart shiftview (no wrap,
           skips empty tags, locks past last occupied); 3-finger gestures are
           INVERTED (swipe left = next tag, swipe right = prev tag) --- */
    { MODKEY|ControlMask,  XK_Left,                 shiftview,      {.i = -1 } },
    { MODKEY|ControlMask,  XK_Right,                shiftview,      {.i = +1 } },

    { MODKEY,              XK_j,        focusstack,     {.i = +1 } },
    { MODKEY,              XK_k,        focusstack,     {.i = -1 } },
    { MODKEY,              XK_i,        incnmaster,     {.i = +1 } },
    { MODKEY,              XK_d,        incnmaster,     {.i = -1 } },
    { MODKEY,              XK_h,        setmfact,       {.f = -0.05} },
    { MODKEY,              XK_l,        setmfact,       {.f = +0.05} },
    { MODKEY,              XK_Tab,      view,           {0} },
    { MODKEY|ShiftMask,    XK_c,        killclient,     {0} },
    { MODKEY|ShiftMask,    XK_space,    togglefloating, {0} },
    /* Super+0 = tag 10 (was stock-dwm "view all" — confusing with 10 tags) */
    TAGKEYS(               XK_0,        9)
    /* "view/tag all tags" moved to Super+`/Super+Shift+` (was Super+0) */
    { MODKEY,              XK_grave,    view,           {.ui = ~0 } },
    { MODKEY|ShiftMask,    XK_grave,    tag,            {.ui = ~0 } },

    { MODKEY,              XK_t,        setlayout,      {.v = &layouts[0]} },
    { MODKEY,              XK_f,        togglefullscreen, {0} },                           /* fullscreen current window */
    { MODKEY|ShiftMask,    XK_f,        setlayout,      {.v = &layouts[1]} },            /* floating */
    { MODKEY,              XK_m,        setlayout,      {.v = &layouts[2]} },            /* monocle */
    { MODKEY,              XK_y,        togglegroup,    {0} },                           /* Hyprland-like group (monocle toggle) */
    { MODKEY,              XK_space,    setlayout,      {0} },

    { MODKEY,              XK_comma,    focusmon,       {.i = -1 } },
    { MODKEY,              XK_period,   focusmon,       {.i = +1 } },
    { MODKEY|ShiftMask,    XK_comma,    tagmon,         {.i = -1 } },
    { MODKEY|ShiftMask,    XK_period,   tagmon,         {.i = +1 } },

    TAGKEYS(               XK_1,        0)
    TAGKEYS(               XK_2,        1)
    TAGKEYS(               XK_3,        2)
    TAGKEYS(               XK_4,        3)
    TAGKEYS(               XK_5,        4)
    TAGKEYS(               XK_6,        5)
    TAGKEYS(               XK_7,        6)
    TAGKEYS(               XK_8,        7)
    TAGKEYS(               XK_9,        8)

    /* tag 10 alias on minus (Super+0 above is the primary binding) */
    { MODKEY,              XK_minus,    view,           {.ui = 1 << 9} },
    { MODKEY|ShiftMask,    XK_minus,    tag,            {.ui = 1 << 9} },

    /* quit dwm (stock handler — no restart signal in stock dwm 6.8) */
    { MODKEY|ShiftMask,    XK_q,        quit,           {0} },
};

static const Button buttons[] = {
    { ClkLtSymbol,        0,       Button1, setlayout,      {0} },
    { ClkLtSymbol,        0,       Button3, setlayout,      {.v = &layouts[2]} },
    { ClkWinTitle,        0,       Button2, zoom,           {0} },
    { ClkStatusText,      0,       Button2, spawn,          {.v = termcmd } },
    { ClkClientWin,       MODKEY,  Button1, movemouse,      {0} },
    { ClkClientWin,       MODKEY,  Button2, togglefloating, {0} },
    { ClkClientWin,       MODKEY,  Button3, resizemouse,    {0} },
    { ClkTagBar,          0,       Button1, view,           {0} },
    { ClkTagBar,          0,       Button3, toggleview,     {0} },
    { ClkTagBar,          MODKEY,  Button1, tag,            {0} },
    { ClkTagBar,          MODKEY,  Button3, toggletag,      {0} },
};
