extends RigidBody3D


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass
func _input(event):
	# Verificamos que sea una tecla presionada y evitamos el "echo" (mantener presionada)
	if event is InputEventKey and event.pressed and not event.echo:
		var impulse := Vector3.ZERO
		
		# Mapeamos WASD a los ejes X y Z
		if event.keycode == KEY_W:
			impulse = Vector3(0, 0, -2.5) # Adelante (-Z)
		elif event.keycode == KEY_S:
			impulse = Vector3(0, 0, 2.5)  # Atrás (+Z)
		elif event.keycode == KEY_A:
			impulse = Vector3(-2.5, 0, 0) # Izquierda (-X)
		elif event.keycode == KEY_D:
			impulse = Vector3(2.5, 0, 0)  # Derecha (+X)
			
		# Si se generó un impulso con alguna de esas teclas, lo aplicamos
		if impulse != Vector3.ZERO:
			sleeping = false
			apply_central_impulse(impulse)
