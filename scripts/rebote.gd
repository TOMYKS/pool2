extends Node3D 

var powerup_rebote_activo: bool = false


func _input(event):
	if event is InputEventKey and event.keycode == KEY_SPACE and event.pressed and not event.echo:
		if powerup_rebote_activo:
			desactivar_bolas_rebotonas()
		else:
			activar_bolas_rebotonas()
			

# Función auxiliar para encontrar la malla
func obtener_mesh(nodo_bola: Node) -> MeshInstance3D:
	for hijo in nodo_bola.get_children():
		if hijo is MeshInstance3D:
			return hijo
	return null

func activar_bolas_rebotonas():
	powerup_rebote_activo = true
	var bolas = get_tree().get_nodes_in_group("bolas_color")
	
	for bola in bolas:
		bola.set_meta("rebote_extra_banda", true)
		var mesh = obtener_mesh(bola)
		if mesh and mesh.get_active_material(0):
			var material = mesh.get_active_material(0)
			
			# 2. Saturamos los colores (Valores mayores a 1.0 sobreexponen el color)
			material.albedo_color = Color(1.5, 1.5, 1.5) 
			

func desactivar_bolas_rebotonas():
	powerup_rebote_activo = false
	var bolas = get_tree().get_nodes_in_group("bolas_color")
	
	for bola in bolas:
		bola.remove_meta("rebote_extra_banda")
		var mesh = obtener_mesh(bola)
		if mesh and mesh.get_active_material(0):
			var material = mesh.get_active_material(0)
			
			# 2. Restauramos los colores.
			material.albedo_color = Color(1.0, 1.0, 1.0)
