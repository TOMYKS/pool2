import re

def patch_file(filepath):
    with open(filepath, "r", encoding="utf-8") as f:
        content = f.read()
    
    # Let's fix the cross product order in ball.gd so it curves in the expected direction (Right spin = Right curve)
    # cross(linear_velocity, angular_velocity) instead of cross(angular_velocity, linear_velocity)
    # Also we remove the limit of 10.0, or increase it.
    
    new_process = """func _physics_process(delta):
\t# Limitamos la velocidad lineal como medida de seguridad final
\tif linear_velocity.length() > 30.0:
\t\tlinear_velocity = linear_velocity.normalized() * 30.0
\t\t
\t# Si la pelota se está moviendo y además está girando sobre sí misma...
\tif linear_velocity.length() > 0.1 and angular_velocity.length() > 0.1:
\t\t
\t\t# En un billar arcade, el sidespin derecho debería curvar la bola hacia la derecha.
\t\t# Invertimos el producto cruz: linear_velocity.cross(angular_velocity)
\t\tvar fuerza_curva = linear_velocity.cross(angular_velocity) * magnus_multiplier
\t\t
\t\t# Anulamos el eje Y para evitar que el efecto haga volar la bola por los aires
\t\tfuerza_curva.y = 0 
\t\t
\t\t# Límite más holgado para permitir un swerve (curve) más notorio con el sidespin
\t\tif fuerza_curva.length() > 20.0:
\t\t\tfuerza_curva = fuerza_curva.normalized() * 20.0
\t\t
\t\t# Aplicamos la fuerza constante mientras ruede para curvar su trayectoria
\t\tapply_central_force(fuerza_curva)
"""
    
    idx_start = content.find("func _physics_process(delta):")
    if idx_start != -1:
        content = content[:idx_start] + new_process
        with open(filepath, "w", encoding="utf-8") as f:
            f.write(content)
    else:
        print("Could not find _physics_process in ball.gd")

patch_file("scripts/ball.gd")
print("Done patching ball.gd.")