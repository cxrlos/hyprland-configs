// Zen Browser — tracked preferences (Catppuccin Mocha · sky · Monaspace desktop).
// scripts/install.sh symlinks this into the active profile resolved from
// profiles.ini; Zen re-applies it on every launch. Only declarative prefs live
// here — the Catppuccin Mod, accent picker, extensions, bookmarks and passwords
// stay in Zen's per-account sync.

// Load chrome/userChrome.css + userContent.css
user_pref("toolkit.legacyUserProfileCustomizations.stylesheets", true);

// Accent → Catppuccin sky, unified with waybar/rofi/swaync/hyprlock. user.js is
// authoritative, so this overrides the Settings accent picker on each launch.
user_pref("zen.theme.accent-color", "#89dceb");

// Glass + corner rounding to echo the Hyprland frosted islands ($rounding = 8)
user_pref("zen.theme.acrylic-elements", true);
user_pref("zen.theme.border-radius", 8);

// Minimal, keyboard-driven: compact mode auto-hides the toolbar (vertical tabs are
// already Zen's default); sidebar and toolbar slide back in on hover.
user_pref("zen.view.compact.enable-at-startup", true);
user_pref("zen.view.compact.hide-toolbar", true);

// MonaspiceNe for monospace web content, matching the terminal. Proportional fonts
// are left to site/web defaults so page layouts don't break.
user_pref("font.name.monospace.x-western", "MonaspiceNe Nerd Font");

// Privacy / cleanup
user_pref("toolkit.telemetry.enabled", false);
user_pref("toolkit.telemetry.unified", false);
user_pref("datareporting.healthreport.uploadEnabled", false);
user_pref("datareporting.policy.dataSubmissionEnabled", false);
user_pref("extensions.pocket.enabled", false);
user_pref("browser.newtabpage.activity-stream.showSponsored", false);
user_pref("browser.newtabpage.activity-stream.showSponsoredTopSites", false);
user_pref("browser.aboutConfig.showWarning", false);
