# Hoja de ruta de Ondalia OS

Aquí se apunta todo lo que sale al probar la distro y lo que queda por hacer.
Estados: **Hecho** (corregido en el código, entra en la próxima ISO), **Pendiente**, **Idea**.

## Fallos encontrados en las pruebas

| Fecha | Versión | Dónde | Problema | Estado |
| --- | --- | --- | --- | --- |
| 2026-11-20 | 0.1 | Arranque en vivo | Se queda en la consola `(initramfs)`: al regenerar el initrd se pierde la orden `boot=casper` | Hecho: se añade `boot=casper` al menú de arranque |
| 2026-11-20 | 0.1 | Menú de arranque (GRUB) | "gráficos básicos" se ve como "gr?ficos b?sicos": la fuente de GRUB no tiene tildes | Hecho: ahora dice "modo grafico seguro", sin tildes |
| 2026-11-20 | 0.1 | Menú de arranque (GRUB) | La entrada "OEM install (for manufacturers)" sale en inglés | Hecho: "Instalacion OEM (para fabricantes)" |
| 2026-11-20 | 0.1 | Menú de arranque (GRUB) | El texto de ayuda de abajo ("Use the ↑ and ↓ keys…") sale en inglés | Pendiente |
| 2026-11-20 | 0.1 | AutoFirma | Se instala la 1.8.3 en lugar de la 1.9 actual: la web oficial enlaza ambas | Pendiente |

## Próxima versión (0.2)

- [ ] Menú de arranque con aspecto de Ondalia: fondo azul, logo y tipografía con tildes (tema de GRUB)
- [ ] Texto de ayuda del menú de arranque en español
- [ ] Elegir siempre la versión más reciente de AutoFirma
- [ ] Revisar todo lo que salga al probar la 0.1 en VirtualBox y en un PC real

## Más adelante

- [ ] Asistente de bienvenida: "¿Vienes de Windows o de Mac?", modo claro u oscuro, apps recomendadas, Steam
- [ ] Lanzador de programas de Windows: doble clic en un .exe para abrirlo con Bottles
- [ ] Importador de certificados .p12/.pfx para Firefox y AutoFirma
- [ ] Centro de ayuda sin conexión, con guía de trámites online
- [ ] Estilo de Plasma propio: la muesca ondulada de la barra superior y etiquetas bajo los iconos del dock
- [ ] Volver a una instantánea desde el menú de arranque (grub-btrfs)
- [ ] Empaquetar los ajustes de Ondalia como paquete .deb propio, para que se actualicen con el sistema
- [ ] Elegir licencia del proyecto (sugerencia: GPL-3.0-or-later para el código y CC BY-SA 4.0 para el arte)

## Decisiones pendientes

- [ ] Correo: incluir Thunderbird o dejarlo en la tienda
- [ ] Nombres en el menú: por función ("Navegador") o por programa ("Firefox")
- [ ] Modo oscuro automático según la hora
- [ ] Antes de publicar: dominio, búsqueda en EUIPO para "Ondalia" y compatibilidad como funcionario
