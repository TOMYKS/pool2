extends VBoxContainer

const PODERES := [
	["pesadas", "Bolas pesadas", "Más peso, otra respuesta", "Las bolas de color ganan masa. Tené en cuenta su nueva respuesta al elegir la potencia."],
	["rebote", "Rebote extra", "La mesa se vuelve impredecible", "Las bolas de color rebotan mucho más. Cuidado con los tiros fuertes."],
	["grandes", "Bolas grandes", "Más tamaño, menos espacio", "Las bolas de color crecen. Es más fácil tocarlas, pero más difícil hacerlas pasar entre otras bolas o por las troneras."],
	["pared", "Pared", "Una barrera cambia la mesa", "Aparece una pared que rebota las bolas. Jugá dentro del sector en el que quedó la blanca."],
	["invisibles", "Bolas invisibles", "Seguí las sombras", "Las bolas de color dejan de verse, pero siguen ahí. Sus sombras ayudan a encontrarlas."],
	["fantasmas", "Bolas falsas", "No todo choque es un choque", "Algunas bolas pueden atravesar otras. Siguen interactuando con la mesa."],
	["troneras", "Troneras bloqueadas", "Buscá una entrada libre", "Se tapan troneras al azar: un lado, algunas o todas. Las tapas rebotan las bolas hasta que termine el efecto."],
	["ochos", "Ochos malditos", "Elegí bien tu objetivo", "Solo queda una bola visible de cada grupo. Embocar la propia revela otra mientras dure el poder.

Si aún te quedan bolas: tocar primero un falso 8 es falta y embocar un 8 pierde.

Si ya ibas por la negra: embocar cualquier 8, incluso uno falso, gana si el tiro es legal."]
]
var pagina: VBoxContainer
var indice := 0
var seleccion := 0
var pestanas: Array[Button] = []

func _ready() -> void:
	add_theme_constant_override("separation", 16)
	var fila := HBoxContainer.new()
	add_child(fila)
	for nombre in ["Controles", "Reglas", "Poderes"]:
		var b := Button.new()
		b.text = nombre
		b.toggle_mode = true
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var numero := pestanas.size()
		b.pressed.connect(func(): mostrar(numero))
		fila.add_child(b)
		pestanas.append(b)
	pagina = VBoxContainer.new()
	pagina.add_theme_constant_override("separation", 12)
	add_child(pagina)
	mostrar(0)

func nota(titulo: String, detalle: String) -> void:
	var panel := PanelContainer.new()
	var estilo := StyleBoxFlat.new()
	estilo.bg_color = Color(0.03, 0.10, 0.13, 0.9)
	estilo.set_corner_radius_all(12)
	estilo.content_margin_left = 18
	estilo.content_margin_right = 18
	estilo.content_margin_top = 14
	estilo.content_margin_bottom = 14
	panel.add_theme_stylebox_override("panel", estilo)
	pagina.add_child(panel)
	var caja := VBoxContainer.new()
	caja.add_theme_constant_override("separation", 7)
	panel.add_child(caja)
	var encabezado := Label.new()
	encabezado.text = titulo
	encabezado.add_theme_color_override("font_color", Color("#e4c58a"))
	caja.add_child(encabezado)
	var texto := Label.new()
	texto.text = detalle
	texto.custom_minimum_size.x = 460
	texto.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	texto.add_theme_font_size_override("font_size", 18)
	caja.add_child(texto)

func mostrar(numero: int) -> void:
	seleccion = numero
	for i in range(pestanas.size()):
		pestanas[i].button_pressed = i == numero
	for hijo in pagina.get_children():
		pagina.remove_child(hijo)
		hijo.queue_free()
	match numero:
		0:
			nota("1 · Apuntá", "Flechas o clic derecho + arrastrar: girar la cámara.
Rueda del ratón: acercar o alejar.")
			nota("2 · Prepará el golpe", "Mantené clic izquierdo sobre la blanca y retirá el taco. Elegí el centro para un golpe recto o un borde para agregar efecto.")
			nota("3 · Avanzá y golpeá", "Más recorrido continuo = más fuerza.
La marca pasa de verde a amarillo y rojo.
Frenar o retroceder reinicia la potencia; soltar cancela.")
			nota("A mano", "Escape: abrir el menú de pausa.
Bola en mano: clic en un lugar libre del paño.")
		1:
			nota("Tu objetivo", "Embocá tu grupo: lisas 1–7 o rayadas 9–15.
Después, la negra. Embocar una propia conserva el turno.")
			nota("El saque y los grupos", "En el saque debe entrar una bola o llegar cuatro bolas de color a banda. Si entra la negra, se reinicia.
La primera embocada legal posterior asigna los grupos.")
			nota("Falta → blanca en mano para el rival", "No tocar ninguna bola, tocar primero una rival, embocar la blanca o sacar bolas de la mesa.
No es obligatorio tocar banda después del contacto.")
			nota("La negra decide", "Primero terminá tu grupo en un tiro anterior.
Podés embocarla en cualquier tronera, sin anunciarla.
Negra antes de tiempo, fuera de la mesa o con falta: perdés. Negra + blanca también pierde.")
		2:
			mostrar_poder()

func mostrar_poder() -> void:
	nota("Tocá el ? con la blanca", "Activá los poderes al crear la partida. Cada poder es sorpresa y dura 1–3 tiros posteriores al de recogida. Aparece después de asignar grupos y completar un tiro de cada jugador.")
	var grilla := GridContainer.new()
	grilla.columns = 4
	grilla.add_theme_constant_override("h_separation", 8)
	grilla.add_theme_constant_override("v_separation", 8)
	pagina.add_child(grilla)
	for i in range(PODERES.size()):
		var b := Button.new()
		b.icon = load("res://assets/powerups/iconos/%s.svg" % PODERES[i][0])
		b.add_theme_constant_override("icon_max_width", 48)
		b.custom_minimum_size = Vector2(115, 72)
		b.tooltip_text = PODERES[i][1]
		b.toggle_mode = true
		b.button_pressed = i == indice
		b.pressed.connect(func(): indice = i; mostrar(2))
		grilla.add_child(b)
	var cabecera := HBoxContainer.new()
	cabecera.add_theme_constant_override("separation", 16)
	pagina.add_child(cabecera)
	var imagen := TextureRect.new()
	imagen.texture = load("res://assets/powerups/iconos/%s.svg" % PODERES[indice][0])
	imagen.custom_minimum_size = Vector2(80, 80)
	imagen.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	imagen.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	cabecera.add_child(imagen)
	var nombre := Label.new()
	nombre.text = "%d / 8 · %s" % [indice + 1, PODERES[indice][1]]
	nombre.add_theme_font_size_override("font_size", 24)
	cabecera.add_child(nombre)
	nota(PODERES[indice][2], PODERES[indice][3])
	var navegacion := HBoxContainer.new()
	pagina.add_child(navegacion)
	for paso in [-1, 1]:
		var b := Button.new()
		b.text = "← Anterior" if paso == -1 else "Siguiente →"
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.pressed.connect(func(): indice = posmod(indice + paso, PODERES.size()); mostrar(2))
		navegacion.add_child(b)
