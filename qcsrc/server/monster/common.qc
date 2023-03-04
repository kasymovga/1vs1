void(void) monster_common_on_remove {
	remove(self.exteriorweaponentity);
	if (self.weaponentity) {
		remove(self.weaponentity.weaponentity);
		remove(self.weaponentity);
	}
}

void(void) monster_common_composite_dlc_reset {
	setattachment(self.weaponentity, self, "tag_torso");
	setattachment(self.weaponentity.weaponentity, self.weaponentity, "tag_head");
	if (self.exteriorweaponentity)
		setattachment(self.exteriorweaponentity, self.weaponentity, "tag_weapon");
}

void(string monstermodel, string wepmodel) monster_common_composite_setup {
	setmodel(self, strcat("models/monsters/", monstermodel, "/lower.md3"));
	self.scale = 1.25;
	self.weaponentity = spawn();
	setmodel(self.weaponentity, strcat("models/monsters/", monstermodel, "/upper.md3"));
	self.weaponentity.weaponentity = spawn();
	setmodel(self.weaponentity.weaponentity, strcat("models/monsters/", monstermodel, "/head.md3"));
	self.movetype = MOVETYPE_WALK;
	if (wepmodel != "") {
		self.exteriorweaponentity = spawn();
		self.exteriorweaponentity.scale = 0.8;
		self.exteriorweaponentity.colormap = 1024;
		setmodel(self.exteriorweaponentity, strcat("models/weapons/v_", wepmodel, ".md3"));
	}
	self.takedamage = DAMAGE_AIM;
	self.solid = SOLID_BBOX;
	self.dlc_reset = monster_common_composite_dlc_reset;
	self.dlc_reset();
	if (self.colormod == '0 0 0')
		self.colormod = '2 2 2';
	else
		self.colormod *= 2;

	self.weaponentity.weaponentity.colormod = self.weaponentity.colormod = self.colormod;
	self.entremove = monster_common_on_remove;
}

void(vector loweranim, vector upperanim, vector fallbackanim) monster_common_composite_anim {
	if (self.weaponentity) {
		anim_set(self, loweranim, TRUE, TRUE, FALSE);
		anim_set(self.weaponentity, upperanim, TRUE, TRUE, FALSE);
		anim_update(self.weaponentity);
		anim_update(self);
	} else
		anim_set(self, '13 1 1', TRUE, TRUE, FALSE);
}

void(string monstermodel, string wepmodel) monster_common_composite_precache {
	precache_model(strcat("models/monsters/", monstermodel, "/lower.md3"));
	precache_model(strcat("models/monsters/", monstermodel, "/upper.md3"));
	precache_model(strcat("models/monsters/", monstermodel, "/head.md3"));
	precache_model(strcat("models/weapons/v_", wepmodel, ".md3"));
}

void(vector _mins, vector _maxs, vector originadjust) monster_common_setup_spawn_size {
	if (originadjust != '0 0 0')
		setorigin(self, self.origin + originadjust);

	setsize(self, '-16 -16 -24' - originadjust, '16 16 45' - originadjust);
}
