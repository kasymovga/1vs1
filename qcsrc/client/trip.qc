entity trip;

void() trip_shutdown {
	cvar_set("r_trippy", "0");
	cvar_set("v_idlescale", "0");
}

void() trip_think {
	if (self.cnt < 0) {
		trip_shutdown();
		remove(trip);
		trip = world;
		return;
	}
	self.nextthink = time;
	if (self.cnt > 0) {
		cvar_set("r_trippy", "1");
		cvar_set("v_idlescale", ftos(min(100, self.cnt * 50)));
	} else {
		cvar_set("r_trippy", "0");
		cvar_set("v_idlescale", "0");
	}
	self.cnt = self.cnt - frametime;
}

void() trip_net_read {
	float t = ReadByte();
	if not(trip) {
		trip = spawn();
		trip.think = trip_think;
		trip.nextthink = time;
	}
	trip.cnt = trip.cnt + t;
}
