extends ColorRect

var contenido: VBoxContainer
var partida: Node
var pausa: Button
var brillo := 1.0
var volumen_musica := 0.8
var volumen_efectos := 0.8
var camara_menu: Camera3D
var camara_anterior: Camera3D
var tiempo_cine := 0.0
var sensibilidad := 0.005
var filtro: ColorRect

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	partida = get_parent().get_parent()
	get_parent().layer = 10
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	color = Color.WHITE
	var fondo := ShaderMaterial.new()
	fondo.shader = preload("res://scripts/fondo_menu.gdshader")
	material = fondo
	var tema := Theme.new()
	tema.default_font_size = 20
	for estado in ["normal", "hover", "pressed", "focus"]:
		var estilo := StyleBoxFlat.new()
		estilo.bg_color = Color("#244c50") if estado != "normal" else Color("#16363e")
		estilo.set_corner_radius_all(12)
		estilo.content_margin_left = 22
		estilo.content_margin_right = 22
		estilo.content_margin_top = 12
		estilo.content_margin_bottom = 12
		estilo.border_color = Color("#d6b777")
		if estado == "focus":
			estilo.set_border_width_all(2)
		tema.set_stylebox(estado, "Button", estilo)
	theme = tema
	var margen := MarginContainer.new()
	margen.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for lado in ["left", "right", "top", "bottom"]:
		margen.add_theme_constant_override("margin_" + lado, 24)
	add_child(margen)
	var scroll := ScrollContainer.new()
	margen.add_child(scroll)
	var centro := CenterContainer.new()
	centro.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	centro.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.add_child(centro)
	contenido = VBoxContainer.new()
	contenido.custom_minimum_size.x = 540
	contenido.add_theme_constant_override("separation", 12)
	centro.add_child(contenido)
	pausa = Button.new()
	pausa.text = "Ⅱ  Pausa"
	pausa.position = Vector2(16, 16)
	pausa.add_theme_font_size_override("font_size", 14)
	pausa.theme = tema
	for estado in ["normal", "hover", "pressed", "focus"]:
		var compacto = tema.get_stylebox(estado, "Button").duplicate()
		compacto.content_margin_top = 6
		compacto.content_margin_bottom = 6
		compacto.content_margin_left = 12
		compacto.content_margin_right = 12
		pausa.add_theme_stylebox_override(estado, compacto)
	pausa.process_mode = Node.PROCESS_MODE_ALWAYS
	get_parent().add_child(pausa)
	pausa.pressed.connect(abrir_pausa)
	pausa.hide()
	var capa := CanvasLayer.new()
	capa.layer = 90
	add_child(capa)
	filtro = ColorRect.new()
	filtro.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	filtro.mouse_filter = Control.MOUSE_FILTER_IGNORE
	capa.add_child(filtro)
	var config := ConfigFile.new()
	if config.load("user://ajustes.cfg") == OK:
		brillo = config.get_value("ajustes", "brillo", brillo)
		volumen_musica = config.get_value("ajustes", "musica", config.get_value("ajustes", "volumen", 0.8))
		volumen_efectos = config.get_value("ajustes", "efectos", config.get_value("ajustes", "volumen", 0.8))
		sensibilidad = config.get_value("ajustes", "sensibilidad", sensibilidad)
	_preparar_audio()
	_aplicar()
	_preparar_cine.call_deferred()
	var panel: Control = partida.get_node("HUD/Panel")
	panel.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	panel.offset_left = 0
	panel.offset_right = 0
	panel.offset_top = 0
	panel.offset_bottom = 0

	partida.texto.add_theme_font_size_override("font_size", 18)
	partida.detalle.custom_minimum_size.x = 330
	principal()
	get_tree().paused = true

func limpiar(titulo: String, subtitulo := "") -> void:
	for hijo in contenido.get_children():
		contenido.remove_child(hijo)
		hijo.queue_free()
	var etiqueta := Label.new()
	etiqueta.text = titulo
	etiqueta.visible = not titulo.is_empty()
	etiqueta.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	etiqueta.add_theme_color_override("font_color", Color("#e4c58a"))
	etiqueta.add_theme_font_size_override("font_size", 34)
	contenido.add_child(etiqueta)
	if not subtitulo.is_empty():
		texto(subtitulo)

func texto(valor: String) -> void:
	var etiqueta := Label.new()
	etiqueta.text = valor
	etiqueta.custom_minimum_size.x = 500
	etiqueta.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	contenido.add_child(etiqueta)

