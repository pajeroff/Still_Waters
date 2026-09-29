extends Node2D

const W := 320
const H := 180
const SAVE_PATH := "user://still_waters_save.json"
const INK := Color("172b32")
const PAPER := Color("f3e8c9")
const MUTED := Color("b3c6b9")
const GOLD := Color("f5c76b")
const AQUA := Color("75c6bd")
const RED := Color("df766b")

const FISH := [
	{"name":"Карась", "rarity":"Обычная", "min":0.3, "max":1.8, "price":8, "color":Color("d8a56c"), "bait":"Червь"},
	{"name":"Окунь", "rarity":"Обычная", "min":0.2, "max":1.2, "price":11, "color":Color("83b88a"), "bait":"Червь"},
	{"name":"Плотва", "rarity":"Обычная", "min":0.1, "max":0.8, "price":6, "color":Color("d9c4a0"), "bait":"Опарыш"},
	{"name":"Лещ", "rarity":"Необычная", "min":0.8, "max":3.5, "price":16, "color":Color("b79b76"), "bait":"Тесто"},
	{"name":"Линь", "rarity":"Необычная", "min":0.5, "max":2.7, "price":18, "color":Color("83a66e"), "bait":"Кукуруза"},
	{"name":"Щука", "rarity":"Редкая", "min":1.2, "max":7.0, "price":30, "color":Color("a7b477"), "bait":"Блесна"},
	{"name":"Золотой карп", "rarity":"Легендарная", "min":2.0, "max":9.0, "price":90, "color":Color("f5c76b"), "bait":"Кукуруза"},
	{"name":"Призрачный угорь", "rarity":"Мифическая", "min":1.0, "max":5.0, "price":120, "color":Color("a9c8d1"), "bait":"Секретная"}
]

var screen := "menu"
var day := 1
var minute_of_day := 6 * 60
var time_accum := 0.0
var money := 35
var xp := 0
var level := 1
var fish_caught: Array = []
var total_caught := 0
var weather := "Ясно"
var selected_bait := 0
var baits := ["Червь", "Опарыш", "Тесто", "Кукуруза", "Блесна"]
var bait_count := [8, 4, 3, 2, 1]
var rod_level := 1
var phase := "ready"
var bite_timer := 0.0
var window_timer := 0.0
var tension := 22.0
var progress := 0.0
var catch_fish: Dictionary = {}
var catch_weight := 0.0
var message := ""
var message_timer := 0.0
var bobber_phase := 0.0
var rain_drops: Array[Vector2] = []
var save_exists := false

func _ready() -> void:
	for i in range(22):
		rain_drops.append(Vector2(randi_range(0, W), randi_range(0, H)))
	save_exists = FileAccess.file_exists(SAVE_PATH)
	set_process(true)

func _process(delta: float) -> void:
	bobber_phase += delta
	if screen == "fishing" or screen == "journal" or screen == "inventory" or screen == "shop":
		time_accum += delta
		if time_accum >= 6.0:
			time_accum -= 6.0
			minute_of_day += 1
			if minute_of_day >= 24 * 60:
				minute_of_day = 6 * 60
				day += 1
				weather = "Дождь" if randf() < 0.28 else "Ясно"
				_save_game()
		if phase == "waiting":
			bite_timer -= delta
			if bite_timer <= 0.0:
				phase = "bite"
				window_timer = 1.15
				message = "ПОКЛЁВКА!"
				message_timer = 1.15
		elif phase == "bite":
			window_timer -= delta
			if window_timer <= 0.0:
				phase = "ready"
				message = "Рыба ушла…"
				message_timer = 1.5
		elif phase == "reeling":
			_update_fight(delta)
	if message_timer > 0:
		message_timer -= delta
	if weather == "Дождь":
		for i in range(rain_drops.size()):
			rain_drops[i].y += delta * 55
			if rain_drops[i].y > H:
				rain_drops[i] = Vector2(randi_range(0, W), -2)
	queue_redraw()

