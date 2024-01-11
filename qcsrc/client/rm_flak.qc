void(vector realorg, vector org, vector dir, float spread, float a, float animphase) rm_flak_charge_indicator_draw_line {
	vector angle = vectoangles(dir);
	vector a2;
	a2_x = 0;
	a2_y = spread;
	a2_z = 0;
	angle_x = -angle_x;
	makevectors(angle + a2);
	dir = v_forward;
	trace_line(org, org + dir * 10000, TRACE_MOVE_NOMONSTERS, world);
	vector dst = trace_endpos;
	draw_cylindric_line(org, dst, 5, "particles/guideline", 0.05, animphase, '1 1 0.35', a, DRAWFLAG_ADDITIVE, view_origin);
}

float rm_flak_charge_anim_phase;

void(void) rm_flak_charge_indicator_draw {
	vector org = view_origin;
	vector dir = view_forward;
	self.origin_z += self.cnt * frametime;
	rm_flak_charge_anim_phase += frametime;
	if (rm_flak_charge_anim_phase > 1)
		rm_flak_charge_anim_phase -= 1;

	float spread = bound(0, self.origin_z, 1);
	float spread2 = self.origin_x * (1 - spread) + self.origin_y * self.origin_x * spread;
	spread = asin(spread2) * MATH_RAD2DEG;
	org += view_forward * self.iorigin1_x - view_right * self.iorigin1_y + view_up * (self.iorigin1_z/* + 6*/);
	rm_flak_charge_indicator_draw_line(view_origin, org, dir, spread, 1, rm_flak_charge_anim_phase);
	rm_flak_charge_indicator_draw_line(view_origin, org, dir, -spread, 1, rm_flak_charge_anim_phase);
}

void(float ignore) rm_flak_charge_indicator_read {
	float sf = net_read_byte();
	if (sf & 1) {
		self.origin_x = net_read_coord(); //spread
		self.origin_y = net_read_coord(); //spread mod
		self.cnt = net_read_coord(); //charge speed
	}
	if (sf & 2) {
		//charge
		self.origin_z = net_read_coord();
		//shotorg
		self.iorigin1_x = net_read_coord();
		self.iorigin1_y = net_read_coord();
		self.iorigin1_z = net_read_coord();
	}
	self.draw = rm_flak_charge_indicator_draw;
}
