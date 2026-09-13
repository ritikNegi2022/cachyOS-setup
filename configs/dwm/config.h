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
static const char col_gray1[] = "#222222";
static const char col_gray2[] = "#444444";
static const char col_gray3[] = "#bbbbbb";
static const char col_gray4[] = "#eeeeee";
static const char col_cyan[] = "#005577";
static const char *colors[][3] = {
    [SchemeNorm] = { col_gray3, col_gray1, col_gray2 },
    [SchemeSel]  = { col_gray4, col_cyan,  col_cyan  },
};

/* tagging — 10 tags (1-8 coding, 9 browser, 10 editor) */
static const char *tags[] = { "1", "2", "3", "4", "5", "6", "7", "8", "9", "10" };

static const Rule rules[] = {
    /* class            instance  title  tags mask  isfloating  monitor */
    { "Gimp",           NULL,     NULL,  0,         1,          -1 },
    { "brave-browser",  NULL,     NULL,  1 << 8,    0,          -1 }, /* Brave → tag 9  */
    { "zen-browser",    NULL,     NULL,  1 << 8,    0,          -1 }, /* Zen   → tag 9  */
    { "Zed",            NULL,     NULL,  1 << 9,    0,          -1 }, /* Zed   → tag 10 */
    { "zed",            NULL,     NULL,  1 << 9,    0,          -1 },
    { "Devdocs",        NULL,     NULL,  1 << 8,    0,          -1 },
};

/* layout(s) */
static const float mfact = 0.55;
static const int nmaster = 1;
static const int resizehints = 0;
static const int lockfullscreen = 1;
static const int refreshrate = 120; /* dwm >= 6.5 */

static const Layout layouts[] = {
    { "[]=", tile },   /* first entry is default */
    { "><>", NULL },   /* floating */
    { "[M]", monocle },
};

#define MODKEY Mod4Mask /* Super key */

#define TAGKEYS(KEY, TAG)                                                   \
    { MODKEY,                       KEY, view,       {.ui = 1 << TAG} },    \
    { MODKEY|ControlMask,           KEY, toggleview, {.ui = 1 << TAG} },    \
    { MODKEY|ShiftMask,             KEY, tag,        {.ui = 1 << TAG} },    \
    { MODKEY|ControlMask|ShiftMask, KEY, toggletag,  {.ui = 1 << TAG} },

#define SHCMD(cmd) { .v = (const char*[]){ "/bin/sh", "-c", cmd, NULL } }

/* commands */
static char dmenumon[2] = "0"; /* referenced by spawn() in dwm.c even when unbound */
static const char *dmenucmd[] = { "dmenu_run", "-m", dmenumon, "-fn", dmenufont, "-nb", col_gray1, "-nf", col_gray3, "-sb", col_cyan, "-sf", col_gray4, NULL };
static const char *termcmd[]   = { "alacritty", NULL };
static const char *bravecmd[]  = { "brave", NULL };
static const char *zencmd[]    = { "zen-browser", NULL };
static const char *editorcmd[] = { "zed", NULL };
static const char *filemgrcmd[] = { "alacritty", "-e", "lf", NULL };
static const char *sysmoncmd[] = { "alacritty", "-e", "btop", NULL };
static const char *lazygitcmd[] = { "alacritty", "-e", "lazygit", NULL };

/* --- media / laptop function-key commands --- */
static const char *volupcmd[]    = { "wpctl", "set-volume", "-l", "1.5", "@DEFAULT_AUDIO_SINK@", "5%+", NULL };
static const char *voldncmd[]    = { "wpctl", "set-volume", "@DEFAULT_AUDIO_SINK@", "5%-", NULL };
static const char *volmutecmd[]  = { "wpctl", "set-mute", "@DEFAULT_AUDIO_SINK@", "toggle", NULL };
static const char *micmutecmd[]  = { "wpctl", "set-mute", "@DEFAULT_AUDIO_SOURCE@", "toggle", NULL };
static const char *brupcmd[]     = { "brightnessctl", "set", "5%+", NULL };
static const char *brdncmd[]     = { "brightnessctl", "set", "5%-", NULL };
static const char *mediaplaycmd[] = { "playerctl", "play-pause", NULL };
static const char *medianextcmd[] = { "playerctl", "next", NULL };
static const char *mediaprevcmd[] = { "playerctl", "previous", NULL };
static const char *mediastopcmd[] = { "playerctl", "stop", NULL };
static const char *screenshotcmd[] = { "sh", "-c", "mkdir -p ~/Pictures && maim ~/Pictures/shot-$(date +%Y%m%d-%H%M%S).png && notify-send -t 1500 'Screenshot' 'saved to ~/Pictures'", NULL };
static const char *selscreenshotcmd[] = { "sh", "-c", "mkdir -p ~/Pictures && maim -s ~/Pictures/shot-$(date +%Y%m%d-%H%M%S).png && notify-send -t 1500 'Screenshot' 'selection saved to ~/Pictures'", NULL };
static const char *lockcmd[]     = { "slock", NULL };
static const char *sleepcmd[]    = { "systemctl", "suspend", NULL };
static const char *displaycmd[]  = { "sh", "-c", "xrandr --auto", NULL };
static const char *calccmd[]     = { "alacritty", "-e", "sh", "-c", "echo 'calc — enter expressions, Ctrl+D to exit'; bc -l", NULL };

static const Key keys[] = {
    /* modifier            key          function        argument */
    { MODKEY,              XK_Return,   zoom,           {0} },          /* stock dwm: zoom to master */
    { MODKEY|ShiftMask,    XK_Return,   spawn,          {.v = termcmd } },
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
    { 0,                   XF86XK_TouchpadToggle,   spawn, SHCMD("id=$(xinput list --id-only \"$(xinput list --name-only | grep -im1 -i touchpad)\" 2>/dev/null) && xinput toggle \"$id\"") },
    { 0,                   XK_Print,                spawn, {.v = screenshotcmd } },
    { ShiftMask,           XK_Print,                spawn, {.v = selscreenshotcmd } },
    { MODKEY|ShiftMask,    XK_x,                    spawn, {.v = lockcmd } },   /* manual lock */

    { MODKEY,              XK_j,        focusstack,     {.i = +1 } },
    { MODKEY,              XK_k,        focusstack,     {.i = -1 } },
    { MODKEY,              XK_i,        incnmaster,     {.i = +1 } },
    { MODKEY,              XK_d,        incnmaster,     {.i = -1 } },
    { MODKEY,              XK_h,        setmfact,       {.f = -0.05} },
    { MODKEY,              XK_l,        setmfact,       {.f = +0.05} },
    { MODKEY,              XK_Tab,      view,           {0} },
    { MODKEY|ShiftMask,    XK_c,        killclient,     {0} },
    { MODKEY|ShiftMask,    XK_space,    togglefloating, {0} },
    { MODKEY,              XK_0,        view,           {.ui = ~0 } },
    { MODKEY|ShiftMask,    XK_0,        tag,            {.ui = ~0 } },

    { MODKEY,              XK_t,        setlayout,      {.v = &layouts[0]} },
    { MODKEY,              XK_f,        setlayout,      {.v = &layouts[1]} },
    { MODKEY,              XK_m,        setlayout,      {.v = &layouts[2]} },
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

    /* tag 10 (XK_0 is "view all") */
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
