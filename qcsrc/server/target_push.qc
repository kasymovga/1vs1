float g_target_push_speed_factor;
void(void) target_push_use {
	entity oo = other;
	other = activator;
	trigger_push_touch();
	other = oo;
}

float target_push_init_done;
void(void) spawnfunc_target_push {
	if not(target_push_init_done) {
		target_push_init_done = 1;
		CVAR_CACHE(g_target_push_speed_factor);
	}
	self.spawnflags = 0;
	if (self.speed)
		entity_movedir_setup();

	self.use = target_push_use;
	if (!self.speed)
		self.speed = 1000;

	self.movedir = self.movedir * self.speed * g_target_push_speed_factor;
	precache_sound (self.noise);
	entity_initialize(self, trigger_push_findtarget, INITPRIO_FINDTARGET);
}
