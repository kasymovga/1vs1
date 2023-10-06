void(void) func_weight_button_wait;

void(void) func_weight_button_reset {
	setorigin(self, self.pos1);
	self.nextthink = 0;
	self.think = NULL;
	self.state = FALSE;
}

void(void) func_weight_button_unpressed {
	self.state = FALSE;
	entity oldactivator = activator;
	activator = self.pusher;
	trigger_use_targets();
	activator = oldactivator;
	func_calc_move(self.pos1, self.speed, NULL);
}

void(void) func_weight_button_wait {
	float r = vlen((self.absmax - self.absmin) / 2);
	entity e;
	float stillpressed = FALSE;
	if ((self.pusher.flags & FL_ONGROUND_OR_SLICK) && self.pusher.groundentity == self) {
		stillpressed = TRUE;
	}
	if (!stillpressed && self.pusher.movetype == MOVETYPE_QCWALK && self.pusher.velocity_z <= 0) {
		trace_box(self.pusher.origin, self.pusher.mins, self.pusher.maxs, self.pusher.origin - self.speed * sys_ticrate * '0 0 2', TRACE_MOVE_NORMAL, self.pusher);
		if (trace_ent == self)
			stillpressed = TRUE;
		else if (trace_startsolid &&
				math_boxes_overlap(self.origin + self.mins, self.origin + self.maxs,
				self.pusher.origin + self.pusher.mins, self.pusher.origin + self.pusher.maxs))
			stillpressed = TRUE;
	}
	if not(stillpressed) {
		for (e = findradius(ENTITY_CENTER(self), r); e; e = e.chain) {
			if (e.movetype == MOVETYPE_TOSS || e.movetype == MOVETYPE_QCWALK || e.movetype == MOVETYPE_WALK)
			if ((e.flags & FL_ONGROUND_OR_SLICK) && e.groundentity == self) {
				self.pusher = e;
				stillpressed = TRUE;
				break;
			}
		}
	}
	if (!stillpressed) {
		self.think = func_weight_button_unpressed;
		self.pusher = NULL;
	}
	self.nextthink = self.ltime + sys_ticrate;
}

void(void) func_weight_button_pressed {
	entity oldactivator = activator;
	activator = self.pusher;
	trigger_use_targets();
	activator = oldactivator;
	self.state = TRUE;
	self.think = func_weight_button_wait;
	self.nextthink = self.ltime + sys_ticrate;
}

void(void) func_weight_button_touch {
	if (self.state) return;
	if (other.velocity_z > 0) return;
	//if (other.groundentity != self) return;
	//if not(other.flags & FL_ONGROUND_OR_SLICK) return;
	if not(other.movetype == MOVETYPE_TOSS || other.movetype == MOVETYPE_QCWALK || other.movetype == MOVETYPE_WALK) return;
	self.pusher = other;
	func_calc_move(self.pos2, self.speed, func_weight_button_pressed);
}

void(void) spawnfunc_func_weight_button {
	entity_movedir_setup();
	if not(func_moving_brush_init())
		return;

	self.touch = func_weight_button_touch;
	self.reset = func_weight_button_reset;
	if (!self.speed) self.speed = 100;
	if (!self.lip) self.lip = 2;
	func_pos_setup();
}
