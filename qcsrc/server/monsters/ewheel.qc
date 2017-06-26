void ewheel_walk();

void ewheel_idle() {
	self.nextthink = time;
	if (monster_look_for_player(2500, 500, 0, 1, 3)) {
		return;
	}
	movelib_beak_simple(50 * frametime);
	setanim(self, '0 0 0', TRUE, TRUE, FALSE);
	updateanim(self);
}

void ewhell_proj_explode (void) {
	self.event_damage = SUB_Null;
	self.takedamage = DAMAGE_NO;
	RadiusDamage(self, self.owner, 25, 0, 25, world, 25, self.projectiledeathtype, other);
	remove (self);
}

void ewhell_proj_touch (void) {
	PROJECTILE_TOUCH;
	ewhell_proj_explode();
}

void ewheel_hunt() {
	self.nextthink = time;
	if (monster_check_target(ewheel_walk, ewheel_idle))
		return;

	vector v;
	float dofire;
	dofire = FALSE;
	if (self.attack_finished_single < time) {
		traceline(self.origin, self.enemy.origin, MOVE_WORLDONLY, self);
		if (trace_fraction == 1)
			dofire = TRUE;
	}
	if (dofire) {
		makevectors(self.angles);
		if (v_forward * normalize(self.enemy.origin - self.origin) > 0.75) {
			vector _shotdir = normalize(self.enemy.origin - self.origin);
			_shotdir_x = v_forward_x;
			_shotdir_y = v_forward_y;
			vector _shotorg = self.origin + v_forward * 16;
			sound(self, CHAN_WEAPON, "weapons/lasergun_fire.wav", VOL_BASE, ATTN_NORM);
			float i;
			for (i = -1; i < 2; i += 2) {
				entity proj = spawn();
				proj.owner = self;
				proj.classname = "ewheel bolt";
				proj.movetype = MOVETYPE_FLYMISSILE;
				proj.gravity = 0.01;
				PROJECTILE_MAKETRIGGER(proj);
				proj.projectiledeathtype = WEP_LASER;
				setorigin(proj, _shotorg + v_right * i * 16);
				setsize(proj, '0 0 0', '0 0 0');
				proj.nextthink = time + 5;
				proj.think = adaptor_think2use;
				proj.use = ewhell_proj_explode;
				proj.touch = ewhell_proj_touch;
				proj.velocity = normalize(_shotdir) * 3200;
				W_SetupProjectileVelocity(proj);
				proj.angles = vectoangles (proj.velocity);
				proj.flags = FL_PROJECTILE;
				CSQCProjectile(proj, TRUE, PROJECTILE_LASER, TRUE);
				self.attack_finished_single = time + 2 + random();
			}
		}
	}
	v = monster_move_walk(500, 1, 0);
	v = vectoangles(v);
	self.angles_y = approach_angle(self.angles_y, v_y, 360 * frametime);
	self.frame = 2;
}

void ewheel_walk() {
	self.nextthink = time;
	if (monster_look_for_player(2500, 500, 0, 1, 3)) {
		return;
	}
	if (monster_walk_finished(ewheel_idle, 100))
		return;

	self.frame = 1;
	if (self.flags & FL_ONGROUND) {
		vector v = monster_move_walk(400, 1, 0);
		v = vectoangles(v);
		self.angles_y = approach_angle(self.angles_y, v_y, 90 * frametime);
	}
}

void ewheel_remove() {
	remove(self.weaponentity);
}

void ewheel_spawn() {
	monster_prepare(ewheel_hunt, ewheel_walk, ewheel_idle);
	setmodel(self, "models/turrets/ewheel-base2.md3");
	self.weaponentity = spawn();
	setmodel(self.weaponentity, "models/turrets/ewheel-gun1.md3");
    setattachment(self.weaponentity, self, "tag_head");
    setsize(self,'-32 -32 0','32 32 48');
	self.species = SPECIES_ROBOT_SOLID;
	self.solid = SOLID_BBOX;
	self.damageforcescale = 1;
	self.netname = "Magic Wheel";
	self.movetype = MOVETYPE_WALK;
	self.entremove = ewheel_remove;
	self.takedamage = DAMAGE_AIM;
	self.weaponentity.colormod = self.colormod;
}

void ewheel_init() {
    precache_model ("models/turrets/ewheel-base2.md3");
    precache_model ("models/turrets/ewheel-gun1.md3");
	precache_sound("weapons/uzi_fire.wav");
}

void spawnfunc_ewheel_spawn() {
	monster_init(ewheel_init);
	monster_prepare_spawn(ewheel_spawn, spawnfunc_ewheel_spawn);
}
