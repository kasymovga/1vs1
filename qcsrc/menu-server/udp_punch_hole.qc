void(void) udp_punch_hole_ping_think {
	if (self.cnt <= 0) {
		strunzone(self.message);
		remove(self);
		return;
	}
	extresponse_query(self.message, "extResponse udppunchhole ping");
	self.nextthink = time + 0.25;
	self.cnt = self.cnt - 1;
}

#define udp_punch_hole_extresponse_handler udppunchhole_extresponse_handler //compatibility with old save files
void(float argc, string response) udp_punch_hole_extresponse_handler {
	string s = argv(2);
	entity e;
	if (s == "ping") {
		extresponse_query(argv(0), "extResponse udppunchhole pong");
	} else if (s == "request") {
		string s2 = argv(3);
		if (s2 != "") {
			e = spawn();
			e.cnt = 3;
			e.message = strzone(s2);
			e.think = udp_punch_hole_ping_think;
			e.nextthink = time;
		}
	} else if (s == "pong") {
		//ignore
	} else if (udp_punch_hole_extresponse_handler_extra) {
		udp_punch_hole_extresponse_handler_extra(argc, response);
	} else {
		print("udppunchhole: unknown command: ", s, "\n");
	}
}

void(void) udp_punch_hole_extresponse_handler_register {
	extresponse_register_handler("udppunchhole", udp_punch_hole_extresponse_handler, NULL);
}
