extends RigidBody3D

@export var magnus_multiplier: float = 0.05 # Sube esto para que la curva sea más exagerada

func _physics_process(delta):
	# Si la pelota se está moviendo y además está girando sobre sí misma...
	if linear_velocity.length() > 0.1 and angular_velocity.length() > 0.1:
		
		# Calculamos la fuerza curva (Producto cruz entre giro y dirección)
		var fuerza_curva = angular_velocity.cross(linear_velocity) * magnus_multiplier
		
		# Anulamos el eje Y para evitar que el efecto haga volar la bola por los aires
		fuerza_curva.y = 0 
		
		# Aplicamos la fuerza constante mientras ruede para curvar su trayectoria
		apply_central_force(fuerza_curva)