func boton(nombre: String, accion: Callable) -> void:
	var b := Button.new()
	b.text = nombre
	b.pressed.connect(accion)
	contenido.add_child(b)
	if contenido.get_child_count() <= 3:
		b.grab_focus()

func principal() -> void:
	show()
	pausa.hide()
	limpiar("")
	var logo := TextureRect.new()
	logo.texture = load("res://LogoNuevo.png")
	logo.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	logo.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	logo.custom_minimum_size = Vector2(300, 240)
	contenido.add_child(logo)
	boton("Nuevo juego", nuevo)
	boton("Ajustes", ajustes)
	boton("Cómo jugar", informacion)
	boton("Salir del juego", func(): get_tree().quit())

func nuevo() -> void:
	limpiar("Nueva partida", "Elegí tu rival y las reglas de la mesa.")
	var rival := OptionButton.new()
	rival.add_item("Dos jugadores locales")
	rival.add_item("Contra la CPU")
	contenido.add_child(rival)
	var nombre1 := LineEdit.new()
	nombre1.placeholder_text = "Nombre del jugador 1"
	nombre1.max_length = 18
	nombre1.name = "NombreJugador1"
	contenido.add_child(nombre1)
	var nombre2 := LineEdit.new()
	nombre2.placeholder_text = "Nombre del jugador 2"
	nombre2.max_length = 18
	nombre2.name = "NombreJugador2"
	contenido.add_child(nombre2)
	rival.item_selected.connect(func(opcion): nombre2.visible = opcion == 0)
	var poderes := CheckButton.new()
	poderes.text = "Activar power-ups sorpresa"
	contenido.add_child(poderes)
	texto("Los poderes aparecen después de asignar grupos y completar un tiro de cada jugador.")
	boton("Jugar", func():
		partida.sala.camera.make_current()
		partida.get_node("HUD/Panel").show()
		var hud_poderes = partida.sala.get_node_or_null("Powerups/HUD")
		if hud_poderes != null:
			hud_poderes.hide()
		get_tree().paused = false
		partida.nombres = [nombre1.text.strip_edges() if not nombre1.text.strip_edges().is_empty() else "Jugador 1", nombre2.text.strip_edges() if not nombre2.text.strip_edges().is_empty() else "Jugador 2"]
		partida.con_powerups = poderes.button_pressed
		partida.comenzar_partida(rival.selected == 1)
		var sistema = partida.sala.get_node_or_null("Powerups")
		if sistema != null and sistema.habilitado != poderes.button_pressed:
			sistema.alternar_sistema()
		hide()
		pausa.hide())
	boton("Volver", principal)

func abrir_pausa() -> void:
	if partida.configurando:
		return
	partida.sala.cancelar_apuntado()
	partida.sala.get_node("Pivot").is_dragging_camera = false
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	if not get_tree().paused:
		camara_anterior = get_viewport().get_camera_3d()
	get_tree().paused = true
	camara_menu.make_current()
	partida.get_node("HUD/Panel").hide()
	show()
	pausa.hide()
	limpiar("Pausa", "La mesa te espera.")
	boton("Continuar", continuar)
	boton("Ajustes", ajustes)
	boton("Cómo jugar", informacion)
	boton("Volver al menú", confirmar_salida)
	boton("Salir del juego", func(): get_tree().quit())

func confirmar_salida() -> void:
	limpiar("¿Volver al menú?", "Se perderá la partida actual.")
	boton("Volver al menú", func():
		get_tree().paused = false
		get_tree().reload_current_scene())
	boton("Cancelar", abrir_pausa)

func continuar() -> void:
	if is_instance_valid(camara_anterior):
		camara_anterior.make_current()
	partida.get_node("HUD/Panel").show()
	hide()
	pausa.hide()
	get_tree().paused = false

func volver() -> void:
	if partida.configurando:
		principal()
	else:
		abrir_pausa()

func ajustes() -> void:
	limpiar("Ajustes", "Se guardan automáticamente en este equipo.")
	deslizador("Brillo", 0.5, 1.5, 0.05, brillo, func(v): brillo = v; _aplicar())
	deslizador("Música", 0.0, 1.0, 0.05, volumen_musica, func(v): volumen_musica = v; _aplicar())
	deslizador("Efectos de sonido", 0.0, 1.0, 0.05, volumen_efectos, func(v): volumen_efectos = v; _aplicar())
	deslizador("Sensibilidad del ratón", 0.001, 0.015, 0.001, sensibilidad, func(v): sensibilidad = v; _aplicar())
	boton("Volver", volver)

