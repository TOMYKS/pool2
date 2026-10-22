extends SceneTree

var fallos := 0

func _initialize() -> void:
	create_timer(15).timeout.connect(func(): quit(2))
	_probar.call_deferred()

func comprobar(valor: bool, mensaje: String) -> void:
	if not valor:
		fallos += 1
		push_error(mensaje)

func _probar() -> void:
	var sala = load("res://scenes/sala.tscn").instantiate()
	root.add_child(sala)
	current_scene = sala
	await process_frame
	var partida = sala.get_node("Partida")
	var pivote = sala.get_node("Pivot")
	var rotacion: Vector3 = pivote.rotation
	var zoom: float = pivote.spring_arm.spring_length
	Input.action_press("ui_left")
	await process_frame
	await process_frame
	Input.action_release("ui_left")
	var rueda := InputEventMouseButton.new()
	rueda.button_index = MOUSE_BUTTON_WHEEL_UP
	rueda.pressed = true
	pivote._unhandled_input(rueda)
	var derecho := InputEventMouseButton.new()
	derecho.button_index = MOUSE_BUTTON_RIGHT
	derecho.pressed = true
	pivote._unhandled_input(derecho)
	var movimiento := InputEventMouseMotion.new()
	movimiento.relative = Vector2(80, 80)
	pivote._unhandled_input(movimiento)
	var espacio := InputEventKey.new()
	espacio.keycode = KEY_SPACE
	espacio.pressed = true
	root.push_input(espacio)
	var clic := InputEventMouseButton.new()
	clic.button_index = MOUSE_BUTTON_LEFT
	clic.pressed = true
	sala._unhandled_input(clic)
	await process_frame
	comprobar(pivote.rotation == rotacion, "Pop-up bloquea flechas y giro")
	comprobar(pivote.spring_arm.spring_length == zoom, "Pop-up bloquea zoom")
	comprobar(not pivote.is_dragging_camera and Input.mouse_mode == Input.MOUSE_MODE_VISIBLE, "No captura el ratón")
	comprobar(not sala.is_hitting_mode and not partida.reglas.en_tiro, "Pop-up bloquea tiro")
	comprobar(not sala.get_node("Powerups").habilitado, "Pop-up bloquea poderes")
	comprobar(partida.configuracion.rival.get_item_text(1) == "Jugador 2: CPU Basico", "Nombre actualizado")
	var boton: Button = partida.configuracion.find_children("*", "Button", true, false).filter(func(nodo): return nodo.text == "Iniciar partida")[0]
	boton.pressed.emit()
	comprobar(not partida.configurando and not partida.configuracion.visible, "Botón habilita partida")
	pivote._unhandled_input(rueda)
	comprobar(pivote.spring_arm.spring_length < zoom, "Zoom habilitado tras iniciar")
	Input.action_press("ui_left")
	pivote._process(0.1)
	Input.action_release("ui_left")
	comprobar(pivote.rotation != rotacion, "Flechas habilitadas tras iniciar")
	print("POPUP INPUT TEST: ", fallos, " fallos")
	quit(0 if fallos == 0 else 1)
