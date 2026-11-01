extends Control
var numero := 0:
	set(valor):
		if numero == valor:
			return
		numero = valor
		if is_node_ready():
			_actualizar()
var embocada := false
var vista: SubViewport
var imagen: TextureRect
var rotulo: Label
var parche_numero: Control
var modelo: MeshInstance3D

func _ready() -> void:
	custom_minimum_size = Vector2(26, 26)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_actualizar()

func _actualizar() -> void:
	queue_redraw()
	if numero == 0:
		if imagen != null:
			imagen.hide()
		if rotulo != null:
			rotulo.hide()
		if parche_numero != null:
			parche_numero.hide()
		return
	if vista == null:
		vista = SubViewport.new()
		vista.size = Vector2i(96, 96)
		vista.transparent_bg = true
		vista.own_world_3d = true
		vista.render_target_update_mode = SubViewport.UPDATE_DISABLED
		add_child(vista)
		var entorno := WorldEnvironment.new()
		entorno.environment = Environment.new()
		entorno.environment.background_mode = Environment.BG_COLOR
		entorno.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
		entorno.environment.ambient_light_color = Color.WHITE
		entorno.environment.ambient_light_energy = 0.65
		vista.add_child(entorno)
		var luz := DirectionalLight3D.new()
		luz.rotation_degrees = Vector3(-35, -30, 0)
		luz.light_energy = 1.3
		vista.add_child(luz)
		modelo = MeshInstance3D.new()
		vista.add_child(modelo)
		var camara := Camera3D.new()
		camara.projection = Camera3D.PROJECTION_ORTHOGONAL
		camara.size = 2.25
		camara.position = Vector3(0, 0, 4)
		vista.add_child(camara)
		camara.make_current()
		imagen = TextureRect.new()
		imagen.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		imagen.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		imagen.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		imagen.mouse_filter = Control.MOUSE_FILTER_IGNORE
		imagen.texture = vista.get_texture()
		add_child(imagen)
		rotulo = Label.new()
		rotulo.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		rotulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		rotulo.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		rotulo.add_theme_font_size_override("font_size", 11)
		rotulo.add_theme_color_override("font_color", Color.BLACK)
		rotulo.mouse_filter = Control.MOUSE_FILTER_IGNORE
		# Dibujar el parche en el centro exacto, independiente del alto de la fuente.
		var parche := Control.new()
		parche_numero = parche
		parche.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		parche.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(parche)
		parche.draw.connect(func():
			if numero != 0:
				parche.draw_circle(parche.size * 0.5, 7.0, Color.WHITE)
		)
		parche.resized.connect(parche.queue_redraw)
		rotulo.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		add_child(rotulo)
	# Mismas mallas, UV y materiales que las bolas de Sala, sin recolorearlas.
	modelo.mesh = load("res://assets/Ball%d.res" % numero)
	var limites := modelo.mesh.get_aabb()
	var escala := 2.0 / maxf(limites.size.x, maxf(limites.size.y, limites.size.z))
	modelo.transform = Transform3D(Basis(Vector3.BACK, PI / 2 if numero >= 9 else 0.0) * escala, Vector3.ZERO)
	modelo.position = -(modelo.basis * limites.get_center())
	imagen.show()
	rotulo.text = str(numero)
	rotulo.show()
	parche_numero.show()
	parche_numero.queue_redraw()
	vista.render_target_update_mode = SubViewport.UPDATE_ONCE

func _draw() -> void:
	if numero == 0:
		var centro := size * 0.5
		var radio := minf(size.x, size.y) * 0.44
		draw_circle(centro, radio, Color("#071018"))
		draw_arc(centro, radio, 0, TAU, 48, Color("#53616d"), 1.2, true)
