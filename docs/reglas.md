# Pool arcade: dos jugadores locales

- Empieza el jugador 1. En el saque se debe embocar una bola o llevar al menos cuatro bolas de color distintas a banda; de lo contrario, el rival recibe bola en mano.
- La 8 embocada en el saque reinicia toda la partida, incluso si también cae la blanca.
- El saque deja la mesa abierta. El primer tiro válido posterior que emboca asigna lisas (1–7) y rayadas (9–15). Si entran ambos grupos, se asigna el de la primera bola embocada.
- Una embocada propia válida conserva el turno. Sin embocadas propias pasa al rival. Las bolas del rival embocadas permanecen fuera.
- La blanca debe tocar primero una bola propia (o la 8 cuando ya se terminó el grupo). En mesa abierta puede tocar primero cualquier bola de color excepto la 8.
- Después del primer contacto tiene que entrar una bola o alguna bola tocar una banda. La pared del power-up cuenta como banda.
- Blanca embocada, bolas fuera de la mesa, primer contacto incorrecto y tiros sin contacto válido son faltas. El rival recibe bola en mano.
- Bola en mano conserva la cámara general. La guía verde indica una posición válida y la roja una inválida. Clic izquierdo coloca la blanca sin superponer bolas, paredes ni troneras y vuelve a la cámara de apuntado. Colocarla no recoge activadores.
- Se gana metiendo legalmente la 8 en cualquier tronera cuando el grupo propio ya estaba terminado al comenzar ese tiro. Meterla antes, sacarla o embocarla con falta pierde la partida.
- La pantalla muestra turno, grupos, bolas restantes y resultado. Al terminar aparece el botón Nueva partida.

## Implementación

scripts/reglas_pool.gd resuelve reglas sin depender de escenas.
scripts/partida.gd registra contactos y caídas, coloca la blanca y actualiza el HUD.
El número se toma de la malla de cada bola para respetar su aspecto, incluso cuando el nombre del nodo no coincide.
Los límites del paño y las seis zonas de tronera corresponden a la geometría actual de mesa.tscn; deben actualizarse si se cambia la mesa.

## Pruebas

Desde la carpeta del proyecto, usando el ejecutable de Godot:

    godot --headless --path . --script res://tests/reglas_pool_test.gd
    godot --headless --path . --script res://tests/partida_test.gd
    godot --headless --path . --script res://tests/powerups_test.gd
