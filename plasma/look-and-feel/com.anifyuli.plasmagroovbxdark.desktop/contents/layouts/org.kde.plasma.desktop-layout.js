var panel = new Panel
panel.location = "bottom"
panel.height = 46
panel.floating = true
panel.alignment = "center"
panel.minimumLength = 1536
panel.maximumLength = 1536

panel.addWidget("org.kde.plasma.kickoff")
panel.addWidget("org.kde.plasma.pager")

var icontasks = panel.addWidget("org.kde.plasma.icontasks")
icontasks.currentConfigGroup = ["General"]
icontasks.writeConfig("launchers", [
    "applications:systemsettings.desktop",
    "applications:org.kde.discover.desktop",
    "preferred://filemanager",
    "preferred://browser"
])

panel.addWidget("org.kde.plasma.marginsseparator")
panel.addWidget("org.kde.plasma.systemtray")
panel.addWidget("org.kde.plasma.digitalclock")
panel.addWidget("org.kde.plasma.showdesktop")

// install.sh rewrites this placeholder to the actual install destination
// (file://<DEST>/wallpapers/PlasmaGroovbxWallpaper/) at install time, since
// the org.kde.image wallpaper plugin needs a real resolved path here.
var wallpaperPath = '__PLASMA_GROOVBX_WALLPAPER_PATH__';

var desktopsArray = desktopsForActivity(currentActivity());
for (var j = 0; j < desktopsArray.length; j++) {
    desktopsArray[j].wallpaperPlugin = 'org.kde.image';
    desktopsArray[j].currentConfigGroup = ['Wallpaper', 'org.kde.image', 'General'];
    desktopsArray[j].writeConfig('Image', wallpaperPath);
}
