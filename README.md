# Simply Pool

La distribución de la escena principal, las responsabilidades de cada script y los comandos de verificación actuales están en [Organización del proyecto](docs/estructura_proyecto.md).

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

## Física común de las bolas

La blanca y las bolas de color usan masa `1.0`, fricción `0.08`, rebote `0.48`, amortiguación lineal `0.04` y angular `0.1`. Subir la masa común desde `0.8` reduce un 20 % la velocidad inicial para el mismo impulso. Se mantiene la igualdad de masas para que los choques transmitan el avance de forma coherente. El paño absorbe el rebote vertical y las bandas conservan parte de la velocidad horizontal. Estos ajustes se aplican durante toda la partida.

La simulación trabaja a 120 pasos físicos por segundo. `scripts/fisica_bola.gd` añade resistencia al avance y al giro de rodadura únicamente cuando hay apoyo en una superficie estática horizontal. No detiene bolas en vuelo ni bloquea las caídas por troneras. El efecto lateral de la blanca y los poderes siguen activos.

El giro vertical se limita a 24 rad/s sobre el paño y se disipa por separado: el freno es suave mientras la bola avanza y aumenta al detenerse. Un giro exclusivamente vertical ya no impide cerrar el tiro después del reposo estable. El giro horizontal sigue contando, porque puede producir avance o retroceso; no se elimina al tocar otra bola. `tests/giro_residual_test.gd` verifica 16 casos de giro estático, efecto lateral y topspin/backspin con fuerza baja, media y alta. Los valores de frenado del giro están al principio de `scripts/fisica_bola.gd`; no cambian la potencia del taco ni la resistencia lineal del paño.

En el Inspector de `Sala`, `desaceleracion_rodadura = 0.2` controla el frenado base y `roce_velocidad = 0.6` añade pérdida de velocidad por encima de 2 unidades/s. Por debajo de ese umbral no actúa el freno adicional, para conservar los tiros finos. Aumentar cualquiera de estos valores acorta el recorrido; cambiarlos antes de iniciar la partida. El paño usa fricción `0.1` y `rough = true` para que su roce prevalezca sobre el de las bolas. Las bandas usan rebote `0.3`, que combinado con las bolas conserva aproximadamente el 78–83 % de la velocidad en los impactos probados. El límite vertical sigue ajustándose con `velocidad_vertical_maxima_color`, también para la blanca.

### Calibración del roce y referencias