func deslizador(nombre: String, minimo: float, maximo: float, paso: float, valor: float, accion: Callable) -> void:
	var etiqueta := Label.new()
	etiqueta.text = "%s: %.3f" % [nombre, valor]
	contenido.add_child(etiqueta)
	var slider := HSlider.new()
	slider.min_value = minimo
	slider.max_value = maximo
	slider.step = paso
	slider.value = valor
	slider.custom_minimum_size.y = 36
	slider.value_changed.connect(func(v):
		etiqueta.text = "%s: %.3f" % [nombre, v]
		accion.call(v))
	contenido.add_child(slider)

func _aplicar() -> void:
	AudioServer.set_bus_volume_linear(0, 1.0)
	AudioServer.set_bus_volume_linear(AudioServer.get_bus_index("Musica"), volumen_musica)
	AudioServer.set_bus_volume_linear(AudioServer.get_bus_index("Efectos"), volumen_efectos)
	partida.sala.get_node("Pivot").mouse_sensitivity = sensibilidad
	partida.sala.cue_mouse_travel = sensibilidad * 2.0
	# Corrección visual global: oscurecer o aclarar sin alterar las luces.
	filtro.color = Color(0, 0, 0, 1.0 - brillo) if brillo <= 1.0 else Color(1, 1, 1, (brillo - 1.0) * 0.5)
	var config := ConfigFile.new()
	config.set_value("ajustes", "brillo", brillo)
	config.set_value("ajustes", "musica", volumen_musica)
	config.set_value("ajustes", "efectos", volumen_efectos)
	config.set_value("ajustes", "sensibilidad", sensibilidad)
	config.save("user://ajustes.cfg")

func informacion() -> void:
	limpiar("Cómo jugar")
	var guia := preload("res://scripts/guia_juego.gd").new()
	contenido.add_child(guia)
	boton("Volver", volver)
func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_ESCAPE and not partida.configurando:
		if visible:
			continuar()
		else:
			abrir_pausa()
		get_viewport().set_input_as_handled()

func _preparar_audio() -> void:
	for nombre in ["Musica", "Efectos"]:
		if AudioServer.get_bus_index(nombre) == -1:
			AudioServer.add_bus()
			var indice := AudioServer.bus_count - 1
			AudioServer.set_bus_name(indice, nombre)
			AudioServer.set_bus_send(indice, "Master")
	_enrutar_arbol(partida.sala)
	get_tree().node_added.connect(_enrutar_audio)

func _enrutar_arbol(nodo: Node) -> void:
	_enrutar_audio(nodo)
	for hijo in nodo.get_children():
		_enrutar_arbol(hijo)

func _enrutar_audio(nodo: Node) -> void:
	if nodo is AudioStreamPlayer or nodo is AudioStreamPlayer3D or nodo is AudioStreamPlayer2D:
		nodo.bus = "Musica" if nodo.name == &"MusicaFondo" else "Efectos"
		if nodo.name == &"MusicaFondo":
			nodo.process_mode = Node.PROCESS_MODE_ALWAYS

func _preparar_cine() -> void:
	if not partida.configurando:
		return
	partida.get_node("HUD/Panel").hide()
	var hud_poderes = partida.sala.get_node_or_null("Powerups/HUD")
	if hud_poderes != null:
		hud_poderes.hide()
	camara_menu = Camera3D.new()
	camara_menu.name = "CamaraMenu"
	camara_menu.fov = 52.0
	camara_menu.near = 0.05
	partida.sala.add_child(camara_menu)
	_actualizar_cine()
	camara_menu.make_current()

func _process(delta: float) -> void:
	if partida != null and visible and get_tree().paused and is_instance_valid(camara_menu):
		tiempo_cine += delta
		_actualizar_cine()

func _actualizar_cine() -> void:
	# Travelling orbital lento: alterna vistas laterales y diagonales sin cortes.
	var angulo := tiempo_cine * 0.055 + 0.65
	var posicion := Vector3(cos(angulo) * 7.5, 7.0 + sin(tiempo_cine * 0.12) * 0.6, sin(angulo) * 6.2)
	camara_menu.global_position = partida.sala.to_global(posicion)
	camara_menu.look_at(partida.sala.to_global(Vector3(0, 4.2, 0)), Vector3.UP)
