class_name TelegramBot
extends Node

var polling_timer : Timer = Timer.new()

signal task_completed(result)
signal task_error(error)

signal new_event(event)
signal got_me(bot_settings)
signal got_updates(updates)
signal message_send(message)
signal message_deleted(message)
signal user_banned(user)

var _bot_token : String = ""
var _base_url : String = "https://api.telegram.org/bot{token}"

var _pooled_tasks : Array = []

var is_polling : bool
var last_update_id : int = -1


func _init(bot_token : String) -> void:
	_bot_token = bot_token
	_base_url = _base_url.format({token = _bot_token})
	set_name(bot_token)

func start_polling(interval : float) -> void:
	add_child(polling_timer)
	is_polling = true
	polling_timer.wait_time = interval
	polling_timer.connect("timeout", self, "_on_polling")
	polling_timer.start()

func stop_polling() -> void:
	polling_timer.stop()
	polling_timer.disconnect("timeout", self, "_on_polling")
	remove_child(polling_timer)

func get_me() -> TelegramBotTask:
	var task : TelegramBotTask = TelegramBotTask.new()
	add_child(task)
	task.set_task(task.Methods.GET_ME)
	task.connect("task_completed", self, "_on_task_completed", [task])
	task.connect("task_error", self, "_on_task_error", [task])
	_pooled_tasks.append(task)
	return task

func get_updates() -> TelegramBotTask:
	var task : TelegramBotTask = TelegramBotTask.new()
	add_child(task)
	task.set_task(task.Methods.GET_UPDATES)
	task.connect("task_completed", self, "_on_task_completed", [task])
	task.connect("task_error", self, "_on_task_error", [task])
	_pooled_tasks.append(task)
	return task

func send_message(message : TelegramMessage) -> TelegramBotTask:
	var task : TelegramBotTask = TelegramBotTask.new()
	add_child(task)
	task.set_task(task.Methods.SEND_MESSAGE, message.to_dict(), ["Content-Type: application/json"])
	task.connect("task_completed", self, "_on_task_completed", [task])
	task.connect("task_error", self, "_on_task_error", [task])
	_pooled_tasks.append(task)
	return task

func delete_message(chat_id, message_id: int) -> TelegramBotTask:
	var task : TelegramBotTask = TelegramBotTask.new()
	add_child(task)
	task.set_task(task.Methods.DELETE_MESSAGE, {chat_id = str(chat_id), message_id = message_id}, ["Content-Type: application/json"])
	task.connect("task_completed", self, "_on_task_completed", [task])
	task.connect("task_error", self, "_on_task_error", [task])
	_pooled_tasks.append(task)
	return task

func ban_chat_member(chat_id, user_id: int) -> TelegramBotTask:
	var task : TelegramBotTask = TelegramBotTask.new()
	add_child(task)
	task.set_task(task.Methods.BAN_CHAT_MEMBER, {chat_id = str(chat_id), user_id = user_id}, ["Content-Type: application/json"])
	task.connect("task_completed", self, "_on_task_completed", [task])
	task.connect("task_error", self, "_on_task_error", [task])
	_pooled_tasks.append(task)
	return task

func _process(delta : float) -> void:
	if _pooled_tasks.size():
		var first_task : TelegramBotTask = _pooled_tasks.pop_front()
		first_task.process_task()

func _on_task_error(error, task : TelegramBotTask) -> void:
	emit_signal("task_error", error)

func _on_task_completed(result, task : TelegramBotTask) -> void:
	match task.method:
		task.Methods.GET_ME: emit_signal("got_me", result)
		task.Methods.GET_UPDATES: 
			if is_polling:
				for update in result:
					var update_id : int = update.update_id
					if update_id > last_update_id:
						emit_signal("new_event", update)
						if last_update_id == -1 : last_update_id = update_id
						else: last_update_id += 1 
			else:
				emit_signal("got_updates", result)
		task.Methods.SEND_MESSAGE: emit_signal("message_send", result)
		task.Methods.DELETE_MESSAGE: emit_signal("message_deleted", result)
		task.Methods.BAN_CHAT_MEMBER: emit_signal("user_banned", result)
	emit_signal("task_completed", result)


func _on_polling() -> void:
	get_updates()
