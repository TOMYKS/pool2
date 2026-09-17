import re

def patch_file(filepath):
    with open(filepath, "r", encoding="utf-8") as f:
        content = f.read()
    
    # We will rewrite the arcade strike system in main.gd
    # We need to make sure the center hit is stronger than topspin, and sidespin works.
    
    new_system = """\t\t\t# ============================================
\t\t\t# SISTEMA DE GOLPE ARCADE
\t\t\t# ============================================
\t\t\t
\t\t\t# 1. DIRECCIÓN DEL GOLPE
\t\t\tvar hit_direction = -taco.global_transform.basis.z.normalized()
\t\t\t
\t\t\t# 4. CALCULAR OFFSET DEL PUNTO DE IMPACTO (Lo hacemos antes para saber la eficiencia)
\t\t\tvar offset_impacto = impact_point_global - ball.global_position
\t\t\tvar offset_normalizado = offset_impacto / ball_radius
\t\t\toffset_normalizado = Vector3(
\t\t\t\tclamp(offset_normalizado.x, -1.0, 1.0),
\t\t\t\tclamp(offset_normalizado.y, -1.0, 1.0),
\t\t\t\tclamp(offset_normalizado.z, -1.0, 1.0)
\t\t\t)
\t\t\t
\t\t\t# 2. POTENCIA (Ajustada para que el centro pegue más fuerte)
\t\t\tvar final_speed = max(max_forward_speed, abs(mouse_movement))
\t\t\t# Calculamos eficiencia: golpe al centro = 100%, borde = menos fuerza lineal
\t\t\tvar offset_length = offset_normalizado.length()
\t\t\tvar power_efficiency = 1.0 - (offset_length * 0.35) # Pierde hasta 35% de fuerza si pegas en el borde
\t\t\t
\t\t\tvar hit_force = final_speed * cue_speed_multiplier * 2.5 * power_efficiency
\t\t\thit_force = clamp(hit_force, 0.5, 20.0)
\t\t\t
\t\t\t# 3. IMPULSO LINEAL PURO
\t\t\tball.apply_central_impulse(hit_direction * hit_force)
\t\t\t
\t\t\t# ============================================
\t\t\t# MULTIPLICADORES INDEPENDIENTES
\t\t\t# ============================================
\t\t\tvar right_axis = hit_direction.cross(Vector3.UP).normalized()
\t\t\tvar topspin_amount = -offset_normalizado.y
\t\t\tvar sidespin_amount = offset_normalizado.dot(right_axis)
\t\t\t
\t\t\tvar spin_torque = Vector3.ZERO
\t\t\t
\t\t\t# Topspin / Backspin: 
\t\t\tvar topspin_multiplier = 0.5
\t\t\tspin_torque += right_axis * (topspin_amount * topspin_multiplier)
\t\t\t
\t\t\t# Sidespin:
\t\t\tvar sidespin_multiplier = 1.0
\t\t\tspin_torque += Vector3.UP * (sidespin_amount * sidespin_multiplier)
\t\t\t
\t\t\t# Aplicamos la fuerza del golpe al giro resultante
\t\t\t# NOTA: Usamos la velocidad antes de aplicar la eficiencia para que el efecto sea pronunciado
\t\t\tvar raw_force = final_speed * cue_speed_multiplier * 2.5
\t\t\traw_force = clamp(raw_force, 0.5, 20.0)
\t\t\tspin_torque *= raw_force
\t\t\t
\t\t\t# Para que el sidespin sea útil, subimos el max_torque temporalmente si es necesario
\t\t\tvar dynamic_max_torque = max_torque * 2.0
\t\t\tif spin_torque.length() > dynamic_max_torque:
\t\t\t\tspin_torque = spin_torque.normalized() * dynamic_max_torque
\t\t\t
\t\t\tball.apply_torque_impulse(spin_torque)
\t\t\t
\t\t\tprint("--- GOLPE ARCADE ---")
\t\t\tprint("  Fuerza lineal: ", hit_force)
\t\t\tprint("  Eficiencia: ", power_efficiency)
\t\t\tprint("  Topspin: ", topspin_amount, " | Sidespin: ", sidespin_amount)
"""
    
    start_str = "\t\t\t# ============================================\n\t\t\t# SISTEMA DE GOLPE ARCADE"
    end_str = "\t\t\t\t\t\t# 2. CAMBIO DE CÁMARA A LA MESA"
    
    idx_start = content.find(start_str)
    # the existing code might have some spaces or tabs. We will search for a safer substring.
    idx_start = content.find("# SISTEMA DE GOLPE ARCADE")
    if idx_start != -1:
        idx_start -= 4 # Back up to the tabs
        
    idx_end = content.find("# 2. CAMBIO DE C")
    if idx_end != -1:
        idx_end -= 7 # Back up to the tabs
    
    if idx_start != -1 and idx_end != -1:
        new_content = content[:idx_start] + new_system + "\n" + content[idx_end:]
        with open(filepath, "w", encoding="utf-8") as f:
            f.write(new_content)
    else:
        print("Could not find replacement bounds!")
        print(idx_start, idx_end)

patch_file("scripts/main.gd")
print("Done patching main.gd.")