float trigger_push_prediction_init_done;
float trigger_push_use_trigger_origin;
var void(entity e) trigger_push_predict_next;

void(entity e) trigger_push_predict;

void(float isnew) trigger_push_prediction_read {
	if not(trigger_push_prediction_init_done) {
		trigger_push_predict_next = physics_plug_frame_end;
		physics_plug_frame_end = trigger_push_predict;
		trigger_push_prediction_init_done = 1;
	}
	self.classname = "trigger_push_prediction";
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
	self.movedir_x = net_read_coord();
	self.movedir_y = net_read_coord();
	self.movedir_z = net_read_coord();
	self.cnt = net_read_coord();
	self.state = net_read_byte();
	if (self.state) {
		self.iorigin1_x = net_read_coord(); //spawnflags
		self.iorigin1_y = net_read_coord(); //count
		self.iorigin1_z = net_read_coord(); //speed
	}
	trigger_push_use_trigger_origin = net_read_coord();
}

void(entity e) trigger_push_predict {
	float ss, vel;
	if (e.classname != "trigger_push_prediction") {
		if (trigger_push_predict_next)
			trigger_push_predict_next(e);

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
	if (e.state) {
		physics_velocity = trigger_push_velocity_calculate_velocity(physics_velocity,
				(trigger_push_use_trigger_origin ? (e.origin + (e.mins + e.maxs) * 0.5) : self.origin), e.movedir, e.cnt,
				e.iorigin1_z/*speed*/, e.iorigin1_x/*spawnflags*/, e.iorigin1_y/*count*/);
	} else
		physics_velocity = trigger_push_calculate_velocity((trigger_push_use_trigger_origin ? (e.origin + (e.mins + e.maxs) * 0.5) : self.origin), e.movedir, e.cnt);
}
