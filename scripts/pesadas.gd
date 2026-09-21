extends Node3D

var powerup_pesado_activo: bool = false
var masa_original: float = 0.8
var masa_pesada: float = 3.5 

func _input(event):
	if event is InputEventKey and event.keycode == KEY_SPACE and event.pressed and not event.echo:
		if powerup_pesado_activo:
			desactivar_bolas_pesadas()
		else:
			activar_bolas_pesadas()

# Función auxiliar para encontrar la malla sin importar su nombre
func obtener_mesh(nodo_bola: Node) -> MeshInstance3D:
	for hijo in nodo_bola.get_children():
		if hijo is MeshInstance3D:
			return hijo
	return null

func activar_bolas_pesadas():
	powerup_pesado_activo = true
	var bolas = get_tree().get_nodes_in_group("bolas_color")
	
	for bola in bolas:
		bola.mass = masa_pesada
		
		var mesh = obtener_mesh(bola)
		if mesh and mesh.get_active_material(0):
			var material = mesh.get_active_material(0)
			
			# 1. Teñimos la textura de gris oscuro para dar el tono pesado
			material.albedo_color = Color(0.95, 0.95, 0.95) 
			# 2. Subimos el metal y bajamos la rugosidad para que brille
			material.metallic = 0.8
			material.roughness = 0.3
			
	print("🔋 POWER-UP ON: ¡Las bolas de color ahora son de metal oscuro (Masa: ", masa_pesada, ")!")

func desactivar_bolas_pesadas():
	powerup_pesado_activo = false
	var bolas = get_tree().get_nodes_in_group("bolas_color")
	
	for bola in bolas:
		bola.mass = masa_original
		
		var mesh = obtener_mesh(bola)
		if mesh and mesh.get_active_material(0):
			var material = mesh.get_active_material(0)
			
			# Restauramos los valores a como estaban en tu Inspector original
			material.albedo_color = Color(1.0, 1.0, 1.0) # Blanco = Textura original al 100%
			material.metallic = 0.0
			material.roughness = 1.0
			
	print("🔋 POWER-UP OFF: Las bolas de color volvieron a la normalidad.")	
# ====================================================================
# 2. IMPLEMENTACIÓN FUTURA CON TRIGGERS (Áreas en la mesa)
# ====================================================================
# Cuando tengan un objeto físico en la mesa para el power-up, usarán
# señales (Signals) de un Area3D para activarlo y desactivarlo.
#
# func _on_trigger_encendido_body_entered(body):
# 	# Si la bola blanca toca el holograma/caja del power up
# 	if body.is_in_group("blanca") and not powerup_pesado_activo:
# 		activar_bolas_pesadas()
#       # Aquí podrías poner: queue_free() al holograma para que desaparezca
#
# func _on_trigger_apagado_body_entered(body):
# 	# Si la bola blanca toca otra zona, o si prefieres apagarlo por tiempo/turnos
# 	if body.is_in_group("blanca") and powerup_pesado_activo:
# 		desactivar_bolas_pesadas()
# ====================================================================
