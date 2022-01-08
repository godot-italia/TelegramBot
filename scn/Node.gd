extends Node

const TOKEN: String = "" 
const CHAT: String = "-1001347347365"

var bot : TelegramBot = TelegramAPI.get_bot(TOKEN)

func _ready():
	bot.connect("new_event", self, "_on_bot_event")
	bot.connect("message_send", self, "_on_message_send")
	bot.connect("task_error", self, "_on_task_error")
	bot.start_polling(1.0)

func _on_bot_event(event : Dictionary) -> void:
	print(event)
	if event.has("message") and event.message.has("text"): 
		if event.message.text.countn("BTC") > 1:
			print("BTC Spam found!")
			print("chat: %s, user: %s" % [event.message.chat.id, event.message.message_id])
			bot.delete_message(event.message.chat.id, event.message.message_id)
			bot.ban_chat_member(event.message.chat.id, event.message.chat.from.id)

func _on_message_send(result) -> void:
	print("Message send! ", result)

func _on_task_error(error) -> void:
	print(error)
