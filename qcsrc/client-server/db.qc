void(float db, string pFilename) db_save {
	float fh, i, n;
	fh = fopen(pFilename, FILE_WRITE);
	if(fh < 0) {
		print(strcat("^1Can't write DB to ", pFilename));
		return;
	}
	n = buf_getsize(db);
	fputs(fh, strcat(ftos(DB_BUCKETS), "\n"));
	for(i = 0; i < n; ++i)
		fputs(fh, strcat(bufstr_get(db, i), "\n"));

	fclose(fh);
}
