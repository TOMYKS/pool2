extends RigidBody3D

@export var magnus_multiplier: float = 0.3
var _reposo := preload("res://scripts/reposo_bola.gd").new()

# Comparte el ajuste de ascenso de las bolas de color desde Sala.
var velocidad_vertical_maxima: float = 1.0
var desaceleracion_rodadura: float = 0.2
var roce_velocidad: float = 0.6


func _integrate_forces(state: PhysicsDirectBodyState3D) -> void:
	preload("res://scripts/fisica_bola.gd").integrar(state, velocidad_vertical_maxima, desaceleracion_rodadura, roce_velocidad)

func _physics_process(delta):
	_reposo.actualizar(self, delta)
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
