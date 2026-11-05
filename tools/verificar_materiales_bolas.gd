extends SceneTree
func _initialize(): call_deferred("run")
func run():
 var sala = load("res://scenes/sala.tscn").instantiate()
 root.add_child(sala)
 var cantidad = 0
 for bola in get_nodes_in_group("bolas_color") + [sala.ball]:
  for visual in bola.get_children():
   if visual is MeshInstance3D and visual.mesh:
    for s in range(visual.mesh.get_surface_count()):
     var mat = visual.mesh.surface_get_material(s)
     assert(mat.texture_filter == 3)
     assert(mat.albedo_texture.resource_path.begins_with("res://assets/bolas_sin_costuras/"))
    cantidad += 1
 assert(cantidad == 16)
 print("OK: 16 bolas con mipmaps y atlas corregidos")
 quit()
