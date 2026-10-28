# Simply Pool

Simply Pool es un juego de billar 3D para dos jugadores locales que combina precisión, efectos sobre la bola blanca y poderes aleatorios. Desarrollado por Tomás González y Nahuel Curbelo para la Universidad de Montevideo.

## 🛠️ Acceso y prueba de la versión Alpha

* **Repositorio:** https://github.com/TOMYKS/pool2
* **Versión utilizada:** Godot 4.7.2 stable
* **Configuración:** Forward Plus, Direct3D 12 y física Jolt

### Pasos de ejecución
1. Clonar o descargar el repositorio e importar el archivo `project.godot` en el editor de Godot.
2. Verificar que la escena "Sala" tenga una instancia de `scenes/powerups.tscn` como hija directa, con el nombre exacto "Powerups", para que el activador sorpresa funcione correctamente.
3. Ejecutar el proyecto presionando `F5`. Antes de cada partida, elegir si el jugador 2 es una persona local o la CPU. El jugador 1 comienza realizando el saque.

### CPU Basico

El pop-up solo permite elegir persona o CPU. La CPU tiene su propia escena en `scenes/cpu/cpu.tscn` y su lógica en `scenes/cpu/cpu.gd`. Los ajustes se modifican al principio de ese script: `probabilidad_error`, `error_angulo_grados`, `error_fuerza` y `demora`. El script incluye ejemplos de valores para distintas dificultades; no hay controles de dificultad dentro del juego.

La CPU elige la bola válida más cercana e intenta empujarla hacia la tronera más cercana. Tras una falta coloca la blanca detrás del objetivo, con una pequeña variación controlada por `distancia_colocacion` y `variacion_colocacion`. Busca un lugar libre y prioriza una línea de tiro despejada. Durante todo su turno se usa la cámara estática de la mesa; al volver el turno humano se recupera la cámara de la bola. No calcula rebotes ni simula trayectorias: incluso sin error aleatorio puede fallar.

## 🎮 Controles

* **Apuntar:** Mueve la cámara con las flechas del teclado o arrastrando el ratón con el botón derecho.
* **Zoom:** Ajusta el acercamiento con la rueda del ratón.
* **Golpear:** Mantené el clic izquierdo sobre la blanca para elegir el punto de impacto. Primero retirás el taco, aunque sea mínimamente, y después avanzás para golpear: avanzar sin ese retroceso no dispara. Cuanto más recorrido continuo hacia adelante hagas, mayor será la fuerza. Si frenás durante 0,16 segundos o retrocedés, el recorrido vuelve a contarse desde esa posición. Para un tiro suave, acercá el taco, frená y completá el golpe desde cerca. Soltar el clic cancela la selección y oculta el taco y el punto; empezar a girar la cámara también los oculta.
* **Indicador de potencia:** La marca sobre la blanca pasa de verde (suave) a amarillo (medio) y rojo (fuerte). Anticipa la fuerza al completar el avance desde la posición del taco y tiene en cuenta el punto de impacto. Al frenar cerca de la bola, vuelve a indicar un golpe suave. El recorrido máximo del taco es de 1,35 unidades.
* **Colocar blanca (Bola en mano):** Tras una falta, haz clic en un lugar libre del paño para reubicar la bola blanca.
* **Habilitar/Deshabilitar Poderes:** Presiona la barra espaciadora (`Espacio`).

## 🎱 Reglas Básicas

* **Formato:** Dos jugadores participan en el mismo equipo localmente.
* **Grupos:** Los grupos (Lisas del 1 al 7 y Rayadas del 9 al 15) se asignan automáticamente tras la primera embocada válida posterior al saque.
* **Victoria:** Ganas al embocar todas las bolas de tu grupo y, posteriormente, embocar la bola 8 (negra) de forma legal.
* **Derrota:** Pierdes automáticamente si embocas la bola 8 antes de tiempo, si la sacas de la mesa, si la embocas cometiendo una falta, o si la bola 8 y la blanca caen en el mismo tiro.
* **Faltas:** Tocar primero una bola del rival, no tocar ninguna bola, embocar la blanca o sacar bolas de la mesa constituye una falta. El oponente recibe "bola en mano".

## ⚡ Sistema de Poderes

El juego no es el típico simulador de pool. Al presionar Espacio, se habilita el sistema de poderes. Pasa la bola blanca por encima del activador (una bola flotante con corona y signo de pregunta) para recoger y sortear un poder sorpresa. Los efectos duran de 1 a 3 tiros.

* **Bolas pesadas:** Aumenta la masa de las bolas de color y altera su respuesta a los impactos.
* **Rebote extra:** Cambia las propiedades físicas para aumentar exageradamente los rebotes.
* **Bolas grandes:** Aumenta el tamaño de las bolas de color.
* **Pared:** Levanta una barrera que divide la mesa y restringe las trayectorias.
* **Bolas invisibles:** Oculta temporalmente los modelos de las bolas de color, dejando solo sus sombras visibles.
* **Bolas falsas:** Permite que ciertas bolas atraviesen a otras manteniendo la interacción con la mesa.
* **Troneras bloqueadas:** Cierra entradas de forma aleatoria, obligando a recalcular los tiros.
* **Ochos malditos:** Transforma todas las bolas en bolas 8 negras, excepto 1 para cada jugador.

## Ajustes de cámara y potencia

