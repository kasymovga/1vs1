#define MAX_URI_HANDLERS 32
float uri_handlers_count;

var void(float id, float status, string data) uri_handlers[MAX_URI_HANDLERS];

void(float id, float status, string data) URI_Get_Callback {
	if (id <= uri_handlers_count && id > 0)
		uri_handlers[id - 1](id, status, data);
	else if (id != URI_GET_DISCARD)
		print("Received HTTP request data for an invalid id ", ftos(id), ".\n");
}

float(void(float id, float status, string data) uri_handler) uri_register_handler {
	if (uri_handlers_count >= MAX_URI_HANDLERS) {
		print("URI callback table overflow!!!\n");
		return -1;
	}
	uri_handlers_count++;
	uri_handlers[uri_handlers_count - 1] = uri_handler;
	return uri_handlers_count;
}
