extends MeshInstance3D

@export var material: Material

@onready var collision_shape_3d: CollisionShape3D = $StaticBody3D/CollisionShape3D

enum Face{BOTTOM, FRONT, RIGHT, TOP, LEFT, BACK}

var surface_array: Array = []
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

func generate_mesh(data: Dictionary[Vector3, Color]) -> void:
	for target_position in data:
		for face_name in Face:
			var face = Face[face_name]
			if not has_neighbour(data, face, target_position):
				var color = data[target_position]
				add_face(face, target_position, color)
		#add_face(Face.FRONT, target_position)
		#add_face(Face.BACK, target_position)
		#add_face(Face.LEFT, target_position)
		#add_face(Face.RIGHT, target_position)
		#add_face(Face.TOP, target_position)
		#add_face(Face.BOTTOM, target_position)
	commit_mesh()


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
	if mesh == null:
		mesh = ArrayMesh.new()
	
	surface_array[Mesh.ARRAY_VERTEX] = vertices
	surface_array[Mesh.ARRAY_NORMAL] = normals
	surface_array[Mesh.ARRAY_COLOR] = colors
	
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, surface_array)
	mesh.surface_set_material(0, material)
	
	collision_shape_3d.shape = mesh.create_trimesh_shape()