Se tomó como referencia la distinción entre deslizamiento y rodadura explicada por [Dr. Dave: efectos del paño](https://drdavepoolinfo.com/FAQ/table/cloth-effects/), y su [análisis de recorridos con pérdidas en bandas](https://drdavepoolinfo.com/technical_proofs/new/TP_B-6.pdf). Ese análisis usa como ejemplos fricción de deslizamiento `0.2`, resistencia de rodadura `0.01` y restitución de banda `0.7`: un tiro fuerte real puede recorrer varias mesas. Los valores del juego se calibran para un paño más lento y una respuesta contenida; no son una reproducción exacta de esas mediciones ni usan la misma escala física. El freno dependiente de velocidad es una asistencia de jugabilidad. La selección de fricción entre materiales sigue la [documentación de Godot](https://docs.godotengine.org/en/stable/classes/class_physicsmaterial.html#class-physicsmaterial-property-rough).

En una prueba sin efecto ni otras bolas, desde el centro hacia una banda del extremo, el impulso `28` pasó de recorrer `43.44` unidades (4.43 largos, cinco rebotes) a `23.90` (2.44 largos, tres rebotes). Hacia una banda lateral pasó de `26.94` a `16.56` unidades. En la calibración previa a la corrección de contactos, los impulsos `0.5`, `6`, `12` y `28` recorrieron aproximadamente `0.28`, `6.01`, `14.29` y `23.90` unidades sobre el eje largo. Son recorridos medidos, no un límite artificial de rebotes: no se teletransporta ni se detiene una bola al alcanzar cierto número de bandas. `tests/recorrido_bandas_test.gd` reproduce la medición (`-- 0.6 28 x` o `-- 0.6 28 z`).

### Corrección de contactos y apertura del saque

La variación inicial del triángulo no solucionaba la concentración contra el fondo. Se compararon frecuencias, motores, materiales, separaciones y precisión de contactos. Se conserva Jolt a 120 pasos/s, con 32 iteraciones de velocidad y 8 de posición. Los márgenes quedan en `penetration_slop = 0.0005`, `speculative_contact_distance = 0.001`, `continuous_cd_movement_threshold = 0.1` y `continuous_cd_max_penetration = 0.01`, en la sección de Jolt de `project.godot`. La idea es evitar contactos anticipados y penetraciones grandes en relación con el radio de las bolas. Se aumentó la transmisión entre bolas y el retorno de las bandas sin reducir el roce del paño.

La validación final incluye 24 saques: ocho semillas de armado y tres ángulos (−0.01, 0 y +0.01 radianes), todos con impulso `28`. Se registraron entre 0 y 4 bolas de color cerca del fondo (`x < -3.8`), frente a las agrupaciones de 8–10 que aparecían antes. Los ocho saques centrados ocuparon entre 4 y 7 zonas de una grilla de 3 × 3. Todos alcanzaron el reposo antes de 8.1 segundos, sin salidas por encima de las bandas ni aumentos de energía fuera de tolerancia. Los golpes descentrados todavía pueden dejar grupos; no se añaden impulsos aleatorios ni se recolocan bolas después del golpe.

`tests/fisica_benchmark.gd -- apertura 0 28` comprueba además que no haya más de cuatro bolas cerca del fondo y que el saque centrado ocupe al menos cuatro zonas. Las pruebas de CPU, poderes, efectos, choques, tiros suaves y reposo pasan, al igual que 120 impactos contra las seis bandas. Después de esta corrección, el tiro fuerte aislado desde el centro hacia una banda del extremo recorre 25.49 unidades (2.60 largos, tres rebotes), por debajo de los 4.43 largos anteriores. Para aplicar estos cambios hay que detener y volver a ejecutar el proyecto: los ajustes del motor no se actualizan en una partida abierta.


Los resultados están en `tests/resultados_fisica.json`. Para repetir una comparación, ejecutar Godot con `--headless --path . --fixed-fps 120 --script tests/fisica_benchmark.gd -- actual 0 28`. Cambiar `actual` por `anterior` reproduce las masas, materiales y frecuencia previos; los últimos argumentos son ángulo e impulso. El banco aísla la mesa de las reglas para medir el movimiento. Las pruebas `choques_bolas_test.gd` y `bandas_test.gd -- --solo-bandas` verifican ocho impactos entre bolas y 120 impactos en las seis bandas, con retención aproximada del 78–83 %. Las pruebas de reposo usan duraciones equivalentes aunque cambie la frecuencia de física.

## Variación discreta del triángulo inicial

`scripts/armado_triangulo.gd` parte de las posiciones manuales de la escena. Al cargar cada partida añade un giro global de hasta ±0.4 grados y diferencias individuales de hasta 0.0015 unidades por eje horizontal. Conserva las alturas, el orden de las bolas, la negra en el centro y la forma general. Antes de aceptar cada posición comprueba la separación entre las esferas; no añade fuerzas ni modifica posiciones después del saque.

En el Inspector de `Sala`, `variacion_triangulo = 0.0015` y `angulo_triangulo = 0.4` son los valores por defecto; se respetan las variaciones `0.005` y `1.0` que ya estaban guardadas en tu escena. `separacion_triangulo = 1.015` expande el armado manual solo un 1.5 % alrededor de la punta para dar margen a los contactos. La silueta sigue siendo triangular. Para recuperar exactamente las posiciones manuales, poner ambas variaciones en cero y la separación en `1.0`. La prueba `tests/triangulo_test.gd` verifica 500 armados sin solapamientos, sin impulsos y estables antes del golpe; limita el cambio según los parámetros del Inspector.

Ocho armados distintos con el mismo golpe frontal produjeron resultados diferentes. La variación reduce la repetición pero no garantiza una apertura mejor: en esa muestra siguieron apareciendo agrupaciones al fondo. Esto concuerda con que los huecos cambian la transmisión del choque y no siempre favorecen la apertura; la referencia de [armado ajustado](https://drdavepoolinfo.com/faq/break/racking/tight/) recomienda minimizar huecos para un saque eficaz. No se aplican impulsos aleatorios para ocultar ese comportamiento. El banco de física permite fijar una semilla como noveno argumento de usuario (después de perfil, ángulo, fuerza, rodadura, rebote, masa, amortiguación y roce) para reproducir una variación.

## Animación del taco de la CPU

La CPU coloca el taco detrás del centro de la blanca, retrocede durante `0.45` segundos, espera `0.12` y avanza durante `0.18`. La longitud del retroceso depende de la fuerza elegida. El impulso y el sonido se aplican una sola vez, cuando la punta llega a la blanca. El modelo utiliza la inclinación visual existente para salvar obstáculos; su cuerpo no añade empujes físicos. La pausa congela la animación y continúa desde ese punto, y terminar la partida cancela el golpe pendiente. `tests/cpu_taco_test.gd` cubre el recorrido, el impulso único, la pausa y la cancelación.
