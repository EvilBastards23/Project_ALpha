extends CharacterBody2D

@onready var animated_sprite_2d = $AnimatedSprite2D
const SPEED = 250.0
const JUMP_VELOCITY = -300  # Negative velocity for the jump force
const run_speed = 400
const roll_speed = 500
var gravity = 400.0  # Higher gravity for more natural falling
var main_sm: LimboHSM

func _ready():
	initiate_state_machine()

func _physics_process(delta):
	var dir = Input.get_action_strength("walk_right") - Input.get_action_strength("walk_left")
	var run_dir = Input.get_action_strength("run_right") - Input.get_action_strength("run_left")

	# Horizontal movement: Run or Walk
	if run_dir != 0:
		velocity.x = run_dir * run_speed
		main_sm.dispatch(&"to_run")
	elif dir != 0:
		velocity.x = dir * SPEED
		main_sm.dispatch(&"to_walk")
	else:
		velocity.x = 0

	# Apply gravity (fall speed)
	if not is_on_floor():
		velocity.y += gravity * delta  # Gravity is applied when not on the floor
	
	flip_sprite(run_dir, dir)

	# Correct way to use move_and_slide
	move_and_slide()

func flip_sprite(run_dir, dir):
	# Flip the sprite based on running or walking direction
	if run_dir != 0:  # If running
		if run_dir == 1:
			animated_sprite_2d.flip_h = false  # Facing right while running
		elif run_dir == -1:
			animated_sprite_2d.flip_h = true   # Facing left while running
	elif dir != 0:  # If walking
		if dir == 1:
			animated_sprite_2d.flip_h = false  # Facing right while walking
		elif dir == -1:
			animated_sprite_2d.flip_h = true   # Facing left while walking

func _unhandled_input(event):
	if event.is_action_pressed("jump"):
		main_sm.dispatch(&"to_jump")
	elif event.is_action_pressed("attack"):
		main_sm.dispatch(&"to_attack")
	elif event.is_action_pressed("roll"):
		main_sm.dispatch(&"to_roll")
	elif event.is_action_pressed("sit"):
		main_sm.dispatch(&"to_circle")

func initiate_state_machine():
	main_sm = LimboHSM.new()
	add_child(main_sm)

	var idle_state = LimboState.new().named("idle").call_on_enter(idle_start).call_on_update(idle_update)
	var walk_state = LimboState.new().named("walk").call_on_enter(walk_start).call_on_update(walk_update)
	var run_state = LimboState.new().named("run").call_on_enter(run_start).call_on_update(run_update)
	var jump_state = LimboState.new().named("jump").call_on_enter(jump_start).call_on_update(jump_update)
	var attack_state = LimboState.new().named("attack").call_on_enter(attack_start).call_on_update(attack_update)
	var roll_state = LimboState.new().named("roll").call_on_enter(roll_start).call_on_update(roll_update)
	var fall_state = LimboState.new().named("fall").call_on_enter(fall_start).call_on_update(fall_update)
	var circle_state = LimboState.new().named("circle").call_on_enter(circle_start).call_on_update(circle_update)
	main_sm.add_child(idle_state)
	main_sm.add_child(walk_state)
	main_sm.add_child(run_state)
	main_sm.add_child(jump_state)
	main_sm.add_child(attack_state)
	main_sm.add_child(roll_state)
	main_sm.add_child(fall_state)
	main_sm.add_child(circle_state)

	main_sm.initial_state = idle_state

	main_sm.add_transition(idle_state, walk_state, &"to_walk")
	main_sm.add_transition(main_sm.ANYSTATE, idle_state, &"state_ended")
	main_sm.add_transition(idle_state, jump_state, &"to_jump")
	main_sm.add_transition(walk_state, jump_state, &"to_jump")
	main_sm.add_transition(run_state, jump_state, &"to_jump")
	main_sm.add_transition(main_sm.ANYSTATE, attack_state, &"to_attack")
	main_sm.add_transition(walk_state, run_state, &"to_run")
	main_sm.add_transition(idle_state, run_state, &"to_run")
	main_sm.add_transition(idle_state, roll_state, &"to_roll")
	main_sm.add_transition(walk_state, roll_state, &"to_roll")
	main_sm.add_transition(run_state, roll_state, &"to_roll")
	main_sm.add_transition(main_sm.ANYSTATE, roll_state, &"to_roll")
	main_sm.add_transition(main_sm.ANYSTATE, fall_state, &"to_fall")
	main_sm.add_transition(idle_state, circle_state, &"to_circle")
	main_sm.add_transition(walk_state, circle_state, &"to_circle")
	main_sm.add_transition(run_state, circle_state, &"to_circle")

	main_sm.initialize(self)
	main_sm.set_active(true)

# State methods
func idle_start():
	animated_sprite_2d.play("idle")

func idle_update(delta):
	if velocity.x != 0:
		main_sm.dispatch(&"to_walk")

func walk_start():
	animated_sprite_2d.play("walk")

func walk_update(delta):
	if velocity.x == 0:
		main_sm.dispatch(&"state_ended")

func jump_start():
	velocity.y = JUMP_VELOCITY  # Apply jump velocity
	animated_sprite_2d.play("jump")

func jump_update(delta):
	if is_on_floor():
		main_sm.dispatch(&"state_ended")
		print("jump")

func run_start():
	animated_sprite_2d.play("run")

func run_update(delta):
	if Input.get_action_strength("run_right") == 0 and Input.get_action_strength("run_left") == 0:
		main_sm.dispatch(&"state_ended")

func attack_start():
	animated_sprite_2d.play("attack")

func attack_update(delta):
	if animated_sprite_2d.frame == animated_sprite_2d.sprite_frames.get_frame_count("attack") - 1:
		main_sm.dispatch(&"state_ended")
func roll_start():
	animated_sprite_2d.play("roll")
	var dir = self.velocity.x
	velocity.x = dir * roll_speed

func roll_update(delta):
	if animated_sprite_2d.frame == animated_sprite_2d.sprite_frames.get_frame_count("roll") - 1:
		main_sm.dispatch(&"state_ended")
func fall_start():
	animated_sprite_2d.play("fall")
func fall_update(delta):
	if not is_on_floor():
		animated_sprite_2d.play("fall")
		main_sm.dispatch(&"to_fall")
		print("fall")
	elif is_on_floor():
		main_sm.dispatch(&"state_ended")
func circle_start():
	animated_sprite_2d.play("circle_attack")
func circle_update(delta):
	if Input.is_action_just_pressed("sit"):
		pass
	elif animated_sprite_2d.frame == animated_sprite_2d.sprite_frames.get_frame_count("circle_attack") - 1:
		main_sm.dispatch(&"state_ended")
		
