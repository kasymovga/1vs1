string sv_udppunchhole_server;
string sv_udppunchhole_key;
entity udppunchhole_keepalive;

void(void) udppunchhole_keepalive_think {
	extresponse_query(sv_udppunchhole_server, strcat("extResponse udppunchhole serverkeepalive ", sv_udppunchhole_key));
	self.nextthink = time + 15;
}

void(void) udppunchhole_init {
	if not(cvar("sv_udppunchhole"))
		return;

	CACHE_CVAR_STR(sv_udppunchhole_server);
	CACHE_CVAR_STR(sv_udppunchhole_key);
	udppunchhole_extresponse_handler_register();
	udppunchhole_keepalive = spawn();
	udppunchhole_keepalive.think = udppunchhole_keepalive_think;
	udppunchhole_keepalive.nextthink = time;
}
