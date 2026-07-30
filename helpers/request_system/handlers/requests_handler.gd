class_name RequestsHandler
extends RefCounted


signal new_request(request: Request);
signal removed_request(request: Request);

var _requests: Array[Request] = []:
	get = get_requests;


func add(request: Request) -> Request:
	var id: int = roundi(Time.get_unix_time_from_system());
	
	var accumulator: int = 1;
	while(_find_request_index_in_array_by_id(id) != -1):
		id = roundi(Time.get_unix_time_from_system()) + accumulator;
		accumulator += 1;
	
	request.id = id;
	
	_requests.append(request);
	new_request.emit(request);
	
	return request;


func get_requests() -> Array[Request]:
	return _requests;


func remove(request: Request) -> void:
	_requests.pop_at(_find_request_index_in_array_by_id(request.id));
	removed_request.emit(request);


func is_empty() -> bool:
	return _requests.size() == 0;


func _find_request_index_in_array_by_id(id: int) -> int:
	return _requests.find_custom(func(r: Request) -> bool: return r.id == id);
