void(float error, string url, string filename, float downloads_left) curl_event {
	entity e;
	entity oldself;
	for (e = NULL; (e = findstring(e, classname, "curl_event_listener"));) {
		oldself = self;
		self = e;
		curl_downloads_left = downloads_left;
		curl_error = error;
		curl_file_name = filename;
		e.think();
		curl_file_name = NULL;
		curl_error = 0;
		curl_downloads_left = 0;
		self = oldself;
	}
}