func _update_fight(delta: float) -> void:
	var fish_pull := sin(bobber_phase * (2.0 + float(level) * 0.08)) * 19.0 + cos(bobber_phase * 3.1) * 8.0
	if Input.is_key_pressed(KEY_SPACE):
		tension += delta * (27.0 + fish_pull * 0.35)
		progress += delta * (16.0 + rod_level * 3.0)
	else:
		tension -= delta * 22.0
		progress -= delta * 3.0
	tension += fish_pull * delta * 0.7
	tension = clampf(tension, 0.0, 100.0)
	progress = clampf(progress, 0.0, 100.0)
	if tension >= 98:
		phase = "ready"
		message = "Леска не выдержала!"
		message_timer = 2.0
	elif progress >= 100:
		_land_fish()

func _input(event: InputEvent) -> void:
	if not (event is InputEventKey and event.pressed and not event.echo):
		return
	var key := event.keycode
	match screen:
		"menu":
			if key == KEY_ENTER:
				if save_exists:
					_load_game()
				else:
					_new_game()
			elif key == KEY_SPACE or key == KEY_N:
				_new_game()
			elif key == KEY_C and save_exists:
				_load_game()
		"pause":
			if key == KEY_ESCAPE or key == KEY_ENTER:
				screen = "fishing"
			elif key == KEY_S:
				_save_game()
				message = "Сохранено"
				message_timer = 1.5
			elif key == KEY_Q:
				screen = "menu"
			elif key == KEY_J:
				screen = "journal"
			elif key == KEY_I:
				screen = "inventory"
			elif key == KEY_M:
				screen = "shop"
		"journal", "inventory":
			if key == KEY_ESCAPE or key == KEY_ENTER or key == KEY_J or key == KEY_I:
				screen = "fishing"
		"shop":
			if key == KEY_ESCAPE or key == KEY_M:
				screen = "fishing"
			elif key == KEY_1:
				_buy_bait()
			elif key == KEY_2:
				_buy_rod()
			elif key == KEY_ENTER:
				_sell_all()
		"fishing":
			if key == KEY_ESCAPE:
				screen = "pause"
			elif key == KEY_SPACE:
				_handle_action()
			elif key == KEY_LEFT or key == KEY_A:
				selected_bait = posmod(selected_bait - 1, baits.size())
			elif key == KEY_RIGHT or key == KEY_D:
				selected_bait = posmod(selected_bait + 1, baits.size())
			elif key == KEY_J:
				screen = "journal"
			elif key == KEY_I:
				screen = "inventory"
			elif key == KEY_M:
				screen = "shop"
			elif key == KEY_E:
				_sleep()

func _handle_action() -> void:
	if phase == "ready":
		if bait_count[selected_bait] <= 0:
			message = "Нет наживки — загляни в лавку"
			message_timer = 2.0
			return
		bait_count[selected_bait] -= 1
		phase = "waiting"
		bite_timer = randf_range(2.0, 5.0) * (0.82 if weather == "Дождь" else 1.0)
		message = "Поплавок лёг на воду…"
		message_timer = 1.6
	elif phase == "bite":
		phase = "reeling"
		tension = 28.0
		progress = 7.0
		catch_fish = _choose_fish()
		catch_weight = randf_range(catch_fish.min, catch_fish.max)
		message = "Есть! Не дай леске лопнуть"
		message_timer = 2.0

func _choose_fish() -> Dictionary:
	var eligible: Array = []
	var weights: Array[float] = []
	for fish in FISH:
		if fish.name == "Золотой карп" and (weather != "Дождь" or minute_of_day < 7 * 60 or minute_of_day > 18 * 60):
			continue
		if fish.name == "Призрачный угорь" and (weather != "Дождь" or minute_of_day < 21 * 60):
			continue
		var weight := 30.0 if fish.rarity == "Обычная" else 12.0 if fish.rarity == "Необычная" else 4.0 if fish.rarity == "Редкая" else 1.0
		if fish.bait == baits[selected_bait]:
			weight *= 1.8
		eligible.append(fish)
		weights.append(weight)
	var total_weight := 0.0
	for weight in weights:
		total_weight += weight
	var roll := randf() * total_weight
	for i in range(eligible.size()):
		roll -= weights[i]
		if roll <= 0.0:
			return eligible[i]
	return eligible.back()

