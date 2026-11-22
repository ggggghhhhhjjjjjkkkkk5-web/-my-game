extends Node3D

const GRID_X := 9
const GRID_Z := 7
const CELL := 1.65
const START_COINS := 180

var coins := START_COINS
var wood := 80
var castle_hp := 100
var wave := 0
var score := 0
var build_mode := ""
var buildings: Array[Dictionary] = []
var enemies: Array[Dictionary] = []
var soldiers: Array[Dictionary] = []
var projectiles: Array[Dictionary] = []
var ui: CanvasLayer
var coin_label: Label
var status_label: Label
var wave_label: Label
var hp_bar: ProgressBar
var message_label: Label
var spawn_clock := 0.0
var income_clock := 0.0
var wave_active := false
var game_finished := false
var rng := RandomNumberGenerator.new()
var ground_material: StandardMaterial3D

func _ready() -> void:
	rng.randomize()
	_build_world()
	_build_castle()
	_build_ui()
	_update_ui()
	_show_message("به پادشاهی کوچک خوش آمدی! زمین را بساز و از قلعه دفاع کن.")

func _process(delta: float) -> void:
	if game_finished:
		return
	income_clock += delta
	if income_clock >= 5.0:
		income_clock = 0.0
		for b in buildings:
			if b.kind == "farm":
				coins += 6
				wood += 2
		_update_ui()
	for e in enemies:
		if not e.node or not is_instance_valid(e.node):
			continue
		e.node.position.z -= float(e.speed) * delta
		if e.node.position.z < -4.0:
			castle_hp = maxi(0, castle_hp - int(e.damage))
			e.node.queue_free()
			e.node = null
			_show_message("دشمن به قلعه آسیب زد!")
	for s in soldiers:
		if not s.node or not is_instance_valid(s.node):
			continue
		s.cooldown = float(s.cooldown) - delta
		if float(s.cooldown) <= 0.0:
			var target = _nearest_enemy(s.node.position)
			if target != null:
				_fire_projectile(s.node.position + Vector3(0, 0.8, 0), target)
				s.cooldown = 1.15
	for b in buildings:
		if b.kind == "tower" and is_instance_valid(b.node):
			b.cooldown = float(b.cooldown) - delta
			if float(b.cooldown) <= 0.0:
				var target = _nearest_enemy(b.node.position)
				if target != null:
					_fire_projectile(b.node.position + Vector3(0, 1.7, 0), target)
					b.cooldown = 0.9
	for p in projectiles:
		if not is_instance_valid(p.node) or not is_instance_valid(p.target):
			if is_instance_valid(p.node):
				p.node.queue_free()
			p.node = null
			continue
		var direction: Vector3 = p.target.position + Vector3(0, 0.65, 0) - p.node.position
		if direction.length() < 0.35:
			p.target.hp = int(p.target.hp) - int(p.damage)
			p.node.queue_free()
			p.node = null
			if int(p.target.hp) <= 0:
				_kill_enemy(p.target)
		else:
			p.node.position += direction.normalized() * 13.0 * delta
	projectiles = projectiles.filter(func(p): return is_instance_valid(p.node))
	enemies = enemies.filter(func(e): return is_instance_valid(e.node))
	if wave_active and enemies.is_empty() and spawn_clock < 0.0:
		wave_active = false
		coins += 35 + wave * 5
		wood += 15
		_show_message("موج %d دفع شد! پاداش دریافت کردی." % wave)
		_update_ui()
	_update_ui()

