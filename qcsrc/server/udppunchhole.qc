string sv_udppunchhole_server;
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
		print("Port test success\n");
		if (udppunchhole_porttest) {
			remove(udppunchhole_porttest);
			udppunchhole_porttest = world;
		}
	} else {
		print("udppunchhole: unknown command: ", s, "\n");
	}
}

void(void) udppunchhole_init {
	if not(cvar("sv_udppunchhole"))
		return;

	udppunchhole_extresponse_handler_extra = udppunchhole_extresponse_handler_extra_sv;
	CACHE_CVAR_STR(sv_udppunchhole_server);
	CACHE_CVAR_STR(sv_udppunchhole_key);
	udppunchhole_extresponse_handler_register();
	udppunchhole_porttest = spawn();
	udppunchhole_porttest.think = udppunchhole_porttest_think;
	udppunchhole_porttest.nextthink = time;
	udppunchhole_porttest.cnt = 3;
}
