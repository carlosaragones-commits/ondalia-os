# Ondalia OS

**Fluidez. Ligereza. Elegancia.**

Ondalia OS es una distribución Linux para personas que vienen de Windows o de Mac y no quieren pelearse con el ordenador. Parte de Kubuntu 26.04 LTS y le añade una identidad propia, Firefox sin Snap, códecs, Flatpak, instantáneas del sistema y todo lo necesario para la administración electrónica española (DNIe, certificados FNMT y AutoFirma).

> Estado: **versión 0.1 de pruebas**. No la uses todavía en un equipo con datos importantes.

## Qué lleva esta versión

| Área | Incluido |
| --- | --- |
| Base | Kubuntu 26.04 LTS (KDE Plasma 6.6, Linux 7.0, Wayland), con soporte hasta abril de 2029 |
| Sin Snap | Snap eliminado y bloqueado; Firefox en .deb desde el repositorio oficial de Mozilla |
| Apps | Firefox, LibreOffice, VLC, Dolphin, Okular, Gwenview, Spectacle, KWrite, Ark, KCalc, KDE Connect, Skanpage |
| Tienda | Discover con Flatpak y Flathub activados |
| Códecs y fuentes | MP3, H.264, H.265, AAC, aceleración de vídeo; fuentes compatibles con documentos de Office |
| España | Español, teclado español y hora de Madrid por defecto; DNIe (OpenSC) cargado en Firefox; AutoFirma |
| Instantáneas | Btrfs por defecto en el instalador y Snapper con instantánea antes de cada actualización |
| Identidad | Logo, fondos claro y oscuro, esquemas de color, arranque (Plymouth), inicio de sesión, instalador y distribución de escritorio (barra arriba y dock flotante abajo) |

## Cómo compilar la ISO (sin tener Linux)

La forma más cómoda es que GitHub la compile en la nube:

1. Crea un repositorio nuevo en GitHub (por ejemplo `ondalia-os`) y sube todo el contenido de esta carpeta.
2. Entra en la pestaña **Actions** del repositorio y acepta activar los workflows si te lo pide.
3. Elige **Compilar ISO de Ondalia** y pulsa **Run workflow**.
4. Espera entre 60 y 120 minutos. Al terminar, abre la ejecución y descarga el artefacto **ondalia-iso** (un ZIP que contiene la ISO y su suma SHA256).

Para publicar una versión con la ISO adjunta, crea una etiqueta que empiece por `v` (por ejemplo `v0.1`). GitHub limita cada archivo a 2 GB, así que la ISO se publica partida en trozos, con instrucciones para unirlos.

## Cómo compilar en tu propio equipo

Necesitas Ubuntu, Debian o derivada, 25 GB libres y conexión a internet:

```bash
sudo apt install wget xorriso squashfs-tools rsync librsvg2-bin
sudo ./build.sh
```

La ISO queda en `out/`. Variables útiles: `VERSION=0.2`, `KEEP_WORK=1` (conserva la carpeta de trabajo para depurar), `SQUASHFS_COMP=xz` (ISO más pequeña, compilación más lenta) y `AUTOFIRMA_REQUIRED=1` (falla si no se puede descargar AutoFirma).

## Cómo probarla

**En VirtualBox:** crea una máquina "Ubuntu (64-bit)" con 4 GB de RAM, 2 núcleos y 40 GB de disco; en *Sistema → Placa base* activa **EFI**; en *Pantalla* sube la memoria de vídeo a 128 MB y activa la aceleración 3D. Monta la ISO y arranca.

**En un PC real:** graba la ISO en un USB de 8 GB o más con [Ventoy](https://www.ventoy.net) o balenaEtcher y arranca desde él. Puedes probarla sin instalar nada.

Qué revisar en cada versión:

- [ ] Arranca con la ola sobre azul (Plymouth) y el menú dice "Ondalia OS"
- [ ] Escritorio con barra fina arriba, dock flotante abajo y fondo de olas
- [ ] Todo en español y con teclado español
- [ ] Firefox abre y en *Ajustes → Privacidad → Dispositivos de seguridad* aparece "DNIe y tarjetas (OpenSC)"
- [ ] AutoFirma aparece en el menú de aplicaciones
- [ ] Discover muestra apps de Flathub
- [ ] Un vídeo MP4 se reproduce en VLC
- [ ] El instalador muestra la marca de Ondalia y propone Btrfs
- [ ] Tras instalar, `sudo snapper list` muestra instantáneas después de una actualización

## Estructura del proyecto

```
build.sh                        Script principal de compilación
config/ondalia.conf             Nombre, versión, ISO base, idioma
config/packages/install.list    Paquetes que se añaden
config/packages/remove.list     Paquetes que se quitan
config/hooks/*.chroot           Pasos de personalización, en orden
config/includes.chroot/         Archivos que se copian tal cual al sistema
branding/                       Logo y fondos en SVG (fuente de las imágenes)
tools/                          Generadores de fondos y esquemas de color
.github/workflows/              Compilación automática en GitHub
```

Para añadir o quitar programas basta con editar las dos listas de `config/packages/`.

## Próximos pasos

- Asistente de bienvenida ("¿Vienes de Windows o de Mac?", modo claro u oscuro, apps recomendadas, Steam)
- Lanzador de programas de Windows: doble clic en un .exe para abrirlo con Bottles
- Importador de certificados .p12/.pfx para Firefox y AutoFirma
- Centro de ayuda sin conexión, con guía de trámites online
- Estilo de Plasma propio: la muesca ondulada de la barra superior y etiquetas bajo los iconos del dock
- Volver a una instantánea desde el menú de arranque (grub-btrfs)
- Empaquetar los ajustes de Ondalia como paquete .deb propio, para que se actualicen con el sistema
- Elegir licencia del proyecto (sugerencia: GPL-3.0-or-later para el código y CC BY-SA 4.0 para el arte)
