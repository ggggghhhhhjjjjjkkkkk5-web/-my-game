extends Node2D

const W := 960.0
const H := 540.0
const MAX_HP := 100
var hp := MAX_HP
var coins := 0
var wave := 1
var score := 0
var game_over := false
var spawn_timer := 1.2
var wave_timer := 0.0
var enemies: Array[Dictionary] = []
var arrows: Array[Dictionary] = []
var soldiers: Array[Dictionary] = []
var particles: Array[Dictionary] = []
var message := "قلعه را از حمله دشمنان حفظ کن!"
var message_time := 3.0
var fire_cooldown := 0.0
var recruit_cost := 35
var selected_action := "arrow"

func _ready() -> void:
    get_viewport().size_changed.connect(queue_redraw)
    _recruit_initial_soldiers()
    set_process(true)

func _recruit_initial_soldiers() -> void:
    soldiers = [
        {"x": 215.0, "y": 352.0, "cool": 0.2},
        {"x": 275.0, "y": 352.0, "cool": 0.8},
        {"x": 335.0, "y": 352.0, "cool": 1.4}
    ]

func _process(delta: float) -> void:
    if game_over:
        queue_redraw()
        return
    fire_cooldown = maxf(0.0, fire_cooldown - delta)
    message_time = maxf(0.0, message_time - delta)
    spawn_timer -= delta
    wave_timer += delta
    if spawn_timer <= 0.0:
        _spawn_enemy()
        spawn_timer = maxf(0.65, 2.6 - wave * 0.12) + randf_range(0.0, 0.8)
    if wave_timer >= 24.0:
        wave += 1
        wave_timer = 0.0
        message = "موج %d شروع شد!" % wave
        message_time = 2.5
        coins += 20
    for e in enemies:
        e.x -= (22.0 + wave * 2.0) * delta
        e.attack -= delta
        if e.x < 400.0 and e.attack <= 0.0:
            hp = max(0, hp - 5)
            e.attack = 1.0
            _burst(Vector2(390, 370), Color(1.0, 0.35, 0.18))
        if e.x < 90.0:
            hp = max(0, hp - 12)
            e.dead = true
    for a in arrows:
        a.x += a.vx * delta
        a.y += a.vy * delta
        a.life -= delta
        for e in enemies:
            if not e.dead and Vector2(a.x, a.y).distance_to(Vector2(e.x, e.y - 15)) < 25.0:
                e.dead = true
                score += 10
                coins += 8
                _burst(Vector2(e.x, e.y), Color(1.0, 0.75, 0.2))
                a.life = 0.0
                break
    for s in soldiers:
        s.cool -= delta
        if s.cool <= 0.0 and not enemies.is_empty():
            var target = _nearest_enemy(float(s.x))
            if target != null:
                _shoot(float(s.x) + 8, float(s.y) - 22, float(target.x), float(target.y) - 18)
                s.cool = 1.15
    for p in particles:
        p.life -= delta
        p.pos += p.vel * delta
        p.vel.y += 100.0 * delta
    enemies = enemies.filter(func(e): return not e.dead)
    arrows = arrows.filter(func(a): return a.life > 0.0)
    particles = particles.filter(func(p): return p.life > 0.0)
    if hp <= 0:
        game_over = true
        message = "قلعه سقوط کرد!"
    queue_redraw()

func _nearest_enemy(from_x: float):
    var best = null
    var dist := 99999.0
    for e in enemies:
        if not e.dead and e.x > from_x - 25 and e.x < dist + from_x:
            var d = absf(e.x - from_x)
            if d < dist:
                dist = d
                best = e
    return best

func _spawn_enemy() -> void:
    var y := randf_range(350.0, 385.0)
    enemies.append({"x": 1010.0, "y": y, "attack": 0.0, "dead": false, "kind": randi_range(0, 2)})

func _shoot(sx: float, sy: float, tx: float, ty: float) -> void:
    var dir := Vector2(tx - sx, ty - sy).normalized()
    arrows.append({"x": sx, "y": sy, "vx": dir.x * 420.0, "vy": dir.y * 420.0, "life": 2.0})

func _burst(pos: Vector2, color: Color) -> void:
    for i in range(7):
        var angle := randf() * TAU
        particles.append({"pos": pos, "vel": Vector2.RIGHT.rotated(angle) * randf_range(35, 110), "life": 0.45, "color": color})

