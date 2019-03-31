entity trip;

void() trip_cvars_disable {
	cvar_set("r_trippy", "0");
	cvar_set("v_color_enable", "0");
	cvar_set("v_idlescale", "0");
}

void() trip_shutdown {
	trip_cvars_disable();
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
		cvar_set("v_color_enable", "1");
		cvar_set("r_trippy", "1");
		float f = min(1, self.cnt / 10);
		cvar_set("v_idlescale", ftos(min(60, f * 60)));
		float f4 = f * 0.25;
		cvar_set("v_color_black_r", ftos(0.25 + f4 * sin(time + 1)));
		cvar_set("v_color_black_g", ftos(0.25 + f4 * sin(time + 2)));
		cvar_set("v_color_black_b", ftos(0.25 + f4 * sin(time + 3)));
		cvar_set("v_color_grey_r", ftos(0.5 + f4 * sin(time * 2 + 4)));
		cvar_set("v_color_grey_g", ftos(0.5 + f4 * sin(time * 2 + 5)));
		cvar_set("v_color_grey_b", ftos(0.5 + f4 * sin(time * 2 + 6)));
		cvar_set("v_color_white_r", ftos(0.75 + f4 * sin(time * 3 + 7)));
		cvar_set("v_color_white_g", ftos(0.75 + f4 * sin(time * 3 + 8)));
		cvar_set("v_color_white_b", ftos(0.75 + f4 * sin(time * 3 + 9)));
	} else
		trip_cvars_disable();

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
