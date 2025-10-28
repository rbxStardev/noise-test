extends StaticBody3D
class_name Chunk

@export var material: Material

@onready var collision_shape: CollisionShape3D = $CollisionShape3D
@onready var mesh_instance: MeshInstance3D = $MeshInstance3D

enum Face{BOTTOM, FRONT, RIGHT, TOP, LEFT, BACK}

var surface_array: Array = []
var voxels: Dictionary[Vector3, Color] = {}
var vertices = PackedVector3Array()
var normals = PackedVector3Array()
var colors = PackedColorArray()

var cube_vertices: Array[Vector3] = [
	Vector3(-0.5, -0.5, 0.5),
	Vector3(0.5, -0.5, 0.5),
	Vector3(0.5, -0.5, -0.5),
	Vector3(-0.5, -0.5, -0.5),
	Vector3(-0.5, 0.5, 0.5),
	Vector3(0.5, 0.5, 0.5),
	Vector3(0.5, 0.5, -0.5),
	Vector3(-0.5, 0.5, -0.5),
]

var face_indices: Dictionary[Face, Array] = {
	Face.FRONT: [[0, 4, 5], [0, 5, 1]],
	Face.BACK: [[2, 6, 7], [2, 7, 3]],
	Face.LEFT: [[3, 7, 4], [3, 4, 0]],
	Face.RIGHT: [[1, 5, 6], [1, 6, 2]],
	Face.BOTTOM: [[3, 0, 1], [3, 1, 2]],
	Face.TOP: [[4, 7, 6], [4, 6, 5]],
}

var face_normals: Dictionary[Face, Vector3] = {
	Face.FRONT: Vector3(0, 0, 1),
	Face.BACK: Vector3(0, 0, -1),
	Face.LEFT: Vector3(-1, 0, 0),
	Face.RIGHT: Vector3(1, 0, 0),
	Face.BOTTOM: Vector3(0, -1, 0),
	Face.TOP: Vector3(0, 1, 0),
}

var face_colors: Dictionary[Face, Color] = {
	Face.BOTTOM: Color.ORANGE,
	Face.FRONT: Color.RED,
	Face.RIGHT: Color.GREEN,
	Face.TOP: Color.BLUE,
	Face.LEFT: Color.YELLOW,
	Face.BACK: Color.PURPLE,
}

func _ready() -> void:
	surface_array.resize(Mesh.ARRAY_MAX)
	mesh_instance.mesh = ArrayMesh.new()
	if voxels.is_empty(): return
	commit_mesh()


func generate_data(chunk_size: int, max_height: int, noise: Noise) -> int:
	for x in range(chunk_size):
		for z in range(chunk_size):
			var global_target_pos: Vector3 = position + Vector3(x, 0, z)
			var rand = ((noise.get_noise_2d(global_target_pos.x, global_target_pos.z) + 0.5 * noise.get_noise_2d(global_target_pos.x * 2, global_target_pos.z * 2) + 0.25 * noise.get_noise_2d(global_target_pos.x * 4, global_target_pos.z * 4)) / 1.75 + 1) / 2
			var rand_p = pow(rand, 2.1)
			var height = max_height * rand_p
			
			if height < position.y: continue
			
			var local_height = height - position.y
			
			for y in range(min(local_height, chunk_size)):
				var global_y_pos = y + position.y
				
				var normalized_x = x / float(chunk_size - 1)
				var normalized_y = global_y_pos / float(max_height)
				var normalized_z = z / float(chunk_size - 1)
				var color = Color(normalized_x, normalized_z, normalized_y)
				voxels[Vector3(x, y, z)] = color
	
	return voxels.keys().size()


func generate_mesh() -> void:
	if voxels.is_empty(): return
	
	for target_position in voxels:
		for face_name in Face:
			var face = Face[face_name]
			if not has_neighbour(voxels, face, target_position):
				var color = voxels[target_position]
				add_face(face, target_position, color)
		#add_face(Face.FRONT, target_position)
		#add_face(Face.BACK, target_position)
		#add_face(Face.LEFT, target_position)
		#add_face(Face.RIGHT, target_position)
		#add_face(Face.TOP, target_position)
		#add_face(Face.BOTTOM, target_position)


func has_neighbour(data: Dictionary[Vector3, Color], face: Face, target_position: Vector3) -> bool:
	var neighbour_position = target_position + face_normals[face]
	if data.has(neighbour_position):
		return true
	else:
		return false


func add_face(face: Face, target_pos: Vector3, color: Color) -> void:
	var indices = face_indices[face]
	for triangle in indices:
		for index in triangle:
			vertices.append(cube_vertices[index] + target_pos)
			normals.append(face_normals[face])
			colors.append(color)

func commit_mesh() -> void:
	if mesh_instance.mesh == null:
		mesh_instance.mesh = ArrayMesh.new()
	
	surface_array[Mesh.ARRAY_VERTEX] = vertices
	surface_array[Mesh.ARRAY_NORMAL] = normals
	surface_array[Mesh.ARRAY_COLOR] = colors
	
	mesh_instance.mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, surface_array)
	mesh_instance.mesh.surface_set_material(0, material)
	
	collision_shape.shape = mesh_instance.mesh.create_trimesh_shape()
