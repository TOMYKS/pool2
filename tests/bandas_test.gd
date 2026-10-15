extends SceneTree

var errores := 0
var casos := 0
var retencion_minima := 1.0
var retencion_maxima := 0.0
const ALTURA_PANO := 4.1761234


func _initialize() -> void:
	create_timer(60).timeout.connect(func(): quit(2))
	_probar.call_deferred()


func _probar() -> void:
	var mesa = load("res://scenes/mesa.tscn").instantiate()
	root.add_child(mesa)
	var sala = load("res://scenes/sala.tscn").instantiate()
	var modelos: Array[RigidBody3D] = [sala.get_node("Ball0"), sala.get_node("Bolas/Ball1")]
	for modelo in modelos:
		modelo.get_parent().remove_child(modelo)
	sala.free()
	for modelo in modelos:
		var radio: float = modelo.get_node("CollisionShape3D").shape.radius
		for cuerpo in [mesa.get_node("Bordes"), mesa.get_node("Pockets")]:
			for colision: CollisionShape3D in cuerpo.get_children():
				# Solo las caras interiores: las traseras de las troneras están
				# fuera del paño y no son superficies de rebote hacia la mesa.
				if colision.name in [&"Pk3", &"Pk6", &"Pk9", &"Pk12", &"Pk13", &"Pk16"]:
					continue
				# Aislar cada labio para medir su material sin empezar solapado
				# con otro bloque de la tronera. Las bandas usan la mesa completa.
				for otro_cuerpo in [mesa.get_node("Bordes"), mesa.get_node("Pockets")]:
					for otra: CollisionShape3D in otro_cuerpo.get_children():
						otra.disabled = cuerpo.name == &"Pockets" and otra != colision
				var tamano: Vector3 = colision.shape.size
				var hacia_mesa: Vector3 = colision.global_basis.inverse() * -colision.global_position
				hacia_mesa.y = 0
				var eje := Vector3.RIGHT if absf(hacia_mesa.x / tamano.x) > absf(hacia_mesa.z / tamano.z) else Vector3.BACK
				eje *= signf(hacia_mesa.dot(eje))
				var normal: Vector3 = colision.global_basis * eje
				var cara: Vector3 = colision.global_position + colision.global_basis * (eje * tamano * 0.5)
				cara.y = ALTURA_PANO + radio
				# Las bocas se prueban con impactos rápidos para alcanzar el
				# labio antes de caer. En las seis bandas también hay tiros suaves.
				var velocidades := [0.4, 2.0, 8.0, 20.0, 30.0] if cuerpo.name == &"Bordes" else [2.0, 8.0, 20.0, 30.0]
				for velocidad in velocidades:
					for angulo in [0.0, 0.5]:
						var bola := modelo.duplicate() as RigidBody3D
						bola.position = cara + normal * (radio + 0.04)
						var direccion: Vector3 = (-normal + normal.cross(Vector3.UP) * angulo).normalized()
						bola.linear_velocity = direccion * velocidad
						bola.angular_velocity = Vector3.UP.cross(bola.linear_velocity) / radio
						root.add_child(bola)
						var reboto := false
						var entrada := bola.linear_velocity
						for paso in range(30):
							await physics_frame
							if bola.linear_velocity.dot(normal) > velocidad * 0.15:
								reboto = true
								var retencion := bola.linear_velocity.length() / entrada.length()
								if velocidad >= 2.0:
									retencion_minima = minf(retencion_minima, retencion)
									retencion_maxima = maxf(retencion_maxima, retencion)
									# En estos ángulos la banda debe perder al menos
									# un 20 % de velocidad, también a máxima potencia.
									if retencion >= 0.80:
										errores += 1
										print("POCA PERDIDA: ", modelo.name, " ", colision.name, " velocidad=", velocidad, " angulo=", angulo, " retencion=", retencion)
								break
							if bola.linear_velocity.dot(normal) < 0.0:
								entrada = bola.linear_velocity
						casos += 1
						if not reboto:
							errores += 1
							print("SIN REBOTE: ", modelo.name, " ", colision.name, " velocidad=", velocidad, " angulo=", angulo, " posicion=", bola.position, " v=", bola.linear_velocity)
						bola.free()
	for modelo in modelos:
		modelo.free()
	mesa.free()
	print("BANDAS TEST: ", errores, " errores en ", casos, " impactos")
	print("Velocidad conservada al rebotar: ", retencion_minima, " a ", retencion_maxima)
	quit(1 if errores else 0)
