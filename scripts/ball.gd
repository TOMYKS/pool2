extends RigidBody3D

@export var magnus_multiplier: float = 0.3
@export var magnus_speed_reference: float = 15.0
@export var magnus_speed_curve: float = 1
@export var max_magnus_force: float = 10.0

func _physics_process(delta):
	# Limitamos la velocidad lineal como medida de seguridad final
	if linear_velocity.length() > 30.0:
		linear_velocity = linear_velocity.normalized() * 30.0
		
	# Si la pelota se est moviendo y además está girando sobre s misma...
	if linear_velocity.length() > 0.1 and angular_velocity.length() > 0.1:
		
		# En un billar arcade, el sidespin derecho debera curvar la bola hacia la derecha.
		# Invertimos el producto cruz: linear_velocity.cross(angular_velocity)
		var fuerza_curva = linear_velocity.cross(angular_velocity) * magnus_multiplier
		
		# Anulamos el eje Y para evitar que el efecto haga volar la bola por los aires
		fuerza_curva.y = 0 
		
		# Lmite ms holgado para permitir un swerve (curve) ms notorio con el sidespin
		if fuerza_curva.length() > 20.0:
			fuerza_curva = fuerza_curva.normalized() * 20.0
		
		# Aplicamos la fuerza constante mientras ruede para curvar su trayectoria
		apply_central_force(fuerza_curva)
