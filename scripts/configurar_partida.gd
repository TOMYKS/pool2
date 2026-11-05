extends ColorRect

const Estilo = preload("res://scripts/estilo_menu.gd")
# El centro de los controles conserva el nivel de mezcla original.
const VOLUMEN_MUSICA_MAX := 2.0
const VOLUMEN_EFECTOS_MAX := 1.6

var contenido: VBoxContainer
var composicion: BoxContainer
var cartel: PanelContainer
var marca: VBoxContainer
var logo: TextureRect
var scroll: ScrollContainer
var _en_principal := false
var partida: Node
var brillo := 1.0
var volumen_musica := 1.0
var volumen_efectos := 0.8
var camara_menu: Camera3D
var camara_anterior: Camera3D
var tiempo_cine := 0.0
var sensibilidad := 0.005
var filtro: ColorRect
var musica_menu: AudioStreamPlayer

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	partida = get_parent().get_parent()
	get_parent().layer = 10
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	color = Color.WHITE
	var fondo := ShaderMaterial.new()
	fondo.shader = preload("res://scripts/fondo_menu.gdshader")
	material = fondo
	var tema := Estilo.crear()
	theme = tema
	var margen := MarginContainer.new()
	margen.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for lado in ["left", "right", "top", "bottom"]:
		margen.add_theme_constant_override("margin_" + lado, 24)
	add_child(margen)
	scroll = ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	margen.add_child(scroll)
	var centro := CenterContainer.new()
	centro.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	centro.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.add_child(centro)
	composicion = BoxContainer.new()
	composicion.alignment = BoxContainer.ALIGNMENT_CENTER
	composicion.add_theme_constant_override("separation", 48)
	centro.add_child(composicion)
	marca = VBoxContainer.new()
	marca.alignment = BoxContainer.ALIGNMENT_CENTER
	marca.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	marca.add_theme_constant_override("separation", 18)
	composicion.add_child(marca)
	var marco_logo := PanelContainer.new()
	var esquinas_logo := StyleBoxFlat.new()
	esquinas_logo.bg_color = Color.WHITE
	esquinas_logo.set_corner_radius_all(8)
	marco_logo.add_theme_stylebox_override("panel", esquinas_logo)
	marco_logo.clip_children = CanvasItem.CLIP_CHILDREN_ONLY
	marca.add_child(marco_logo)
	logo = TextureRect.new()
	logo.texture = preload("res://LogoNuevo.png")
	logo.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	logo.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	marco_logo.add_child(logo)
	cartel = PanelContainer.new()
	cartel.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	cartel.add_theme_stylebox_override("panel", Estilo.cartel())
	composicion.add_child(cartel)
	var interior := VBoxContainer.new()
	interior.add_theme_constant_override("separation", 12)
	cartel.add_child(interior)
	contenido = VBoxContainer.new()
	contenido.add_theme_constant_override("separation", 10)
	interior.add_child(contenido)
	resized.connect(_ajustar_diseno)
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
		volumen_musica = config.get_value("ajustes", "musica", config.get_value("ajustes", "volumen", volumen_musica))
		volumen_efectos = config.get_value("ajustes", "efectos", config.get_value("ajustes", "volumen", 0.8))
		sensibilidad = config.get_value("ajustes", "sensibilidad", sensibilidad)
	_preparar_audio()
	visibility_changed.connect(func(): _cambiar_musica(visible))
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
	if get_tree().get_meta("abrir_nueva_partida", false):
		get_tree().remove_meta("abrir_nueva_partida")
		nuevo()
	else:
		principal()
	get_tree().paused = true

func limpiar(titulo: String, subtitulo := "") -> void:
	_en_principal = false
	_ajustar_diseno()
	scroll.scroll_vertical = 0
	for hijo in contenido.get_children():
		contenido.remove_child(hijo)
		hijo.queue_free()
	var etiqueta := Label.new()
	etiqueta.text = titulo
	etiqueta.visible = not titulo.is_empty()
	etiqueta.add_theme_color_override("font_color", Estilo.ROSA)
	etiqueta.add_theme_font_override("font", Estilo.FUENTE_TITULO)
	etiqueta.add_theme_color_override("font_shadow_color", Color(0.95, 0.2, 0.6, 0.35))
	etiqueta.add_theme_constant_override("shadow_outline_size", 5)
	etiqueta.add_theme_font_size_override("font_size", 44)
	etiqueta.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	contenido.add_child(etiqueta)
	if not subtitulo.is_empty():
		texto(subtitulo)