func _land_fish() -> void:
	phase = "ready"
	var record := {"name":catch_fish.name, "weight":snappedf(catch_weight, 0.01), "day":day, "rarity":catch_fish.rarity}
	fish_caught.append(record)
	total_caught += 1
	xp += 10 + int(catch_weight * 3.0)
	if xp >= level * 60:
		xp -= level * 60
		level += 1
		message = "НОВЫЙ УРОВЕНЬ! Уровень %d" % level
	else:
		message = "Поймано: %s · %.2f кг" % [catch_fish.name, catch_weight]
	message_timer = 3.0
	_save_game()

func _sleep() -> void:
	day += 1
	minute_of_day = 6 * 60
	weather = "Дождь" if randf() < 0.28 else "Ясно"
	phase = "ready"
	_save_game()
	message = "Новый день · %s" % weather
	message_timer = 2.2

func _buy_bait() -> void:
	if money >= 8:
		money -= 8
		bait_count[selected_bait] += 5
		message = "+5 %s" % baits[selected_bait]
	else:
		message = "Не хватает монет"
	message_timer = 1.7
	_save_game()

func _buy_rod() -> void:
	if rod_level >= 3:
		message = "У тебя лучшая удочка"
	elif money >= 45 * rod_level:
		money -= 45 * rod_level
		rod_level += 1
		message = "Удочка улучшена!"
	else:
		message = "Не хватает монет"
	message_timer = 1.7
	_save_game()

func _sell_all() -> void:
	if fish_caught.is_empty():
		message = "В садке пока пусто"
	else:
		var earned := 0
		for item in fish_caught:
			for fish in FISH:
				if fish.name == item.name:
					earned += int(fish.price * float(item.weight))
		fish_caught.clear()
		money += earned
		message = "Продано за %d монет" % earned
	message_timer = 2.0
	_save_game()

func _new_game() -> void:
	day = 1
	minute_of_day = 6 * 60
	time_accum = 0.0
	money = 35
	xp = 0
	level = 1
	fish_caught.clear()
	total_caught = 0
	bait_count = [8, 4, 3, 2, 1]
	rod_level = 1
	weather = "Ясно"
	phase = "ready"
	screen = "fishing"
	_save_game()

func _save_game() -> void:
	var data := {"day":day, "minute":minute_of_day, "money":money, "xp":xp, "level":level, "fish":fish_caught, "total":total_caught, "weather":weather, "bait_count":bait_count, "rod_level":rod_level}
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(data))
	save_exists = true

func _load_game() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		_new_game()
		return
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	var parsed = JSON.parse_string(file.get_as_text())
	if typeof(parsed) == TYPE_DICTIONARY:
		day = int(parsed.get("day", 1))
		minute_of_day = int(parsed.get("minute", 360))
		money = int(parsed.get("money", 35))
		xp = int(parsed.get("xp", 0))
		level = int(parsed.get("level", 1))
		fish_caught = parsed.get("fish", [])
		total_caught = int(parsed.get("total", fish_caught.size()))
		weather = str(parsed.get("weather", "Ясно"))
		bait_count = parsed.get("bait_count", [8, 4, 3, 2, 1])
		rod_level = int(parsed.get("rod_level", 1))
	screen = "fishing"
	phase = "ready"

func _draw() -> void:
	if screen == "menu":
		_draw_menu()
	else:
		_draw_lake()
		if screen == "journal":
			_draw_journal()
		elif screen == "inventory":
			_draw_inventory()
		elif screen == "shop":
			_draw_shop()
		elif screen == "pause":
			_draw_pause()

func _draw_menu() -> void:
	_draw_lake_bg()
	_draw_water()
	_draw_land()
	_draw_fisherman(92, 72)
	_draw_cloud(31 + int(fposmod(bobber_phase * 5, 30)), 20)
	_draw_cloud(220 - int(fposmod(bobber_phase * 3, 24)), 34)
	_draw_text("ТИХИЙ ОМУТ", 54, 57, 25, PAPER)
	_draw_text("ПОЙМАЙ СВОЮ ЛЕГЕНДУ", 76, 73, 8, GOLD)
	_draw_rect(83, 92, 154, 1, Color("718b7a"))
	_draw_text("ENTER  ·  начать / продолжить", 73, 111, 9, PAPER)
	_draw_text("N  ·  новая игра", 101, 126, 8, MUTED)
	_draw_text("Тихая рыбалка у старого пруда", 83, 159, 8, PAPER)

