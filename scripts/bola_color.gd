extends RigidBody3D

# Referencia rápida al nodo de sonido que acabamos de crear
@onready var sonido_choque = $SonidoChoque
@onready var sonido_choque_blanca = $SonidoChoqueBlanca
# Esta función se ejecutará automáticamente cada vez que la bola golpee algo
func _on_body_entered(body):
	# Verificamos que el objeto con el que chocamos sea otra pelota
	if body.is_in_group("bolas_color"):
		
		# Calculamos la fuerza del impacto sumando las velocidades de ambas bolas
		var fuerza_impacto = linear_velocity.length() + body.linear_velocity.length()
		
		# Solo reproducimos el sonido si el choque fue medianamente fuerte (evita ruidos al rozarse despacio)
		if fuerza_impacto > 0.4:
			sonido_choque.play()
	if body.is_in_group("blanca"):
		
		# Calculamos la fuerza del impacto sumando las velocidades de ambas bolas
		var fuerza_impacto = linear_velocity.length() + body.linear_velocity.length()
		
		# Solo reproducimos el sonido si el choque fue medianamente fuerte (evita ruidos al rozarse despacio)
		if fuerza_impacto > 0.4:
			sonido_choque_blanca.play()
		
