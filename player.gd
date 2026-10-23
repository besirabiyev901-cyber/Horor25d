extends CharacterBody3D

const SPEED = 4.0
const GRAVITY = 20.0
const MOUSE_SENS = 0.003

const BOB_FREQ = 8.0
const BOB_AMP = 0.06
var bob_time = 0.0

const PITCH_MIN = -0.4
const PITCH_MAX = 0.15

@onready var sprite = $AnimatedSprite3D
@onready var spring_arm = $SpringArm3D
@onready var camera = $SpringArm3D/Camera3D
var sprite_base_y = 0.0

func _ready():
	sprite_base_y = sprite.position.y

	sprite.billboard = BaseMaterial3D.BILLBOARD_FIXED_Y


	collision_layer = 2
	collision_mask = 1

	spring_arm.spring_length = 6.0
	spring_arm.position = Vector3(0, 1.6, 0)
	spring_arm.rotation_degrees = Vector3(-15, 0, 0)
	spring_arm.collision_mask = 1
	spring_arm.margin = 0.3

	camera.current = true
	camera.fov = 50


func _unhandled_input(event):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED if event.pressed else Input.MOUSE_MODE_VISIBLE

	if event is InputEventMouseMotion and Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT):
		spring_arm.rotate_y(-event.relative.x * MOUSE_SENS)
		var new_x = spring_arm.rotation.x - event.relative.y * MOUSE_SENS
		spring_arm.rotation.x = clamp(new_x, PITCH_MIN, PITCH_MAX)

func _physics_process(delta):
	if not is_on_floor():
		velocity.y -= GRAVITY * delta
	else:
		velocity.y = 0.0

	var input_dir = Input.get_vector("left", "right", "up", "down")
	var cam_basis = spring_arm.global_transform.basis
	var direction = (cam_basis.x * input_dir.x + cam_basis.z * input_dir.y)
	direction.y = 0
	direction = direction.normalized()

	var is_moving = direction.length() > 0.1

	if input_dir:
		sprite.play("walk")
	else:
		sprite.stop()

	if is_moving:
		velocity.x = direction.x * SPEED
		velocity.z = direction.z * SPEED
		sprite.flip_h = direction.x < 0
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)

	move_and_slide()

	if is_moving and is_on_floor():
		if sprite.animation != "walk":
			sprite.play("walk")

	if is_moving and is_on_floor():
		bob_time += delta * BOB_FREQ
		sprite.position.y = sprite_base_y + sin(bob_time) * BOB_AMP
	else:
		bob_time = 0.0
		sprite.position.y = lerp(sprite.position.y, sprite_base_y, delta * 10.0)
