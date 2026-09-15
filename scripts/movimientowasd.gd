extends Node3D

@export var ball: RigidBody3D
@onready var spring_arm: SpringArm3D = $SpringArm3D # Referencia al brazo de la cámara

@export var rotation_speed: float = 3.0

# Variables para controlar el zoom
@export var zoom_speed: float = 0.2
@export var min_zoom: float = 0.4 # Distancia mínima (qué tan cerca puedes estar)
@export var max_zoom: float = 5.0 # Distancia máxima (qué tan lejos puedes estar)

func _process(delta):
	# El pivote sigue a la bola
	if ball:
		global_position = ball.global_position
		
	# Rotación con WASD
	var input_dir = Input.get_vector("ui_right", "ui_left", "ui_down", "ui_up") # Mapea A, D, W, S
	
	# Rotar en Y (Izquierda / Derecha)
	rotation.y -= input_dir.x * rotation_speed * delta
	# Rotar en X (Arriba / Abajo) - Limitado para no dar la vuelta entera
	rotation.x -= input_dir.y * rotation_speed * delta
	rotation.x = clamp(rotation.x, deg_to_rad(-80), deg_to_rad(-10))

func _unhandled_input(event):
	# Detectar la rueda del ratón para el Zoom
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			# Acercar
			spring_arm.spring_length -= zoom_speed
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			# Alejar
			spring_arm.spring_length += zoom_speed
			
		# Limitar el zoom para que no traspase la bola ni se vaya al infinito
		spring_arm.spring_length = clamp(spring_arm.spring_length, min_zoom, max_zoom)