func texto(valor: String) -> void:
	var etiqueta := Label.new()
	etiqueta.text = valor
	etiqueta.add_theme_color_override("font_color", Estilo.SUAVE)
	etiqueta.add_theme_font_size_override("font_size", 16)
	etiqueta.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	contenido.add_child(etiqueta)

func boton(nombre: String, accion: Callable) -> void:
	var b := Button.new()
	b.text = nombre
	b.alignment = HORIZONTAL_ALIGNMENT_LEFT
	b.custom_minimum_size.y = 50
	var icono := ""
	match nombre:
		"Ajustes": icono = "ajustes"
		"Cómo jugar": icono = "guia"
		"Salir del juego", "Volver al menú", "Volver", "Cancelar": icono = "salir"
	if not icono.is_empty():
		b.icon = load("res://assets/menu/%s.svg" % icono)
	if nombre in ["Nuevo juego", "Jugar", "Continuar"]:
		for estado in ["normal", "hover", "pressed", "hover_pressed"]:
			b.add_theme_stylebox_override(estado, Estilo.principal(estado))
			b.add_theme_color_override("font_" + estado + "_color", Color("#272518"))
			b.add_theme_color_override("icon_" + estado + "_color", Color("#272518"))
		b.add_theme_color_override("font_color", Color("#272518"))
		b.add_theme_color_override("font_focus_color", Color("#272518"))
		b.add_theme_color_override("icon_focus_color", Color("#272518"))
		b.custom_minimum_size.y = 56
	if nombre == "Salir del juego":
		b.add_theme_color_override("font_color", Estilo.SUAVE)
		b.add_theme_font_size_override("font_size", 23)
	b.pressed.connect(accion)
	contenido.add_child(b)
	if nombre in ["Nuevo juego", "Jugar", "Continuar", "Cancelar", "Volver"]:
		var enfocado := get_viewport().gui_get_focus_owner()
		if enfocado == null or not contenido.is_ancestor_of(enfocado):
			b.grab_focus()

func principal() -> void:
	show()
	limpiar("")
	_en_principal = true
	_ajustar_diseno()
	boton("Nuevo juego", nuevo)
	boton("Ajustes", ajustes)
	boton("Cómo jugar", informacion)
	boton("Salir del juego", func(): get_tree().quit())

func nuevo() -> void:
	limpiar("Nueva partida", "Elegí tu rival y las reglas de la mesa.")
	var rival := OptionButton.new()
	rival.custom_minimum_size.y = 52
	rival.add_item("Dos jugadores locales")
	rival.add_item("Contra la CPU")
	contenido.add_child(rival)
	var jugadores := HBoxContainer.new()
	jugadores.add_theme_constant_override("separation", 12)
	contenido.add_child(jugadores)
	var nombre1 := LineEdit.new()
	nombre1.custom_minimum_size.y = 50
	nombre1.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	nombre1.placeholder_text = "Nombre del jugador 1"
	nombre1.max_length = 18
	nombre1.name = "NombreJugador1"
	jugadores.add_child(nombre1)
	var nombre2 := LineEdit.new()
	nombre2.custom_minimum_size.y = 50
	nombre2.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	nombre2.placeholder_text = "Nombre del jugador 2"
	nombre2.max_length = 18
	nombre2.name = "NombreJugador2"
	jugadores.add_child(nombre2)
	rival.item_selected.connect(func(opcion): nombre2.visible = opcion == 0)
	var poderes := CheckButton.new()
	poderes.text = "Activar power-ups sorpresa"
	poderes.button_pressed = true
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
	)
	boton("Volver", principal)

func abrir_pausa() -> void:
	if partida.configurando:
		return
	# El tween de la CPU se congela con el árbol; conservar su taco al reanudar.
	if not partida.cpu.animando_golpe:
		partida.sala.cancelar_apuntado()
	partida.sala.get_node("Camaras/Pivot").is_dragging_camera = false
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	if not get_tree().paused:
		camara_anterior = get_viewport().get_camera_3d()
	get_tree().paused = true
	partida.get_node("HUD/Panel").hide()
	show()
	limpiar("Pausa")
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
	get_tree().paused = false

func volver() -> void:
	if partida.configurando:
		principal()
	else:
		abrir_pausa()

func ajustes() -> void:
	limpiar("Ajustes")
	deslizador("Brillo", 0.5, 1.5, 0.05, brillo, func(v): brillo = v; _aplicar())
	deslizador("Música", 0.0, 1.0, 0.05, volumen_musica / VOLUMEN_MUSICA_MAX, func(v): volumen_musica = v * VOLUMEN_MUSICA_MAX; _aplicar())
	deslizador("Efectos de sonido", 0.0, 1.0, 0.05, volumen_efectos / VOLUMEN_EFECTOS_MAX, func(v): volumen_efectos = v * VOLUMEN_EFECTOS_MAX; _aplicar())
	boton("Volver", volver)

