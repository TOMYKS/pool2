extends Node3D

func _ready() -> void:
	_preparar_tubo([$Simply, $"Simply - bucle de la y"], $LuzSimply)
	_preparar_tubo([$POOL], $LuzPool)
	_preparar_tubo([$"Corona dorada", $"Corona - punta 2"], $LuzCorona)


func _preparar_tubo(piezas: Array[MeshInstance3D], luz: OmniLight3D) -> void:
	var material: StandardMaterial3D = piezas[0].get_surface_override_material(0).duplicate()
	for pieza in piezas:
		pieza.set_surface_override_material(0, material)
	_titilar(material, luz)


func _titilar(material: StandardMaterial3D, luz: OmniLight3D) -> void:
	var emision := material.emission_energy_multiplier
	var intensidad := luz.light_energy
	while true:
		await get_tree().create_timer(randf_range(8.0, 18.0), false).timeout
		_ajustar_brillo(material, luz, emision, intensidad, 0.35)
		await get_tree().create_timer(0.045, false).timeout
		_ajustar_brillo(material, luz, emision, intensidad, 1.0)
		await get_tree().create_timer(0.065, false).timeout
		_ajustar_brillo(material, luz, emision, intensidad, 0.55)
		await get_tree().create_timer(0.055, false).timeout
		_ajustar_brillo(material, luz, emision, intensidad, 1.0)


func _ajustar_brillo(material: StandardMaterial3D, luz: OmniLight3D, emision: float, intensidad: float, factor: float) -> void:
	material.emission_energy_multiplier = emision * factor
	luz.light_energy = intensidad * factor
