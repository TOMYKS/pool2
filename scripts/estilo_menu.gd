extends RefCounted
## Paleta compartida por los carteles y controles del salón.

const ROSA := Color("#f4aad9")
const ORO := Color("#ffe6a3")
const TEXTO := Color("#f4eee2")
const SUAVE := Color("#aabbb0")
const FONDO := Color("#101d18")
const FUENTE_TITULO = preload("res://assets/menu/fuentes/Yellowtail-Regular.ttf")
const FUENTE_BOTON = preload("res://assets/menu/fuentes/BarlowCondensed-SemiBoldItalic.ttf")

static func caja(fondo: Color, borde: Color, radio := 8, margen := 16) -> StyleBoxFlat:
	var estilo := StyleBoxFlat.new()
	estilo.bg_color = fondo
	estilo.border_color = borde
	estilo.set_border_width_all(1)
	estilo.set_corner_radius_all(radio)
	estilo.set_content_margin_all(margen)
	return estilo

static func cartel() -> StyleBoxFlat:
	var estilo := caja(Color(0.025, 0.065, 0.045, 0.94), Color(0.96, 0.64, 0.83, 0.65), 14, 24)
	estilo.shadow_color = Color(0.95, 0.22, 0.59, 0.13)
	estilo.shadow_size = 18
	return estilo

static func principal(estado: String) -> StyleBoxFlat:
	var iluminado := estado in ["hover", "hover_pressed"]
	var estilo := caja(Color("#fff0bd") if iluminado else ORO, Color("#fff5d8"), 8, 14)
	if estado == "pressed":
		estilo.bg_color = Color("#dcbf78")
	estilo.shadow_color = Color(1.0, 0.75, 0.24, 0.25 if iluminado else 0.12)
	estilo.shadow_size = 14 if iluminado else 8
	return estilo

static func crear() -> Theme:
	var tema := Theme.new()
	tema.default_font_size = 19
	for tipo in ["Button", "OptionButton", "CheckButton", "PopupMenu"]:
		tema.set_font("font", tipo, FUENTE_BOTON)
		tema.set_font_size("font_size", tipo, 26)
	for tipo in ["Label", "Button", "CheckButton", "OptionButton", "LineEdit", "PopupMenu"]:
		tema.set_color("font_color", tipo, TEXTO)
	for estado in ["normal", "hover", "pressed", "hover_pressed", "disabled"]:
		var activo: bool = estado in ["hover", "pressed", "hover_pressed"]
		var estilo := caja(Color("#291d29") if activo else FONDO, ROSA if activo else Color("#425449"), 8, 16)
		estilo.content_margin_top = 12
		estilo.content_margin_bottom = 12
		estilo.content_margin_left = 20
		estilo.content_margin_right = 20
		if activo:
			estilo.shadow_color = Color(0.95, 0.25, 0.63, 0.12)
			estilo.shadow_size = 8
		for tipo in ["Button", "OptionButton"]:
			tema.set_stylebox(estado, tipo, estilo)
			tema.set_color("font_" + estado + "_color", tipo, ROSA if activo else TEXTO)
			tema.set_color("icon_" + estado + "_color", tipo, ROSA if activo else SUAVE)
	var foco := caja(Color.TRANSPARENT, ORO, 8, 0)
	foco.set_border_width_all(2)
	for tipo in ["Button", "OptionButton", "CheckButton", "LineEdit"]:
		tema.set_stylebox("focus", tipo, foco)
		tema.set_constant("h_separation", tipo, 14)
		tema.set_color("font_focus_color", tipo, TEXTO)
	tema.set_color("font_disabled_color", "Button", SUAVE.darkened(0.3))
	for tipo in ["LineEdit", "PopupMenu"]:
		tema.set_stylebox("normal" if tipo == "LineEdit" else "panel", tipo, caja(Color("#0c1712"), Color("#425449"), 8, 12))
	tema.set_color("font_placeholder_color", "LineEdit", Color("#91a496"))
	tema.set_color("caret_color", "LineEdit", ROSA)
	tema.set_color("selection_color", "LineEdit", Color("#703e63"))
	tema.set_stylebox("hover", "PopupMenu", caja(Color("#3e2638"), ROSA, 4, 10))
	tema.set_color("font_hover_color", "PopupMenu", ROSA)
	tema.set_constant("v_separation", "PopupMenu", 16)
	for estado in ["normal", "hover", "pressed", "hover_pressed"]:
		tema.set_stylebox(estado, "CheckButton", caja(Color("#17251a"), Color("#526348"), 8, 14))
	tema.set_color("font_hover_color", "CheckButton", ORO)
	tema.set_color("font_pressed_color", "CheckButton", ORO)
	tema.set_icon("checked", "CheckButton", preload("res://assets/menu/encendido.svg"))
	tema.set_icon("unchecked", "CheckButton", preload("res://assets/menu/apagado.svg"))
	tema.set_stylebox("slider", "HSlider", caja(Color("#293b30"), Color.TRANSPARENT, 3, 3))
	tema.set_stylebox("grabber_area", "HSlider", caja(ORO.darkened(0.2), Color.TRANSPARENT, 3, 3))
	tema.set_stylebox("grabber_area_highlight", "HSlider", caja(ORO, Color.TRANSPARENT, 3, 3))
	tema.set_icon("grabber", "HSlider", preload("res://assets/menu/deslizador.svg"))
	tema.set_icon("grabber_highlight", "HSlider", preload("res://assets/menu/deslizador.svg"))
	tema.set_stylebox("scroll", "VScrollBar", caja(Color(0.1, 0.15, 0.12, 0.3), Color.TRANSPARENT, 3, 3))
	for estado in ["grabber", "grabber_highlight", "grabber_pressed"]:
		tema.set_stylebox(estado, "VScrollBar", caja(ROSA.darkened(0.4), Color.TRANSPARENT, 3, 3))
	return tema
