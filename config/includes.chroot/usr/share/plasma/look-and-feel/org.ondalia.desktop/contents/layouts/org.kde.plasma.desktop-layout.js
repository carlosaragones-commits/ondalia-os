// Distribución por defecto de Ondalia OS para usuarios nuevos:
// una barra fina arriba (menú, reloj, bandeja) y un dock flotante abajo.

// Algunas propiedades no existen en todas las versiones de Plasma:
// se aplican sin romper el resto si fallan.
function intenta(fn) {
    try { fn(); } catch (e) { print("Ondalia: propiedad no disponible: " + e); }
}

// --- Fondo de escritorio ---
var escritorios = desktopsForActivity(currentActivity());
for (var i = 0; i < escritorios.length; i++) {
    escritorios[i].wallpaperPlugin = "org.kde.image";
    escritorios[i].currentConfigGroup = ["Wallpaper", "org.kde.image", "General"];
    escritorios[i].writeConfig("Image", "file:///usr/share/wallpapers/Ondalia/");
}

// --- Barra superior ---
var barra = new Panel;
barra.location = "top";
barra.height = 2 * Math.floor(gridUnit * 1.5 / 2);
intenta(function () { barra.floating = false; });

var menu = barra.addWidget("org.kde.plasma.kickoff");
menu.currentConfigGroup = ["General"];
menu.writeConfig("icon", "/usr/share/pixmaps/ondalia-logo.svg");

barra.addWidget("org.kde.plasma.panelspacer");
var reloj = barra.addWidget("org.kde.plasma.digitalclock");
reloj.currentConfigGroup = ["Appearance"];
reloj.writeConfig("showDate", "true");
reloj.writeConfig("dateFormat", "longDate");
barra.addWidget("org.kde.plasma.panelspacer");
barra.addWidget("org.kde.plasma.systemtray");

// --- Dock inferior ---
var dock = new Panel;
dock.location = "bottom";
dock.height = 2 * Math.floor(gridUnit * 3.4 / 2);
intenta(function () { dock.alignment = "center"; });
intenta(function () { dock.lengthMode = "fit"; });
intenta(function () { dock.hiding = "dodgewindows"; });
intenta(function () { dock.floating = true; });

var tareas = dock.addWidget("org.kde.plasma.icontasks");
tareas.currentConfigGroup = ["General"];
tareas.writeConfig("launchers", [
    "applications:firefox.desktop",
    "applications:org.kde.dolphin.desktop",
    "applications:libreoffice-startcenter.desktop",
    "applications:vlc.desktop",
    "applications:org.kde.discover.desktop",
    "applications:systemsettings.desktop"
].join(","));
tareas.writeConfig("iconSpacing", "2");
