extends Node3D

@export var world_size: Vector3 = Vector3(128, 64, 128)
@export_range(-1, 1, 0.01) var cutoff: float = 0.5
@export var noise: FastNoiseLite

@onready var default_cube: CSGBox3D = $DefaultCube
@onready var multi_mesh_instance_3d: MultiMeshInstance3D = $MultiMeshInstance3D

var data: Array[Vector3] = []

func  _ready() -> void:
	randomize()
	if !noise:
		noise = FastNoiseLite.new()
	noise.seed = randi()
	var gen_start_time = Time.get_ticks_usec()
	
	Performance.add_custom_monitor("game/cubes", func(): return data.size())
	
	for x in range(-world_size.x / 2, world_size.x / 2):
		for y in range(world_size.y):
			for z in range(-world_size.z / 2, world_size.z / 2):
				var random = noise.get_noise_3d(x, y, z)
				if random > cutoff:
					data.append(Vector3(x, y, z))
					#var cube = default_cube.duplicate()
					#cube.position = Vector3(x, y, z)
					#var normalized_x = (x + world_size.x / 2) / world_size.x
					#var normalized_y = y / world_size.y
					#var normalized_z = (z + world_size.z / 2) / world_size.z
					#var color = Color(normalized_x, normalized_y, normalized_z)
					#cube.material = cube.material.duplicate()
					#cube.material.albedo_color = color
					#
					#add_child(cube)
					#
					#cubes += 1
	var gen_end_time = Time.get_ticks_usec()
	var gen_time = (gen_end_time - gen_start_time) / 1000000.0
	print_debug("Blocks in world: %s\nGen Time: %s" % [data.size(), gen_time])
	default_cube.queue_free()
	
	multi_mesh_instance_3d.multimesh.instance_count = data.size()
	
	for i in range(multi_mesh_instance_3d.multimesh.instance_count):
		multi_mesh_instance_3d.multimesh.set_instance_transform(i, Transform3D(Basis(), data[i]))
		var normalized_x = (data[i].x + world_size.x / 2) / world_size.x
		var normalized_y = data[i].y / world_size.y
		var normalized_z = (data[i].z + world_size.z / 2) / world_size.z
		var color = Color(normalized_x, normalized_y, normalized_z)
		multi_mesh_instance_3d.multimesh.set_instance_color(i, color)
