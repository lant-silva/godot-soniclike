extends CharacterBody2D
# Personagem com física estilo Sonic (está muito mal feito :/)

# Flags
@export var onGround : bool
@export var onAir : bool
@export var downSlope : bool
@export var upSlope : bool
@export var currentAction : int 
@export var currentDirection : int
@export var moving : bool

# Enumerações
# As ações disponíveis do personagem
enum Action{
	IDLE,
	JUMP,
	WALK,
	DASH,
	STOP
}
# Que direção ele estará olhando
enum Direction{
	LEFT,
	RIGHT
}

# Constantes
const NORMAL_TOP_SPEED : float = 250.00 # Velocidade máxima ao andar normalmente
const DASH_TOP_SPEED : float = 300.00 # Velocidade máxima ao usar impulso
const ABS_TOP_SPEED : float = 500.00 # Velocidade máxima absoluta
const DASH : float = 200.0 # Velocidade de impulso
const GROUND_POUND : float = 500 # Força da investida no chão (quando vc segura o botão de agachar no ar)
const JUMP_VELOCITY : float = -350.0 # Força do pulo
const FRICTION : float = 2 # Força da fricção
const BRAKE_FRICTION : float = 10 # Força do freio
const AIR_FRICTION : float = 1.5 # Força da fricção no ar
const ACCEL : float = 3.25 # Força de aceleração
const DASH_ACCEL : float = 500 # Força de aceleração do impuslo

var count : int = 0
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")
var airJump : bool = true

func _ready():
	currentAction = Action.IDLE

func _physics_process(delta):
	print(get_floor_normal())
	gravity_handling(delta) # Função lida com a gravidade (tambem lida com algumas flags) 
	fisicaBotoes(delta) # Função lida com a física do personagem
	if velocity.x == 0 and velocity.y == 0:
		currentAction = Action.IDLE
	animacaoPersonagem() # Função lida com as animações

func animacaoPersonagem():
	var direction = Input.get_action_strength("move_right") - Input.get_action_strength("move_left")
	if velocity.x != 0 and velocity.x > 0 and is_on_floor():
		if direction == -1:
			$Sprite.animation = "stop"
			$Sprite.flip_h = false
		else:
			$Sprite.animation = "walk"
			$Sprite.flip_h = false
			if velocity.x > 150:
				$Sprite.speed_scale = 1.5
			elif velocity.x > 300:
				$Sprite.speed_scale = 2.25
			else:
				$Sprite.speed_scale = 1.0
	elif velocity.x != 0 and velocity.x < 0 and is_on_floor():
		if direction == 1:
			$Sprite.animation = "stop"
			$Sprite.flip_h = true
		else:
			$Sprite.animation = "walk"
			$Sprite.flip_h = true
			if velocity.x < -150:
				$Sprite.speed_scale = 1.5
			elif velocity.x < -300:
				$Sprite.speed_scale = 2.25
			else:
				$Sprite.speed_scale = 1.0
	elif not is_on_floor():
		if Input.is_action_pressed("crouch"):
			$Sprite.animation = "crouch"
		else:
			$Sprite.animation = "jump"
	else:
		$Sprite.animation = "idle"


func fisicaBotoes(delta: float):
	
	# Direção que o personagem estiver olhando
	var direction = Input.get_action_strength("move_right") - Input.get_action_strength("move_left")
	if direction == 1:
		currentDirection = Direction.RIGHT
		moving = true
	elif direction == -1:
		currentDirection = Direction.LEFT
		moving = true
	else:
		moving = false
		

	# Ações do personagem

	if moving:
		if (velocity.x > 0 and currentDirection == Direction.LEFT) or (velocity.x < 0 and currentDirection == Direction.RIGHT):
			velocity.x = brake(direction)
			currentAction = Action.STOP
		else:
			if upSlope and onGround:
				velocity.x = move_toward(velocity.x, direction * (NORMAL_TOP_SPEED - 50), ACCEL - FRICTION)
			elif downSlope and onGround:
				velocity.x = move_toward(velocity.x, direction * (NORMAL_TOP_SPEED + 250), ACCEL + (FRICTION * 2))
			else:
				# Se a velocidade atual é maior que a maxima padrão, decaimento vai ser menor
				if (velocity.x > NORMAL_TOP_SPEED+1) or (velocity.x < -NORMAL_TOP_SPEED-1):
					velocity.x = move_toward(velocity.x, direction * NORMAL_TOP_SPEED, ACCEL / 4)
				else:
					velocity.x = move_toward(velocity.x, direction * NORMAL_TOP_SPEED, ACCEL)
				velocity.x += direction * ACCEL * delta
			if onGround:
				currentAction = Action.WALK
		
		if Input.is_action_pressed("dash"):
			if velocity.x > 0 and currentDirection == Direction.LEFT:
				velocity.x = brake(direction)
				currentAction = Action.STOP
			elif velocity.x < 0 and currentDirection == Direction.RIGHT:
				velocity.x = brake(direction)
				currentAction = Action.STOP
			else:
				velocity.x = move_toward(velocity.x, direction * (DASH_TOP_SPEED + DASH), DASH_ACCEL)
	else:
		# Velocidade vai ir decaindo
		velocity.x = move_toward(velocity.x, 0, FRICTION)
	if onGround:
		if Input.is_action_just_pressed("jump"):
			velocity.y = JUMP_VELOCITY
			currentAction = Action.JUMP
	if onAir:
		if Input.is_action_just_pressed("jump") and airJump:
			velocity.y = JUMP_VELOCITY
			airJump = false
			currentAction = Action.JUMP
	move_and_slide()

func is_on_slope():
	if onGround:
		var aux : Vector2 = get_floor_normal()
		if aux.x != 0:
			return true
		else:
			# Se não estiver em uma ladeira, reseta as flags e retorna
			upSlope = false
			downSlope = false
			return false
	else:
		return false

func apply_velocity():
	print('wip')

func brake(direction):
	if onAir:
		return move_toward(velocity.x, direction * NORMAL_TOP_SPEED, (BRAKE_FRICTION + (AIR_FRICTION * 2)))
	else:
		return move_toward(velocity.x, direction * NORMAL_TOP_SPEED, BRAKE_FRICTION)

func gravity_handling(delta):
	# Se estiver no ar
	if not is_on_floor():
		onGround = false
		onAir = true
		if Input.is_action_just_pressed("crouch"):
			velocity.y += (gravity + 500) * delta
		elif Input.is_action_pressed("crouch"):
			velocity.y += (gravity + 500) * delta
		else:
			velocity.y += gravity * delta
	# Se estiver no chão
	else:
		onGround = true
		onAir = false
		airJump = true
		
		# Personagem entrou em uma ladeira
		if is_on_slope():
			# Verificar se estou subindo a ladeira
			var vetor = get_floor_normal()
				
			if (velocity.x > 0 and vetor.x < 0) or (velocity.x < 0 and vetor.x > 0):
				upSlope = true
				downSlope = false
			elif (velocity.x < 0 and vetor.x < 0) or (velocity.x > 0 and vetor.x > 0):
				upSlope = false
				downSlope = true
				
