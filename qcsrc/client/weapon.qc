void(void) weapon_cross_origin_set {
	if (CVAR(chase_active) || physics_plug_adjust_view) {
		traceline(view_origin, view_origin + WORLD_MAX_SHOT_DISTANCE * view_forward, TRACE_MOVE_WORLDONLY, world);
		weapon_cross_origin = view_project_3d_to_2d(trace_endpos);
	} else {
		weapon_cross_origin = view_project_3d_to_2d(view_origin + WORLD_MAX_SHOT_DISTANCE * view_forward);
	}
	weapon_cross_origin_z = 0;
}

void(void) weapon_info_read {
	float wid, imp, at;
	string n;
	entity e;
	while ((wid = net_read_byte())) {
		imp = net_read_byte();
		at = net_read_coord();
		n = str_zone_ifneeded(net_read_string());
		weapon_impulses[wid - 1] = imp;
		weapon_register_real(wid, at, imp, n, n, n);
	}
}