func _build_world() -> void:
	var env := WorldEnvironment.new()
	var environment := Environment.new()
	environment.background_mode = Environment.BG_SKY
	var sky := Sky.new()
	var sky_mat := ProceduralSkyMaterial.new()
	sky_mat.sky_top_color = Color("#3986c8")
	sky_mat.sky_horizon_color = Color("#b8e5f4")
	sky_mat.ground_bottom_color = Color("#66824b")
	sky_mat.ground_horizon_color = Color("#c4d5a0")
	sky.sky_material = sky_mat
	environment.sky = sky
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color("#d9e9ff")
	environment.ambient_light_energy = 0.7
	env.environment = environment
	add_child(env)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-52, -28, 0)
	sun.light_energy = 1.25
	sun.shadow_enabled = true
	add_child(sun)
	var cam := Camera3D.new()
	cam.projection = Camera3D.PROJECTION_ORTHOGONAL
	cam.size = 20.0
	cam.position = Vector3(0, 19, 22)
	cam.look_at(Vector3(0, 0, 0), Vector3.UP)
	add_child(cam)
	cam.current = true
	ground_material = _mat("#79b957")
	_box("Grassland", Vector3(0, -0.35, 0), Vector3(19, 0.6, 15), ground_material)
	_box("Main road", Vector3(0, 0.0, 2.0), Vector3(3.0, 0.08, 12.0), _mat("#c9a875"))
	for x in range(-8, 9, 2):
		for z in range(-6, 7, 2):
			if abs(x) > 6 or z > 4:
				_make_tree(Vector3(float(x) + rng.randf_range(-0.3,0.3), 0, float(z) + rng.randf_range(-0.3,0.3)))
	for i in range(18):
		var x := rng.randf_range(-8.7, 8.7)
		var z := rng.randf_range(-6.8, 6.8)
		_make_rock(Vector3(x, 0, z))

func _build_castle() -> void:
	var stone := _mat("#d7c9a8")
	var dark := _mat("#80674f")
	var roof := _mat("#bd5144")
	var wood_mat := _mat("#8d5934")
	_box("Castle keep", Vector3(0, 1.15, -4.6), Vector3(4.3, 2.3, 3.2), stone)
	_box("Keep roof", Vector3(0, 2.45, -4.6), Vector3(4.7, 0.25, 3.5), dark)
	for x in [-2.0, 2.0]:
		for z in [-5.9, -3.3]:
			_tower(Vector3(x, 0, z), stone, roof)
	_box("Gate", Vector3(0, 0.85, -2.95), Vector3(1.4, 1.7, 0.18), wood_mat)
	_box("Gate arch", Vector3(0, 1.8, -2.94), Vector3(1.8, 0.22, 0.3), dark)
	_box("Flag pole", Vector3(0, 4.0, -4.6), Vector3(0.09, 2.0, 0.09), dark)
	_box("Royal flag", Vector3(0.55, 4.45, -4.6), Vector3(1.0, 0.55, 0.08), _mat("#e3b943"))
	_make_soldier(Vector3(-0.9, 0, -1.7), true)
	_make_soldier(Vector3(0.9, 0, -1.7), true)

func _tower(pos: Vector3, stone: Material, roof_mat: Material) -> void:
	_box("Castle tower", pos + Vector3(0, 1.5, 0), Vector3(1.35, 3.0, 1.35), stone)
	_box("Tower battlement", pos + Vector3(0, 3.08, 0), Vector3(1.55, 0.22, 1.55), stone)
	var roof_mesh := CylinderMesh.new()
	roof_mesh.top_radius = 0.0
	roof_mesh.bottom_radius = 0.9
	roof_mesh.height = 1.35
	var roof_node := MeshInstance3D.new()
	roof_node.mesh = roof_mesh
	roof_node.material_override = roof_mat
	roof_node.position = pos + Vector3(0, 3.85, 0)
	add_child(roof_node)

func _make_tree(pos: Vector3) -> void:
	var trunk := _mesh_node(CylinderMesh.new(), pos + Vector3(0, 0.55, 0), _mat("#805232"))
	trunk.scale = Vector3(0.25, 0.9, 0.25)
	var crown := _mesh_node(SphereMesh.new(), pos + Vector3(0, 1.45, 0), _mat(["#3d934b","#58a94f","#79b94e"][rng.randi_range(0,2)]))
	crown.scale = Vector3(0.85, 0.9, 0.85)

func _make_rock(pos: Vector3) -> void:
	var rock := _mesh_node(SphereMesh.new(), pos + Vector3(0, 0.18, 0), _mat("#9b9a87"))
	rock.scale = Vector3(0.35, 0.22, 0.42)

func _box(label: String, pos: Vector3, size: Vector3, material: Material) -> MeshInstance3D:
	var mesh := BoxMesh.new()
	mesh.size = size
	var node := MeshInstance3D.new()
	node.name = label
	node.mesh = mesh
	node.material_override = material
	node.position = pos
	node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	add_child(node)
	return node

