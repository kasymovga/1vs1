void(void) weapon_cross_origin_set {
	if (CVAR(chase_active) || physics_plug_adjust_view) {
		traceline(view_origin, view_origin + MAX_SHOT_DISTANCE * view_forward, MOVE_WORLDONLY, world);
		weapon_cross_origin = view_project_3d_to_2d(trace_endpos);
	} else {
		weapon_cross_origin = view_project_3d_to_2d(view_origin + MAX_SHOT_DISTANCE * view_forward);
	}
	weapon_cross_origin_z = 0;
}

