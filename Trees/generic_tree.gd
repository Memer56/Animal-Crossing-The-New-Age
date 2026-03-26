extends Node3D

const PICK_UP = preload("uid://c8p87t4ex6hyc")

@export var normal_trees : Array[PackedScene]
@export var special_trees : Array[PackedScene]
@export var wood_types : Array[SlotData]
@export var selected_tree : PackedScene
@export var selected_position : Vector3
@export var tree_branch : SlotData
@export var spawn_positions : Array[Marker3D]
@export var tree_branches_spawn_positions : Array[Marker3D]
@onready var tree_node: Node3D = $TreeNode
@onready var animation_player: AnimationPlayer = $AnimationPlayer

var tree
var health : int = 6
var can_take_damage : bool = true
var tree_branches_have_been_dropped : bool = false

func _ready() -> void:
	begin_tree_selection_process()

func begin_tree_selection_process():
	var value = randi_range(0, 100)
	var chosen_tree_packedscene : PackedScene
	
	if value <= 80:
		var chosen_tree = normal_trees.pick_random()
		chosen_tree_packedscene = chosen_tree
		tree = chosen_tree.instantiate()
	elif value >=81:
		var chosen_tree = special_trees.pick_random()
		chosen_tree_packedscene = chosen_tree
		tree = chosen_tree.instantiate()
	
	tree_node.add_child(tree)
	tree.send_damage.connect(damage_object)
	selected_tree = chosen_tree_packedscene
	selected_position = global_position
	## Allows time for position to be set before saving it
	await get_tree().create_timer(0.2).timeout
	EventBus.current_trees.append([selected_tree, global_position])

func damage_object(tool_slot_data : SlotData):
	if can_take_damage:
		if !tree_branches_have_been_dropped:
			tree_branches_have_been_dropped = true
			drop_tree_branches()
		# stops tree from falling as soon as player clicks
		await get_tree().create_timer(0.4).timeout
		health -= tool_slot_data.item_data.item_strength
		if health <= 0:
			can_take_damage = false
			animation_player.play("TreeFall")
			drop_loot()

func drop_loot():
	for point in spawn_positions:
		var wood : SlotData = wood_types.pick_random()
		wood.quantity = randi_range(1, 4)
		
		var pick_up = create_pickup(wood)
		pick_up.global_position = global_position
		var tween = get_tree().create_tween()
		tween.tween_property(pick_up, "global_position", point.global_position, 1.0).set_trans(Tween.TRANS_SINE)

func drop_tree_branches():
	for point in tree_branches_spawn_positions:
		var new_tree_branch : SlotData = tree_branch
		new_tree_branch.quantity = randi_range(1, 4)
		
		var pick_up = create_pickup(new_tree_branch)
		pick_up.global_position = global_position
		var tween = get_tree().create_tween()
		tween.tween_property(pick_up, "global_position", point.global_position, 1.0).set_trans(Tween.TRANS_SINE)


func create_pickup(slot_data):
	var pick_up = PICK_UP.instantiate()
	pick_up.slot_data = slot_data
	get_tree().root.add_child(pick_up)
	pick_up.label_3d.text = slot_data.item_data.name
	return pick_up

func fade_tree():
	tree.fade_tree()


func _on_animation_player_animation_finished(_anim_name: StringName) -> void:
	queue_free()
