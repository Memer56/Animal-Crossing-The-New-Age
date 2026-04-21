extends Control

@onready var loan_balance: Label = $Background/Panel/BalanceBG/VBoxContainer/HBoxContainer/LoanBalance
@onready var savings_balance: Label = $Background/Panel/BalanceBG/VBoxContainer/HBoxContainer2/SavingsBalance
@onready var player_balance: Label = $Background/Panel/PlayerBalanceBG/PlayerBalance
@onready var input_field: LineEdit = $Background/Panel/InputBG/InputField
@onready var num_pad: Control = $Background/Panel/NumPad
@onready var input_bg: Panel = $Background/Panel/InputBG
@onready var main_buttons: VBoxContainer = $Background/Panel/MainButtons
@onready var title: Label = $Background/Title

var state

enum {
	LOAN,
	DEPOSIT,
	WITHDRAW
}


func _ready() -> void:
	EventBus.toggle_atm_ui.connect(toggle_self)
	set_balances()

func set_balances():
	if EventBus.player_is_debt_free:
		loan_balance.text = "Tom will want more"
	else:
		loan_balance.text = format_with_commas(EventBus.loan_balance)
	savings_balance.text = format_with_commas(EventBus.savings_balance)
	player_balance.text = format_with_commas(EventBus.player_balance)

func format_with_commas(number: int) -> String:
	var number_as_string : String = str(number)
	var output_string : String = ""
	var last_index : int = number_as_string.length() - 1
	#For each digit in the number...
	for index in range(number_as_string.length()):
		#add that digit to the output string, and then...
		output_string = output_string + number_as_string.substr(index,1)
		#if the index is at the thousandths, millions, billionths place, etc.
		#i.e. where you would put a comma, then insert a comma after that digit.
		if (last_index - index) % 3 == 0 and index != last_index:
			output_string = output_string + ","
	return output_string

func toggle_self():
	if visible:
		hide()
	else:
		show()
		set_balances()


func _on_loan_payment_pressed() -> void:
	state = LOAN
	toggle_numpad()
	title.text = "Input amount to repay loan"


func _on_deposit_pressed() -> void:
	state = DEPOSIT
	toggle_numpad()
	title.text = "Input amount to deposit"


func _on_withdraw_pressed() -> void:
	state = WITHDRAW
	toggle_numpad()
	title.text = "Input amount to withdraw"


func _on_num_button_pressed(source: BaseButton) -> void:
	var button_value = source.text
	update_input_field(button_value)


func _on_clear_pressed() -> void:
	input_field.text = ""


func _on_full_amount_pressed() -> void:
	input_field.text = str(EventBus.player_balance)


func _on_delete_pressed() -> void:
	if input_field.text != "":
		var text = input_field.text
		var new_text = text.erase(text.length() - 1, 1)
		input_field.text = new_text


func _on_confirm_pressed() -> void:
	match state:
		LOAN:
			if EventBus.savings_balance >= int(input_field.text) and !EventBus.player_is_debt_free:
				EventBus.previous_loan_balance = EventBus.loan_balance
				EventBus.loan_balance -= int(input_field.text)
				EventBus.savings_balance -= int(input_field.text)
				if EventBus.loan_balance <= 0:
					EventBus.player_is_debt_free = true
		DEPOSIT:
			if EventBus.player_balance >= int(input_field.text):
				EventBus.savings_balance += int(input_field.text)
				EventBus.player_balance -= int(input_field.text)
		WITHDRAW:
			if EventBus.savings_balance >= int(input_field.text):
				EventBus.savings_balance -= int(input_field.text)
				EventBus.player_balance += int(input_field.text)

	set_balances()
	input_field.text = ""


func update_input_field(button_value : String):
	var value_check = int(button_value)
	if input_field.text == "" and value_check == 0:
		return
	var previous_text : String = input_field.text
	var value = button_value
	var combined_value = previous_text + value
	input_field.text = combined_value


func toggle_numpad():
	if num_pad.visible:
		num_pad.hide()
		input_bg.hide()
		main_buttons.show()
	else:
		num_pad.show()
		input_bg.show()
		main_buttons.hide()


func _on_back_pressed() -> void:
	toggle_numpad()
	title.text = "Select an option below"


func _on_exit_pressed() -> void:
	toggle_self()
	toggle_numpad()
