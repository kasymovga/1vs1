void(void) db_init {
	db_server = db_load("server.db");
	db_temp = db_create();
}

void(void) db_shutdown {
	db_save(db_server, "server.db");
	if(cvar("developer"))
		db_save(db_temp, "server-temp.db");

	db_close(db_server);
	db_close(db_temp);
}
