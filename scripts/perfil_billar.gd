extends Resource

# Perfil independiente; parametros de choque medidos en la version online con REA.
# Escala existente: radio 0.14 / radio reglamentario 0.028575 ≈ 4.9.
@export var unidades_por_metro: float = 4.9
@export var friccion_deslizamiento: float = 0.1997830457035402
@export var friccion_rodadura: float = 0.008715414837205986
@export var friccion_giro: float = 0.02
@export var restitucion_bolas: float = 0.95
@export var restitucion_bandas: float = 0.78
@export var friccion_banda: float = 0.16
@export var friccion_bolas_lenta: float = 0.117951
@export var friccion_bolas_rapida: float = 0.009951
@export var velocidad_transicion_friccion: float = 0.919117647 # m/s de contacto
@export var masa_relativa_taco: float = 3.0
@export_range(0.0, 8.0, 0.1) var desvio_lateral_maximo_grados: float = 8.0
@export_range(0.0, 0.08, 0.001) var intensidad_comba: float = 0.012
@export_range(0.0, 1.0, 0.05) var intensidad_avance_retroceso: float = 0.70
@export var limite_efecto: float = 0.95 # fraccion del radio

func friccion_contacto(velocidad: float) -> float:
	return lerpf(friccion_bolas_rapida, friccion_bolas_lenta, exp(-absf(velocidad) / maxf(velocidad_transicion_friccion, 0.001)))
