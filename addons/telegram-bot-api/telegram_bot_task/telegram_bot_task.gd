class_name TelegramBotTask
extends HTTPRequest

signal task_completed(result)
signal task_error(error)

enum Methods {
	GET_ME,
	GET_UPDATES,
	SEND_MESSAGE,
	DELETE_MESSAGE,
	BAN_CHAT_MEMBER
}

var _base_url : String
var _endpoint : String
var _http_method : int
var _header : PoolStringArray
var _payload : Dictionary

var method : int

func _ready() -> void:
	connect("request_completed", self, "_on_task_completed")

func match_endpoint(_method : int) -> void:
	method = _method
	match method:
		Methods.GET_UPDATES:
			_endpoint =  "getUpdates"
			_http_method = HTTPClient.METHOD_GET
		Methods.SEND_MESSAGE:
			_endpoint = "sendMessage"
			_http_method = HTTPClient.METHOD_POST
		Methods.BAN_CHAT_MEMBER:
			_endpoint = "banChatMember"
			_http_method = HTTPClient.METHOD_POST
		Methods.DELETE_MESSAGE:
			_endpoint = "deleteMessage"
			_http_method = HTTPClient.METHOD_POST
		_, Methods.GET_ME:
			_http_method = HTTPClient.METHOD_GET
			_endpoint = "getMe"

func set_task(_method : int, payload : Dictionary = {}, header : PoolStringArray = []) -> void:
	_base_url = get_parent()._base_url
	match_endpoint(_method)
	_header = header
	_payload = payload

func process_task() ->  void:
	request(_base_url + "/" + _endpoint, _header, true, _http_method, to_json(_payload))

func _on_task_completed(result : int, response_code : int, headers : PoolStringArray, body : PoolByteArray):
	if result == 0:
		if response_code == 200:
			var result_body = parse_json(body.get_string_from_utf8()).result
			emit_signal("task_completed", result_body)
		if response_code > 300:
			var error_json = JSON.parse(body.get_string_from_utf8())
			emit_signal("task_error", error_json.result if error_json.error == OK else {})
		queue_free()
			