func _mesh_node(mesh: Mesh, pos: Vector3, material: Material) -> MeshInstance3D:
	var node := MeshInstance3D.new()
	node.mesh = mesh
	node.material_override = material
	node.position = pos
	add_child(node)
	return node

func _mat(color: String) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(color)
	m.roughness = 0.86
	return m

func _make_soldier(pos: Vector3, friendly: bool) -> Node3D:
	var root := Node3D.new()
	root.position = pos
	add_child(root)
	var body := _mesh_node_for(root, CapsuleMesh.new(), Vector3(0, 0.72, 0), _mat("#326ca8" if friendly else "#a64439"))
	body.scale = Vector3(0.42, 0.55, 0.42)
	var head := _mesh_node_for(root, SphereMesh.new(), Vector3(0, 1.55, 0), _mat("#edbd8d"))
	head.scale = Vector3(0.38, 0.38, 0.38)
	var helmet := _mesh_node_for(root, SphereMesh.new(), Vector3(0, 1.78, 0), _mat("#d9b64f" if friendly else "#55465d"))
	helmet.scale = Vector3(0.42, 0.19, 0.42)
	var spear := _mesh_node_for(root, CylinderMesh.new(), Vector3(0.42, 0.85, -0.12), _mat("#765333"))
	spear.scale = Vector3(0.08, 0.95, 0.08)
	return root

func _mesh_node_for(parent: Node3D, mesh: Mesh, pos: Vector3, material: Material) -> MeshInstance3D:
	var node := MeshInstance3D.new()
	node.mesh = mesh
	node.material_override = material
	node.position = pos
	parent.add_child(node)
	return node

func _build_ui() -> void:
	ui = CanvasLayer.new()
	add_child(ui)
	var panel := ColorRect.new()
	panel.color = Color(0.08, 0.12, 0.17, 0.88)
	panel.anchor_left = 0
	panel.anchor_right = 1
	panel.offset_bottom = 76
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui.add_child(panel)
	var top := ColorRect.new()
	top.color = Color(0.08, 0.12, 0.17, 0.82)
	top.anchor_right = 1
	top.offset_bottom = 54
	top.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui.add_child(top)
	coin_label = _label("سکه: 180   چوب: 80", 22, Color("#ffe08a"))
	coin_label.position = Vector2(24, 12)
	coin_label.size = Vector2(330, 38)
	ui.add_child(coin_label)
	wave_label = _label("موج: 0", 21, Color.WHITE)
	wave_label.position = Vector2(500, 12)
	wave_label.size = Vector2(220, 38)
	ui.add_child(wave_label)
	status_label = _label("سلامت قلعه", 18, Color("#d7f0ff"))
	status_label.position = Vector2(900, 12)
	status_label.size = Vector2(220, 34)
	ui.add_child(status_label)
	hp_bar = ProgressBar.new()
	hp_bar.position = Vector2(1080, 17)
	hp_bar.size = Vector2(165, 22)
	hp_bar.max_value = 100
	hp_bar.value = castle_hp
	hp_bar.show_percentage = false
	ui.add_child(hp_bar)
	message_label = _label("", 20, Color.WHITE)
	message_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	message_label.position = Vector2(300, 65)
	message_label.size = Vector2(680, 42)
	ui.add_child(message_label)
	_add_button("مزرعه  40", Vector2(18, 640), Vector2(145, 58), func(): _select_build("farm"))
	_add_button("برج دفاع  60", Vector2(174, 640), Vector2(155, 58), func(): _select_build("tower"))
	_add_button("سربازخانه  75", Vector2(340, 640), Vector2(165, 58), func(): _select_build("barracks"))
	_add_button("دیوار  25", Vector2(516, 640), Vector2(145, 58), func(): _select_build("wall"))
	_add_button("شروع موج", Vector2(680, 640), Vector2(155, 58), func(): _start_wave())
	_add_button("بهبود قلعه", Vector2(846, 640), Vector2(155, 58), func(): _upgrade_castle())
	_add_button("لغو ساخت", Vector2(1012, 640), Vector2(145, 58), func(): _select_build(""))
	_add_button("راهنما", Vector2(1168, 640), Vector2(94, 58), func(): _show_message("ساختمان را انتخاب کن و روی زمین خالی بزن. مزرعه سکه و چوب می‌دهد؛ برج‌ها دفاع می‌کنند."))

