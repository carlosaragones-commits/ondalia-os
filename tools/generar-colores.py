"""Genera los esquemas de color de Ondalia para KDE Plasma (claro y oscuro).

Uso: python3 tools/generar-colores.py
"""
import sys, os

def rgb(h):
    h = h.lstrip('#')
    return ",".join(str(int(h[i:i+2], 16)) for i in (0, 2, 4))

PAL = {
    "claro": dict(
        name="Ondalia Claro", id="OndaliaClaro",
        window_bg="#F3F6F9", window_alt="#E8EDF2", view_bg="#FFFFFF", view_alt="#F5F8FA",
        button_bg="#EAEFF4", button_alt="#DDE4EB", header_bg="#E6ECF1",
        text="#1F2935", text_inactive="#5D6B7A",
        tooltip_bg="#002F6C", tooltip_text="#F3F6F9",
        compl_bg="#002F6C", compl_text="#EAF4F8",
    ),
    "oscuro": dict(
        name="Ondalia Oscuro", id="OndaliaOscuro",
        window_bg="#0F1B2A", window_alt="#132234", view_bg="#0A1420", view_alt="#0F1B2A",
        button_bg="#172A40", button_alt="#1C324B", header_bg="#0C1724",
        text="#E4ECF3", text_inactive="#93A3B4",
        tooltip_bg="#0A1420", tooltip_text="#E4ECF3",
        compl_bg="#001B3E", compl_text="#E4ECF3",
    ),
}

ACCENT = dict(
    selection="#007A7A",       # verde azulado oscuro: texto blanco con buen contraste
    selection_text="#FFFFFF",
    focus="#00BCD4",           # cian Ondalia
    hover="#4DB6AC",           # espuma
    link="#00708F",
    visited="#6A5ACD",
    active="#FF7043",          # coral: indicadores activos
    negative="#D84343",
    neutral="#FF7043",
    positive="#2E9D6A",
)

def group(name, bg, alt, fg, inactive, accent, dark):
    link = "#4DD0E1" if dark else accent["link"]
    return f"""[{name}]
BackgroundAlternate={rgb(alt)}
BackgroundNormal={rgb(bg)}
DecorationFocus={rgb(accent['focus'])}
DecorationHover={rgb(accent['hover'])}
ForegroundActive={rgb(accent['active'])}
ForegroundInactive={rgb(inactive)}
ForegroundLink={rgb(link)}
ForegroundNegative={rgb(accent['negative'])}
ForegroundNeutral={rgb(accent['neutral'])}
ForegroundNormal={rgb(fg)}
ForegroundPositive={rgb(accent['positive'])}
ForegroundVisited={rgb(accent['visited'])}
"""

def scheme(p, dark):
    a = ACCENT
    out = f"""[ColorEffects:Disabled]
Color=56,56,56
ColorAmount=0
ColorEffect=0
ContrastAmount=0.65
ContrastEffect=1
IntensityAmount=0.1
IntensityEffect=2

[ColorEffects:Inactive]
ChangeSelectionColor=true
Color=112,111,110
ColorAmount=0.025
ColorEffect=2
ContrastAmount=0.1
ContrastEffect=2
Enable=false
IntensityAmount=0
IntensityEffect=0

"""
    out += group("Colors:Button", p["button_bg"], p["button_alt"], p["text"], p["text_inactive"], a, dark) + "\n"
    out += group("Colors:Complementary", p["compl_bg"], p["compl_bg"], p["compl_text"], "#93A3B4", a, True) + "\n"
    out += group("Colors:Header", p["header_bg"], p["header_bg"], p["text"], p["text_inactive"], a, dark) + "\n"
    out += group("Colors:Header][Inactive", p["window_bg"], p["window_bg"], p["text"], p["text_inactive"], a, dark) + "\n"
    out += group("Colors:Selection", a["selection"], a["selection"], a["selection_text"], "#CDEFEF", a, True) + "\n"
    out += group("Colors:Tooltip", p["tooltip_bg"], p["tooltip_bg"], p["tooltip_text"], "#93A3B4", a, True) + "\n"
    out += group("Colors:View", p["view_bg"], p["view_alt"], p["text"], p["text_inactive"], a, dark) + "\n"
    out += group("Colors:Window", p["window_bg"], p["window_alt"], p["text"], p["text_inactive"], a, dark) + "\n"
    out += f"""[General]
ColorScheme={p['id']}
Name={p['name']}
shadeSortColumn=true

[KDE]
contrast=4

[WM]
activeBackground={rgb(p['header_bg'])}
activeBlend={rgb(p['text'])}
activeForeground={rgb(p['text'])}
inactiveBackground={rgb(p['window_bg'])}
inactiveBlend={rgb(p['text_inactive'])}
inactiveForeground={rgb(p['text_inactive'])}
"""
    return out

dest = sys.argv[1] if len(sys.argv) > 1 else os.path.join(os.path.dirname(__file__), "..", "config", "includes.chroot", "usr", "share", "color-schemes")
for key, p in PAL.items():
    with open(os.path.join(dest, p["id"] + ".colors"), "w") as f:
        f.write(scheme(p, key == "oscuro"))
    print("ok", p["id"])
