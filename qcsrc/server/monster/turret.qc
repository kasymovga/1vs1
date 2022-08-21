void() monster_turret_idle;
void() monster_turret_walk;

void() monster_turret_hunt {
	self.nextthink = time;
	if (monster_check_target(monster_turret_walk, monster_turret_idle))
		return;

	if (self.flags & FL_ONGROUND) {
		vector v = self.enemy.origin - self.origin;
		float d = vlen(v);
		if (d < 400) {
			v = monster_move_walk(-600 * self.scale, 5, 0);
			self.frame = 1;
			v = vectoangles(v);
			self.angles_y = approach_angle(self.angles_y, v_y, 90 * frametime);
		} else if (d > 500) {
			vector v = monster_move_walk(600 * self.scale, 5, 0);
			self.frame = 0;
			v = vectoangles(v);
			self.angles_y = approach_angle(self.angles_y, v_y, 90 * frametime);
		} else {
			movelib_beak_simple(1000 * frametime);
			v = vectoangles(v);
			d = self.angles_y - v_y;
			while (d >= 360) d -= 360;
			while (d <= -360) d += 360;
			if (d > 10)
				self.frame = 0;
			else if (d < -10)
				self.frame = 0;
			else
				self.frame = 5;

			self.angles_y = approach_angle(self.angles_y, v_y, 90 * frametime);
		}
	}
}

void() monster_turret_walk {
	self.nextthink = time;
	if (monster_look_for_player(1500, 1500, 0, 1, 3)) {
		return;
	}
	if (monster_walk_finished(monster_turret_idle, 100))
		return;

	self.frame = 0;
	if (self.flags & FL_ONGROUND) {
		vector v = monster_move_walk(600 * self.scale, 5, 0);
		v = vectoangles(v);
		self.angles_y = approach_angle(self.angles_y, v_y, 90 * frametime);
	}
}

void() monster_turret_idle {
	self.nextthink = time;
	if (monster_look_for_player(1500, 1500, 0, 1, 3)) {
		return;
	}
	movelib_beak_simple(100 * frametime);
	self.frame = 5;
}

void(void) monster_turret_remove {
	if (wasfreed(self.weaponentity) || self.weaponentity.tag_entity != self)
		return;

	setattachment(self.weaponentity, world, "");
	if (self.scale) {
		self.weaponentity.scale *= self.scale;
	}
	setorigin(self.weaponentity, self.origin + '0 0 50');
	self.weaponentity.movetype = MOVETYPE_TOSS;
	self.weaponentity.angles_y += self.angles_y;
	self.weaponentity.takedamage = DAMAGE_YES;
	if not(cvar("g_monster_turret_drop")) {
		damage(self.weaponentity, world, world, max(0, self.weaponentity.health), DEATH_HURTTRIGGER, ENTITY_CENTER(self.weaponentity), '0 0 0');
	}
}

void() monster_turret_spawn {
	monster_prepare(monster_turret_hunt, monster_turret_walk, monster_turret_idle);
	setmodel(self, "models/spiderbot/spiderbot.dpm");
	self.colormap = 1024;
	self.colormod = '0.75 1 0.75';
	self.species = SPECIES_ROBOT_SOLID;
	self.solid = SOLID_BBOX;
	self.damageforcescale = 0.1;
	self.netname = "Walking Turret";
	self.movetype = MOVETYPE_WALK;
	self.entremove = monster_turret_remove;
	self.takedamage = DAMAGE_AIM;
	self.frags = 3;
	self.view_ofs = '0 0 50';
	self.weaponentity = spawn();
	entity oldself = self;
	self = self.weaponentity;
	self.scale = 0.75;
	setorigin(self, oldself.origin);
	self.team = oldself.team;
	self.spawnflags = TSL_NO_RESPAWN;
	self.turret_scale_damage = (oldself.scale ? oldself.scale : 1) * self.scale * monster_difficulty;
	callfunction(strcat("spawnfunc_turret_", oldself.owner.weaponname));
	self.health = oldself.health * 0.25;
	self = oldself;
	setattachment(self.weaponentity, self, "tag_head");
	self.weaponentity.movetype = MOVETYPE_NONE;
	self.weaponentity.takedamage = FALSE;
	setorigin(self.weaponentity, self.weaponentity.mins_z * '0 0 -1' + '0 0 10');
}

void() monster_turret_compact_spawn {
	self.scale = 0.75;
	monster_turret_spawn();
	self.netname = "Compact Walking Turret";
}

void() monster_turret_init {
	precache_model("models/spiderbot/spiderbot.dpm");
}

void(void) monster_turret_init_clean {
	remove(self.tur_head);
	remove(self);
}

float(string turret_name) monster_turret_precache {
	entity oldself = self;
	self = spawn();
	setorigin(self, oldself.origin);
	string turret_func = strcat("spawnfunc_turret_", turret_name);
	if (isfunction(turret_func)) {
		callfunction(turret_func);
	} else {
		self = oldself;
		remove(self);
		return FALSE;
	}
	entity_initialize(self, monster_turret_init_clean, INITPRIO_LAST);
	self = oldself;
	return TRUE;
}

void() spawnfunc_monster_turret_spawn {
	if (self.weaponname == "")
		self.weaponname = "plasma";

	if (!monster_turret_precache(self.weaponname)) {
		remove(self);
		return;
	}
	setsize(self, '-60 -60 5', '60 60 100');
	monster_init(monster_turret_init);
	monster_prepare_spawn(monster_turret_spawn, spawnfunc_monster_turret_spawn);
}

void() spawnfunc_monster_turret_compact_spawn {
	if (self.weaponname == "")
		self.weaponname = "plasma";

	if (!monster_turret_precache(self.weaponname)) {
		remove(self);
		return;
	}
	setsize(self, '-45 -45 3.75', '45 45 75');
	monster_init(monster_turret_init);
	monster_prepare_spawn(monster_turret_compact_spawn, spawnfunc_monster_turret_compact_spawn);
}
