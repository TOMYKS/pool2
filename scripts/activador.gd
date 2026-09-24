extends Area3D

signal recogido
@export_range(0.0, 180.0, 5.0) var giro_grados_por_segundo := 60.0
@export_range(0.0, 0.1, 0.005) var amplitud_flotacion := 0.025
@export_range(0.5, 6.0, 0.1) var periodo_flotacion := 2.6

var consumido := false
var _fase := 0.0
@onready var _visual: Node3D = $BolaMisterio
@onready var _altura_base: float = _visual.position.y


func _ready() -> void:
	body_entered.connect(_al_entrar)


func _process(delta: float) -> void:
	if consumido:
		return
	# Solo animamos el modelo. El Area sigue a la altura de la blanca.
	_fase = fmod(_fase + TAU * delta / periodo_flotacion, TAU)
	_visual.position.y = _altura_base + sin(_fase) * amplitud_flotacion
	_visual.rotation.y = wrapf(_visual.rotation.y + deg_to_rad(giro_grados_por_segundo) * delta, 0.0, TAU)


func _al_entrar(body: Node3D) -> void:
	if not consumido and body.is_in_group("blanca"):
		consumido = true
		hide()
		set_deferred("monitoring", false)
		recogido.emit()


func comprobar_recorrido(blanca: RigidBody3D, desde: Vector3, hasta: Vector3) -> void:
	# El Area puede saltarse un contacto si la blanca cruza muy rápido.
	var cercano := Geometry3D.get_closest_point_to_segment(global_position, desde, hasta)
	# Radio del activador (0.14) más el de la blanca (0.14).
	if cercano.distance_to(global_position) <= 0.28:
		_al_entrar(blanca)
