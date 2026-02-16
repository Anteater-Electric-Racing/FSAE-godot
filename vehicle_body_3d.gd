extends VehicleBody3D

const DISPLAY_DEBUG_SPEED = true

var previousDisplayedSpeed = 0.0

const MAX_POWER = 500.0
const ACCELERATION_STEP = 5.0
const USE_DYNAMIC_THROTTLE = true
const MOTOR_RAMP_DOWN_STEP = 50.0
const BRAKING_STEP = 1.0
const BASE_DECEL = 5.0
const MAX_BRAKING = 15.0
const STEER_STEP = 0.25
const MAX_STEERING_ANGLE = 32.0
const MAX_VEHICLE_SPEED_MPH = 60.0

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
	
func throttle_function(current_speed):
	# Connect engine power data here
	return 1000.0
	
func _physics_process(delta: float) -> void:
	var steer = 0.0
	var throttle = 0.0
	var dynamic_throttle = false
	var reset_steering = false
	var braking = 0.0
	
	# W - Accelerate
	# A - Turn wheels towards the left
	# S - Apply brakes
	# D - Turn wheels towards the right
	# C - Reset steering to center
	
	
	# Map inputs to parameter deltas
	if Input.is_action_pressed("accelerate"):
		if USE_DYNAMIC_THROTTLE:
			dynamic_throttle = true
		else:
			throttle = ACCELERATION_STEP
	elif Input.is_action_pressed("decelerate"):
		braking = BRAKING_STEP;
	
	if Input.is_action_pressed("steer_left"):
		steer = STEER_STEP
	elif Input.is_action_pressed("steer_right"):
		steer = -STEER_STEP
		
	if Input.is_action_pressed("steer_center"):
		reset_steering = true
		
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
				if (throttle > 0 or dynamic_throttle) and wheel.engine_force + throttle <= MAX_POWER and int(round(linear_velocity.length() * 3.6)) <= MAX_VEHICLE_SPEED_MPH*1.609:
					if USE_DYNAMIC_THROTTLE and dynamic_throttle:
						wheel.engine_force = throttle_function(linear_velocity.length())
					else:
						wheel.engine_force += throttle
				elif braking > 0 and wheel.brake + braking <= MAX_BRAKING:
					wheel.brake += braking
					wheel.engine_force = 0.0
				else:
					# Apply natural deceleration parameter
					if wheel.engine_force - MOTOR_RAMP_DOWN_STEP >= 0:
						wheel.engine_force -= MOTOR_RAMP_DOWN_STEP
					else:
						wheel.engine_force = 0.0
					wheel.brake = BASE_DECEL
					
				
				
			elif wheel.use_as_steering:
				var steer_deg = rad_to_deg(wheel.steering)
				var steer_rad = deg_to_rad(steer)
				
				if wheel.steering > PI:
					wheel.steering /= PI
				
				if reset_steering:
					wheel.steering = 0.0
				elif steer > 0 and steer_deg + steer <= MAX_STEERING_ANGLE:
					wheel.steering += steer_rad
				elif steer < 0 and steer_deg + steer >= -MAX_STEERING_ANGLE:
					wheel.steering += steer_rad
					
			
