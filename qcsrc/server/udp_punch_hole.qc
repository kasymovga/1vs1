string sv_udppunchhole_server;
float sv_udppunchhole_verbose;
string sv_udppunchhole_key;
entity udp_punch_hole_keepalive;
entity udp_punch_hole_port_test;

void(void) udp_punch_hole_keepalive_think {
	extresponse_query(sv_udppunchhole_server, strcat("extResponse udppunchhole serverkeepalive ", sv_udppunchhole_key));
	self.nextthink = time + 15;
}

#define udp_punch_hole_port_test_think udppunchhole_porttest_think //compatibility with old save files
void(void) udp_punch_hole_port_test_think {
	self.cnt = self.cnt - 1;
	if (self.cnt >= 0) {
		extresponse_query(sv_udppunchhole_server, "extResponse udppunchhole porttest");
	}
	if (self.cnt < 0) {
		if (sv_udppunchhole_verbose)
			print("Port test failed, will try udp punch hole\n");

		remove(udp_punch_hole_port_test);
		udp_punch_hole_port_test = world;
		udp_punch_hole_keepalive = spawn();
		udp_punch_hole_keepalive.think = udp_punch_hole_keepalive_think;
		udp_punch_hole_keepalive.nextthink = time;
		return;
	}
	self.nextthink = time + 0.5;
}

void(float argc, string response) udp_punch_hole_extresponse_handler_extra_sv {
	string s = argv(2);
	if (s == "porttest") {
		if (sv_udppunchhole_verbose)
			print("Port test success\n");

		if (udp_punch_hole_port_test) {
			remove(udp_punch_hole_port_test);
			udp_punch_hole_port_test = world;
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
			print("udp_punch_hole: unknown command: ", s, "\n");
	}
}

void(void) udp_punch_hole_init {
	if not(cvar("sv_udppunchhole"))
		return;

	udp_punch_hole_extresponse_handler_extra = udp_punch_hole_extresponse_handler_extra_sv;
	CVAR_CACHE_STR(sv_udppunchhole_server);
	CVAR_CACHE_STR(sv_udppunchhole_key);
	CVAR_CACHE(sv_udppunchhole_verbose);
	udp_punch_hole_extresponse_handler_register();
	udp_punch_hole_port_test = spawn();
	udp_punch_hole_port_test.think = udp_punch_hole_port_test_think;
	udp_punch_hole_port_test.nextthink = time;
	udp_punch_hole_port_test.cnt = 3;
}
