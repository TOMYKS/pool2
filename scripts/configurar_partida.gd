extends ColorRect

var rival: OptionButton


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	color = Color(0.01, 0.02, 0.03, 0.9)
	mouse_filter = Control.MOUSE_FILTER_STOP
	var centro := CenterContainer.new()
	centro.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(centro)
	var panel := PanelContainer.new()
	centro.add_child(panel)
	var margen := MarginContainer.new()
	for lado in ["left", "right", "top", "bottom"]:
		margen.add_theme_constant_override("margin_" + lado, 24)
	panel.add_child(margen)
	var contenido := VBoxContainer.new()
	contenido.add_theme_constant_override("separation", 12)
	margen.add_child(contenido)
	var titulo := Label.new()
	titulo.text = "Nueva partida"
	titulo.add_theme_font_size_override("font_size", 28)
	contenido.add_child(titulo)
	rival = OptionButton.new()
	rival.add_item("Jugador 2: persona (local)")
	rival.add_item("Jugador 2: CPU Basico")
	contenido.add_child(rival)
	var comenzar := Button.new()
	comenzar.text = "Iniciar partida"
	comenzar.pressed.connect(func():
		get_parent().get_parent().comenzar_partida(rival.selected == 1))
	contenido.add_child(comenzar)
	rival.grab_focus()
