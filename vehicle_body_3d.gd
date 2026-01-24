extends VehicleBody3D


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
	
func deg_to_rad(deg):
	return deg * PI / 180
	
func rad_to_deg(rad):
	return rad * 180 / PI
	
func _physics_process(delta: float) -> void:
	var steer = 0.0
	var throttle = 0.0
	var braking = 0.0
	
	const MAX_POWER = 50.0
	const ACCELERATION_STEP = 5.0
	const BRAKING_STEP = 1.0
	const BASE_DECEL = 5.0
	const MAX_BRAKING = 15.0
	const STEER_STEP = 0.5
	const MAX_STEERING_ANGLE = 15.0
	
	
	# Map inputs to parameters
	if Input.is_action_pressed("accelerate"):
		throttle = ACCELERATION_STEP
	elif Input.is_action_pressed("decelerate"):
		braking = BRAKING_STEP;
	
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
					#wheel.brake = 0.0
					wheel.engine_force += throttle
				elif braking > 0 and wheel.brake + braking <= MAX_BRAKING:
					wheel.brake += braking
					wheel.engine_force = 0.0
				else:
					# Apply natural deceleration parameter
					wheel.engine_force = 0.0
					wheel.brake = BASE_DECEL
					
				
				
			elif wheel.use_as_steering:
				var steer_deg = rad_to_deg(wheel.steering)
				var steer_rad = deg_to_rad(steer)
				
				if wheel.steering > PI:
					wheel.steering /= PI
				
				if steer > 0 and steer_deg + steer <= MAX_STEERING_ANGLE:
					wheel.steering += steer_rad
				elif steer < 0 and steer_deg + steer >= -MAX_STEERING_ANGLE:
					wheel.steering += steer_rad
			
