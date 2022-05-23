void(float error, string url, string filename, float downloads_left) curl_event {
	curl_downloads_left = downloads_left;
	curl_error = error;
	entity e;
	entity oldself;
	for (e = NULL; (e = findstring(e, classname, "curl_event_listener"));) {
		oldself = self;
		self = e;
		curl_file_name = filename;
		e.think();
		curl_file_name = NULL;
		self = oldself;
	}
}
