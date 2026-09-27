// Prefs userChrome.css and userContent.css rely on; Zen copies them into prefs.js at startup.
user_pref("toolkit.legacyUserProfileCustomizations.stylesheets", true);
user_pref("zen.view.window.scheme", 0);
user_pref("zen.theme.accent-color", "#83a598");
user_pref("zen.theme.border-radius", 10);
// InactiveCaption is the GTK colour, which fights the flat base when Zen loses focus.
user_pref("zen.view.grey-out-inactive-windows", false);
user_pref("zen.theme.acrylic-elements", false);
