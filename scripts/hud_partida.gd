extends PanelContainer
var partida: Node
var fila: HBoxContainer
var turno: Label
var modo: Label
var efecto: Label
var mensaje: Label
var icono_poder: TextureRect
var duracion_poder: Label
var nombre_poder: Label
var ficha_poder: HBoxContainer
var ultimo_icono := -1
var jugadores: Array[Label] = []
var grupos: Array[Label] = []
var bolas: Array = []

func etiqueta(padre: Node, tamano: int) -> Label:
	var l := Label.new()
	l.add_theme_font_size_override("font_size", tamano)
	padre.add_child(l)
	return l

func _ready() -> void:
	partida = get_parent().get_parent()
	var caja = get_node("Margen/Contenido")
	caja.add_theme_constant_override("separation", 0)
	get_node("Margen").add_theme_constant_override("margin_top", 4)
	get_node("Margen").add_theme_constant_override("margin_bottom", 4)
	get_node("Margen/Contenido/Estado").hide()
	get_node("Margen/Contenido/Detalle").hide()
	var estilo := StyleBoxFlat.new()
	estilo.bg_color = Color(0.025, 0.055, 0.085, 0.96)
	estilo.border_color = Color("#b79a64")
	estilo.border_width_bottom = 2
	add_theme_stylebox_override("panel", estilo)
	fila = HBoxContainer.new()
	fila.add_theme_constant_override("separation", 18)
	caja.add_child(fila)
	caja.move_child(fila, 0)
	crear_jugador()
	var centro := VBoxContainer.new()
	centro.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	centro.size_flags_stretch_ratio = 2.0
	centro.add_theme_constant_override("separation", 5)
	fila.add_child(centro)
	var cabecera := VBoxContainer.new()
	cabecera.add_theme_constant_override("separation", 2)
	centro.add_child(cabecera)
	modo = etiqueta(cabecera, 11)
	turno = etiqueta(cabecera, 16)
	turno.add_theme_color_override("font_color", Color("#e4c58a"))
	efecto = etiqueta(cabecera, 12)
	mensaje = etiqueta(centro, 12)
	for l in [modo, turno, efecto, mensaje]:
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		l.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	modo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	efecto.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	centro.custom_minimum_size.x = 400
	# Los laterales ocupan menos y el turno recibe la mayor parte del centro.
	turno.size_flags_stretch_ratio = 2.5
	var centrado := CenterContainer.new()
	centro.add_child(centrado)
	ficha_poder = HBoxContainer.new()
	ficha_poder.add_theme_constant_override("separation", 8)
	centrado.add_child(ficha_poder)
	icono_poder = TextureRect.new()
	icono_poder.custom_minimum_size = Vector2(30, 30)
	icono_poder.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icono_poder.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	ficha_poder.add_child(icono_poder)
	var textos := VBoxContainer.new()
	textos.alignment = BoxContainer.ALIGNMENT_CENTER
	textos.add_theme_constant_override("separation", 2)
	ficha_poder.add_child(textos)
	nombre_poder = etiqueta(textos, 13)
	nombre_poder.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	duracion_poder = etiqueta(textos, 12)
	duracion_poder.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	duracion_poder.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	ficha_poder.hide()
	mensaje.hide()
	efecto.hide()
	crear_jugador()

func crear_jugador() -> void:
	var columna := VBoxContainer.new()
	columna.custom_minimum_size.x = 240
	columna.size_flags_horizontal = Control.SIZE_FILL
	columna.add_theme_constant_override("separation", 0)
	fila.add_child(columna)
	var nombre := etiqueta(columna, 15)
	nombre.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	nombre.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	jugadores.append(nombre)
	var grupo := etiqueta(columna, 12)
	grupo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	grupos.append(grupo)
	var centrado := CenterContainer.new()
	columna.add_child(centrado)
	var rack := HBoxContainer.new()
	rack.add_theme_constant_override("separation", 3)
	centrado.add_child(rack)
	var lista := []
	for i in range(8):
		var bola = preload("res://scripts/bola_hud.gd").new()
		rack.add_child(bola)
		lista.append(bola)
	bolas.append(lista)

func integrar_pausa(boton: Button) -> void:
	boton.reparent(fila)
	fila.move_child(boton, 0)
	boton.text = "Ⅱ"
	boton.tooltip_text = "Pausa · Escape"
	boton.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	boton.custom_minimum_size = Vector2(36, 36)

func _process(_delta: float) -> void:
	actualizar()

func actualizar() -> void:
	if not partida.is_node_ready():
		return
	var r = partida.reglas
	modo.text = "MODO: CON POWER-UPS" if partida.con_powerups else "MODO: SIN POWER-UPS"
	var nombre: String = partida.nombre_jugador(r.turno)
	turno.text = "Turno: %s" % nombre
	if r.saque:
		turno.text += " · Saque"
	if partida.terminada:
		turno.text = "Ganó %s" % partida.nombre_jugador(r.ganador)
	for i in range(2):
		var grupo: int = r.grupos[i]
		var activo: bool = r.turno == i + 1 and not partida.terminada
		jugadores[i].text = ("▸ " if activo else "") + partida.nombre_jugador(i + 1)
		jugadores[i].modulate = Color("#e4c58a") if activo else Color("#acbcc9")
		grupos[i].text = "Mesa abierta" if grupo == 0 else ("%s · %s" % ["Lisas" if grupo == 1 else "Rayadas", "Va por la 8" if r.pendientes(i + 1).is_empty() else "%d restantes" % r.pendientes(i + 1).size()])
		var anotadas: Array[int] = []
		for n in r.embocadas_partida:
			if (grupo != 0 and n != 8 and r.grupo_de(n) == grupo) or (n == 8 and r.jugador_que_emboco_ocho == i + 1):
				anotadas.append(n)
		for j in range(8):
			var bola = bolas[i][j]
			bola.numero = anotadas[j] if j < anotadas.size() else 0
			bola.embocada = false
			bola.queue_redraw()
	# El turno se indica junto al nombre; no mostrar mensajes narrativos.
	turno.visible = true
	mensaje.hide()
	efecto.hide()
	var sistema = partida.sala.get_node_or_null("Powerups")
	var activo: bool = partida.con_powerups and sistema != null and sistema.poder_actual != -1 and not partida.terminada
	ficha_poder.visible = activo
	if activo:
		if ultimo_icono != sistema.poder_actual:
			ultimo_icono = sistema.poder_actual
			var archivo: String = sistema.PODERES[ultimo_icono]["escena"]
			icono_poder.texture = load("res://assets/powerups/iconos/%s.svg" % archivo)
		ficha_poder.tooltip_text = sistema.PODERES[sistema.poder_actual]["nombre"]
		nombre_poder.text = ficha_poder.tooltip_text
		duracion_poder.text = "%d tiro%s" % [sistema.tiros_restantes, "" if sistema.tiros_restantes == 1 else "s"]
	modo.tooltip_text = modo.text
	turno.tooltip_text = turno.text
	# Con nombres largos, reducir solo lo necesario sin recortar el turno.
	var fuente := turno.get_theme_font("font")
	var tamano := 16
	while tamano > 10 and turno.size.x > 0 and fuente.get_string_size(turno.text, HORIZONTAL_ALIGNMENT_LEFT, -1, tamano).x > turno.size.x:
		tamano -= 1
	turno.add_theme_font_size_override("font_size", tamano)
