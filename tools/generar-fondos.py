"""Genera los fondos de pantalla de Ondalia (claro y oscuro) como SVG.

Uso: python3 tools/generar-fondos.py
Escribe branding/wallpaper.svg y branding/wallpaper-dark.svg.
build.sh los convierte a PNG en varias resoluciones.
"""
import math
from pathlib import Path

W, H = 1920, 1080
BRANDING = Path(__file__).resolve().parent.parent / "branding"


def fondo(oscuro: bool) -> str:
    if oscuro:
        cielo = [("0", "#000C1F"), ("0.55", "#001B3E"), ("0.8", "#0B2F55"), ("1", "#14466B")]
        brillo, brillo_op = "#FF7043", 0.18
        capas = [("#002F6C", 0.95), ("#004A7A", 0.9), ("#00697A", 0.85), ("#007A7A", 0.9)]
        espuma = "#4DB6AC"
    else:
        cielo = [("0", "#0A2A5E"), ("0.45", "#2F5E8E"), ("0.72", "#E9A27A"), ("1", "#FFB38A")]
        brillo, brillo_op = "#FF7043", 0.55
        capas = [("#0B3A73", 0.92), ("#005F8A", 0.9), ("#008B9A", 0.9), ("#00A3A8", 0.95)]
        espuma = "#BFF3F0"

    stops = "".join(f'<stop offset="{o}" stop-color="{c}"/>' for o, c in cielo)
    out = [
        f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 {W} {H}" width="{W}" height="{H}">',
        "<defs>",
        f'<linearGradient id="cielo" x1="0" y1="0" x2="0" y2="1">{stops}</linearGradient>',
        f'<radialGradient id="sol" cx="0.68" cy="0.62" r="0.45">'
        f'<stop offset="0" stop-color="{brillo}" stop-opacity="{brillo_op}"/>'
        f'<stop offset="1" stop-color="{brillo}" stop-opacity="0"/></radialGradient>',
        "</defs>",
        f'<rect width="{W}" height="{H}" fill="url(#cielo)"/>',
        f'<rect width="{W}" height="{H}" fill="url(#sol)"/>',
    ]

    base = [640, 720, 800, 880]
    amp = [38, 46, 54, 62]
    freq = [1.3, 1.0, 0.8, 0.65]
    fase = [0.3, 1.7, 3.1, 4.4]
    for k, (color, opacidad) in enumerate(capas):
        puntos = []
        for x in range(0, W + 1, 24):
            t = x / W * 2 * math.pi
            y = (base[k] + amp[k] * math.sin(freq[k] * t + fase[k])
                 + amp[k] * 0.35 * math.sin(2.7 * freq[k] * t + fase[k] * 1.3))
            puntos.append(f"{x},{y:.1f}")
        primera_y = puntos[0].split(",")[1]
        d = f"M0,{primera_y} L" + " L".join(puntos) + f" L{W},{H} L0,{H} Z"
        out.append(f'<path d="{d}" fill="{color}" fill-opacity="{opacidad}"/>')
        cresta = "M" + " L".join(puntos)
        out.append(
            f'<path d="{cresta}" fill="none" stroke="{espuma}" '
            f'stroke-opacity="{0.18 + 0.06 * k:.2f}" stroke-width="{1.5 + k * 0.5}"/>'
        )
    out.append("</svg>")
    return "\n".join(out)


if __name__ == "__main__":
    (BRANDING / "wallpaper.svg").write_text(fondo(False))
    (BRANDING / "wallpaper-dark.svg").write_text(fondo(True))
    print("Fondos generados en", BRANDING)
