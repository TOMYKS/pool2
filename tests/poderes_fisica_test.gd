extends SceneTree
var errores := 0
func _initialize() -> void:
	probar.call_deferred()
func probar() -> void:
	for nombre in ["PESADAS", "REBOTE", "GRANDES"]:
		var sala = load("res://scenes/sala.tscn").instantiate()
		root.add_child(sala)
		await process_frame
		await process_frame
		var p = sala.get_node("Partida")
		p.comenzar_partida(false)
		paused = false
		var sistema = sala.get_node("Powerups")
		var masa_base: float = sala.get_node("Bolas/Ball1").mass
		var rebote_base: float = sala.get_node("Bolas/Ball1").physics_material_override.bounce
		var tipo: int = sistema.TipoPoder[nombre]
		sistema._guardar_originales()
		sistema._controladores[tipo].call(sistema.PODERES[tipo]["activar"])
		sistema.poder_actual = tipo
		sala.ball.apply_central_impulse(Vector3.LEFT * 20.0)
		for paso in range(Engine.physics_ticks_per_second * 12):
			await physics_frame
			for bola in [sala.ball] + get_nodes_in_group("bolas_color"):
				if not bola.position.is_finite() or not bola.linear_velocity.is_finite():
					errores += 1
					push_error("Estado físico inválido con " + nombre)
				if bola.position.y < 3.5:
					bola.freeze = true
		sistema._terminar_poder()
		for bola in get_nodes_in_group("bolas_color"):
			if not is_equal_approx(bola.mass, masa_base) or not is_equal_approx(bola.physics_material_override.bounce, rebote_base):
				errores += 1
				push_error("El poder debe restaurar la física base: " + nombre)
		sala.queue_free()
		await process_frame
	print("PODERES FISICA: ", errores, " errores en pesadas, rebote y grandes")
	quit(1 if errores else 0)
