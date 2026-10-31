string(float db, string pKey) db_get {
	float h, n;
	h = math_mod(crc16(FALSE, pKey), DB_BUCKETS) + 1;
	string s;
	for (n = buf_getsize(db), s = ""; h < n; h += DB_BUCKETS) {
		s = infoget(bufstr_get(db, h), pKey);
		if (s != "")
			return uri_unescape(s);
	}
	return NULL;
}

void(float db, string pKey, string pValue) db_put {
	float h, n, i;
	string s;
	pValue = uri_escape(pValue);
	if (strlen(pKey) + strlen(pValue) > 16380) return; // info string can't hold this data, sad
	h = math_mod(crc16(FALSE, pKey), DB_BUCKETS) + 1;
	for (i = h, n = buf_getsize(db); i < n; i += DB_BUCKETS) { // clear all values first
		s = bufstr_get(db, i);
		bufstr_set(db, i, infoadd(s, pKey, ""));
	}
	if (pValue == "") return;
	s = bufstr_get(db, h);
	while (strlen(s) + strlen(pKey) + strlen(pValue) > 16380) {
		h += DB_BUCKETS;
		if (h >= buf_getsize(db)) {
			//print("DB capacity extended\n");
			s = "";
			break;
		} else
			s = bufstr_get(db, h);
	}
	bufstr_set(db, h, infoadd(s, pKey, pValue));
	bufstr_set(db, 0, "modified");
}

float(void) db_create {
	return buf_create();
}

void(float db) db_close {
	buf_del(db);
}
