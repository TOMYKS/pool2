extends RefCounted

enum Grupo { SIN_ASIGNAR, LISAS, RAYADAS }
var turno := 1
var grupos := [Grupo.SIN_ASIGNAR, Grupo.SIN_ASIGNAR]
var restantes: Array[int] = []
var saque := true
var ganador := 0
var en_tiro := false
var primer_contacto := -1
var banda_despues := false
var bolas_en_banda: Dictionary = {}
var embocadas: Array[int] = []
var fuera: Array[int] = []
var blanca_falta := false
var blanca_embocada := false
var objetivo_ocho := false
var ocho_mortal_embocado := false


func _init() -> void:
	for numero in range(1, 16):
		restantes.append(numero)


func grupo_de(numero: int) -> Grupo:
	if numero >= 1 and numero <= 7:
		return Grupo.LISAS
	if numero >= 9 and numero <= 15:
		return Grupo.RAYADAS
	return Grupo.SIN_ASIGNAR


func pendientes(jugador: int) -> Array[int]:
	var lista: Array[int] = []
	for numero in restantes:
		if grupo_de(numero) == grupos[jugador - 1] and numero != 8:
			lista.append(numero)
	return lista


func iniciar_tiro() -> void:
	if ganador != 0 or en_tiro:
		return
	en_tiro = true
	primer_contacto = -1
	banda_despues = false
	bolas_en_banda.clear()
	embocadas.clear()
	fuera.clear()
	blanca_falta = false
	blanca_embocada = false
	ocho_mortal_embocado = false
	objetivo_ocho = grupos[turno - 1] != Grupo.SIN_ASIGNAR and pendientes(turno).is_empty()


func contacto(numero: int) -> void:
	if en_tiro and primer_contacto == -1 and numero > 0:
		primer_contacto = numero


func banda(numero: int) -> void:
	if en_tiro and primer_contacto != -1:
		banda_despues = true
		if numero > 0:
			bolas_en_banda[numero] = true


func retirar(numero: int, tronera: bool, ocho_mortal := false) -> void:
	if not en_tiro:
		return
	if numero == 0:
		blanca_falta = true
		blanca_embocada = tronera
		return
	if not restantes.has(numero):
		return
	restantes.erase(numero)
	if tronera:
		# Guardar el estado al caer, aunque el poder venza antes de resolver.
		ocho_mortal_embocado = ocho_mortal_embocado or ocho_mortal
		embocadas.append(numero)
	else:
		fuera.append(numero)


func finalizar_tiro() -> Dictionary:
	if not en_tiro:
		return {}
	en_tiro = false
	if ocho_mortal_embocado:
		ganador = 3 - turno
		return {"ganador": ganador, "mensaje": "El jugador %d pierde por embocar una bola 8 durante Ochos malditos." % turno}
	# Regla de esta variante: la 8 embocada en el saque siempre reinicia.
	if saque and embocadas.has(8):
		return {"reiniciar": true, "mensaje": "La 8 entró en el saque. Se reinicia la partida."}
	var falta := ""
	if blanca_falta:
		falta = "La blanca entró en una tronera." if blanca_embocada else "La blanca salió de la mesa."
	elif not fuera.is_empty():
		falta = "Una bola salió de la mesa."
	elif primer_contacto == -1:
		falta = "La blanca no tocó ninguna bola."
	elif not saque and objetivo_ocho and primer_contacto != 8:
		falta = "Debías tocar primero la bola 8."
	elif not saque and not objetivo_ocho and grupos[turno - 1] != Grupo.SIN_ASIGNAR and grupo_de(primer_contacto) != grupos[turno - 1]:
		falta = "La primera bola tocada no era de tu grupo."
	elif not saque and grupos[turno - 1] == Grupo.SIN_ASIGNAR and primer_contacto == 8:
		falta = "No se puede tocar primero la 8 con la mesa abierta."
	elif saque and embocadas.is_empty() and bolas_en_banda.size() < 4:
		falta = "Saque inválido: debían llegar cuatro bolas a banda o entrar una."

	if embocadas.has(8) or fuera.has(8):
		ganador = turno if objetivo_ocho and falta.is_empty() and embocadas.has(8) else 3 - turno
		var mensaje := "Bola 8 embocada legalmente."
		if fuera.has(8):
			mensaje = "El jugador %d pierde porque la bola 8 salió de la mesa." % turno
		elif blanca_falta:
			if blanca_embocada:
				mensaje = "El jugador %d pierde por embocar la negra y la blanca en el mismo tiro." % turno
			else:
				mensaje = "El jugador %d pierde: embocó la negra y la blanca salió de la mesa en el mismo tiro." % turno
		elif not objetivo_ocho:
			mensaje = "El jugador %d pierde por embocar la 8 antes de terminar su grupo en un tiro anterior." % turno
		elif not falta.is_empty():
			mensaje = "El jugador %d pierde por embocar la 8 con falta: %s" % [turno, falta]
		return {"ganador": ganador, "mensaje": mensaje}

	if not saque and falta.is_empty() and grupos[turno - 1] == Grupo.SIN_ASIGNAR:
		for numero in embocadas:
			var grupo := grupo_de(numero)
			if grupo != Grupo.SIN_ASIGNAR:
				grupos[turno - 1] = grupo
				grupos[2 - turno] = Grupo.RAYADAS if grupo == Grupo.LISAS else Grupo.LISAS
				break
	var continua := false
	if falta.is_empty():
		for numero in embocadas:
			if saque or grupo_de(numero) == grupos[turno - 1]:
				continua = true
	saque = false
	if not continua:
		turno = 3 - turno
	return {"bola_en_mano": not falta.is_empty(), "mensaje": falta if not falta.is_empty() else ("Bola embocada: continúa el turno." if continua else "Cambio de turno.")}
