extends Node3D

## Misma tecla de prueba que los demás power-ups.
@export var tecla_activacion: Key = KEY_SPACE

const ALTURA_PANO := 4.1761234
const GROSOR := 0.18
const ALTURA := 1.2
const MARGEN_BOLAS := 0.15

@onready var pared: StaticBody3D = $Barrera
@onready var colision: CollisionShape3D = $Barrera/CollisionShape3D
@onready var malla: MeshInstance3D = $Barrera/MeshInstance3D

var powerup_pared_activo: bool = false
var _alternar_pendiente: bool = false
var _azar := RandomNumberGenerator.new()


func _ready() -> void:
	_azar.randomize()
	# La escena muestra una vista previa en el editor; jugando arranca apagada.
	pared.visible = false
	colision.disabled = true
	# Recursos propios para que varias instancias no compartan dimensiones.
	colision.shape = colision.shape.duplicate()
	malla.mesh = malla.mesh.duplicate()
	var bordes := get_parent().get_node_or_null("Mesa/Bordes") as StaticBody3D
	if bordes != null and bordes.physics_material_override != null:
		pared.physics_material_override = bordes.physics_material_override.duplicate()


func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == tecla_activacion:
		_alternar_pendiente = not _alternar_pendiente


func _physics_process(_delta: float) -> void:
	if not _alternar_pendiente:
		return
	_alternar_pendiente = false
	if powerup_pared_activo:
		desactivar_pared()
	else:
		activar_pared()


func activar_pared() -> bool:
	if powerup_pared_activo:
		return true
	var bolas := get_tree().get_nodes_in_group("bolas_color")
	bolas.append_array(get_tree().get_nodes_in_group("blanca"))
	# Reunimos posiciones válidas en las dos orientaciones antes de sortear.
	var candidatas: Array[Vector2] = []
	for eje in range(2):
		var limite := 3.2 if eje == 0 else 1.3
		for paso in range(65):
			var coordenada := lerpf(-limite, limite, paso / 64.0)
			if _posicion_libre(eje, coordenada, bolas):
				candidatas.append(Vector2(eje, coordenada))
	if candidatas.is_empty():
		print("PARED: No hay espacio libre para dividir la mesa. Probá después del tiro.")
		return false

	var elegida := candidatas[_azar.randi_range(0, candidatas.size() - 1)]
	var corta_x := int(elegida.x) == 0
	# Los extremos entran en las bandas para que no quede un hueco.
	var dimensiones := Vector3(GROSOR, ALTURA, 5.2) if corta_x else Vector3(10.2, ALTURA, GROSOR)
	var centro := Vector3(elegida.y, ALTURA_PANO + ALTURA / 2.0, 0) if corta_x else Vector3(0, ALTURA_PANO + ALTURA / 2.0, elegida.y)
	# Las medidas pertenecen a Sala, no al nodo Pared que puede haberse
	# movido en el editor. Evita sumar su altura a la altura del paño.
	var sala := get_parent() as Node3D
	pared.global_transform = sala.global_transform * Transform3D(Basis.IDENTITY, centro)
	(colision.shape as BoxShape3D).size = dimensiones
	(malla.mesh as BoxMesh).size = dimensiones
	colision.disabled = false
	pared.visible = true
	powerup_pared_activo = true
	print("POWER-UP ON: Pared aleatoria activada. ", OS.get_keycode_string(tecla_activacion), " para quitarla.")
	return true


func _posicion_libre(eje: int, coordenada: float, bolas: Array[Node]) -> bool:
	var lado_blanca := 0.0
	var lados_color: Array[float] = []
	for nodo in bolas:
		var bola := nodo as RigidBody3D
		if bola == null or bola.is_queued_for_deletion():
			continue
		var radio := 0.14
		for hijo in bola.get_children():
			if hijo is CollisionShape3D and hijo.shape is SphereShape3D:
				radio = hijo.shape.radius
				break
		var sala := get_parent() as Node3D
		var pos := sala.to_local(bola.global_position)
		var distancia := (pos.x if eje == 0 else pos.z) - coordenada
		if absf(distancia) < radio + GROSOR / 2.0 + MARGEN_BOLAS:
			return false
		if bola.is_in_group("blanca"):
			lado_blanca = signf(distancia)
		else:
			lados_color.append(signf(distancia))
	# Evita dejar a la blanca aislada de todas las bolas de color.
	return lado_blanca != 0.0 and lados_color.has(lado_blanca)


func desactivar_pared() -> void:
	colision.disabled = true
	pared.visible = false
	powerup_pared_activo = false
	print("POWER-UP OFF: Mesa completa disponible.")