func _label(text_value: String, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = text_value
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	return label

func _add_button(text_value: String, pos: Vector2, size: Vector2, action: Callable) -> void:
	var button := Button.new()
	button.text = text_value
	button.position = pos
	button.size = size
	button.add_theme_font_size_override("font_size", 18)
	button.add_theme_color_override("font_color", Color.WHITE)
	button.add_theme_stylebox_override("normal", _button_style(Color("#386b58")))
	button.add_theme_stylebox_override("hover", _button_style(Color("#4b8b6c")))
	button.add_theme_stylebox_override("pressed", _button_style(Color("#244b40")))
	button.pressed.connect(action)
	ui.add_child(button)

func _button_style(color: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.corner_radius_top_left = 12
	style.corner_radius_top_right = 12
	style.corner_radius_bottom_left = 12
	style.corner_radius_bottom_right = 12
	style.border_width_bottom = 3
	style.border_color = color.darkened(0.35)
	style.content_margin_left = 6
	style.content_margin_right = 6
	return style

func _select_build(kind: String) -> void:
	build_mode = kind
	if kind == "":
		_show_message("انتخاب ساخت لغو شد.")
	else:
		var names := {"farm":"مزرعه", "tower":"برج دفاع", "barracks":"سربازخانه", "wall":"دیوار"}
		_show_message("%s انتخاب شد؛ روی خانه خالی زمین بزن." % names[kind])

func _unhandled_input(event: InputEvent) -> void:
	var screen_pos := Vector2.ZERO
	var pressed := false
	if event is InputEventScreenTouch and event.pressed:
		screen_pos = event.position
		pressed = true
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		screen_pos = event.position
		pressed = true
	if not pressed or build_mode == "" or screen_pos.y > 620 or screen_pos.y < 115:
		return
	var camera := get_viewport().get_camera_3d()
	if camera == null:
		return
	var origin := camera.project_ray_origin(screen_pos)
	var direction := camera.project_ray_normal(screen_pos)
	var plane := Plane(Vector3.UP, 0.0)
	var hit = plane.intersects_ray(origin, direction)
	if hit == null:
		return
	var point: Vector3 = hit
	var gx := roundi(point.x / CELL)
	var gz := roundi(point.z / CELL)
	if abs(gx) > 5 or gz < -3 or gz > 4:
		return
	var cell_pos := Vector3(gx * CELL, 0, gz * CELL)
	if abs(cell_pos.x) < 2.6 and cell_pos.z < -2.7:
		_show_message("این محدوده متعلق به قلعه است.")
		return
	for b in buildings:
		if Vector2(b.pos.x, b.pos.z).distance_to(Vector2(cell_pos.x, cell_pos.z)) < 1.0:
			_show_message("این خانه قبلاً ساخته شده است.")
			return
	_place_building(build_mode, cell_pos)
	build_mode = ""

func _place_building(kind: String, pos: Vector3) -> void:
	var costs := {"farm":[40, 10], "tower":[60, 15], "barracks":[75, 20], "wall":[25, 5]}
	var cost: Array = costs[kind]
	if coins < int(cost[0]) or wood < int(cost[1]):
		_show_message("سکه یا چوب کافی نداری!")
		return
	coins -= int(cost[0])
	wood -= int(cost[1])
	var node := Node3D.new()
	node.position = pos
	add_child(node)
	var body_color := {"farm":"#c99545", "tower":"#9ba9b8", "barracks":"#b47b4c", "wall":"#b9b5a8"}
	_mesh_node_for(node, BoxMesh.new(), Vector3(0, 0.42, 0), _mat(body_color[kind])).scale = Vector3(1.25, 0.85, 1.25)
	if kind == "farm":
		for i in range(3):
			var crop := _mesh_node_for(node, CylinderMesh.new(), Vector3(-0.35 + i * 0.35, 0.9, 0), _mat("#5d9b42"))
			crop.scale = Vector3(0.12, 0.65, 0.12)
	elif kind == "tower":
		_mesh_node_for(node, CylinderMesh.new(), Vector3(0, 1.35, 0), _mat("#d2d5d8")).scale = Vector3(0.75, 1.2, 0.75)
		_mesh_node_for(node, ConeMesh.new(), Vector3(0, 2.2, 0), _mat("#c35a48")).scale = Vector3(0.9, 0.7, 0.9)
	elif kind == "barracks":
		_mesh_node_for(node, BoxMesh.new(), Vector3(0, 1.15, 0), _mat("#c8a276")).scale = Vector3(1.35, 0.8, 1.2)
		_mesh_node_for(node, PrismMesh.new(), Vector3(0, 1.8, 0), _mat("#a84f3f")).scale = Vector3(1.1, 0.7, 1.0)
		_make_soldier(pos + Vector3(0, 0, 0.7), true)
	elif kind == "wall":
		_mesh_node_for(node, BoxMesh.new(), Vector3(0, 0.8, 0), _mat("#c6b99b")).scale = Vector3(1.55, 1.6, 0.45)
	buildings.append({"kind":kind, "pos":pos, "node":node, "cooldown":0.3})
	_show_message("ساختمان ساخته شد!")
	_update_ui()

func _start_wave() -> void:
	if wave_active:
		_show_message("هنوز دشمنان این موج باقی مانده‌اند.")
		return
	wave += 1
	wave_active = true
	spawn_clock = 0.0
	var count := 4 + wave * 2
	for i in range(count):
		var timer := get_tree().create_timer(float(i) * 1.25)
		timer.timeout.connect(func(): _spawn_enemy() if wave_active and not game_finished else null)
	_show_message("موج %d شروع شد؛ آماده دفاع باش!" % wave)
	_update_ui()

func _spawn_enemy() -> void:
	var root := Node3D.new()
	root.position = Vector3(rng.randf_range(-1.2, 1.2), 0, 7.2)
	add_child(root)
	_mesh_node_for(root, CapsuleMesh.new(), Vector3(0, 0.7, 0), _mat("#a33f3b")).scale = Vector3(0.45, 0.55, 0.45)
	_mesh_node_for(root, SphereMesh.new(), Vector3(0, 1.48, 0), _mat("#e7b58a")).scale = Vector3(0.35, 0.35, 0.35)
	_mesh_node_for(root, SphereMesh.new(), Vector3(0, 1.7, 0), _mat("#56475e")).scale = Vector3(0.4, 0.18, 0.4)
	enemies.append({"node":root, "hp":30 + wave * 5, "speed":0.55 + wave * 0.035, "damage":8 + wave})

func _nearest_enemy(from: Vector3):
	var best = null
	var best_dist := 999.0
	for e in enemies:
		if is_instance_valid(e.node):
			var d: float = from.distance_to(e.node.position)
			if d < best_dist:
				best_dist = d
				best = e
	return best

func _fire_projectile(from: Vector3, target: Dictionary) -> void:
	var orb := _mesh_node(SphereMesh.new(), from, _mat("#ffe17a"))
	orb.scale = Vector3(0.16, 0.16, 0.16)
	projectiles.append({"node":orb, "target":target.node, "damage":18})

func _kill_enemy(target: Node3D) -> void:
	for e in enemies:
		if e.node == target:
			target.queue_free()
			e.node = null
			coins += 8
			wood += 2
			score += 10
			_update_ui()
			return

func _upgrade_castle() -> void:
	if coins < 80 or wood < 25:
		_show_message("برای بهبود قلعه ۸۰ سکه و ۲۵ چوب لازم است.")
		return
	coins -= 80
	wood -= 25
	castle_hp = mini(100, castle_hp + 30)
	_show_message("قلعه تعمیر و تقویت شد.")
	_update_ui()

func _update_ui() -> void:
	if not is_instance_valid(coin_label):
		return
	coin_label.text = "سکه: %d     چوب: %d     امتیاز: %d" % [coins, wood, score]
	wave_label.text = "موج: %d" % wave
	status_label.text = "سلامت قلعه"
	hp_bar.value = castle_hp

func _show_message(value: String) -> void:
	if is_instance_valid(message_label):
		message_label.text = value

