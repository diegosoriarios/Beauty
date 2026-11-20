extends CharacterBody2D

const SCALE = 1

@export var snap = false
@export var move_speed = 200
@export var jump_force = -250
@export var gravity = 10
@export var slope_slide_threshold = 50.0
var floorNormal = Vector2(0, -1)

var canJumpEvenMaybeNotTouchingTheGround = true
var jumpWasPressed = false
var can_jump = true
var isCrouched = false
var is_dashing = false
var can_dash = false
var dash_is_active = true
var dash_direction = Vector2()
@export var dash_speed = 500
@export var dash_length = 0.2
@onready var dash_timer = $Timer

var is_on_rope = false 
var can_hold_rope = true
var rope = null

var wall_jump = 100
var jump_wall = 20

var its_raining = false

func _ready():
	add_to_group("player")
	dash_timer.timeout.connect(dash_timer_timeout)
	up_direction = floorNormal
	if snap:
		floor_snap_length = 1.0
	its_raining = get_parent().find_child("RainParticle")
	if its_raining:
		move_speed = 50
		jump_force = -125
	LevelManager.register_player(self)

func _physics_process(delta):
	handle_animation()
	if is_on_rope:
		handle_rope()
	else:
		var goDown = Input.is_action_pressed("ui_down") and Input.is_action_just_pressed("jump")
		var jump = Input.is_action_just_pressed("jump")
		var left = Input.is_action_pressed("ui_left")
		var right = Input.is_action_pressed("ui_right")
		var crouch = Input.is_action_just_pressed("ui_down")
		
		if is_on_floor() or is_next_wall():
			canJumpEvenMaybeNotTouchingTheGround = true
			can_jump = true
		
		if can_jump:
			if jumpWasPressed:
				if next_to_wall_right():
					velocity.x += wall_jump
					velocity.y = jump_force
				elif next_to_wall_left():
					velocity.x -= wall_jump
					velocity.y = jump_force
				elif is_on_floor():
					velocity.y = jump_force
		
		if goDown:
			for platform in get_parent().get_children():
				if platform.is_in_group('through'):
					platform.disableCollision()
		elif jump:
			jumpWasPressed = true
			rememberJumpTime()
			if canJumpEvenMaybeNotTouchingTheGround:
				velocity.y = jump_force
		
		if Input.is_action_just_released("jump"):
			can_jump = false
			jump_cut()
		
		if !is_on_floor():
			coyoteTime()
			velocity.y += gravity
			
		if left:
			velocity.x = -move_speed
		elif right:
			velocity.x = move_speed
		else:
			#if is_on_floor():
			velocity.x = 0
		
		if crouch:
			isCrouched = true
		if Input.is_action_just_released("ui_down"):
			isCrouched = false
		
		if isCrouched:
			$Stand.disabled = true
			$Crouch.disabled = false
			$Sprite2D.scale.y = SCALE#.1
			velocity.x = 0
		else:
			$Stand.disabled = false
			$Crouch.disabled = true
			$Sprite2D.scale.y = SCALE#.1
		
		if (dash_is_active):
			handle_dash(delta)
		
		if is_on_floor():
			can_dash = true
			
		if is_dashing:
			velocity = dash_direction

		move_and_slide()

func coyoteTime():
	await get_tree().create_timer(.1).timeout
	canJumpEvenMaybeNotTouchingTheGround = false
	pass

func rememberJumpTime():
	await get_tree().create_timer(.1).timeout
	jumpWasPressed = false
	pass

func handle_dash(delta):
	if(Input.is_action_just_pressed("dash") and can_dash and !is_on_floor()):
		is_dashing = true
		can_dash = false
		dash_direction = get_direction_from_input()
		dash_timer.start(dash_length)
	
	if(is_dashing):
		if(is_on_floor()):
			is_dashing = false
		if(is_on_wall()):
			is_dashing = false
		pass
	
func get_direction_from_input():
	var move_dir = Vector2()
	
	move_dir.x = -Input.get_action_strength("ui_left") + Input.get_action_strength("ui_right")
	move_dir.y = Input.get_action_strength("ui_down") - Input.get_action_strength("ui_up")
		
	move_dir = move_dir.limit_length(1)
	
	#check if no movement is pressed further enough... then dash towards ur facing position
	if (move_dir == Vector2(0,0)):
		if($Sprite2D.flip_h):
			move_dir.x = -1
		else:
			move_dir.x = 1
	
	var dashing_speed = dash_speed if move_dir.y == 0 else dash_speed * .6
	return move_dir * dashing_speed
	
func dash_timer_timeout():
	is_dashing = false

func jump_cut():
	if velocity.y < -100:
		velocity.y = -100

func transition_on():
	set_physics_process(false)

func transition_off():
	await get_tree().create_timer(1).timeout
	set_physics_process(true)

