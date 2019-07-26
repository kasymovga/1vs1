void(void) udppunchhole_ping_think {
	if (self.cnt <= 0) {
		strunzone(self.message);
		remove(self);
		return;
	}
	extresponse_query(self.message, "extResponse udppunchhole ping");
	self.nextthink = time + 0.25;
	self.cnt = self.cnt - 1;
}

void(float argc, string response) udppunchhole_extresponse_handler {
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
			e.think = udppunchhole_ping_think;
			e.nextthink = time;
		}
	} else if (s == "pong") {
		//ignore
	} else if (udppunchhole_extresponse_handler_extra) {
		udppunchhole_extresponse_handler_extra(argc, response);
	} else {
		print("udppunchhole: unknown command: ", s, "\n");
	}
}

void(void) udppunchhole_extresponse_handler_register {
	extresponse_register_handler("udppunchhole", udppunchhole_extresponse_handler, world);
}
