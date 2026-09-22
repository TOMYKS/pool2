extends Node3D

## Multiplica el radio y el tamaño visual de las bolas de color.
@export_range(2.0, 3.0, 1.0) var multiplicador_tamano: float = 2.0

var powerup_grandes_activo: bool = false
var _bolas_originales: Array[Dictionary] = []


func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.keycode == KEY_SPACE and event.pressed and not event.echo:
		alternar_bolas_grandes.call_deferred()


func alternar_bolas_grandes() -> void:
	if powerup_grandes_activo:
		desactivar_bolas_grandes()
	else:
		activar_bolas_grandes()


func activar_bolas_grandes() -> void:
	if powerup_grandes_activo:
		return

	var factor := clampf(multiplicador_tamano, 2.0, 3.0)
	for nodo in get_tree().get_nodes_in_group("bolas_color"):
		var bola := nodo as RigidBody3D
		if bola == null or bola.is_queued_for_deletion():
			continue

		var colision: CollisionShape3D = null
		var mallas: Array[Dictionary] = []
		for hijo in bola.get_children():
			if hijo is CollisionShape3D and hijo.shape is SphereShape3D:
				colision = hijo
			elif hijo is MeshInstance3D:
				mallas.append({"nodo": hijo, "escala": hijo.scale})

		if colision == null:
			continue

		var forma_original := colision.shape as SphereShape3D
		# Las bolas comparten la forma en sala.tscn: duplicarla evita
		# multiplicar el radio varias veces o cambiar otras instancias.
		var forma_grande := forma_original.duplicate() as SphereShape3D
		forma_grande.radius = forma_original.radius * factor
		var aumento_radio := forma_grande.radius - forma_original.radius
		_bolas_originales.append({
			"bola": bola,
			"colision": colision,
			"forma": forma_original,
			"mallas": mallas,
			"aumento_radio": aumento_radio,
		})

		# Cambiamos la esfera, no la escala del RigidBody3D.
		colision.shape = forma_grande
		for datos in mallas:
			datos["nodo"].scale = datos["escala"] * factor
		bola.global_position += Vector3.UP * aumento_radio
		bola.sleeping = false

	powerup_grandes_activo = true
	print("POWER-UP ON: Bolas de color de tamaño x", factor)


func desactivar_bolas_grandes() -> void:
	if not powerup_grandes_activo:
		return

	for datos in _bolas_originales:
		var bola = datos["bola"]
		# Una bola puede haber caído y sido eliminada durante el efecto.
		if not is_instance_valid(bola) or bola.is_queued_for_deletion():
			continue
		var colision = datos["colision"]
		if is_instance_valid(colision):
			colision.shape = datos["forma"]
		for malla in datos["mallas"]:
			if is_instance_valid(malla["nodo"]):
				malla["nodo"].scale = malla["escala"]
		bola.global_position -= Vector3.UP * datos["aumento_radio"]
		bola.sleeping = false

	_bolas_originales.clear()
	powerup_grandes_activo = false
	print("POWER-UP OFF: Las bolas recuperaron su tamaño original.")
