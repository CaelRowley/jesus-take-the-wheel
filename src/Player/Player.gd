extends KinematicBody2D

const PlayerHurtSound = preload("res://Player/PlayerHurtSound.tscn")

var state = "Idle"
var velocity = Vector2.ZERO
var rollVector = Vector2.DOWN
var stats = PlayerStats

const MAX_SPEED = 100
const ACCELERATION = 400
const FRICTION = 400
const ROLL_SPEED = 110

onready var animationTree = $AnimationTree
onready var animationState = animationTree.get("parameters/playback")
onready var swordHitbox = $HitboxPivot/SwordHitbox
onready var hurtbox = $Hurtbox
onready var blinkAnimationPlayer = $BlinkAnimationPlayer

onready var cardArea = $CardArea

var timer = null
var canPlayCard = true
var speed = 1

func _ready():
	stats.connect("noHealth", self, "queue_free")
	animationTree.active = true
	# sets default direction for sword attack to match roll direction
	swordHitbox.knockbackVector = rollVector
	timer = Timer.new()
	timer.set_one_shot(true)
	timer.set_wait_time(0.5)
	timer.connect("timeout", self, "on_timeout_complete")
	add_child(timer)
	
func _unhandled_input(event):
	if event.is_action_released("left_click"):
		for area in cardArea.get_overlapping_areas():
			state = area.getCard()
			area.queue_free()

func _process(delta):
	match state:
		"Idle":
			idleState(delta)
		"LeftCard":
			speed +=1
			leftState(delta)
		"RightCard":
			speed +=1
			rightState(delta)
	var targetVector = Vector2.ZERO
	targetVector.y = speed
	var targetPosition = global_position + targetVector
	moveTowardPosition(targetPosition, delta)
	velocity = move_and_slide(velocity)

func on_timeout_complete():
	canPlayCard = true
	state = "Idle"
	
func leftState(delta):
	if(canPlayCard):
		canPlayCard = false
		timer.start()
	var targetVector = Vector2.ZERO
	targetVector.x = -5
	var targetPosition = global_position + targetVector
	moveTowardPosition(targetPosition, delta)

func rightState(delta):
	if(canPlayCard):
		canPlayCard = false
		timer.start()
	var targetVector = Vector2.ZERO
	targetVector.x = 5
	var targetPosition = global_position + targetVector
	moveTowardPosition(targetPosition, delta)
	
func moveTowardPosition(targetPosition, delta):
	var direction = global_position.direction_to(targetPosition)
	velocity = velocity.move_toward(direction * MAX_SPEED, ACCELERATION * delta)
	
func idleState(delta):
	velocity = velocity.move_toward(Vector2.ZERO, FRICTION * delta)	
	
	
	
	
	
	
	
	
func runState(delta):
	var inputVector = Vector2.ZERO
	inputVector.x = Input.get_action_strength("ui_right") - Input.get_action_strength("ui_left")
	inputVector.y = Input.get_action_strength("ui_down") - Input.get_action_strength("ui_up")
	inputVector = inputVector.normalized()
	
	if inputVector != Vector2.ZERO:
		rollVector = inputVector
		swordHitbox.knockbackVector = inputVector
		animationTree.set("parameters/Idle/blend_position", inputVector)
		animationTree.set("parameters/Run/blend_position", inputVector)
		animationTree.set("parameters/Attack/blend_position", inputVector)
		animationTree.set("parameters/Roll/blend_position", inputVector)
		animationState.travel("Run")
		velocity = velocity.move_toward(inputVector * MAX_SPEED, ACCELERATION * delta)
	else:
		animationState.travel("Idle")
		velocity = velocity.move_toward(Vector2.ZERO, FRICTION * delta)
		
	velocity = move_and_slide(velocity)

	if Input.is_action_just_pressed("attack"):
		state = "attack"
		
	if Input.is_action_just_pressed("dodge"):
		state = "dodge"
	
func attackState():
	velocity = Vector2.ZERO
	animationState.travel("Attack")

func attackStateFinished():
	state = "run"

func dodgeState():
	velocity = move_and_slide(rollVector * ROLL_SPEED)
	animationState.travel("Roll")

func dodgeStateFinished():
	velocity = velocity * 0.9
	state = "run"

func _on_Hurtbox_area_entered(collider):
	hurtbox.startInvincibility(1)
	hurtbox.createHitEffect()
	blinkAnimationPlayer.play("Start")
	stats.setHealth(stats.getHealth() - collider.getDamage())
	var playerHurtSound = PlayerHurtSound.instance()
	get_tree().current_scene.add_child(playerHurtSound)
	
