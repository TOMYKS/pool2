extends SceneTree
var errores := 0
func _initialize() -> void:
	probar.call_deferred()
func comprobar(valor: bool, mensaje: String) -> void:
	if not valor:
		errores += 1
		push_error(mensaje)
func probar() -> void:
	for velocidad in [0.5, 2.0, 8.0, 20.0]:
		for corte in [0.0, 0.12]:
			var sala = load("res://scenes/sala.tscn").instantiate()
			var bolas: Array[RigidBody3D] = [sala.get_node("Ball0"), sala.get_node("Bolas/Ball1")]
			for bola in bolas:
				bola.get_parent().remove_child(bola)
			sala.free()
			# Sin paño ni gravedad: aislar transferencia y conservación de energía.
			for i in range(2):
				var bola := bolas[i]
				bola.position = Vector3(-0.34 if i == 0 else 0.0, 10, corte if i == 0 else 0.0)
				bola.gravity_scale = 0
				bola.linear_damp_mode = RigidBody3D.DAMP_MODE_REPLACE
				bola.linear_damp = 0
				bola.angular_damp_mode = RigidBody3D.DAMP_MODE_REPLACE
				bola.angular_damp = 0
				if i == 0:
					bola.magnus_multiplier = 0
				root.add_child(bola)
			await process_frame
			await physics_frame
			bolas[0].linear_velocity = Vector3.RIGHT * velocidad
			var maxima := 0.0
			var hubo_contacto := false
			for i in range(Engine.physics_ticks_per_second):
				await physics_frame
				var energia := 0.0
				for bola in bolas:
					energia += 0.5 * bola.mass * bola.linear_velocity.length_squared()
				maxima = maxf(maxima, energia)
				hubo_contacto = hubo_contacto or bolas[1].linear_velocity.x > velocidad * 0.1
			comprobar(hubo_contacto, "Debe transferirse movimiento también en tiros suaves")
			comprobar(maxima <= 0.5 * bolas[0].mass * velocidad * velocidad * 1.02, "Un choque no debe crear energía lineal")
			if corte == 0.0:
				comprobar(absf(bolas[0].linear_velocity.x) < velocidad * 0.12, "Con masas iguales, la blanca debe ceder casi todo su avance en un choque frontal")
				comprobar(bolas[1].linear_velocity.x > velocidad * 0.85, "El choque frontal debe transmitir la mayor parte de la velocidad")
			for bola in bolas:
				bola.free()
			await process_frame
	print("CHOQUES BOLAS: ", errores, " errores en 8 impactos")
	quit(1 if errores else 0)
