@tool
extends MeshInstance3D

const PUNTAS := 8
const SEGMENTOS := 128
const BASE := 0.135


func _ready() -> void:
	# Corona hueca: pared exterior, interior y canto superior.
	var superficie := SurfaceTool.new()
	superficie.begin(Mesh.PRIMITIVE_TRIANGLES)
	for segmento in range(SEGMENTOS):
		var a := TAU * segmento / SEGMENTOS
		var b := TAU * (segmento + 1) / SEGMENTOS
		var cima_a := _cima(a)
		var cima_b := _cima(b)
		var base_a := Vector3(cos(a) * 0.165, BASE, sin(a) * 0.165)
		var base_b := Vector3(cos(b) * 0.165, BASE, sin(b) * 0.165)
		var dentro_a := cima_a - Vector3(cos(a), 0, sin(a)) * 0.012
		var dentro_b := cima_b - Vector3(cos(b), 0, sin(b)) * 0.012
		var base_dentro_a := base_a - Vector3(cos(a), 0, sin(a)) * 0.012
		var base_dentro_b := base_b - Vector3(cos(b), 0, sin(b)) * 0.012
		_cuadrilatero(superficie, base_a, cima_a, cima_b, base_b)
		_cuadrilatero(superficie, base_dentro_b, dentro_b, dentro_a, base_dentro_a)
		_cuadrilatero(superficie, cima_a, dentro_a, dentro_b, cima_b)
		_cuadrilatero(superficie, base_b, base_dentro_b, base_dentro_a, base_a)
	mesh = superficie.commit()
	# Remates redondos en cada punta, como en la referencia.
	var remate := SphereMesh.new()
	remate.radius = 0.021
	remate.height = 0.042
	remate.radial_segments = 16
	remate.rings = 8
	for punta in range(PUNTAS):
		var bolita := MeshInstance3D.new()
		bolita.mesh = remate
		bolita.material_override = material_override
		bolita.position = _cima(TAU * punta / PUNTAS)
		add_child(bolita)


func _cima(angulo: float) -> Vector3:
	var pico := pow((cos(angulo * PUNTAS) + 1.0) * 0.5, 1.5)
	var radio := 0.178 + pico * 0.04
	return Vector3(cos(angulo) * radio, 0.205 + pico * 0.18, sin(angulo) * radio)


func _cuadrilatero(superficie: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, d: Vector3) -> void:
	var normal := (b - a).cross(c - a).normalized()
	superficie.set_normal(normal)
	for vertice in [a, b, c, a, c, d]:
		superficie.add_vertex(vertice)
