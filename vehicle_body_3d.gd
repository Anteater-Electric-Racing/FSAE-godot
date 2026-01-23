extends VehicleBody3D


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
	
func deg_to_rad(deg):
	return deg * PI / 180
	
func _physics_process(delta: float) -> void:
	var steer = 0.0
	var throttle = 0.0
	
	const MAX_POWER = 900.0
	const ACCELERATION_STEP = 20.0
	const BRAKING_STEP = 50.0
	const BASE_DECEL = 5.0
	const STEER_STEP = 10.0
	const MAX_STEERING_ANGLE = 30.0
	
	
	# Map inputs to parameters
	if Input.is_action_pressed("accelerate"):
		throttle = ACCELERATION_STEP
	elif Input.is_action_pressed("decelerate"):
		throttle = -BRAKING_STEP;
		
	if Input.is_action_pressed("steer_left"):
		steer = STEER_STEP
	elif Input.is_action_pressed("steer_right"):
		steer = -STEER_STEP
		
	for object in get_children():
		if object is VehicleWheel3D:
			var wheel = object
			
			# Apply throttle and steering parameters
			if wheel.use_as_traction:
				if throttle > 0 and engine_force + throttle <= MAX_POWER:
					wheel.engine_force += throttle
				elif throttle < 0 and engine_force - throttle >= 0:
					wheel.engine_force -= throttle
				else:
					wheel.engine_force = 0.0;
				
			elif wheel.use_as_steering:
				if steer > 0 and wheel.steering + steer <= MAX_STEERING_ANGLE:
					wheel.steering += steer
				elif steer < 0 and wheel.steering - steer >= 0:
					wheel.steering -= steer
				else:
					wheel.steering = 0.0;
			
			# Apply natural deceleration parameter
			if throttle == 0.0:
				wheel.brake = BASE_DECEL
			
