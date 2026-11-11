extends RigidBody3D

@export var magnus_multiplier: float = 0.3
var _tiempo_comba := 0.0
var _reposo := preload("res://scripts/reposo_bola.gd").new()

# Comparte el ajuste de ascenso de las bolas de color desde Sala.
var velocidad_vertical_maxima: float = 0.0
var desaceleracion_rodadura: float = 0.418514221
var roce_velocidad: float = 0.0


func _ready() -> void:
	preload("res://scripts/fisica_bola.gd").preparar(self)

func iniciar_comba() -> void:
	_tiempo_comba = 0.65


func _integrate_forces(state: PhysicsDirectBodyState3D) -> void:
	var factor_comba := minf(_tiempo_comba / 0.2, 1.0)
	_tiempo_comba = maxf(0.0, _tiempo_comba - state.step)
	preload("res://scripts/fisica_bola.gd").actualizar_contactos(self, state)
	preload("res://scripts/fisica_bola.gd").integrar(state, velocidad_vertical_maxima, desaceleracion_rodadura, roce_velocidad, preload("res://scripts/fisica_bola.gd").radio_de(self), factor_comba)

func _physics_process(delta):
	preload("res://scripts/fisica_bola.gd").anticipar_contactos(self, delta)
	_reposo.actualizar(self, delta)
