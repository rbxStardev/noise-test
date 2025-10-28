extends CharacterBody3D

# Configurações de movimento
@export_group("Movimento")
@export var velocidade_base: float = 5.0
@export var velocidade_min: float = 1.0
@export var velocidade_max: float = 15.0
@export var incremento_velocidade: float = 0.5
@export var aceleracao: float = 10.0
@export var desaceleracao: float = 8.0
@export var jump_velocity: float = 4.5

# Configurações de câmera
@export_group("Câmera")
@export var mouse_sensitivity: float = 0.003
@export var limite_vertical_min: float = -75.0
@export var limite_vertical_max: float = 75.0

# Referências aos nós
@onready var head: Node3D = $Head
@onready var camera_3d: Camera3D = $Head/Camera3D

# Variáveis internas
var velocidade_atual: float
var mouse_capturado: bool = false
var fly_mode: bool = false

func _ready():
	velocidade_atual = velocidade_base

func _input(event: InputEvent) -> void:
	# Detecta quando o botão direito é pressionado/solto
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT:
		if event.pressed:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
			mouse_capturado = true
		else:
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
			mouse_capturado = false
	
	# Ajusta velocidade com scroll do mouse
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP and event.pressed:
			velocidade_atual = min(velocidade_atual + incremento_velocidade, velocidade_max)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN and event.pressed:
			velocidade_atual = max(velocidade_atual - incremento_velocidade, velocidade_min)

func _unhandled_input(event: InputEvent) -> void:
	# Rotação da câmera apenas quando o mouse está capturado
	if event is InputEventMouseMotion and mouse_capturado:
		var relative = event.relative * mouse_sensitivity
		
		# Rotaciona o corpo (yaw)
		head.rotate_y(-relative.x)
		
		# Rotaciona a câmera (pitch) com limite
		camera_3d.rotate_x(-relative.y)
		camera_3d.rotation.x = clamp(
			camera_3d.rotation.x, 
			deg_to_rad(limite_vertical_min), 
			deg_to_rad(limite_vertical_max)
		)

func _physics_process(delta: float) -> void:
	# Toggle fly mode
	if Input.is_action_just_pressed("Fly"):
		fly_mode = !fly_mode
	
	if fly_mode:
		# Modo fly - movimento livre sem gravidade e colisão
		var input_dir := Input.get_vector("Left", "Right", "Down", "Up")
		
		# Pega a direção absoluta da câmera
		var camera_basis := camera_3d.global_transform.basis
		var forward := -camera_basis.z
		var right := camera_basis.x
		var up := camera_basis.y
		
		# Combina as direções (W/S = frente/trás, A/D = esquerda/direita)
		var direction := (right * input_dir.x + forward * input_dir.y).normalized()
		
		# Adiciona movimento vertical (Espaço = subir, Shift = descer)
		if Input.is_action_pressed("ui_accept"):
			direction += Vector3.UP
		if Input.is_key_pressed(KEY_SHIFT):
			direction += Vector3.DOWN
		
		direction = direction.normalized()
		
		# Move sem usar velocity e move_and_slide (movimento direto)
		if direction:
			global_position += direction * velocidade_atual * delta
	else:
		# Modo normal - com gravidade e colisão
		# Adiciona gravidade
		if not is_on_floor():
			velocity += get_gravity() * delta
		
		# Pulo
		if Input.is_action_just_pressed("ui_accept") and is_on_floor():
			velocity.y = jump_velocity
		
		# Obtém direção de input (WASD)
		var input_dir := Input.get_vector("Left", "Right", "Down", "Up")
		
		# Calcula direção baseada na rotação da cabeça (apenas horizontal)
		var head_basis := head.global_transform.basis
		var forward := -head_basis.z
		var right := head_basis.x
		
		# Projeta no plano horizontal (ignora Y)
		forward.y = 0
		right.y = 0
		forward = forward.normalized()
		right = right.normalized()
		
		# Combina as direções
		var direction := (right * input_dir.x + forward * input_dir.y).normalized()
		
		# Aplica movimento com aceleração/desaceleração suaves
		if direction:
			velocity.x = move_toward(velocity.x, direction.x * velocidade_atual, aceleracao * delta)
			velocity.z = move_toward(velocity.z, direction.z * velocidade_atual, aceleracao * delta)
		else:
			velocity.x = move_toward(velocity.x, 0, desaceleracao * delta)
			velocity.z = move_toward(velocity.z, 0, desaceleracao * delta)
		
		move_and_slide()
