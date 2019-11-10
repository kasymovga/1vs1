void(void) spawnfunc_light {
	remove(self);
}

void(void) spawnfunc_light_torch_small_walltorch {
	precache_model("models/turrets/tesla_head.md3");
	setmodel(self, "models/turrets/tesla_head.md3");
}

void(void) spawnfunc_light_flame_large_yellow {
	setmodel(self, "null");
	self.effects |= EF_FLAME;
}
