# Simply Pool

Simply Pool es un juego de billar 3D para dos jugadores locales que combina precisión, efectos sobre la bola blanca y poderes aleatorios. Desarrollado por Tomás González y Nahuel Curbelo para la Universidad de Montevideo.

## 🛠️ Acceso y prueba de la versión Alpha

* **Repositorio:** https://github.com/TOMYKS/pool2
* **Versión utilizada:** Godot 4.7.2 stable
* **Configuración:** Forward Plus, Direct3D 12 y física Jolt

### Pasos de ejecución
1. Clonar o descargar el repositorio e importar el archivo `project.godot` en el editor de Godot.
2. Verificar que la escena "Sala" tenga una instancia de `scenes/powerups.tscn` como hija directa, con el nombre exacto "Powerups", para que el activador sorpresa funcione correctamente.
3. Ejecutar el proyecto presionando `F5`. La escena principal es "Sala" y el jugador 1 comienza realizando el saque.

## 🎮 Controles

* **Apuntar:** Mueve la cámara con las flechas del teclado o arrastrando el ratón con el botón derecho.
* **Zoom:** Ajusta el acercamiento con la rueda del ratón.
* **Golpear:** Haz clic izquierdo para elegir el punto de impacto sobre la blanca y mueve el ratón para impulsar el taco. La velocidad de tu movimiento determina la fuerza del tiro.
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
* **Ochos malditos:** Transforma gran parte de las bolas en bolas 8 negras; tocar primero una falsa 8 es falta, y embocarla puede significar la derrota.

## 🐛 Bugs Conocidos

1. **Pelotas salen a pasear:** A veces pasa que si hay dos o más pelotas colisionando y girando juntas, giran por mucho más tiempo y más distancia de lo que deberían.
2. **Rebotes secos en las bandas:** Cuando las pelotas chocan con la pared a una velocidad baja puede que en lugar de rebotar se peguen a la pared y sigan de largo.
3. **Pelotas saltan de la mesa:** Nunca lo logramos replicar, pero en algunos tiros puede pasar que una bola salga de la mesa. Sigo sin entender qué lo causa, pero planeamos dejarlo ya que agrega al caos y sorpresa.
4. **Pelotas deslizan:** En el poder de extra rebote las pelotas puede que terminen deslizando por la mesa como si fuera hielo al girar poco en su propio eje.
5. **Pelotas Fantasma:** Puede pasar que una bola quede dentro de otra al terminar el poder de pelotas fantasma, pero al golpearlas se separan de forma coherente y funciona de forma correcta.
6. **Límites al colocar:** Todavía hay zonas donde deberías poder colocar la pelota blanca al tenerla en la mano, pero el juego no te lo permite.