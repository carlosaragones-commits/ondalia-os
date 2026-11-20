"""Genera las diapositivas que muestra el instalador mientras copia el sistema.

Uso: python3 tools/generar-diapositivas.py
Escribe branding/instalador/diapositiva-N.svg (build.sh las convierte a PNG).
"""
from pathlib import Path

DEST = Path(__file__).resolve().parent.parent / "branding" / "instalador"
LOGO = (Path(__file__).resolve().parent.parent / "branding" / "logo-mono-light.svg").read_text()
LOGO_INNER = LOGO[LOGO.index(">", LOGO.index("<svg")) + 1:LOGO.rindex("</svg>")]

DIAPOSITIVAS = [
    ("Bienvenido a Ondalia OS", ["Fluidez. Ligereza. Elegancia.",
                                 "Mientras se instala, puedes seguir probando el sistema."]),
    ("Tus aplicaciones, a un clic", ["Abre Discover, la tienda de aplicaciones,",
                                      "y encontrarás miles de programas gratuitos."]),
    ("Trámites online sin complicaciones", ["DNIe, certificados digitales y AutoFirma",
                                             "vienen preparados para usar."]),
    ("Actualizaciones sin miedo", ["Antes de cada actualización se guarda una copia del sistema",
                                   "para poder recuperarlo si algo falla."]),
]

W, H = 800, 440


def diapositiva(titulo, lineas):
    texto = "".join(
        f'<text x="400" y="{330 + i * 30}" text-anchor="middle" font-family="Inter, DejaVu Sans, sans-serif" '
        f'font-size="20" fill="#CFE7EE">{l}</text>'
        for i, l in enumerate(lineas)
    )
    return f'''<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 {W} {H}" width="{W}" height="{H}">
<defs><linearGradient id="f" x1="0" y1="0" x2="0" y2="1">
<stop offset="0" stop-color="#001B3E"/><stop offset="1" stop-color="#004A7A"/></linearGradient></defs>
<rect width="{W}" height="{H}" fill="url(#f)"/>
<path d="M0,380 C200,350 300,410 500,385 C640,368 720,390 800,375 L800,440 L0,440 Z" fill="#00697A" opacity="0.6"/>
<svg x="340" y="60" width="120" height="120" viewBox="0 0 256 256">{LOGO_INNER}</svg>
<text x="400" y="260" text-anchor="middle" font-family="Inter, DejaVu Sans, sans-serif" font-size="34"
 font-weight="600" fill="#FFFFFF">{titulo}</text>
{texto}
</svg>'''


if __name__ == "__main__":
    DEST.mkdir(parents=True, exist_ok=True)
    for n, (t, ls) in enumerate(DIAPOSITIVAS, 1):
        (DEST / f"diapositiva-{n}.svg").write_text(diapositiva(t, ls))
    print(f"{len(DIAPOSITIVAS)} diapositivas en {DEST}")
