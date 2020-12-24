extends Spatial

var area_percent = 0.03
var dir = Vector3(0, 0, 0)
var speed = 0
var acc = 10
var dec = 25
var ang_dec = 8
var ang_acc = 3
var angu = 1
var angd = -1
var angl = -1
var angr = 1
var MAX_SPEED = 100
var crsr = Vector2(0, 0)
var MAX_ANG_SPEED = 50
var low = -1.158
var high = 0.325

var max_zoom = 10
var min_zoom = 0.5
var zoom_to_cursor = true

var is_panning = false
var zoom = 1.5
var zoom_speed = 0.09

var previous_scale
var mouse_in = true

var ground_plane = Plane(Vector3.UP, 0)

func _input(event):
	if event is InputEventPanGesture:
#		print("test")
		$VerticalRotation/Camera.fov = clamp($VerticalRotation/Camera.fov, 0, 170)
		$VerticalRotation/Camera.fov *= event.factor
		$VerticalRotation/Camera.fov = clamp($VerticalRotation/Camera.fov, 0, 170)

	if event is InputEventMouseMotion:
		crsr = event.position

	if event is InputEventMouseMotion:
		if Input.is_mouse_button_pressed(BUTTON_MIDDLE):
			
			rotate_y(-event.relative.x * 0.001)
			$VerticalRotation.rotation.x = clamp($VerticalRotation.rotation.x,low, high)
			$VerticalRotation.rotate_x(event.relative.y * 0.001)
			$VerticalRotation.rotation.x = clamp($VerticalRotation.rotation.x,low, high)
#			print($VerticalRotation/Camera.rotation.x)
#			$VerticalRotation.rotate_x(deg2rad(event.relative.y * 0.3))
		
		if Input.is_mouse_button_pressed(BUTTON_RIGHT):
			is_panning = true
#			var pos = get_viewport().get_visible_rect()
#			get_parent().translate((-get_parent().global_transform.basis.z * event.relative.y + -get_parent().global_transform.basis.x * event.relative.x) * 12 * 0.001)
#			if mouse_in:
#				if get_viewport().get_mouse_position().x <= pos.position.x:
#					Input.warp_mouse_position(Vector2(pos.size.x, get_viewport().get_mouse_position().y))
#				if get_viewport().get_mouse_position().x >= pos.size.x:
#					Input.warp_mouse_position(Vector2(pos.size.x, get_viewport().get_mouse_position().y))
#				if get_viewport().get_mouse_position().y <= pos.position.y:
#					Input.warp_mouse_position(Vector2(get_viewport().get_mouse_position().x, pos.size.y))
#				if get_viewport().get_mouse_position().y >= pos.size.y:
#					Input.warp_mouse_position(Vector2(get_viewport().get_mouse_position().x, pos.size.y))
			print(-(global_transform.basis.z * event.relative.y + global_transform.basis.x * event.relative.x) * 10 * 0.001)
			translate_object_local(-(global_transform.basis.z * event.relative.y + global_transform.basis.x * event.relative.x) * 10 * 0.001)
			is_panning = false

	if event is InputEventScreenPinch:
#		print(event.speed)
		if event.relative < 0:
			zoom += -event.relative / 64
		elif event.relative > 0:
			zoom += -event.relative / 64
		previous_scale = scale
		zoom = clamp(zoom, min_zoom, max_zoom)
			
	


func _process(delta):
	if previous_scale != lerp(scale, Vector3.ONE * zoom, zoom_speed):
#		if zoom_to_cursor:
#			var from = $VerticalRotation/Camera.project_ray_origin(get_viewport().get_mouse_position())
#			var to = from + $VerticalRotation/Camera.project_ray_normal(get_viewport().get_mouse_position()) * 1000
#			var result = ground_plane.intersects_ray(from, to)
#			print(result)
#			if result != null:
#				var from_1 = $VerticalRotation/Camera.project_ray_origin(get_viewport().get_mouse_position())
#				var to_1 = from_1 + $VerticalRotation/Camera.project_ray_normal(get_viewport().get_mouse_position() * delta) * 1000
#				var result_1 = ground_plane.intersects_ray(from_1, to_1)
#				print(result_1)
#				if result_1 != null:
#					prints("test", result - result_1)
#					translate(result - result_1) 
	
		scale = lerp(scale, Vector3.ONE * zoom, zoom_speed)
