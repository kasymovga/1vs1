void(void) rm_effect_heal_read {
	vector o;
	o_x = net_read_coord();
	o_y = net_read_coord();
	o_z = net_read_coord();
	pointparticles(particleeffectnum("RM_HEAL"), o, '0 0 0', 1);
}
