void(float db, string pFilename) db_save {
	float fh, i, n = buf_getsize(db);
	fh = fopen(pFilename, FILE_WRITE);
	if (fh < 0) {
		print(strcat("^1Can't write DB to ", pFilename));
		return;
	}
	fputs(fh, strcat(ftos(DB_BUCKETS), "\n"));
	for(i = 1; i < n; i++) {
		fputs(fh, bufstr_get(db, i));
		fputs(fh, "\n");
	}
	fclose(fh);
}

float(string pFilename) db_load {
	float db, fh, i, j, n;
	string l;
	db = buf_create();
	if (db < 0)
		return -1;

	fh = fopen(pFilename, FILE_READ);
	if (fh < 0)
		return db;

	if (stof(fgets(fh)) == DB_BUCKETS) {
		i = 1;
		for (; (l = fgets(fh)); i++) {
			if (l != "")
				bufstr_set(db, i, l);
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

void(void) db_init {
	db_server = db_load("server.db");
	db_temp = db_create();
}

float(float db) db_is_modified {
	return (bufstr_get(db, 0) == "modified");
}

void(void) db_shutdown {
	if (db_is_modified(db_server))
		db_save(db_server, "server.db");

	if (cvar("developer"))
		db_save(db_temp, "server-temp.db");

	db_close(db_server);
	db_close(db_temp);
}
