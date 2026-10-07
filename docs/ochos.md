# Ochos malditos

Mientras este poder está activo:

- Queda una lisa y una rayada con su aspecto original, elegidas al azar entre las que siguen en la mesa. Si un grupo ya no tiene bolas, no se crea ninguna.
- Las demás bolas de color se ven como la 8. Embocar cualquiera de estas negras hace perder a quien realizó el tiro, incluida la 8 original y también durante el saque.
- La blanca no cambia; embocarla sigue siendo falta.
- Embocar la visible de tu propio grupo revela otra de ese mismo grupo, si queda alguna y el efecto continúa. Con mesa abierta, se permite revelar el grupo de la visible embocada. Embocar la visible del rival no revela otra.
- Las caídas del mismo paso de física se registran antes de revelar otra bola: una negra que cae junto con la visible sigue siendo mortal.
- Los números originales se conservan para contar las bolas restantes y evaluar el primer contacto. El cambio especial de reglas es la derrota por embocar una negra del poder.
- Al desactivarse, todas las bolas que siguen en la mesa recuperan exactamente sus modelos y materiales. Las ya embocadas no reaparecen. La 8 original vuelve a las reglas normales.

El resultado se decide al terminar el tiro, conservando cómo era cada bola al caer aunque el poder ya haya vencido.

## Activación

El administrador incluye `TipoPoder.OCHOS` en el activador sorpresa y usa su duración aleatoria actual (uno, dos o tres tiros completos, sin contar el de recogida).

Para probarlo solo: instanciá `scenes/ochos.tscn` como hija de Sala, quitá temporalmente de Sala Powerups y los otros poderes individuales que respondan a Espacio, y ejecutá el juego. Espacio activa/desactiva Ochos. En esta prueba individual permanece hasta que lo apagues.

    godot --headless --path . --fixed-fps 60 --script res://tests/ochos_test.gd
