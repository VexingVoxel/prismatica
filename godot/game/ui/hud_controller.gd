class_name HUDControllerClass extends Control

## HUDController
##
## Responsibility: Manages the 2D UI Overlay (Labels, Progress Bars, Toasts).
##
## Connections:
## - Listens to GameplayEventBus.resource_changed -> Updates SparksLabel.
## - Listens to CoreEventBus.toast_notification_requested -> Spawns transient info popups.

# ------------------------------------------------------------------------------
# Nodes
# ------------------------------------------------------------------------------

@onready var sparks_label: Label = %SparksLabel
@onready var message_log: VBoxContainer = %MessageLog # For toast messages

var overload_bar: ProgressBar
var overload_btn: Button
var prestige_btn: Button

# ------------------------------------------------------------------------------
# Initialization
# ------------------------------------------------------------------------------

func _ready() -> void:
	_create_overload_ui()
	_create_prestige_ui()
	_connect_signals()
	# Initial UI update
	_update_sparks_display(GameCore.get_sparks())

func _create_overload_ui() -> void:
	# ... (Existing code) ...
	var bottom_panel: HBoxContainer = HBoxContainer.new()
	bottom_panel.layout_mode = 1
	bottom_panel.anchors_preset = 12 # Bottom wide
	bottom_panel.anchor_top = 1.0
	bottom_panel.anchor_right = 1.0
	bottom_panel.anchor_bottom = 1.0
	bottom_panel.offset_top = -60.0
	bottom_panel.offset_bottom = -20.0
	bottom_panel.alignment = BoxContainer.ALIGNMENT_CENTER
	
	overload_btn = Button.new()
	overload_btn.text = "OVERLOAD"
	overload_btn.pressed.connect(_on_overload_pressed)
	bottom_panel.add_child(overload_btn)
	
	overload_bar = ProgressBar.new()
	overload_bar.custom_minimum_size = Vector2(200, 30)
	overload_bar.show_percentage = false
	bottom_panel.add_child(overload_bar)
	
	add_child(bottom_panel)

func _create_prestige_ui() -> void:
	prestige_btn = Button.new()
	prestige_btn.text = "ASCEND (Reset for Light)"
	prestige_btn.pressed.connect(_on_prestige_pressed)
	prestige_btn.visible = false
	
	# Top Right
	prestige_btn.layout_mode = 1
	prestige_btn.anchors_preset = 1
	prestige_btn.position = Vector2(get_viewport_rect().size.x - 220, 20)
	add_child(prestige_btn)

func _process(_delta: float) -> void:
	_update_overload_ui()
	_update_prestige_ui()

func _update_prestige_ui() -> void:
	var potential: BigNumber = GameCore.get_prestige_potential()
	if not potential.is_zero():
		prestige_btn.visible = true
		prestige_btn.text = "ASCEND (+%s Light)" % potential.to_formatted_string()
	else:
		prestige_btn.visible = false

func _on_prestige_pressed() -> void:
	GameCore.prestige()

func _update_overload_ui() -> void:
	var state: Dictionary = GameCore.get_overload_state()
	
	if state.active:
		overload_btn.disabled = true
		overload_btn.text = "ACTIVE!"
		overload_bar.max_value = state.duration
		overload_bar.value = state.time_left
		overload_bar.modulate = Color.RED # Active color
	elif state.cooldown_left > 0.0:
		overload_btn.disabled = true
		overload_btn.text = "Cooldown"
		overload_bar.max_value = state.cooldown_max
		overload_bar.value = state.cooldown_max - state.cooldown_left # Fill up
		overload_bar.modulate = Color.GRAY # Cooldown color
	else:
		overload_btn.disabled = false
		overload_btn.text = "OVERLOAD"
		overload_bar.value = 0
		overload_bar.modulate = Color.WHITE

func _on_overload_pressed() -> void:
	GameCore.activate_overload()

func _connect_signals() -> void:
	GameplayEventBus.resource_changed.connect(_on_resource_changed)
	# TODO: Connect to GameCore for Ability Cooldowns -> OverloadProgressBar
	CoreEventBus.toast_notification_requested.connect(_on_toast_notification_requested)

# ------------------------------------------------------------------------------
# Event Handlers
# ------------------------------------------------------------------------------

func _on_resource_changed(type: String, amount_bignum: BigNumber, formatted_str: String) -> void:
	match type:
		"sparks":
			_update_sparks_display(amount_bignum)
		"feedback_message":
			_display_toast(formatted_str)
		_:
			pass # Handle other resources here if needed

func _on_toast_notification_requested(title: String, message: String, type: CoreEventBus.ToastType) -> void:
	_display_toast("%s: %s" % [title, message], type)

# ------------------------------------------------------------------------------
# UI Updates
# ------------------------------------------------------------------------------

func _update_sparks_display(sparks: BigNumber) -> void:
	sparks_label.text = "Sparks: %s" % sparks.to_formatted_string()

func _display_toast(message: String, type: CoreEventBus.ToastType = CoreEventBus.ToastType.INFO) -> void:
	var toast_label: Label = Label.new()
	toast_label.text = message
	toast_label.add_theme_color_override("font_color", _get_color_for_toast_type(type))
	toast_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	
	message_log.add_child(toast_label)
	
	# Fade out and remove after a short delay
	var tween: Tween = get_tree().create_tween()
	tween.tween_property(toast_label, "modulate", Color(1, 1, 1, 0), 2.0).set_delay(1.0)
	tween.tween_callback(toast_label.queue_free)

func _get_color_for_toast_type(type: CoreEventBus.ToastType) -> Color:
	match type:
		CoreEventBus.ToastType.INFO: return Color.WHITE
		CoreEventBus.ToastType.WARNING: return Color.YELLOW
		CoreEventBus.ToastType.ERROR: return Color.RED
	return Color.WHITE
