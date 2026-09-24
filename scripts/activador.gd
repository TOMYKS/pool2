extends Area3D

signal recogido
var consumido := false


func _ready() -> void:
	body_entered.connect(_al_entrar)


func _al_entrar(body: Node3D) -> void:
	if not consumido and body.is_in_group("blanca"):
		consumido = true
		hide()
		set_deferred("monitoring", false)
		recogido.emit()


func comprobar_recorrido(blanca: RigidBody3D, desde: Vector3, hasta: Vector3) -> void:
	# El Area puede saltarse un contacto si la blanca cruza muy rápido.
	var cercano := Geometry3D.get_closest_point_to_segment(global_position, desde, hasta)
	if cercano.distance_to(global_position) <= 0.40:
		_al_entrar(blanca)
