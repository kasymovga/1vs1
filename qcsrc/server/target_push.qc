void(void) target_push_use {
	entity oo = other;
	other = activator;
	trigger_push_touch();
	other = oo;
}

void(void) spawnfunc_target_push {
	self.spawnflags = 0;
	if (self.speed)
		entity_movedir_setup();

	self.use = target_push_use;
	if (!self.speed)
		self.speed = 1000;

	self.movedir = self.movedir * self.speed * 10;
	precache_sound (self.noise);
	entity_initialize(self, trigger_push_findtarget, INITPRIO_FINDTARGET);
}
