extends CharacterBody2D

const GRAVITY: int = 4200;
const JUMP_SPEED: int = -1800

@onready var jump_sound: AudioStreamPlayer2D = $jump_sound
@onready var anim: AnimatedSprite2D = $AnimatedSprite2D
@onready var run_col: CollisionShape2D = $run_col
@onready var duck_col: CollisionShape2D = $duck_col

func _physics_process(delta):
	velocity.y += GRAVITY * delta;
	if is_on_floor():
		run_col.disabled = false; # does not disable run collisiion
		if Input.is_action_just_pressed("jump"): #if player jumps
			velocity.y = JUMP_SPEED;
			jump_sound.play()
		elif Input.is_action_pressed("duck"): #if player ducks
			#disables run collision
			run_col.disabled = true;
			anim.play("duck")
		else:
			anim.play("run")
	else:
		anim.play("jump")
	
	move_and_slide()
