# Acabado de las bolas

Se conservan los atlas originales en assets/model2. Las copias en
assets/bolas_sin_costuras corrigen exclusivamente el margen de las islas UV.

- Más LOD: descartado; no resolvía las uniones de textura.
- Sin mipmaps: eliminaba las uniones, pero generaba granulado a distancia.
- Antialiasing global: no corrige el fondo negro que entra en los mipmaps.
- Desenfoque global: perjudica números, HUD y detalles.
- Solución elegida: margen de color de 32 texeles, reparación de 4 texeles
  contaminados del borde, mipmaps y filtrado lineal. Importación sin pérdida.

No se cambian las normales, la rugosidad, las luces, la geometría ni la física.
El procesamiento conserva los píxeles interiores y comprueba que los márgenes
realmente cambien. Solo rellena negro conectado al exterior; no borra números.

Para regenerar: ejecutar tools/generar_margen_bolas.py con Python, Pillow y
NumPy, y reimportar en Godot. La lista de fuentes está en tools/bolas_texturas.json.
Las texturas se precargan para incluirlas en la exportación y se aplican también
al material de la 8 reutilizado por los poderes.

Coste: más memoria de textura que la compresión VRAM; no se añaden shaders ni
trabajo de procesamiento de imágenes durante la partida.

Comparación renderizada en docs/comparacion_acabado_bolas.png:
izquierda original, centro sin mipmaps, derecha margen corregido con mipmaps.
La comparación aislada usa Compatibility; el proyecto mantiene Forward Plus.
Verificación de integración: godot --headless --path . --script res://tools/verificar_materiales_bolas.gd