#	print(is_panning)
	if is_panning:
		return
	var pos = get_viewport().get_visible_rect()
	
	
	var new_dir := Vector3.ZERO
#	print(pos)
#	print(pos.has_point(crsr))
#	print(crsr)
	if mouse_in:
		if (crsr.x < int(pos.size.x*area_percent)):
			new_dir.x -= 1
		if (crsr.x > (pos.size.x-(pos.size.x*area_percent))):
			new_dir.x += 1
		if (crsr.y < int(pos.size.y*area_percent)):
			new_dir.z -= 1
		if (crsr.y > (pos.size.y-(pos.size.y*area_percent))):
			new_dir.z += 1
	
	if OS.is_window_focused():
		if Input.is_key_pressed(KEY_A):
			new_dir.x -= 1
		if Input.is_key_pressed(KEY_D):
			new_dir.x += 1
		if Input.is_key_pressed(KEY_W):
			new_dir.z -= 1
		if Input.is_key_pressed(KEY_S):
			new_dir.z += 1

	if new_dir.length() > 1:
		new_dir = new_dir.normalized()
	
	if new_dir and OS.is_window_focused():
		dir = new_dir
		speed += acc * delta
	else:
		speed -= dec * delta
	speed = clamp(speed,0,MAX_SPEED)
	translate_object_local(dir*delta*speed)
	
	if Input.is_key_pressed(KEY_Q):
		
		angr += ang_acc * delta
		angr = clamp(angr,0,MAX_ANG_SPEED)
		rotate_y(angr*delta)
		
		
	elif Input.is_key_pressed(KEY_E):
		
		angl += ang_acc * delta
		angl = clamp(angl,0,MAX_ANG_SPEED)
		rotate_y(-angl*delta)
		

	else:
		
		angr -= ang_dec * delta
		angr = clamp(angr,0,MAX_ANG_SPEED)
		rotate_y(angr*delta)
		angl -= ang_dec * delta
		angl = clamp(angl,0,MAX_ANG_SPEED)
		rotate_y(-angl*delta)
	
	if Input.is_key_pressed(KEY_R):
		if rotation.x <= (high):
			angd += ang_acc * delta
			angd = clamp(angd,0,MAX_ANG_SPEED)
			$VerticalRotation.rotation.x = clamp($VerticalRotation.rotation.x,low, high)
			$VerticalRotation.rotate_x(angd*delta)
			$VerticalRotation.rotation.x = clamp($VerticalRotation.rotation.x,low, high)
#			print($VerticalRotation/Camera.rotation.x)
			
	
	elif Input.is_key_pressed(KEY_F):
		if rotation.x >= (low):
			angu += ang_acc * delta
			angu = clamp(angu,0,MAX_ANG_SPEED)
			$VerticalRotation.rotation.x = clamp($VerticalRotation.rotation.x,low, high)
			$VerticalRotation.rotate_x(-angu*delta)
			$VerticalRotation.rotation.x = clamp($VerticalRotation.rotation.x,low, high)
#			print($VerticalRotation/Camera.rotation.x)

	else:
		angd -= ang_dec * delta
		angd = clamp(angd,0,MAX_ANG_SPEED)
		$VerticalRotation.rotation.x = clamp($VerticalRotation.rotation.x,low, high)
		$VerticalRotation.rotate_x(angd*delta)
		$VerticalRotation.rotation.x = clamp($VerticalRotation.rotation.x,low, high)
		angu -= ang_dec * delta
		angu = clamp(angu,0,MAX_ANG_SPEED)
		$VerticalRotation.rotation.x = clamp($VerticalRotation.rotation.x,low, high)
		$VerticalRotation.rotate_x(-angu*delta)
		$VerticalRotation.rotation.x = clamp($VerticalRotation.rotation.x,low, high)
#	print(dir)


func _notification(what):
	match what:
		NOTIFICATION_WM_MOUSE_ENTER:
			mouse_in = true
		NOTIFICATION_WM_MOUSE_EXIT:
			mouse_in = false

