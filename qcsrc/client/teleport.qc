float teleport_predicted_last;
float teleport_predicted_last_time;
float teleport_prediction_init_done;
float g_teleport_keep_velocity;
float g_teleport_keep_velocity_crouch;
float g_teleport_time;
var void(entity e) teleport_predict_next;

void(entity e) teleport_predict;

void(float isnew) teleport_prediction_read {
	if not(teleport_prediction_init_done)
	if not(main_isdemo) {
		teleport_predict_next = physics_plug_frame_end;
		physics_plug_frame_end = teleport_predict;
		teleport_prediction_init_done = 1;
	}
	self.sv_entnum = net_read_coord();
	self.classname = "teleport_prediction";
	self.modelindex = net_read_coord();
	vector v, v2;
	//trigger origin
	self.origin_x = net_read_coord();
	self.origin_y = net_read_coord();
	self.origin_z = net_read_coord();
	//mins
	v_x = net_read_coord();
	v_y = net_read_coord();
	v_z = net_read_coord();
	//maxs
	v2_x = net_read_coord();
	v2_y = net_read_coord();
	v2_z = net_read_coord();
	setsize(self, v, v2);
	self.cnt = net_read_coord();
	//target origin
	v_x = net_read_coord();
	v_y = net_read_coord();
	v_z = net_read_coord();
	self.movedir = v;
	v_x = net_read_coord();
	v_y = net_read_coord();
	v_z = 0;
	self.iorigin1 = v;
	setorigin(self, self.origin);
	g_teleport_keep_velocity = net_read_coord();
	g_teleport_keep_velocity_crouch = net_read_coord();
	g_teleport_time = net_read_coord();
}

void(void) teleport_teleported_draw2d {
	if (time > self.cnt) {
		remove(self);
		return;
	}
	view_fixangle = 1;
	view_fixed_angles = self.origin;
	makevectors(view_fixed_angles);
	view_forward = v_forward; //hack for crosshair position
}

void(vector a) teleport_fix_angles {
	entity e = spawn();
	e.origin = a;
	e.draw2dflag = 1;
	e.draw2d = teleport_teleported_draw2d;
	e.cnt = time + server_deltatime * 1.125;
	view_fixangle = 1;
	view_fixed_angles = a;
}

void(void) teleport_teleportation_read {
	vector a;
	float teleport = net_read_coord();
	a_x = net_read_coord();
	a_y = net_read_coord();
	a_z = 0;
	if (teleport == teleport_predicted_last && teleport_predicted_last_time > time - 0.5) {
		return;
	}
	view_angles = a;
	R_SetView(VF_CL_VIEWANGLES, a);
	if (main_isdemo || (view_spectatee_status && !view_observer_status)) {
		teleport_fix_angles(a);
	}
}

void(entity e) teleport_predict {
	float ss, vel;
	if (e.classname != "teleport_prediction") {
		if (teleport_predict_next)
			teleport_predict_next(e);

		return;
	}
	e.solid = SOLID_BSP;
	ss = self.solid;
	self.solid = SOLID_NOT;
	trace_box(self.origin, self.mins, self.maxs, self.origin, TRACE_MOVE_NORMAL, NULL);
	self.solid = ss;
	e.solid = SOLID_NOT;
	if not(trace_ent == e) return;
	physics_was_teleported = TRUE;
	//Must be synced with similar code in server physics code
	vel = vlen(physics_velocity);
	if (e.cnt >= 0)
		vel = min(vel, e.cnt);

	float keep_velocity = (physics_crouch ? g_teleport_keep_velocity_crouch : g_teleport_keep_velocity);
	if (e.cnt == -2)
		vel = min(vel, vlen(physics_velocity_x * '1 0 0' + physics_velocity_y * '0 1 0'));
	else if (keep_velocity > 0)
		vel = min(vel, keep_velocity);
	else if (keep_velocity == 0)
		vel = 0;

	makevectors(e.iorigin1);
	self.velocity = physics_velocity = vel * v_forward;
	//Must be synced with similar code in server physics code
	if (g_teleport_time) {
		if (g_nofriction_cpm_hacks)
			physics_nofriction = g_teleport_time;
		else
			physics_teleport_time = g_teleport_time;
	}
	setorigin(self, e.movedir);
	if (teleport_predicted_last == e.cnt && teleport_predicted_last_time > time - 0.5) {
		teleport_predicted_last_time = time; //yes, it must be this way
		return;
	}
	teleport_predicted_last_time = time; //yes, it must be this way
	teleport_predicted_last = e.sv_entnum;
	view_angles = e.iorigin1;
	R_SetView(VF_CL_VIEWANGLES, e.iorigin1);
	if (main_isdemo || (view_spectatee_status && !view_observer_status)) {
		teleport_fix_angles(e.iorigin1);
	}
}