func _draw_lake() -> void:
	_draw_lake_bg()
	_draw_sun_moon()
	_draw_cloud(25 + int(fposmod(bobber_phase * 3, 36)), 20)
	_draw_cloud(239 - int(fposmod(bobber_phase * 2, 28)), 28)
	_draw_water()
	_draw_land()
	_draw_fisherman(92, 72)
	_draw_bobber()
	_draw_hud()
	if screen == "fishing":
		_draw_fishing_panel()
	if message_timer > 0 and screen == "fishing":
		_draw_panel(65, 34, 190, 21)
		_draw_text(message, 160 - message.length() * 2, 48, 8, GOLD if message.contains("ПОКЛЁВКА") else PAPER)
	if weather == "Дождь":
		for drop in rain_drops:
			_draw_rect(int(drop.x), int(drop.y), 1, 3, Color(0.61, 0.78, 0.78, 0.65))

func _draw_lake_bg() -> void:
	_draw_rect(0, 0, W, H, Color("c4b18a"))
	_draw_rect(0, 0, W, 58, Color("a9c5a6"))
	_draw_rect(0, 0, W, 5, Color("d4d4a8"))
	_draw_rect(0, 40, W, 19, Color("829d73"))
	# distant trees
	for x in [8, 24, 48, 278, 296, 314]:
		_draw_rect(x, 24 + (x % 3) * 4, 9, 27, Color("476955"))
		_draw_rect(x - 4, 17 + (x % 3) * 4, 17, 13, Color("527960"))
		_draw_rect(x + 2, 14 + (x % 3) * 4, 7, 9, Color("71906b"))
	_draw_rect(0, 59, W, 8, Color("806e54"))

func _draw_land() -> void:
	_draw_rect(0, 67, 86, 113, Color("c7ad7e"))
	_draw_rect(225, 67, 95, 113, Color("c7ad7e"))
	_draw_rect(0, 70, 88, 3, Color("e0ca94"))
	_draw_rect(221, 70, 99, 3, Color("e0ca94"))
	_draw_rect(80, 88, 52, 9, Color("896a4d"))
	for x in [82, 94, 106, 118, 130]:
		_draw_rect(x, 88, 2, 9, Color("b18a5b"))
	_draw_rect(85, 96, 4, 20, Color("715640"))
	_draw_rect(124, 96, 4, 20, Color("715640"))
	for x in [17, 29, 54, 70, 244, 263, 287, 307]:
		_draw_rect(x, 59, 1, 8, Color("526e4d"))
		_draw_rect(x - 2, 59, 2, 3, Color("87975c"))
		_draw_rect(x + 1, 56, 2, 3, Color("82955c"))

func _draw_water() -> void:
	_draw_rect(0, 67, W, 113, Color("527f7d"))
	_draw_rect(0, 67, W, 4, Color("77a49a"))
	for i in range(15):
		var x := int(fposmod(i * 27 + bobber_phase * (8 + i % 3), W))
		var y := 77 + (i * 19 % 93)
		var shade := Color("729b91") if i % 3 else Color("91b2a1")
		_draw_rect(x, y, 8 + i % 5, 1, shade)
		_draw_rect(x + 2, y + 2, 4, 1, Color("446e70"))
	if minute_of_day > 17 * 60:
		_draw_rect(137, 69, 5, 106, Color(0.91, 0.67, 0.35, 0.12))

func _draw_bobber() -> void:
	var y := 102.0 + sin(bobber_phase * 2.0) * 1.5
	if phase == "bite":
		y += 5.0 + absf(sin(bobber_phase * 18.0)) * 3.0
	elif phase == "reeling":
		y -= progress * 0.17
	_draw_rect(104, 93, 1, int(y - 93), Color("ded0a7"))
	_draw_rect(101, int(y), 7, 3, Color("eee2bd"))
	_draw_rect(102, int(y) + 2, 5, 3, Color("dc7567"))
	_draw_rect(103, int(y) + 5, 3, 2, Color("31595b"))
	if phase == "bite":
		_draw_text("!", 105, int(y) - 5, 9, GOLD)

