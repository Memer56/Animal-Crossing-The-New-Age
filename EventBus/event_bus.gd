extends Node

signal create_overflow_slot_data(slot_data : SlotData)
signal duplicate_slot_data_info
signal armour_piece_equipped(grabbed_slot_data : SlotData, index : int)
signal armour_piece_unequipped(inventory_data : InventoryDataEquip, grabbed_slot_data : SlotData, index : int)

var player
var can_place : bool = true
var held_item_slot_data : SlotData
var coins
var game_paused : bool = false
