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
* **Golpear:** Haz clic izquierdo para elegir el punto de impacto sobre la blanca y mueve el ratón para impulsar el taco. Cuanto más recorrido continuo hacia adelante hagas, mayor será la fuerza. Si frenás durante 0,16 segundos o retrocedés, el recorrido vuelve a contarse desde esa posición. Para un tiro suave, acercá el taco, frená y completá el golpe desde cerca.
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
