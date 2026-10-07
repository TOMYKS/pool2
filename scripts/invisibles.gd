extends Node3D


func obtener_mesh(nodo_bola: Node) -> MeshInstance3D:
	for hijo in nodo_bola.get_children():
		if hijo is MeshInstance3D:
			return hijo
	return null

func activar_bolas_invisibles():
	var bolas = get_tree().get_nodes_in_group("bolas_color")
	
	for bola in bolas:
		var mesh = obtener_mesh(bola)
		if mesh:
			mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_SHADOWS_ONLY

func desactivar_bolas_invisibles():
	var bolas = get_tree().get_nodes_in_group("bolas_color")
	
	for bola in bolas:
		var mesh = obtener_mesh(bola)
		if mesh:
			mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