func _draw() -> void:
    draw_rect(Rect2(0, 0, W, H), Color("#8bc9e8"))
    draw_circle(Vector2(820, 85), 34, Color("#ffe58a"))
    draw_colored_polygon(PackedVector2Array([Vector2(0,300),Vector2(150,175),Vector2(310,300)]), Color("#79a98b"))
    draw_colored_polygon(PackedVector2Array([Vector2(190,300),Vector2(400,165),Vector2(610,300)]), Color("#65977d"))
    draw_rect(Rect2(0, 300, W, 240), Color("#7caa55"))
    draw_rect(Rect2(0, 405, W, 135), Color("#6c8e43"))
    draw_rect(Rect2(45, 205, 345, 205), Color("#b9b6ad"))
    draw_rect(Rect2(35, 190, 365, 25), Color("#ded9cc"))
    for x in range(45, 400, 48):
        draw_rect(Rect2(x, 174, 25, 28), Color("#d6d1c5"))
    for x in [55.0, 325.0]:
        draw_rect(Rect2(x, 125, 58, 285), Color("#a9a69e"))
        draw_rect(Rect2(x-7, 112, 72, 22), Color("#e0dbce"))
        for bx in range(int(x-3), int(x+68), 23):
            draw_rect(Rect2(bx, 98, 15, 18), Color("#d4cfc3"))
        draw_rect(Rect2(x+17, 325, 24, 85), Color("#614536"))
        draw_circle(Vector2(x+29, 145), 7, Color("#27394b"))
    for y in range(230, 400, 35):
        draw_line(Vector2(45,y), Vector2(390,y), Color("#918e87"), 2)
    for x in range(70, 390, 70):
        draw_line(Vector2(x,230), Vector2(x,400), Color("#918e87"), 2)
    draw_rect(Rect2(165, 305, 95, 105), Color("#65452f"))
    draw_rect(Rect2(175, 315, 75, 95), Color("#8b5d38"))
    draw_line(Vector2(175,340), Vector2(250,340), Color("#4a3325"), 3)
    draw_line(Vector2(175,370), Vector2(250,370), Color("#4a3325"), 3)
    draw_line(Vector2(83, 100), Vector2(83, 40), Color("#51463d"), 4)
    draw_colored_polygon(PackedVector2Array([Vector2(85,42),Vector2(135,55),Vector2(85,70)]), Color("#c43e38"))
    draw_line(Vector2(355, 95), Vector2(355, 35), Color("#51463d"), 4)
    draw_colored_polygon(PackedVector2Array([Vector2(357,37),Vector2(410,50),Vector2(357,66)]), Color("#d2a63e"))
    for s in soldiers:
        _draw_soldier(Vector2(float(s.x), float(s.y)), true)
    for e in enemies:
        _draw_enemy(Vector2(e.x, e.y), int(e.kind))
    for a in arrows:
        draw_line(Vector2(a.x, a.y), Vector2(a.x-13, a.y+4), Color("#3c2b1e"), 4)
        draw_colored_polygon(PackedVector2Array([Vector2(a.x+5,a.y),Vector2(a.x-2,a.y-4),Vector2(a.x-2,a.y+4)]), Color("#f4e6c2"))
    for p in particles:
        draw_circle(p.pos, 3.5 * p.life / 0.45, p.color)
    _draw_hud()
    if message_time > 0.0:
        draw_rect(Rect2(300, 15, 360, 38), Color(0.05,0.1,0.12,0.78), true)
        draw_string(ThemeDB.fallback_font, Vector2(330, 41), message, HORIZONTAL_ALIGNMENT_CENTER, 300, 18, Color.WHITE)
    if game_over:
        draw_rect(Rect2(0,0,W,H), Color(0,0,0,0.68))
        draw_string(ThemeDB.fallback_font, Vector2(330,245), "قلعه سقوط کرد!", HORIZONTAL_ALIGNMENT_CENTER, 300, 34, Color.WHITE)
        draw_string(ThemeDB.fallback_font, Vector2(330,290), "برای شروع دوباره روی «شروع مجدد» بزن", HORIZONTAL_ALIGNMENT_CENTER, 300, 17, Color.WHITE)

func _draw_soldier(pos: Vector2, friendly: bool) -> void:
    var armor := Color("#2867a8") if friendly else Color("#9b3d35")
    draw_circle(pos + Vector2(0,-25), 10, Color("#e9b88b"))
    draw_rect(Rect2(pos.x-10,pos.y-18,20,25), armor)
    draw_line(pos+Vector2(-7,-10),pos+Vector2(-19,4),Color("#e9b88b"),5)
    draw_line(pos+Vector2(7,-10),pos+Vector2(17,1),Color("#e9b88b"),5)
    draw_line(pos+Vector2(-5,7),pos+Vector2(-8,20),Color("#343b45"),6)
    draw_line(pos+Vector2(5,7),pos+Vector2(8,20),Color("#343b45"),6)
    draw_line(pos+Vector2(12,-8),pos+Vector2(30,-23),Color("#493a2a"),4)
    draw_circle(pos+Vector2(30,-23),3,Color("#d9d0b8"))

func _draw_enemy(pos: Vector2, kind: int) -> void:
    var c := Color("#8d342f") if kind == 0 else (Color("#5d425f") if kind == 1 else Color("#6b6337"))
    draw_circle(pos+Vector2(0,-24),11,Color("#d7a17b"))
    draw_rect(Rect2(pos.x-12,pos.y-17,24,29),c)
    draw_line(pos+Vector2(-7,-8),pos+Vector2(-17,5),Color("#d7a17b"),5)
    draw_line(pos+Vector2(7,-8),pos+Vector2(18,4),Color("#d7a17b"),5)
    draw_line(pos+Vector2(-6,10),pos+Vector2(-8,22),Color("#343238"),6)
    draw_line(pos+Vector2(6,10),pos+Vector2(8,22),Color("#343238"),6)
    draw_line(pos+Vector2(10,-5),pos+Vector2(24,-20),Color("#4b3325"),4)

