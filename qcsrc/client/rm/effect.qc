void(void) rm_effect_heal_read {
	vector o;
	o_x = net_read_coord();
	o_y = net_read_coord();
	o_z = net_read_coord();
	pointparticles(particleeffectnum("RM_HEAL"), o, '0 0 0', 1);
}

void(void) rm_effect_heal_emitter_draw {
	if (time < self.cnt) return;
	self.cnt = time + 0.15 + random() * 0.15;
	pointparticles(particleeffectnum("RM_HEAL"), self.origin + randomvec() * 50, '0 0 0', 1);
}

void(float ignore) rm_effect_heal_emitter_read {
	self.origin_x = net_read_int24();
	self.origin_y= net_read_int24();
	self.origin_z= net_read_int24();
	self.draw = rm_effect_heal_emitter_draw;
}
