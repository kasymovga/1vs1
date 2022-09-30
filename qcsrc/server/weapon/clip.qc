float(float capacity, .float ammofield, .float clipfield, float ammo1, float ammo2) weapon_clip_checkmaxbullets {
	float maxbulls;
	if (self.items & IT_UNLIMITED_WEAPON_AMMO)
		maxbulls = capacity;
	else
		maxbulls = min(capacity, floor(self.ammofield / min(ammo1, ammo2)));

	if(self.clipfield > maxbulls)
		self.clipfield = maxbulls;

	return (self.clipfield == maxbulls);
}

void(float capacity, .float ammofield, .float clipfield, float ammo1, float ammo2, float reloadtime) weapon_clip_reloadandready {
	float t;
	self.clipfield = capacity;
	weapon_clip_checkmaxbullets(capacity, ammofield, clipfield, ammo1, ammo2);
	t = ATTACK_FINISHED(self) - reloadtime - 1;
	ATTACK_FINISHED(self) = t;
	weapon_ready();
}

void (float capacity, .float ammofield, .float clipfield, float ammo1, float ammo2, string reloadsound, float reloadtime, void(void) reloadandready) weapon_clip_reload {
	float t;
	weapon_clip_checkmaxbullets(capacity, ammofield, clipfield, ammo1, ammo2);
	if (self.clipfield >= capacity)
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
	t = max(time, ATTACK_FINISHED(self)) + reloadtime + 1;
	ATTACK_FINISHED(self) = t;
	weapon_thinkf(WEAPON_FRAME_RELOAD, reloadtime, reloadandready);
	self.clipfield = -1;
}
