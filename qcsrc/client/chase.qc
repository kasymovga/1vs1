float chase_locks;
float chase_active_save;

vector(float back, float up) chase_adjust_view {
	makevectors(view_fixangle ? view_fixed_angles : view_angles);
	vector v = view_origin;
	tracebox(v, '-8 -8 -8', '8 8 8', v - v_forward * back, TRACE_MOVE_WORLDONLY, world);
	v = trace_endpos;
	tracebox(v, '-8 -8 -8', '8 8 8', v  + v_up * up, TRACE_MOVE_WORLDONLY, world);
	return trace_endpos;
}

void(void) chase_lock {
	if not(chase_locks) {
		chase_active_save = cvar("chase_active");
		cvar_set("chase_active", "1");
		CVAR(chase_active) = 1;
	}
	chase_locks++;
}

void(void) chase_unlock {
	if (chase_locks <= 0) return;
	chase_locks--;
	if (chase_locks <= 0) {
		cvar_set("chase_active", ftos(chase_active_save));
		CVAR(chase_active) = chase_active_save;
	}
}

void(void) chase_unlock_all {
	if (chase_locks > 0) {
		chase_locks = 0;
		cvar_set("chase_active", ftos(chase_active_save));
		CVAR(chase_active) = chase_active_save;
	}
}
