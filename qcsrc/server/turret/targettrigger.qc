void(void) turret_targettrigger_touch {
	entity e;
	if (self.cnt > time) return;
	entity oldself;
	oldself = self;
	e = find(world, targetname, self.target);
	while (e) {
		if (e.turrcaps_flags & TFL_TURRCAPS_RECIVETARGETS) {
			self = e;
			if(e.turret_addtarget)
				e.turret_addtarget(other,oldself);
		}
		e = find(e, targetname, oldself.target);
	}
	oldself.cnt = time + 0.5;
	self = oldself;
}

/*QUAKED turret_targettrigger (.5 .5 .5) ?
*/
void(void) spawnfunc_turret_targettrigger {
	if (!cvar("g_turrets")) {
		remove(self);
		return;
	}
	trigger_solid_brush_init();
	self.touch = turret_targettrigger_touch;
}
