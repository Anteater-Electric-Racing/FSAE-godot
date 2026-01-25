extends VehicleBody3D

const DISPLAY_DEBUG_SPEED = true

var previousDisplayedSpeed = 0.0

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
	
func kph_to_mph(kph):
	return kph / 1.609
	
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
	const MAX_STEERING_ANGLE = 20.0
	const MAX_VEHICLE_SPEED_MPH = 40.0
	
	
	# Map inputs to parameter deltas
	if Input.is_action_pressed("accelerate"):
		throttle = ACCELERATION_STEP
	elif Input.is_action_pressed("decelerate"):
		braking = BRAKING_STEP;
	
	if Input.is_action_pressed("steer_left"):
		steer = STEER_STEP
	elif Input.is_action_pressed("steer_right"):
		steer = -STEER_STEP
		
	# Debug printing for vehicle speed
	
	if DISPLAY_DEBUG_SPEED:
		var velocity_mps = linear_velocity.length()
		
		var velocity_kph = int(round(velocity_mps * 3.6))
		
		var velocity_mph = int(round(velocity_kph / 1.609))
		
		if velocity_kph != previousDisplayedSpeed:
			var printString = "VEHICLE SPEED | " + str(velocity_kph) + " km/h" + " (" + str(velocity_mph) + " mph)"
			print(printString)
			
		previousDisplayedSpeed = velocity_kph
		
	# Update vehicle physics based on deltas
	
	for object in get_children():
		if object is VehicleWheel3D:
			var wheel = object
			
			# Apply throttle and steering parameters
			if wheel.use_as_traction:
				if throttle > 0 and engine_force + throttle <= MAX_POWER and int(round(linear_velocity.length() * 3.6 / 1.609)) < MAX_VEHICLE_SPEED_MPH:
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
			