En el nodo raíz `Sala`, el Inspector expone los ajustes del script `scripts/main.gd`:

* `cue_max_pullback = 1.35`: recorrido máximo hacia atrás. Subirlo permite dosificar la potencia en una distancia mayor.
* `cue_mouse_travel = 0.01`: distancia del taco por píxel de movimiento. Bajarlo requiere más movimiento del ratón para el mismo recorrido.
* `cue_max_force = 30.0`: potencia máxima.
* `velocidad_vertical_maxima_color = 1.0`: velocidad ascendente máxima de todas las bolas, incluida la blanca, en metros por segundo. Conserva su nombre anterior para respetar los ajustes guardados; `Sala` actualmente guarda `0.8`. Ver los valores de prueba debajo.
* `saque_max_force = 24.0`: fuerza máxima exclusiva del saque. Suaviza únicamente el tramo alto de potencia; `0` desactiva este ajuste.
* `camera_transition_seconds = 0.65`: duración del cambio de cámara. Probar 1.0–1.2 para un viaje más pausado; 0 desactiva el tween.

`cambiar_camara(destino)` crea una cámara auxiliar llamada `CamaraTransicion` y la mueve desde la vista que se está mostrando hasta la cámara de destino. Interpola posición, orientación y campo de visión, con una curva `TRANS_SINE` / `EASE_IN_OUT`: acelera y frena suavemente. Al llegar, activa la cámara de destino. Así ya se obtiene un movimiento recto como una cámara en cable, tanto al pasar a `CameraMesa` como al regresar al apuntado. La posición y rotación de `CameraMesa` en `scenes/sala.tscn` determinan el extremo del viaje; las cámaras originales conservan sus posiciones. Para velocidad constante se puede usar `TRANS_LINEAR`. El trayecto actual no esquiva obstáculos.

## Ajustar los saltos de las bolas

Los contactos de la física 3D pueden convertir parte del movimiento horizontal en ascenso: por ejemplo, un impacto contra una arista o entre bolas con centros a distintas alturas. Esto último ocurre con el poder de bolas grandes. No se ha aislado un único choque que explique todas las salidas; el límite es una protección contra ascensos excesivos.

Seleccioná el nodo raíz `Sala` y ajustá `velocidad_vertical_maxima_color` en el Inspector antes de ejecutar la partida. Se copia a todas las bolas, incluida la blanca, al iniciar. También podés cambiar su valor por defecto al comienzo de `scripts/main.gd` si no hay un valor guardado en el Inspector.

| Valor | Resultado para probar |
| --- | --- |
| `0.7` | Protección más fuerte; permite menos ascenso. |
| `1.0` | Valor inicial moderado. |
| `1.5` | Permite saltos mayores. |
| `0.0` | Desactiva el límite para comparar con la física anterior. |

Con gravedad normal, 1 m/s equivale aproximadamente a 5 cm de ascenso libre desde el punto en que se aplica el límite. No es un techo de altura: los contactos continuos pueden seguir elevando una bola. El límite se aplica en la integración física únicamente a la componente Y positiva. No cambia directamente X/Z, el giro, las masas, los materiales ni la potencia, y deja libres las caídas en troneras. Al reducir saltos, sí cambia la resolución de los choques que antes levantaban las bolas: ese es el efecto buscado. Probá el mismo saque y tiros contra bandas con y sin poderes, bajando el valor en pasos de `0.1` si todavía hay salidas frecuentes.

El taco ahora usa una consulta de colisión para detectar el contacto y aplica el impulso del golpe por código. Su cuerpo no empuja las bolas por separado ni queda colisionando cuando está oculto.

## Ajustar la concentración de bolas tras el saque

Para moderar el empuje hacia el fondo sin cambiar los tiros posteriores, `saque_max_force` comprime progresivamente la fuerza que supera el 70 % de `cue_max_force`. Por debajo de ese umbral no cambia nada. Con los valores actuales, la fuerza hasta `20.3` se conserva y el extremo de `29` pasa a `24`. El avance del taco sigue aumentando la potencia en todo su recorrido, sin una meseta al llegar al máximo. El indicador anticipa esta fuerza ajustada y el giro utiliza la misma potencia base. El ajuste también se consulta al disparar la CPU; sus tiros habituales quedan por debajo del umbral actual.

Solo se aplica mientras las reglas indican saque. No modifica las masas, el rozamiento, las bandas ni los tiros posteriores. No agrega direcciones aleatorias ni recoloca bolas. Para afinarlo, probá `23`, `24` o `25` en el Inspector de `Sala`; `0` permite comparar con la fuerza anterior. La distribución sigue dependiendo del ángulo y del punto de impacto: el ajuste reduce la tendencia, no garantiza que desaparezcan las agrupaciones.

La comparación aislada de tres ángulos (frontal y ±0.04 radianes), con límite vertical `0.8` y sin poderes, dio 23 de 45 bolas de color cerca de una banda con fuerza `24`, frente a 28 con fuerza `29`. Se contó como cerca de banda `abs(x) > 3.8` o `abs(z) > 1.8`, a los 20 segundos. Es una muestra pequeña para orientar el ajuste, no una garantía estadística. `tests/saque_distribucion_test.gd` permite repetir una simulación por proceso pasando fuerza y ángulo después de `--`; `tests/golpe_saltos_test.gd` verifica el límite de ambas clases de bola y que la potencia general se conserve fuera del saque.
