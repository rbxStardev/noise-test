extends Node3D

@export var world_size: Vector3 = Vector3(128, 64, 128)
@export_range(-1, 1, 0.01) var cutoff: float = 0.5
@export var noise: FastNoiseLite

@onready var mesh_instance_3d: MeshInstance3D = $MeshInstance3D

var count: int = 0
var data: Dictionary[Vector3, Color] = {}

func  _ready() -> void:
	randomize()
	if !noise:
		noise = FastNoiseLite.new()
		
	var gen_start_time = Time.get_ticks_usec()
	print_debug("Generating world... World Size: \nx: %s \ny: %s \nz: %s" % [world_size.x, world_size.y, world_size.z])
	
	Performance.add_custom_monitor("game/cubes", func(): return count)
	
	for x in range(-world_size.x / 2, world_size.x / 2):
		for y in range(world_size.y):
			for z in range(-world_size.z / 2, world_size.z / 2):
				var random = noise.get_noise_3d(x, y, z)
				if random > cutoff:
					var normalized_x = (x + world_size.x / 2) / world_size.x
					var normalized_y = y / world_size.y
					var normalized_z = (z + world_size.z / 2) / world_size.z
					var color = Color(normalized_x, normalized_y, normalized_z)
					data[Vector3(x, y, z)] = color
					count += 1

	var gen_end_time = Time.get_ticks_usec()
	var gen_time = (gen_end_time - gen_start_time) / 1000000.0
	print_debug("Gen Time: %s \nBlocks in world: %s" % [gen_time, count])
	
	mesh_instance_3d.generate_mesh(data)
