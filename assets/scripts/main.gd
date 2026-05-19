extends Node

#for saving
var save_path = "user://variable.save"

#preload obstacles
var stump = preload("res://assets/objects/obstacles/stump.tscn");
var rock = preload("res://assets/objects/obstacles/rock.tscn");
var bird = preload("res://assets/objects/obstacles/bird.tscn");
var barrel = preload("res://assets/objects/obstacles/barrell.tscn")
var obstacle_types := [stump, rock, barrel];
var obstacles : Array;
var bird_heights := [200, 390] #randomizes when the bird will spawn

#game variables
const DINO_START_POS := Vector2(150, 485);
const CAM_START_POS := Vector2(576, 324);
var difficulty: int = 0;
const MAX_DIFFICULTY: int = 5
const bird_difficulty_spawn: int = 3;

var score: int;
var high_score: int;
const SCORE_MODIFIER: int = 50;
@onready var dino: CharacterBody2D = $dino;
@onready var camera: Camera2D = $camera
@onready var ground: StaticBody2D = $ground
@onready var hud: CanvasLayer = $HUD
@onready var gameover: CanvasLayer = $GAMEOVER
var player: CharacterBody2D;

var speed: int; #changing speed
const START_SPEED: int = 10;
var screen_size: Vector2i
var ground_height: int;
var game_running: bool = false;
var SPEED_MODIFIER: float = 25000
var last_obs
var obs_spacing_min: int = 300;
var obs_spacing_max: int = 500;
var obs_x_offscreen = 100; #so it will appear offscreen

func _ready():
	player = get_tree().get_first_node_in_group("player")
	screen_size = get_window().size;
	ground_height = ground.get_node("Sprite2D").texture.get_height()
	gameover.get_node("restart2").pressed.connect(new_game) #when the restart button is pressed the game will restart
	new_game()

func new_game():
	load_data()
	#reset var
	score = 0;
	show_score();
	#show high score
	check_high_score()
	get_tree().paused = false; #SO IF There is a gameover the game restarts and if we restart the gameunpauses
	difficulty = 0;
	#resets everything if there is a new game
	dino.position = DINO_START_POS;
	dino.velocity = Vector2i(0, 0);
	camera.position = CAM_START_POS;
	ground.position = Vector2i(0,0)
	
	#resets obstacles
	for obs in obstacles:
		obs.queue_free()
	obstacles.clear()
	
	#show start game text + hiding game over text
	hud.get_node("MarginContainer/pressspaceto_play").show()
	gameover.hide()

func _process(_delta):
	if game_running == true:
		#speed up and adjust difficulty
		@warning_ignore("narrowing_conversion")
		speed = START_SPEED + (score / SPEED_MODIFIER);
		adjust_difficulty()
		
		#generate obstacles
		generate_obs()
		
		#move dino and camera
		dino.position.x += speed;
		camera.position.x += speed;
		
		#update score
		score += speed 
		show_score()
		
		#update ground position to move along with the camera
		if camera.position.x - ground.position.x > screen_size.x * 1.5:
			ground.position.x += screen_size.x
		
		#remove obstacles that have gone off screen
		for obs in obstacles:
			if obs.position.x < (camera.position.x - screen_size.x):
				remove_obs(obs)
	else:
		if Input.is_action_just_pressed("jump"):
			game_running = true;
			hud.get_node("MarginContainer/pressspaceto_play").hide()

func generate_obs():
	#gnerate ground obstacles
	if obstacles.is_empty() or last_obs.position.x < score + randi_range(obs_spacing_min, obs_spacing_max):
		var obs_type = obstacle_types[randi() % obstacle_types.size()] #randomly chooses an obstacle
		var obs
		var max_obs = difficulty + 1; 
		for i in range(randi() % max_obs + 1): #randomizes object spawning
			obs = obs_type.instantiate();
			var obs_height = obs.get_node("Sprite2D").texture.get_height() #gets obstacle's height
			var obs_scale = obs.get_node("Sprite2D").scale #gets obstacle's scale
			var obs_x: int = screen_size.x + score + obs_x_offscreen + (i * 100)
			var obs_y: int = screen_size.y - ground_height - (obs_height * obs_scale.y / 2) + 5
			last_obs = obs;
			add_obs(obs, obs_x, obs_y)
		#random chance for a bird to spawn
		if difficulty == bird_difficulty_spawn:
			if (randi() % 2) == 0:
				#get the bird
				obs = bird.instantiate()
				var obs_x: int = screen_size.x + score + obs_x_offscreen;
				var obs_y: int = bird_heights[randi() % bird_heights.size()]
				add_obs(obs, obs_x, obs_y)

func add_obs(obs, x, y): #adds obstacles
	obs.position = Vector2i(x, y)
	obs.body_entered.connect(hit_obs)
	add_child(obs);
	obstacles.append(obs)

func remove_obs(obs): #removes obstacles from the node tree AND array
	obs.queue_free()
	obstacles.erase(obs)

func hit_obs(body): #when you hhit  the obstacle
	if body == player: 
		game_over()

func show_score():
	@warning_ignore("integer_division")
	hud.get_node("MarginContainer/current_score").text = str(score / SCORE_MODIFIER)

func check_high_score():
	if score > high_score:
		high_score = score;
	@warning_ignore("integer_division")
	hud.get_node("MarginContainer/HIGHESTSCORE").text = str(high_score / SCORE_MODIFIER)

func adjust_difficulty():
	@warning_ignore("narrowing_conversion")
	difficulty = score / SPEED_MODIFIER;
	if difficulty > MAX_DIFFICULTY:
		difficulty = MAX_DIFFICULTY;

func game_over(): #ends the game
	save()
	get_tree().paused = true;
	game_running = false;
	gameover.show()

#for saving the file
func save():
	var file = FileAccess.open(save_path, FileAccess.WRITE)
	file.store_var(high_score)

#for loading the save data
func load_data():
	if FileAccess.file_exists(save_path):
		var file = FileAccess.open(save_path, FileAccess.READ)
		high_score = file.get_var(high_score); #gets the var saved in the file
	else:
		print("no data found!")
		high_score = 0;
