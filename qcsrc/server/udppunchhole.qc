string sv_udppunchhole_server;
float sv_udppunchhole_verbose;
string sv_udppunchhole_key;
entity udppunchhole_keepalive;
entity udppunchhole_porttest;

void(void) udppunchhole_keepalive_think {
	extresponse_query(sv_udppunchhole_server, strcat("extResponse udppunchhole serverkeepalive ", sv_udppunchhole_key));
	self.nextthink = time + 15;
}

void(void) udppunchhole_porttest_think {
	self.cnt = self.cnt - 1;
	if (self.cnt >= 0) {
		extresponse_query(sv_udppunchhole_server, "extResponse udppunchhole porttest");
	}
	if (self.cnt < 0) {
		if (sv_udppunchhole_verbose)
			print("Port test failed, will try udp punch hole\n");

		remove(udppunchhole_porttest);
		udppunchhole_porttest = world;
		udppunchhole_keepalive = spawn();
		udppunchhole_keepalive.think = udppunchhole_keepalive_think;
		udppunchhole_keepalive.nextthink = time;
		return;
	}
	self.nextthink = time + 0.5;
}

void(float argc, string response) udppunchhole_extresponse_handler_extra_sv {
	string s = argv(2);
	if (s == "porttest") {
		if (sv_udppunchhole_verbose)
			print("Port test success\n");

		if (udppunchhole_porttest) {
			remove(udppunchhole_porttest);
			udppunchhole_porttest = world;
		}
		if (argc >= 4) {
			registercvar("_net_http_server_host_auto", "0");
			if (cvar_string("net_http_server_host") == "" || cvar("_net_http_server_host_auto")) {
				cvar_set("_net_http_server_host_auto", "1");
				cvar_set("net_http_server_host", argv(3));
			}
		}
	} else {
		if (sv_udppunchhole_verbose)
			print("udppunchhole: unknown command: ", s, "\n");
	}
}

void(void) udppunchhole_init {
	if not(cvar("sv_udppunchhole"))
		return;

	udppunchhole_extresponse_handler_extra = udppunchhole_extresponse_handler_extra_sv;
	CVAR_CACHE_STR(sv_udppunchhole_server);
	CVAR_CACHE_STR(sv_udppunchhole_key);
	CVAR_CACHE(sv_udppunchhole_verbose);
	udppunchhole_extresponse_handler_register();
	udppunchhole_porttest = spawn();
	udppunchhole_porttest.think = udppunchhole_porttest_think;
	udppunchhole_porttest.nextthink = time;
	udppunchhole_porttest.cnt = 3;
}
