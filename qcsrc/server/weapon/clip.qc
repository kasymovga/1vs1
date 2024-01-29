float(.float ammofield, .float clipfield, float ammo1, float ammo2) weapon_clip_checkmaxbullets {
	float maxbulls;
	if (self.items & IT_UNLIMITED_WEAPON_AMMO)
		maxbulls = self.ammoclipmax;
	else
		maxbulls = min(self.ammoclipmax, floor(self.ammofield / min(ammo1, ammo2)));

	if(self.clipfield > maxbulls)
		self.clipfield = maxbulls;

	return (self.clipfield == maxbulls);
}

void(.float ammofield, .float clipfield, float ammo1, float ammo2, float reloadtime) weapon_clip_reloadandready {
	float t;
	self.clipfield = self.ammoclipmax;
	weapon_clip_checkmaxbullets(ammofield, clipfield, ammo1, ammo2);
	t = WEAPON_ATTACK_FINISHED(self) - reloadtime - 1;
	WEAPON_ATTACK_FINISHED(self) = t;
	weapon_ready();
}

void(.float ammofield, .float clipfield, float ammo1, float ammo2, string reloadsound, float reloadtime, void(void) reloadandready) weapon_clip_reload {
	float t;
	weapon_clip_checkmaxbullets(ammofield, clipfield, ammo1, ammo2);
	if (self.clipfield >= self.ammoclipmax)
		return;

	if not(self.items & IT_UNLIMITED_WEAPON_AMMO)
	if (self.ammofield < min(ammo1, ammo2)) {
		self.clipfield = -1; // reload later
		if (akimbo_active(self) < 2)
			weapon_switch_force(self, weapon_best(self));

		return;
	}
	if (self.weaponentity) {
		if (self.weaponentity.wframe == WEAPON_FRAME_RELOAD)
			return;

		// allow to switch away while reloading, but this will cause a new reload!
		self.weaponentity.state = WEAPON_STATE_READY;
	}
	sound (self, CHAN_WEAPON2, reloadsound, VOL_BASE, ATTN_NORM);
	t = max(time, WEAPON_ATTACK_FINISHED(self)) + reloadtime + 1;
	WEAPON_ATTACK_FINISHED(self) = t;
	weapon_thinkf(WEAPON_FRAME_RELOAD, reloadtime, reloadandready);
	self.clipfield = -1;
}

void(float capacity , .float ammofield, .float clipfield, float ammo1, float ammo2) weapon_clip_setup {
	if (capacity) {
		self.ammoclipmax = capacity;
		weapon_clip_checkmaxbullets(ammofield, clipfield, ammo1, ammo2);
		if not(self.clipfield)
			self.clipfield = -1;
	}
}
