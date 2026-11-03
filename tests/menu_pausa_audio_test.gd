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
	for i in range(3):
		await process_frame
	var p = sala.get_node("Partida")
	var config = p.configuracion
	var musica_3d = sala.get_node("MusicaFondo")
	comprobar(paused and config.musica_menu.playing and not musica_3d.playing, "El menú debe reproducir únicamente música simple, incluso con el árbol pausado")
	comprobar(config.musica_menu.bus == &"Musica" and musica_3d.bus == &"Musica", "Ambos reproductores deben respetar el ajuste de volumen de música")
	var hud = p.get_node("HUD/Panel")
	comprobar(is_equal_approx(hud.get_theme_stylebox("panel").bg_color.a, 0.75), "Solo el fondo del HUD debe ser más transparente")
	config.nuevo()
	for boton in config.contenido.get_children():
		if boton is Button and boton.text == "Jugar":
			boton.pressed.emit()
			break
	await process_frame
	comprobar(not paused and not config.visible and musica_3d.playing and not config.musica_menu.playing, "Al jugar debe volver únicamente la música espacial")
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
	sala.queue_free()
	await process_frame
	print("MENU PAUSA AUDIO: ", errores, " errores")
	quit(1 if errores else 0)
