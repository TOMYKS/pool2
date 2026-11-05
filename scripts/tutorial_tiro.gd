extends PanelContainer

const Estilo = preload("res://scripts/estilo_menu.gd")
const INSTRUCCIONES := [
	"Hacé clic en la blanca y mantenelo.",
	"Arrastrá hacia atrás para cargar el golpe.",
	"Deslizá hacia adelante sin soltar el clic.",
]

@onready var partida = get_parent().get_parent()
@onready var sala = partida.sala
@onready var hud: Control = get_parent().get_node("Panel")
var instruccion: Label
var fondo: StyleBoxFlat
var altura_punta := 0.0

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	fondo = Estilo.cartel()
	fondo.content_margin_left = 14
	fondo.content_margin_right = 14
	fondo.content_margin_top = 8
	fondo.content_margin_bottom = 8
	add_theme_stylebox_override("panel", fondo)
	instruccion = Label.new()
	instruccion.mouse_filter = Control.MOUSE_FILTER_IGNORE
	instruccion.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	instruccion.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	instruccion.add_theme_font_override("font", Estilo.FUENTE_BOTON)
	instruccion.add_theme_font_size_override("font_size", 20)
	instruccion.add_theme_color_override("font_color", Estilo.TEXTO)
	add_child(instruccion)
	hide()


func _process(_delta: float) -> void:
	visible = _actualizar_cartel()


func _actualizar_cartel() -> bool:
	if get_tree().paused or partida.jugador_2_cpu or not partida.puede_apuntar():
		return false
	if partida.tutorial_completado[partida.reglas.turno - 1] or sala.camara_en_transicion():
		return false
	var camara := get_viewport().get_camera_3d()
	var blanca: Vector3 = sala.ball.global_position
	if camara == null or camara.is_position_behind(blanca):
		return false
	var pantalla := get_viewport_rect()
	var centro := camara.unproject_position(blanca)
	if not pantalla.has_point(centro):
		return false
	var paso := 0
	if sala.is_hitting_mode:
		paso = 2 if sala._golpe_armado else 1
	instruccion.text = INSTRUCCIONES[paso]
	var ancho := minf(340.0, centro.x - 52.0)
	if ancho < 150.0:
		return false
	size = Vector2(ancho, 0.0)
	var piso_hud := hud.get_global_rect().end.y + 8.0
	var y := centro.y - size.y * 0.5
	position = Vector2(
		centro.x - size.x - 40.0,
		clampf(y, piso_hud, maxf(piso_hud, pantalla.size.y - size.y - 12.0))
	)
	altura_punta = centro.y - position.y
	queue_redraw()
	return true


func _draw() -> void:
	if fondo == null:
		return
	var centro_borde := clampf(altura_punta, 15.0, size.y - 15.0)
	var arriba := Vector2(size.x - 1.0, centro_borde - 7.0)
	var abajo := Vector2(size.x - 1.0, centro_borde + 7.0)
	var punta := Vector2(size.x + 14.0, altura_punta)
	draw_colored_polygon(PackedVector2Array([arriba, punta, abajo]), fondo.bg_color)
	draw_polyline(PackedVector2Array([arriba, punta, abajo]), fondo.border_color, 1.0, true)
