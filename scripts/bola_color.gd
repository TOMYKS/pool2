extends RigidBody3D

const Fisica = preload("res://scripts/fisica_bola.gd")

var _velocidad_anterior := Vector3.ZERO
var _reposo := preload("res://scripts/reposo_bola.gd").new()

# Configurado para todas las bolas de color desde el Inspector de Sala.
var velocidad_vertical_maxima: float = 0.0
var desaceleracion_rodadura: float = 0.418514221
var roce_velocidad: float = 0.0


func _ready() -> void:
	preload("res://scripts/fisica_bola.gd").preparar(self)

func _integrate_forces(state: PhysicsDirectBodyState3D) -> void:
	var radio := Fisica.radio_de(self)
	if has_meta("rebote_extra_banda"):
		Fisica.aplicar_rebote_extra_banda(state, _velocidad_anterior, radio)
	Fisica.actualizar_contactos(self, state)
	Fisica.integrar(state, velocidad_vertical_maxima, desaceleracion_rodadura, roce_velocidad, radio)
	_velocidad_anterior = state.linear_velocity

func _physics_process(delta: float) -> void:
	preload("res://scripts/fisica_bola.gd").anticipar_contactos(self, delta)
	_reposo.actualizar(self, delta)

# Referencia rápida al nodo de sonido que acabamos de crear
@onready var sonido_choque = $SonidoChoque
@onready var sonido_choque_blanca = $SonidoChoqueBlanca
# Esta función se ejecutará automáticamente cada vez que la bola golpee algo
func _on_body_entered(body):
	# Verificamos que el objeto con el que chocamos sea otra pelota
	# 1. PRIMERO verificamos que el objeto con el que chocamos sea otra pelota (RigidBody3D)
	if body.is_in_group("bolas_color") or body.is_in_group("blanca"):
		
		# 2. AHORA SÍ, como sabemos que es una pelota, podemos calcular su velocidad de forma segura
		var fuerza_impacto = linear_velocity.length() + body.linear_velocity.length()
		
		# 3. Solo continuamos si el choque fue perceptible
		if fuerza_impacto > 0.2:
			
			# -- CONFIGURACIÓN DEL LERP --
			var fuerza_maxima_esperada = 20.0 
			var db_minimos = -17.0 
			var db_maximos = 6.0   
			
			var fuerza_limitada = clamp(fuerza_impacto, 0.4, fuerza_maxima_esperada)
			var peso_impacto = inverse_lerp(0.4, fuerza_maxima_esperada, fuerza_limitada)
			var volumen_final = lerp(db_minimos, db_maximos, peso_impacto)
			
			# 4. Elegimos qué sonido reproducir y le aplicamos los decibeles calculados
			if body.is_in_group("bolas_color"):
				sonido_choque.volume_db = volumen_final
				sonido_choque.play()
				
			elif body.is_in_group("blanca"):
				sonido_choque_blanca.volume_db = volumen_final
				sonido_choque_blanca.play()