func deslizador(nombre: String, minimo: float, maximo: float, paso: float, valor: float, accion: Callable) -> void:
	var etiqueta := Label.new()
	etiqueta.text = _valor_ajuste(nombre, valor)
	etiqueta.add_theme_color_override("font_color", Estilo.ORO)
	etiqueta.add_theme_font_size_override("font_size", 16)
	contenido.add_child(etiqueta)
	var slider := HSlider.new()
	slider.min_value = minimo
	slider.max_value = maximo
	slider.step = paso
	slider.value = valor
	slider.custom_minimum_size.y = 36
	slider.value_changed.connect(func(v):
		etiqueta.text = _valor_ajuste(nombre, v)
		accion.call(v))
	contenido.add_child(slider)

func _valor_ajuste(nombre: String, valor: float) -> String:
	return "%s   ·   %d%%" % [nombre, roundi(valor * 100.0)]

func _ajustar_diseno() -> void:
	if not is_instance_valid(cartel):
		return
	var ancho := get_viewport_rect().size.x
	var alto := get_viewport_rect().size.y
	var horizontal := ancho >= 1000.0
	composicion.vertical = not horizontal
	composicion.add_theme_constant_override("separation", 48 if horizontal else 22)
	marca.visible = _en_principal
	var lado := clampf(alto * 0.63, 280.0, 480.0) if horizontal else 150.0
	logo.custom_minimum_size = Vector2(lado, lado)
	contenido.custom_minimum_size.x = minf(360.0 if _en_principal else 490.0, maxf(240.0, ancho - 120.0))

func _aplicar() -> void:
	AudioServer.set_bus_volume_linear(0, 1.0)
	AudioServer.set_bus_volume_linear(AudioServer.get_bus_index("Musica"), volumen_musica)
	AudioServer.set_bus_volume_linear(AudioServer.get_bus_index("Efectos"), volumen_efectos)
	partida.sala.get_node("Camaras/Pivot").mouse_sensitivity = sensibilidad
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
	var musica_3d: AudioStreamPlayer3D = partida.sala.get_node("Audio/MusicaFondo")
	musica_menu = AudioStreamPlayer.new()
	musica_menu.name = "MusicaMenu"
	musica_menu.stream = musica_3d.stream
	musica_menu.volume_db = musica_3d.volume_db - 15.0
	musica_menu.pitch_scale = musica_3d.pitch_scale
	musica_menu.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(musica_menu)
	_cambiar_musica(true)

func _cambiar_musica(en_menu: bool) -> void:
	if not is_instance_valid(musica_menu):
		return
	var musica_3d: AudioStreamPlayer3D = partida.sala.get_node("Audio/MusicaFondo")
	var origen: Node = musica_3d if en_menu else musica_menu
	var destino: Node = musica_menu if en_menu else musica_3d
	if destino.playing:
		return
	var posicion: float = origen.get_playback_position() if origen.playing else 0.0
	origen.stop()
	destino.play(posicion)

func _enrutar_arbol(nodo: Node) -> void:
	_enrutar_audio(nodo)
	for hijo in nodo.get_children():
		_enrutar_arbol(hijo)

func _enrutar_audio(nodo: Node) -> void:
	if nodo is AudioStreamPlayer or nodo is AudioStreamPlayer3D or nodo is AudioStreamPlayer2D:
		var es_musica := nodo.name in [&"MusicaFondo", &"MusicaMenu"]
		nodo.bus = "Musica" if es_musica else "Efectos"
		if es_musica:
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
	partida.sala.get_node("Camaras").add_child(camara_menu)
	_actualizar_cine()
	camara_menu.make_current()

func _process(delta: float) -> void:
	if partida != null and partida.configurando and visible and get_tree().paused and is_instance_valid(camara_menu):
		tiempo_cine += delta
		_actualizar_cine()

func _actualizar_cine() -> void:
	# Travelling orbital lento: alterna vistas laterales y diagonales sin cortes.
	var angulo := tiempo_cine * 0.055 + 0.65
	var posicion := Vector3(cos(angulo) * 7.5, 7.0 + sin(tiempo_cine * 0.12) * 0.6, sin(angulo) * 6.2)
	camara_menu.global_position = partida.sala.to_global(posicion)
	camara_menu.look_at(partida.sala.to_global(Vector3(0, 4.2, 0)), Vector3.UP)
