var void(entity e) trigger_impulse_predict_next;
void(entity e) trigger_impulse_predict;

float trigger_impulse_prediction_init_done;
void(float isnew) trigger_impulse_prediction_read {
	if not(trigger_impulse_prediction_init_done)
	if not(main_isdemo) {
		trigger_impulse_predict_next = physics_plug_frame_end;
		physics_plug_frame_end = trigger_impulse_predict;
		trigger_impulse_prediction_init_done = 1;
	}
	self.classname = "trigger_impulse_prediction";
	self.modelindex = net_read_coord();
	self.origin_x = net_read_coord();
	self.origin_y = net_read_coord();
	self.origin_z = net_read_coord();
	self.mins_x = net_read_coord();
	self.mins_y = net_read_coord();
	self.mins_z = net_read_coord();
	self.maxs_x = net_read_coord();
	self.maxs_y = net_read_coord();
	self.maxs_z = net_read_coord();
	setsize(self, self.mins, self.maxs);
	setorigin(self, self.origin);
	self.cnt = net_read_byte();
	if (self.cnt == 1) { //directional
		self.iorigin1_x = net_read_coord();
		self.iorigin1_y = net_read_coord();
		self.iorigin1_z = net_read_coord();
	} else if (self.cnt == 2) { //acceleration/deceleration
	} else { //sphere
		self.iorigin1_x = net_read_coord(); //radius
		self.iorigin1_y = net_read_coord(); //falloff
	}
	self.iorigin2_x = net_read_coord(); //strength
}

void(entity e) trigger_impulse_predict {
	float ss, vel;
	if (e.classname != "trigger_impulse_prediction") {
		if (trigger_impulse_predict_next)
			trigger_impulse_predict_next(e);

		return;
	}
	e.solid = SOLID_BSP;
	ss = self.solid;
	self.solid = SOLID_NOT;
	trace_box(self.origin, self.mins, self.maxs, self.origin, TRACE_MOVE_NORMAL, NULL);
	self.solid = ss;
	e.solid = SOLID_NOT;
	if not(trace_ent == e) return;
	//Must be synced with similar code in server physics code
	if (e.cnt == 1) { //directional
		self.velocity = physics_velocity = physics_velocity + normalize(e.iorigin1 - e.origin) * e.iorigin2_x * frametime;
	} else if (e.cnt == 2) {
		self.velocity = physics_velocity = physics_velocity * pow(e.iorigin2_x, frametime);
	} else {
		vector o = self.origin + (self.mins + self.maxs) * .5;
		//setsize(e, '-1 -1 -1' * e.radius,'1 1 1' * e.radius);
		float str = min(e.iorigin1_x, vlen(e.origin - o));
		if (e.iorigin1_y == 1)
			str = (1 - str / e.iorigin1_x) * e.iorigin2_x; // 1 in the inside
		else if (e.iorigin1_y == 2)
			str = (str / e.iorigin1_x) * e.iorigin2_x; // 0 in the inside
		else
			str = e.iorigin2_x;

		self.velocity = physics_velocity = physics_velocity + normalize(o - e.origin) * str * frametime;
	}
}
