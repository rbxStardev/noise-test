extends Camera3D

# Configurações de movimento
@export var velocidade_base: float = 7.0
@export var velocidade_min: float = 5.0
@export var velocidade_max: float = 32.0
@export var incremento_velocidade: float = 1.0

# Configurações de rotação
@export var sensibilidade_mouse: float = 0.003

# Variáveis internas
var velocidade_atual: float
var rotacao_x: float = 0.0
var rotacao_y: float = 0.0

func _ready():
	velocidade_atual = velocidade_base

func _input(event):
	# Detecta quando o botão direito é pressionado/solto
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT:
		if event.pressed:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		else:
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	
	# Captura o movimento do mouse quando o botão direito está pressionado
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		rotacao_y -= event.relative.x * sensibilidade_mouse
		rotacao_x -= event.relative.y * sensibilidade_mouse
		rotacao_x = clamp(rotacao_x, -PI/2, PI/2)
		
		rotation.y = rotacao_y
		rotation.x = rotacao_x
	
	# Ajusta velocidade com scroll do mouse
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP and event.pressed:
			velocidade_atual = min(velocidade_atual + incremento_velocidade, velocidade_max)
			print("Velocidade: ", velocidade_atual)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN and event.pressed:
			velocidade_atual = max(velocidade_atual - incremento_velocidade, velocidade_min)
			print("Velocidade: ", velocidade_atual)

func _process(delta):
	# Movimento com WASD
	var direcao = Vector3.ZERO
	
	if Input.is_key_pressed(KEY_W):
		direcao -= transform.basis.z
	if Input.is_key_pressed(KEY_S):
		direcao += transform.basis.z
	if Input.is_key_pressed(KEY_A):
		direcao -= transform.basis.x
	if Input.is_key_pressed(KEY_D):
		direcao += transform.basis.x
	
	# Normaliza para manter velocidade consistente em diagonal
	if direcao.length() > 0:
		direcao = direcao.normalized()
	
	# Aplica movimento
	global_position += direcao * velocidade_atual * delta