func _draw_fisherman(x: int, y: int) -> void:
	_draw_rect(x + 4, y, 8, 7, Color("e8bd91"))
	_draw_rect(x + 3, y - 2, 10, 3, Color("8f5943"))
	_draw_rect(x + 3, y + 7, 10, 9, Color("4b6672"))
	_draw_rect(x + 1, y + 8, 3, 8, Color("e8bd91"))
	_draw_rect(x + 12, y + 8, 3, 8, Color("e8bd91"))
	_draw_rect(x + 4, y + 16, 4, 7, Color("685247"))
	_draw_rect(x + 9, y + 16, 4, 7, Color("685247"))
	_draw_rect(x + 4, y + 4, 2, 1, INK)
	_draw_rect(x + 9, y + 4, 2, 1, INK)
	if screen != "menu":
		_draw_rect(x + 13, y + 7, 17, 1, Color("654e39"))

func _draw_sun_moon() -> void:
	var hour := int(minute_of_day / 60)
	var c := Color("f6d58c") if hour >= 6 and hour < 19 else Color("e4e8d6")
	_draw_rect(270, 13, 12, 12, c)
	_draw_rect(267, 17, 18, 4, c)

func _draw_cloud(x: int, y: int) -> void:
	var c := Color("dce0c3")
	_draw_rect(x, y, 16, 5, c)
	_draw_rect(x + 3, y - 3, 7, 8, c)
	_draw_rect(x + 9, y - 2, 6, 7, c)

func _draw_hud() -> void:
	_draw_panel(5, 5, 116, 27)
	_draw_text("ДЕНЬ %02d   %02d:%02d" % [day, int(minute_of_day / 60), minute_of_day % 60], 11, 16, 8, PAPER)
	_draw_text("%s  ·  %d ¤  ·  ур. %d" % [weather, money, level], 11, 27, 8, GOLD)
	_draw_panel(210, 5, 105, 27)
	_draw_text("СТАРЫЙ ПРУД", 220, 16, 8, PAPER)
	_draw_text("Удочка %s" % ["Бамбук", "Стекло", "Карбон"][rod_level - 1], 220, 27, 8, MUTED)
	_draw_rect(6, 162, 308, 13, Color(0.09, 0.16, 0.17, 0.93))
	_draw_text("SPACE заброс / подсечка / подмотка     ← → наживка     J журнал  I снасти  M лавка  E сон  ESC пауза", 10, 171, 6, PAPER)

func _draw_fishing_panel() -> void:
	_draw_panel(147, 105, 164, 48)
	var title := "ГОТОВ К ЗАБРОСУ"
	var detail := "SPACE — забросить поплавок"
	if phase == "waiting":
		title = "ТИШИНА У ВОДЫ"
		detail = "Ждём поклёвку…"
	elif phase == "bite":
		title = "ПОПЛАВОК НЫРНУЛ!"
		detail = "SPACE — подсечь  ·  %.1fс" % window_timer
	elif phase == "reeling":
		title = "ВЫВАЖИВАНИЕ"
		detail = "ДЕРЖИ SPACE, отпускай если красное"
	elif phase == "ready" and message_timer > 0:
		title = "У ВОДЫ"
		detail = "SPACE — забросить ещё раз"
	_draw_text(title, 156, 117, 8, GOLD if phase == "bite" else PAPER)
	_draw_text(detail, 156, 128, 7, MUTED)
	if phase == "reeling":
		_draw_text("НАТЯЖЕНИЕ", 156, 139, 6, MUTED)
		_draw_bar(202, 133, 99, 7, tension, RED, Color("6d4d46"))
		_draw_text("УЛОВ", 156, 149, 6, MUTED)
		_draw_bar(202, 143, 99, 7, progress, AQUA, Color("365958"))
	else:
		_draw_text("Наживка: %s ×%d" % [baits[selected_bait], bait_count[selected_bait]], 156, 146, 7, AQUA)

func _draw_journal() -> void:
	_draw_panel(43, 31, 234, 123)
	_draw_text("ЖУРНАЛ РЫБАКА", 57, 47, 12, GOLD)
	_draw_text("Поймано: %d / 8 видов     Всего: %d" % [_unique_fish_count(), total_caught], 57, 60, 8, PAPER)
	var y := 73
	for fish in FISH:
		var found := false
		var best := 0.0
		for item in fish_caught:
			if item.name == fish.name:
				found = true
				best = maxf(best, float(item.weight))
		var label := "%s  ·  %s" % [fish.name, fish.rarity] if found else "???  ·  ещё не встречалась"
		_draw_text(label, 58, y, 7, fish.color if found else MUTED)
		if found:
			_draw_text("рекорд %.2f кг" % best, 207, y, 7, PAPER)
		y += 9
	_draw_text("ESC — вернуться к воде", 101, 147, 7, MUTED)

