extends CharacterBody2D
# Personagem com física estilo Sonic (está muito mal feito :/)

# Constantes
const SPEED : float = 250.00 #Velocidade máxima
const DASH : float = 80.0 #Velocidade de impulso
const JUMP_VELOCITY : float = -350.0 #Força do pulo
const FRICTION : float = 2 #Força da fricção
const ACCEL : float = 3.25 #Força de aceleração

var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")
var podePular : bool = true

func _physics_process(delta):
	if not is_on_floor():
		velocity.y += gravity * delta
	else:
		podePular = true
	fisicaBotoes(delta) #Função lida com a física do personagem
	animacaoPersonagem() #Função lida com as animações

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
	
	
	if Input.is_action_just_pressed("jump") and podePular == true:
		velocity.y = JUMP_VELOCITY
		if Input.is_action_just_pressed("jump") and not is_on_floor():
			podePular = false

	# Direção que o personagem estiver olhando
	var direction = Input.get_action_strength("move_right") - Input.get_action_strength("move_left")

	if direction != 0:
		# Freio
		if(velocity.x > 0 and direction == -1):
			velocity.x = move_toward(velocity.x, direction * SPEED, FRICTION + 9)
		elif(velocity.x < 0 and direction == 1):
			velocity.x = move_toward(velocity.x, direction * SPEED, FRICTION + 9)
			
		# Dash
		if(Input.is_action_pressed("dash")):
			# Considerar que o personagem precisa desacelerar primeiro pra dar dash pro lado oposto
			if(velocity.x > 0 and direction == -1):
				velocity.x = move_toward(velocity.x, direction * SPEED, FRICTION + 9)
			elif(velocity.x < 0 and direction == 1):
				velocity.x = move_toward(velocity.x, direction * SPEED, FRICTION + 9)
			else:
				velocity.x = move_toward(velocity.x, direction * (SPEED +  200), 99)

		# Andar
		print('Aceleração :', ACCEL)
		velocity.x = move_toward(velocity.x, direction * SPEED, ACCEL - detectarRampa())
		print('Aceleração com rampa :', detectarRampa())

		velocity.x += direction * ACCEL * delta
		print(velocity.x)
		print('direção: ', direction)
	else:
		velocity.x = move_toward(velocity.x, 0, FRICTION)

	move_and_slide()
	
func detectarRampa():
	if get_floor_angle() <= -25:
		return 4
	else:
		return 0
