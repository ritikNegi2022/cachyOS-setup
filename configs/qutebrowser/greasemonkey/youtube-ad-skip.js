// ==UserScript==
// @name        YouTube ad auto-skip and mute
// @description Skips skippable YouTube ads ASAP, mutes + fast-forwards unskippable ones, hides overlay/banner ad slots. Player-API approach (no request blocking), so it rarely trips adblock-detection walls.
// @match       *://*.youtube.com/*
// @match       *://*.youtube-nocookie.com/*
// @include     *://*.youtube.com/*
// @include     *://*.youtube-nocookie.com/*
// @run-at      document-start
// ==/UserScript==

// Installed by setup.sh step 5 to ~/.config/qutebrowser/greasemonkey/
// (qutebrowser loads *.js from there on start — restart after changes).
// YouTube renames player classes occasionally; if ads slip through again,
// update SKIP_SELECTORS / AD_MARKERS below (inspect with `wi` devtools).

(function () {
    'use strict';

    // "Skip ad" buttons seen in the wild (classic + modern player).
    var SKIP_SELECTORS = [
        '.ytp-ad-skip-button',
        '.ytp-skip-ad-button',
        '.ytp-ad-skip-button-modern'
    ];

    // Player states meaning "an ad is on screen right now".
    var AD_MARKERS = ['ad-showing', 'ad-interrupting'];

    // Overlay / banner / in-feed ad slots to hide outright.
    var HIDE_CSS = [
        '.ytp-ad-overlay-container',
        '.ytp-ad-overlay-slot',
        '.ytp-ad-text',
        '.ytd-ad-slot-renderer',
        '.ytd-promoted-sparkles-web-renderer',
        '.ytd-display-ad-renderer'
    ].join(',') + ' { display: none !important; }';

    var CSS_ID = 'qb-yt-adblock-css';
    var ourMute = false;  // only unmute what WE muted (never fight the user)
    var ourRate = false;  // only restore speed WE changed

    function ensureCss() {
        if (document.getElementById(CSS_ID)) {
            return;
        }
        var root = document.head || document.documentElement;
        if (!root) {
            return;
        }
        var style = document.createElement('style');
        style.id = CSS_ID;
        style.textContent = HIDE_CSS;
        root.appendChild(style);
    }

    function clickSkipButtons() {
        for (var i = 0; i < SKIP_SELECTORS.length; i++) {
            var btns = document.querySelectorAll(SKIP_SELECTORS[i]);
            for (var j = 0; j < btns.length; j++) {
                try {
                    btns[j].click();
                } catch (e) { /* button vanished mid-click, ignore */ }
            }
        }
    }

    function inAd(player) {
        if (!player || !player.classList) {
            return false;
        }
        for (var i = 0; i < AD_MARKERS.length; i++) {
            if (player.classList.contains(AD_MARKERS[i])) {
                return true;
            }
        }
        return false;
    }

    function tick() {
        ensureCss();
        clickSkipButtons();

        var player = document.getElementById('movie_player');
        var video = document.querySelector('video.html5-main-video') ||
            document.querySelector('video');
        if (!video) {
            return;
        }

        if (inAd(player)) {
            if (!video.muted) {
                try {
                    video.muted = true;
                    ourMute = true;
                } catch (e) { /* ignore */ }
            }
            if (video.playbackRate === 1) {
                try {
                    video.playbackRate = 16;
                    ourRate = true;
                } catch (e) { /* ignore */ }
            }
            // Short unskippable bumpers: nudge to the end when allowed.
            try {
                if (video.duration && video.duration < 31 &&
                    video.duration - video.currentTime > 1) {
                    video.currentTime = video.duration - 0.25;
                }
            } catch (e) { /* seeking blocked during ads, ignore */ }
        } else {
            if (ourMute) {
                try {
                    video.muted = false;
                } catch (e) { /* ignore */ }
                ourMute = false;
            }
            if (ourRate) {
                try {
                    video.playbackRate = 1;
                } catch (e) { /* ignore */ }
                ourRate = false;
            }
        }
    }

    // YouTube is an SPA (no full reloads between videos) — poll so the
    // handler survives in-page navigation. 500ms keeps skip delay short
    // without burning CPU in the background.
    window.setInterval(tick, 500);
    tick();
})();
