extends Node3D

@export var ball: RigidBody3D
@onready var spring_arm: SpringArm3D = $SpringArm3D # Referencia al brazo de la cámara

@export var rotation_speed: float = 3.0
@export var mouse_sensitivity: float = 0.005 # Qué tan rápido gira con el ratón

# Variables para controlar el zoom
@export var zoom_speed: float = 0.2
@export var min_zoom: float = 0.4 # Distancia mínima
@export var max_zoom: float = 5.0 # Distancia máxima

var is_dragging_camera: bool = false # Rastrea si el clic derecho está apretado

func _process(delta):
	# El pivote sigue a la bola
	if ball:
		global_position = ball.global_position
		
	# Rotación con WASD o Flechas
	var input_dir = Input.get_vector("ui_right", "ui_left", "ui_down", "ui_up") 
	
	if input_dir != Vector2.ZERO:
		rotation.y -= input_dir.x * rotation_speed * delta
		rotation.x -= input_dir.y * rotation_speed * delta
		rotation.x = clamp(rotation.x, deg_to_rad(-80), deg_to_rad(-10))

func _unhandled_input(event):
	# 1. Detectar si presionamos o soltamos el clic derecho
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT:
		if event.pressed:
			is_dragging_camera = true
			# Atrapa el ratón para que no se salga de la ventana al girar
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		else:
			is_dragging_camera = false
			# Libera el ratón
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
			
	# 2. Rotar la cámara al mover el ratón (solo si el clic derecho está apretado)
	elif event is InputEventMouseMotion and is_dragging_camera:
		# event.relative nos da la distancia que recorrió el ratón desde el frame anterior
		rotation.y -= event.relative.x * mouse_sensitivity
		rotation.x -= event.relative.y * mouse_sensitivity
		
		# Limitamos la rotación arriba/abajo igual que con el teclado
		rotation.x = clamp(rotation.x, deg_to_rad(-80), deg_to_rad(-10))

	# 3. Detectar la rueda del ratón para el Zoom
	elif event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			spring_arm.spring_length -= zoom_speed
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			spring_arm.spring_length += zoom_speed
			
		spring_arm.spring_length = clamp(spring_arm.spring_length, min_zoom, max_zoom)
