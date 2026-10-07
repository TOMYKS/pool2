# Poder: troneras bloqueadas

El activador sorpresa incluye `TipoPoder.TRONERAS`. Al recogerlo sortea, con la misma probabilidad, uno de estos patrones:

- Un lado completo: las tres de un lateral largo o las dos de un extremo.
- Una combinación de una a cinco troneras distintas.
- Las seis troneras.

Las barreras violetas y doradas cierran las entradas y usan el mismo material físico que las bandas. Si una bola ocupa la entrada al activarse, esa barrera espera a que quede libre. Las troneras no elegidas siguen funcionando normalmente.

La duración usa el sorteo actual del administrador (uno, dos o tres tiros completos, sin descontar el de recogida). Al vencer, se quitan las barreras antes de resolver el tiro; el juego espera cualquier movimiento o caída. Apagar el sistema con Espacio también las quita.

## Prueba directa

Para probarlo sin esperar el sorteo, instanciá `scenes/troneras.tscn` como hija de Sala y quitá temporalmente la instancia Powerups y otros poderes que usen Espacio. Ejecutá Sala y usá Espacio para activar/desactivar. Cada activación vuelve a sortear. El campo **Patron** del Inspector permite forzar **Un lado**, **Mezcla** o **Todas**; normalmente dejalo en **Aleatorio**.

Con Powerups presente no hace falta agregar esta escena: el administrador la crea y controla automáticamente.

Las posiciones de las seis barreras en `scripts/troneras.gd` corresponden a la mesa actual. Si cambia la geometría de la mesa, hay que ajustarlas.

Prueba automática de selección, cierre seguro, duración y colisiones reales de las seis entradas:

    godot --headless --path . --fixed-fps 60 --script res://tests/troneras_test.gd
