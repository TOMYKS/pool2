extends Node3D 

var powerup_rebote_activo: bool = false
var material_reboton: PhysicsMaterial

func _ready():
	# Creamos un material físico nuevo exclusivamente para el rebote
	material_reboton = PhysicsMaterial.new()
	# El rebote va de 0.0 a 1.0. (1.0 significa que nunca pierde energía al chocar)
	material_reboton.bounce = 1 
	material_reboton.absorbent = false # Asegura que la fuerza no se absorba
	material_reboton.friction = 0.01
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
		# 1. Sustituimos temporalmente las físicas de la bola por nuestro material rebotón
		bola.physics_material_override = material_reboton
		bola.mass = 0.4
		var mesh = obtener_mesh(bola)
		if mesh and mesh.get_active_material(0):
			var material = mesh.get_active_material(0)
			
			# 2. Saturamos los colores (Valores mayores a 1.0 sobreexponen el color)
			material.albedo_color = Color(1.5, 1.5, 1.5) 
			# 3. Activamos una ligera emisión de luz para que resalten
			material.emission_enabled = true
			# Si usas Godot 4.3+, puedes ajustar la energía. Si te da error, borra la línea de abajo:
			material.emission_energy_multiplier = 0.2 
			
	print("🔋 POWER-UP ON: ¡Bolas saltarinas y vibrantes activadas!")

func desactivar_bolas_rebotonas():
	powerup_rebote_activo = false
	var bolas = get_tree().get_nodes_in_group("bolas_color")
	
	for bola in bolas:
		# 1. Al asignarle 'null', la bola vuelve a usar su física normal por defecto
		bola.physics_material_override = null
		bola.mass = 0.8
		var mesh = obtener_mesh(bola)
		if mesh and mesh.get_active_material(0):
			var material = mesh.get_active_material(0)
			
			# 2. Restauramos los colores y apagamos la emisión
			material.albedo_color = Color(1.0, 1.0, 1.0)
			material.emission_enabled = false
			
	print("🔋 POWER-UP OFF: Las bolas volvieron a la normalidad.")
