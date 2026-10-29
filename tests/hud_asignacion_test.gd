extends SceneTree

func _initialize() -> void:
	call_deferred("probar")

func comprobar_fila(hud: Node, jugador: int, esperadas: Array) -> void:
	var numeros := []
	for bola in hud.bolas[jugador]:
		if bola.numero != 0:
			numeros.append(bola.numero)
	assert(numeros == esperadas, "La fila debe mostrar todas las embocadas de su grupo")

func probar() -> void:
	for grupo_asignador in [1, 9]:
		var sala = load("res://scenes/sala.tscn").instantiate()
		root.add_child(sala)
		await process_frame
		await process_frame
		var p = sala.get_node("Partida")
		var hud = p.get_node("HUD/Panel")
		p.comenzar_partida(false)
		paused = false
		for bola in get_nodes_in_group("bolas_color") + get_nodes_in_group("blanca"):
			bola.freeze = true
		var r = p.reglas
		# J1 emboca de ambos grupos en el saque; J2 todavía no jugó.
		r.iniciar_tiro()
		r.contacto(2)
		r.retirar(2, true)
		r.retirar(12, true)
		p.finalizar_tiro()
		assert(r.grupos == [0, 0])
		comprobar_fila(hud, 0, [])
		comprobar_fila(hud, 1, [])
		# J1 asigna los grupos en su siguiente tiro.
		r.iniciar_tiro()
		r.contacto(grupo_asignador)
		r.retirar(grupo_asignador, true)
		p.finalizar_tiro()
		assert(r.turno == 1)
		# Sin esperar frames ni otro tiro: ambas filas ya deben estar completas.
		comprobar_fila(hud, 0, [2, 1] if grupo_asignador == 1 else [12, 9])
		comprobar_fila(hud, 1, [12] if grupo_asignador == 1 else [2])
		sala.queue_free()
		await process_frame
	print("HUD ASIGNACION: ambos grupos visibles sin que J2 tire; OK")
	quit()
