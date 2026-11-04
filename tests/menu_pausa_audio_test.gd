extends SceneTree

var errores := 0

func _initialize() -> void:
	probar.call_deferred()

func comprobar(condicion: bool, mensaje: String) -> void:
	if not condicion:
		errores += 1
		push_error(mensaje)

func probar() -> void:
	var sala = load("res://scenes/sala.tscn").instantiate()
	root.add_child(sala)
	current_scene = sala
	for i in range(3):
		await process_frame
	var p = sala.get_node("Partida")
	var config = p.configuracion
	var musica_anterior: float = config.volumen_musica
	var efectos_anteriores: float = config.volumen_efectos
	config.volumen_musica = 1.0
	config.volumen_efectos = 0.8
	config.ajustes()
	var controles_audio: Array[HSlider] = []
	for control in config.contenido.get_children():
		if control is HSlider:
			controles_audio.append(control)
	comprobar(controles_audio.size() == 3, "Ajustes debe mostrar solo brillo, música y efectos")
	comprobar(is_equal_approx(controles_audio[1].value, 0.5) and is_equal_approx(controles_audio[2].value, 0.5), "Los niveles originales de música y efectos deben aparecer al 50%")
	for indice in [1, 2]:
		var bus := AudioServer.get_bus_index("Musica" if indice == 1 else "Efectos")
		controles_audio[indice].value = 1.0
		comprobar(is_equal_approx(AudioServer.get_bus_volume_linear(bus), 2.0 if indice == 1 else 1.6), "El máximo debe permitir subir el volumen por encima de la mezcla original")
		controles_audio[indice].value = 0.0
		comprobar(is_zero_approx(AudioServer.get_bus_volume_linear(bus)), "El mínimo debe silenciar el canal")
		controles_audio[indice].value = 0.5
		comprobar(is_equal_approx(AudioServer.get_bus_volume_linear(bus), 1.0 if indice == 1 else 0.8), "El 50% debe conservar exactamente la mezcla original")
	config.volumen_musica = musica_anterior
	config.volumen_efectos = efectos_anteriores
	config._aplicar()
	config.principal()
	var musica_3d = sala.get_node("MusicaFondo")
	comprobar(paused and config.musica_menu.playing and not musica_3d.playing, "El menú debe reproducir únicamente música simple, incluso con el árbol pausado")
	comprobar(config.musica_menu.bus == &"Musica" and musica_3d.bus == &"Musica", "Ambos reproductores deben respetar el ajuste de volumen de música")
	var hud = p.get_node("HUD/Panel")
	comprobar(is_equal_approx(hud.get_theme_stylebox("panel").bg_color.a, 0.75), "Solo el fondo del HUD debe ser más transparente")
	config.nuevo()
	var poderes: CheckButton
	for control in config.contenido.get_children():
		if control is CheckButton:
			poderes = control
	comprobar(poderes != null and poderes.button_pressed, "Nueva partida debe ofrecer poderes activados por defecto")
	poderes.button_pressed = false
	for boton in config.contenido.get_children():
		if boton is Button and boton.text == "Jugar":
			boton.pressed.emit()
			break
	await process_frame
	comprobar(not paused and not config.visible and musica_3d.playing and not config.musica_menu.playing, "Al jugar debe volver únicamente la música espacial")
	comprobar(not p.con_powerups and not sala.get_node("Powerups").habilitado, "El jugador debe poder desactivar los poderes antes de jugar")
	var camara: Camera3D = root.get_camera_3d()
	var vista := camara.global_transform
	config.abrir_pausa()
	for i in range(3):
		await process_frame
	comprobar(paused and root.get_camera_3d() == camara and camara.global_transform.is_equal_approx(vista), "Pausar debe mantener congelada la vista actual, sin pasar a la cámara del menú")
	comprobar(config.material.shader == load("res://scripts/fondo_menu.gdshader"), "La vista congelada debe conservar el desenfoque")
	comprobar(config.musica_menu.playing and not musica_3d.playing, "Pausar debe reproducir solo música simple")
	config.ajustes()
	config.volver()
	comprobar(root.get_camera_3d() == camara and config.musica_menu.playing, "Los ajustes de pausa deben conservar el fondo y la música simple")
	config.continuar()
	await process_frame
	comprobar(not paused and root.get_camera_3d() == camara and musica_3d.playing and not config.musica_menu.playing, "Continuar debe recuperar la misma cámara y la música espacial")
	p.terminada = true
	p._actualizar_hud()
	p.reiniciar.pressed.emit()
	await scene_changed
	for i in range(3):
		await process_frame
	sala = current_scene
	p = sala.get_node("Partida")
	config = p.configuracion
	comprobar(paused and p.configurando and not p.terminada, "Nueva partida debe cargar una mesa limpia y pausada para elegir las reglas")
	comprobar(config.contenido.get_child(0).text == "Nueva partida", "El botón de fin de partida debe abrir la selección, sin pasar por el menú principal")
	comprobar(not has_meta("abrir_nueva_partida"), "La navegación debe consumirse para no afectar las próximas vueltas al menú")
	for control in config.contenido.get_children():
		if control is CheckButton:
			comprobar(control.button_pressed, "Los poderes deben volver a estar activados al entrar de nuevo")
		if control is OptionButton:
			control.select(1)
	for control in config.contenido.get_children():
		if control is Button and control.text == "Jugar":
			control.pressed.emit()
			break
	comprobar(not paused and p.jugador_2_cpu and p.con_powerups and sala.get_node("Powerups").habilitado, "La nueva selección debe iniciar una partida contra CPU con poderes")
	# Un reinicio automático conserva su ruta al menú, sin heredar la del botón.
	p.reiniciar_partida()
	await scene_changed
	for i in range(3):
		await process_frame
	config = current_scene.get_node("Partida").configuracion
	var hay_menu := false
	for control in config.contenido.get_children():
		if control is Button and control.text == "Nuevo juego":
			hay_menu = true
	comprobar(hay_menu, "Los otros reinicios deben conservar la entrada normal al menú")
	current_scene.queue_free()
	await process_frame
	print("MENU PAUSA AUDIO: ", errores, " errores")
	quit(1 if errores else 0)