func hit():
	LevelManager.kill_player()

func enter_death() -> void:
	is_dashing = false
	is_on_rope = false
	rope = null
	dash_timer.stop()
	velocity = Vector2.ZERO
	visible = false
	set_physics_process(false)
	$Hold.monitoring = false
	$Stand.disabled = true
	$Crouch.disabled = true


func respawn_at(position: Vector2) -> void:
	global_position = position
	is_dashing = false
	isCrouched = false
	is_on_rope = false
	rope = null
	can_hold_rope = true
	can_jump = true
	canJumpEvenMaybeNotTouchingTheGround = true
	jumpWasPressed = false
	can_dash = true
	dash_timer.stop()
	velocity = Vector2.ZERO
	$Stand.disabled = false
	$Crouch.disabled = true
	$Sprite2D.scale.y = SCALE
	$Hold.monitoring = true
	visible = true
	set_physics_process(true)

func handle_rope():
	if rope != null:
		$Stand.disabled = true
		position = rope.global_position
		rope.constant_force = Vector2(1, 1)
		velocity -= rope.constant_force
		
		var jump = Input.is_action_just_pressed("jump")
		var left = Input.is_action_pressed("ui_left")
		var right = Input.is_action_pressed("ui_right")
		var up = Input.is_action_just_pressed("ui_up")
		var down = Input.is_action_just_pressed("ui_down")
		
		if left:
			rope.constant_force.x -= move_speed
		if right:
			rope.constant_force.x += move_speed
		
		if up:
			var ropes = rope.get_parent()
			var index = ropes.get_children().find(rope)
			if index - 2 > 0:
				rope = ropes.get_child(index - 2)
		elif down:
			var ropes = rope.get_parent()
			var index = ropes.get_children().find(rope)
			if index + 2 < ropes.get_child_count():
				rope = ropes.get_child(index + 2)
		
		if jump:
			velocity.y += jump_force
			is_on_rope = false
			rope = null
			can_hold_rope = false
			await get_tree().create_timer(.2).timeout
			$Stand.disabled = false

func _on_Hold_body_entered(body):
	if body.is_in_group("chain") and !is_on_rope and can_hold_rope:
		#set_collision_layer_bit(1, true)
		#set_collision_layer_bit(0, false)
		#set_collision_mask_bit(1, true)
		#set_collision_mask_bit(0, false)
		#canJumpEvenMaybeNotTouchingTheGround = true
		#can_jump = true
		await get_tree().create_timer(.4).timeout
		is_on_rope = true
		rope = body


func _on_Hold_body_exited(body):
	if body.is_in_group("chain") and !is_on_rope:
		#set_collision_layer_bit(0, true)
		#set_collision_layer_bit(1, false)
		#set_collision_mask_bit(1, false)
		#set_collision_mask_bit(0, true)
		is_on_rope = false
		rope = null
		await get_tree().create_timer(.5).timeout
		can_hold_rope = true

func handle_animation():
	var lookLeft = Input.is_action_just_pressed("ui_left")
	var lookRight = Input.is_action_just_pressed("ui_right")
	var isWalking = (Input.is_action_pressed("ui_right") or Input.is_action_pressed("ui_left"))
	var isIdle = Input.is_action_just_released("ui_right") or Input.is_action_just_pressed("ui_left")
	var isJumping = Input.is_action_pressed("jump")
	var releaseJump = Input.is_action_just_released("jump")
	var crouch = Input.is_action_pressed("ui_down")
	var is_on_left_wall = next_to_wall_left()
	var is_on_right_wall = next_to_wall_right()
	
	if lookLeft: $Sprite2D.flip_h = true
	elif lookRight: $Sprite2D.flip_h = false
	
	if is_dashing:
		$Sprite2D.play("dash")
	elif isJumping or !can_jump:
		$Sprite2D.play("jump")
	elif releaseJump or !next_to_floor():
		$Sprite2D.play("falling")
	elif is_on_left_wall or is_on_right_wall:
		$Sprite2D.play("wall_slide")
	elif isWalking and !crouch:
		$Sprite2D.play("walk")
	else:
		$Sprite2D.play("idle")

func _on_Hold_area_entered(area):
	if area.is_in_group('cover'):
		if its_raining:
			move_speed = 200
			jump_force = -250


func _on_Hold_area_exited(area):
	if area.is_in_group('cover'):
		if its_raining:
			move_speed = 50
			jump_force = -125

func is_next_wall():
	return next_to_wall_left() or next_to_wall_right()

func next_to_wall_left():
	return ($isNextWallLeft.is_colliding() or $isNextWallLeft2.is_colliding()) and !next_to_floor()

func next_to_wall_right():
	return ($isNextWallRight.is_colliding() or $isNextWallRight2.is_colliding()) and !next_to_floor()

func next_to_floor():
	return $isNextFloor.is_colliding()
