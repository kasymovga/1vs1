entity jetpack_physics;

float(void) jetpack_using {
	float it = getstati(STAT_ITEMS);
	if not(it & IT_JETPACK)
		return 0;

	if not(it & IT_FUEL)
		return 0;

	return 1;
}

void(float fuel_fact) jetpack_finished {
}

float(float fvel) jetpack_velocity_mod {
	return 1;
}

void(float dummy) jetpack_read {
	jetpack_physics = self;
	g_jetpack_acceleration_side = net_read_coord();
	g_jetpack_acceleration_up = net_read_coord();
	g_jetpack_antigravity = net_read_coord();
	g_jetpack_maxspeed_side = net_read_coord();
	g_jetpack_maxspeed_up = net_read_coord();
	physics_jetpack_enable();
}
