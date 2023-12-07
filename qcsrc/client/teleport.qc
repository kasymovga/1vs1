float teleport_predicted_last;
float teleport_predicted_last_time;
float teleport_prediction;
float g_teleport_keep_velocity;
float g_teleport_time;

void(float isnew) teleport_prediction_read {
	teleport_prediction = 1;
	self.cnt = net_read_coord();
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
	g_teleport_time = net_read_coord();
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
}

float(entity e) teleport_collision {

	return TRUE;
}

void(void) teleport_predict {
	float r = vlen(self.maxs - self.mins) / 2;
	vector o = self.origin + (self.maxs + self.mins) * 2;
	entity e = findradius(o, r);
	vector mins1, mins2, maxs1, maxs2;
	float ss, vel;
	for (; e; e = e.chain) {
		if (e.classname != "teleport_prediction") continue;
		mins1 = e.origin + e.mins;
		maxs1 = e.origin + e.maxs;
		mins2 = self.origin + self.mins;
		maxs2 = self.origin + self.maxs;
		if (
				mins1_x >= maxs1_x
				|| mins1_y >= maxs1_y
				|| mins1_z >= maxs1_z
				|| maxs1_x <= mins2_x
				|| maxs1_y <= mins2_y
				|| maxs1_z <= mins2_z
				)
			continue;

		e.solid = SOLID_BSP;
		ss = self.solid;
		self.solid = SOLID_NOT;
		trace_box(self.origin, self.mins, self.maxs, self.origin, TRACE_MOVE_NORMAL, NULL);
		self.solid = ss;
		e.solid = SOLID_NOT;
		if not(trace_ent == e) continue;
		physics_was_teleported = TRUE;
		vel = vlen(physics_velocity);
		if (g_teleport_keep_velocity > 0)
			vel = min(vel, g_teleport_keep_velocity);
		else if (g_teleport_keep_velocity == 0)
			vel = 0;

		makevectors(e.iorigin1);
		physics_velocity = vlen(physics_velocity) * v_forward;
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
			continue;
		}
		teleport_predicted_last_time = time; //yes, it must be this way
		teleport_predicted_last = e.cnt;
		view_angles = e.iorigin1;
		R_SetView(VF_CL_VIEWANGLES, e.iorigin1);
	}
}
