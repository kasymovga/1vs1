string(float db, string pKey) db_get {
	float h;
	h = math_mod(crc16(FALSE, pKey), DB_BUCKETS);
	string s = bufstr_get(db, h);
	if not(s)
		return "";

	s = infoget(s, pKey);
	if not(s)
		return "";

	return uri_unescape(s);
}

void(float db, string pKey, string pValue) db_put {
	float h;
	h = math_mod(crc16(FALSE, pKey), DB_BUCKETS);
	string s = bufstr_get(db, h);
	if (strlen(s) > 4096) {
		print("Database field keep too much data! Truncating.\n");
		s = "";
	}
	bufstr_set(db, h, infoadd(s, pKey, uri_escape(pValue)));
	bufstr_set(db, 0, infoadd(bufstr_get(db, 0), "modified", "1"));
}

float(void) db_create {
	return buf_create();
}

float(string pFilename) db_load {
	float db, fh, i, j, n;
	string l;
	db = buf_create();
	if(db < 0)
		return -1;
	fh = fopen(pFilename, FILE_READ);
	if(fh < 0)
		return db;
	if(stof(fgets(fh)) == DB_BUCKETS) {
		i = 0;
		while((l = fgets(fh))) {
			if(l != "")
				bufstr_set(db, i, l);
			++i;
		}
	} else {
		// different count of buckets?
		// need to reorganize the database then (SLOW)
		while((l = fgets(fh))) {
			n = tokenizebyseparator(l, "\\");
			for(j = 2; j < n; j += 2)
				db_put(db, argv(j-1), uri_unescape(argv(j)));
		}
	}
	fclose(fh);
	return db;
}

void(float db) db_close {
	buf_del(db);
}