func _draw_hud() -> void:
    draw_rect(Rect2(15, 12, 230, 78), Color(0.04,0.09,0.13,0.86), true)
    draw_string(ThemeDB.fallback_font, Vector2(30,38), "قلعه‌بان  |  موج %d" % wave, HORIZONTAL_ALIGNMENT_LEFT, 210, 18, Color.WHITE)
    draw_string(ThemeDB.fallback_font, Vector2(30,65), "سکه: %d    امتیاز: %d" % [coins,score], HORIZONTAL_ALIGNMENT_LEFT, 210, 16, Color("#ffe08a"))
    draw_rect(Rect2(700, 18, 240, 25), Color("#472b2b"), true, 6)
    draw_rect(Rect2(700, 18, 240.0 * hp / MAX_HP, 25), Color("#54b86b"), true, 6)
    draw_string(ThemeDB.fallback_font, Vector2(775,37), "سلامت قلعه: %d%%" % hp, HORIZONTAL_ALIGNMENT_CENTER, 160, 15, Color.WHITE)
    draw_rect(Rect2(0, 465, W, 75), Color(0.04,0.08,0.11,0.92))
    _draw_button(Rect2(25,477,170,48), "تیراندازی", Color("#356c9d"))
    _draw_button(Rect2(215,477,170,48), "استخدام سرباز  (%d)" % recruit_cost, Color("#3d8052"))
    _draw_button(Rect2(405,477,170,48), "تعمیر قلعه  (25)", Color("#98713a"))
    _draw_button(Rect2(595,477,170,48), "تقویت دفاع", Color("#6b578f"))
    _draw_button(Rect2(785,477,150,48), "شروع مجدد" if game_over else "راهنما", Color("#555e68"))

func _draw_button(rect: Rect2, label: String, color: Color) -> void:
    draw_rect(rect, color, true)
    draw_rect(rect, color.lightened(0.25), false, 2, true)
    draw_string(ThemeDB.fallback_font, rect.position + Vector2(10,30), label, HORIZONTAL_ALIGNMENT_CENTER, rect.size.x-20, 15, Color.WHITE)

func _input(event: InputEvent) -> void:
    var pos := Vector2.ZERO
    var pressed := false
    if event is InputEventScreenTouch and event.pressed:
        pos = event.position
        pressed = true
    elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
        pos = event.position
        pressed = true
    if not pressed:
        return
    if game_over:
        if pos.y >= 465:
            _restart()
        return
    if pos.y >= 465:
        if pos.x < 205:
            _manual_shot()
        elif pos.x < 395:
            _recruit()
        elif pos.x < 585:
            _repair()
        elif pos.x < 775:
            _upgrade()
        else:
            message = "سربازها خودکار به دشمنان تیراندازی می‌کنند."
            message_time = 3.0
    elif pos.x > 400 and pos.y > 250:
        _manual_shot()

func _manual_shot() -> void:
    if fire_cooldown > 0.0:
        return
    if enemies.is_empty():
        message = "هنوز دشمنی در میدان نیست!"
        message_time = 1.5
        return
    var target = enemies[0]
    _shoot(380, 270, float(target.x), float(target.y)-18)
    fire_cooldown = 0.28

func _recruit() -> void:
    if coins < recruit_cost:
        message = "سکه کافی نداری؛ دشمنان را شکست بده!"
        message_time = 2.0
        return
    coins -= recruit_cost
    soldiers.append({"x": 215.0 + (soldiers.size() % 5) * 34.0, "y": 352.0, "cool": 0.4})
    recruit_cost += 15
    message = "یک سرباز تازه به قلعه پیوست!"
    message_time = 2.0

func _repair() -> void:
    if coins < 25:
        message = "برای تعمیر به ۲۵ سکه نیاز داری."
    elif hp >= MAX_HP:
        message = "سلامت قلعه کامل است."
    else:
        coins -= 25
        hp = mini(MAX_HP, hp + 25)
        message = "قلعه تعمیر شد!"
    message_time = 2.0

func _upgrade() -> void:
    if coins < 50:
        message = "برای تقویت دفاع به ۵۰ سکه نیاز داری."
    else:
        coins -= 50
        for s in soldiers:
            s.cool = minf(float(s.cool), 0.1)
        message = "روحیه و سرعت دفاع تقویت شد!"
    message_time = 2.0

func _restart() -> void:
    hp = MAX_HP
    coins = 0
    wave = 1
    score = 0
    game_over = false
    spawn_timer = 1.0
    wave_timer = 0.0
    enemies.clear()
    arrows.clear()
    particles.clear()
    recruit_cost = 35
    _recruit_initial_soldiers()
    message = "دفاع از قلعه را آغاز کن!"
    message_time = 3.0
