extends Node3D

var powerup_fantasmas_activo: bool = false
var bolas_fantasmas: Array[RigidBody3D] = []

func _input(event):
	# Prueba con barra espaciadora
	if event is InputEventKey and event.keycode == KEY_SPACE and event.pressed and not event.echo:
		if powerup_fantasmas_activo:
			desactivar_bolas_fantasmas()
		else:
			activar_bolas_fantasmas()

func activar_bolas_fantasmas():
	powerup_fantasmas_activo = true
	var todas_las_bolas = get_tree().get_nodes_in_group("bolas_color")
	
	var bolas_mezcladas = todas_las_bolas.duplicate()
	bolas_mezcladas.shuffle()
	
	var cantidad_a_afectar = bolas_mezcladas.size() / 2
	var bolas_blancas = get_tree().get_nodes_in_group("blanca")
	
	for i in range(cantidad_a_afectar):
		var bola_fantasma = bolas_mezcladas[i] as RigidBody3D
		bolas_fantasmas.append(bola_fantasma)
		
		for otra_bola in todas_las_bolas:
			if otra_bola != bola_fantasma:
				# Hacemos la excepción bidireccional por seguridad
				bola_fantasma.add_collision_exception_with(otra_bola)
				otra_bola.add_collision_exception_with(bola_fantasma)

		for blanca in bolas_blancas:
			bola_fantasma.add_collision_exception_with(blanca)
			blanca.add_collision_exception_with(bola_fantasma)

func desactivar_bolas_fantasmas():
	powerup_fantasmas_activo = false
	var todas_las_bolas = get_tree().get_nodes_in_group("bolas_color")
	var bolas_blancas = get_tree().get_nodes_in_group("blanca")

	for bola_fantasma in bolas_fantasmas:
		if is_instance_valid(bola_fantasma):
			
			for otra_bola in todas_las_bolas:
				if is_instance_valid(otra_bola) and otra_bola != bola_fantasma:
					bola_fantasma.remove_collision_exception_with(otra_bola)
					otra_bola.remove_collision_exception_with(bola_fantasma)
					
			for blanca in bolas_blancas:
				if is_instance_valid(blanca):
					bola_fantasma.remove_collision_exception_with(blanca)
					blanca.remove_collision_exception_with(bola_fantasma)
					
	bolas_fantasmas.clear()
