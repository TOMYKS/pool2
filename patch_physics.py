import re

def patch_file(filepath):
    with open(filepath, "r", encoding="utf-8") as f:
        content = f.read()
    
    content = re.sub(r"radius = [\d\.]+", "radius = 0.14", content)
    
    node_pattern = r"(\[node name=\"Ball.*?\" type=\"RigidBody3D\".*?\]\n)(.*?)(?=\n\[)"
    
    def repl(m):
        header = m.group(1)
        props = m.group(2).split("\n")
        props = [p for p in props if not p.startswith("mass =") and not p.startswith("linear_damp =") and not p.startswith("angular_damp =") and not p.startswith("continuous_cd =") and p.strip() != ""]
        props.append("mass = 1.0")
        props.append("linear_damp = 0.5")
        props.append("angular_damp = 1.0")
        props.append("continuous_cd = true")
        return header + "\n".join(props) + "\n"
        
    content = re.sub(node_pattern, repl, content, flags=re.DOTALL)
    
    phys_pattern = r"(\[sub_resource type=\"PhysicsMaterial\".*?\]\n)(.*?)(?=\n\n|\n\[)"
    
    def phys_repl(m):
        header = m.group(1)
        return header + "friction = 0.1\nbounce = 0.8"
        
    content = re.sub(phys_pattern, phys_repl, content, flags=re.DOTALL)
    
    with open(filepath, "w", encoding="utf-8") as f:
        f.write(content)

patch_file("scenes/Ball0.tscn")
patch_file("scenes/Balls.tscn")
print("Done patching.")