func _draw_inventory() -> void:
	_draw_panel(52, 37, 216, 108)
	_draw_text("СНАРЯЖЕНИЕ", 68, 55, 12, GOLD)
	_draw_text("Удочка: %s  ·  уровень %d" % [["Бамбуковая", "Стеклопластиковая", "Карбоновая"][rod_level - 1], rod_level], 68, 72, 8, PAPER)
	_draw_text("Наживки", 68, 89, 8, AQUA)
	for i in range(baits.size()):
		var x := 68 + (i % 3) * 62
		var y := 103 + int(i / 3) * 15
		_draw_text("%s ×%d" % [baits[i], bait_count[i]], x, y, 7, PAPER if i != selected_bait else GOLD)
	_draw_text("ESC — закрыть", 124, 136, 7, MUTED)

func _draw_shop() -> void:
	_draw_panel(48, 36, 224, 112)
	_draw_text("ЛАВКА У ПРИЧАЛА", 64, 54, 12, GOLD)
	_draw_text("Монеты: %d ¤" % money, 64, 67, 8, PAPER)
	_draw_text("1  ·  купить 5 выбранных наживок  —  8 ¤", 64, 87, 8, AQUA)
	_draw_text("2  ·  улучшить удочку  —  %d ¤" % (45 * rod_level), 64, 103, 8, PAPER)
	_draw_text("Продать садок: ENTER", 64, 119, 8, GOLD)
	if message_timer > 0.0:
		_draw_text(message, 64, 130, 7, AQUA)
	_draw_text("ESC — закрыть", 190, 137, 7, MUTED)

func _draw_pause() -> void:
	_draw_rect(0, 0, W, H, Color(0.04, 0.09, 0.1, 0.76))
	_draw_panel(75, 42, 170, 99)
	_draw_text("ПАУЗА", 128, 63, 15, GOLD)
	_draw_text("ENTER  ·  продолжить", 98, 82, 8, PAPER)
	_draw_text("S  ·  сохранить игру", 98, 97, 8, MUTED)
	_draw_text("Q  ·  главное меню", 98, 112, 8, MUTED)
	_draw_text("J журнал    I снасти    M лавка", 89, 129, 7, AQUA)

func _draw_panel(x: int, y: int, w: int, h: int) -> void:
	_draw_rect(x + 2, y + 2, w, h, Color(0.04, 0.08, 0.09, 0.52))
	_draw_rect(x, y, w, h, Color("243a3d"))
	_draw_rect(x + 1, y + 1, w - 2, h - 2, Color("344c4b"))
	_draw_rect(x + 2, y + 2, w - 4, h - 4, Color(0.08, 0.15, 0.16, 0.94))
	_draw_rect(x + 3, y + 2, w - 6, 1, Color("829482"))

func _draw_bar(x: int, y: int, w: int, h: int, value: float, fill: Color, empty: Color) -> void:
	_draw_rect(x, y, w, h, empty)
	_draw_rect(x + 1, y + 1, int((w - 2) * value / 100.0), h - 2, fill)
	if value > 72 and fill == RED:
		_draw_rect(x + int(w * 0.72), y, int(w * 0.28), h, Color(0.88, 0.32, 0.27, 0.38))

func _draw_rect(x: int, y: int, w: int, h: int, color: Color) -> void:
	draw_rect(Rect2(x, y, w, h), color)

func _draw_text(text: String, x: int, y: int, size: int, color: Color) -> void:
	var font := ThemeDB.fallback_font
	if font:
		draw_string(font, Vector2(x, y), text, HORIZONTAL_ALIGNMENT_LEFT, -1, size, color)

func _unique_fish_count() -> int:
	var names: Array[String] = []
	for item in fish_caught:
		if not names.has(str(item.name)):
			names.append(str(item.name))
	return names.size()
