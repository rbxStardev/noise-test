extends Node
class_name ChunkManager

const CHUNK = preload("uid://cbijv5xmdkmxq")

@export var dimensions: Vector3 = Vector3(128, 64, 128)
@export var chunk_size: int = 32
@export var world_seed: int = 0

var loading_threads: Array[Thread] = [Thread.new(), Thread.new(), Thread.new(), Thread.new()]
var chunk_number: Vector3
var noise: Noise

var total_chunks: int = 0
var total_voxels: int = 0

var chunks_mutex: Mutex = Mutex.new()
var voxels_mutex: Mutex = Mutex.new()

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	noise = FastNoiseLite.new()
	noise.noise_type = FastNoiseLite.TYPE_SIMPLEX
	noise.frequency = 0.003
	noise.seed = world_seed
	
	chunk_number = dimensions / chunk_size
	
	Performance.add_custom_monitor("game/chunks", func(): return total_chunks)
	Performance.add_custom_monitor("game/voxels", func(): return total_voxels)
	
	loading_threads[0].start(generate_chunks.bind(Vector3(0,0,0)))
	loading_threads[1].start(generate_chunks.bind(Vector3(dimensions.x / 2, 0, 0)))
	loading_threads[2].start(generate_chunks.bind(Vector3(0, 0, dimensions.z / 2)))
	loading_threads[3].start(generate_chunks.bind(Vector3(dimensions.x / 2, 0, dimensions.z / 2)))


func generate_chunks(target_pos: Vector3) -> void:
	var chunks: Vector3 = chunk_number / 2
	var world_offset = Vector3(-dimensions.x / 2, 0, -dimensions.z / 2)  # Adiciona isso
	
	for x in range(chunks.x):
		for z in range(chunks.z):
			for y in range(chunk_number.y):
				var new_chunk: Chunk = CHUNK.instantiate()
				new_chunk.position = Vector3(x, y, z) * chunk_size + target_pos + world_offset  # Adiciona o offset aqui
				var voxels_in_chunk: int = new_chunk.generate_data(chunk_size, dimensions.y, noise)
				new_chunk.generate_mesh()
				call_deferred("add_child", new_chunk)
				
				chunks_mutex.lock()
				total_chunks += 1
				chunks_mutex.unlock()
				
				voxels_mutex.lock()
				total_voxels += voxels_in_chunk
				voxels_mutex.unlock()


func _exit_tree() -> void:
	for thread in loading_threads:
		thread.wait_to_finish()
