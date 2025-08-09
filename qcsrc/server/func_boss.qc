enum {
	FUNC_BOSS_STATE_ACTIVE = 1,
	FUNC_BOSS_STATE_TAKEDAMAGE = 2,
	FUNC_BOSS_STATE_DEAD = 4
};

void(entity e) func_boss_volume_explode {
	float c = ((e.maxs_x - e.mins_x) / 200 + 1) *
			((e.maxs_y - e.mins_y) / 200 + 1) *
			((e.maxs_z - e.mins_z) / 200 + 1);
	float i;
	makevectors(e.angles);
	vector v;
	for (i = 0; i < c; i++) {
		v = e.origin + v_forward * (e.mins_x + random() * (e.maxs_x - e.mins_x))
				- v_right * (e.mins_y + random() * (e.maxs_y - e.mins_y))
				+ v_up * (e.mins_z + random() * (e.maxs_z - e.mins_z));
		pointparticles(particleeffectnum("rocket_explode"), v, '0 0 0', 1);
	}
}

void(string t) func_boss_controller_switch_target {
	entity boss = self.enemy;
	self.aiment = NULL;
	while ((self.aiment = find(self.aiment, targetname, t))) {
		if (self.aiment.cnt == boss.cnt)
			break;
	}
	if (self.aiment) {
		entity_angles_normalize(boss, self.aiment.angles);
		self.speed = (self.aiment.speed ? self.aiment.speed : boss.speed);
	} else
		self.speed = boss.speed;
}

void(entity shooter, float _speed, float damage, float force, float radius, float projtype, float deathtype, float impact, float muzzleflash, float refire) func_boss_shooter_projectile_fire {
	vector torg = ENTITY_CENTER(shooter.enemy);
	float expected_time = vlen(torg - shooter.origin) / _speed;
	vector dir = normalize(torg - shooter.origin + shooter.enemy.velocity * expected_time + randomvec() * radius);
	entity proj = projectile(TRUE, projtype, FALSE, shooter);
	proj.realowner = proj;
	proj.netname = shooter.netname;
	proj.classname = "monster_projectile";
	projectile_setup(proj, shooter.origin, impact, deathtype, damage * monster_difficulty, 0, radius, force, 0, MOVETYPE_FLY);
	proj.nextthink = time + 10;
	proj.think = projectile_think2use;
	proj.use = projectile_explode;
	proj.touch = projectile_touch_explode;
	proj.velocity = dir * _speed;
	pointparticles(muzzleflash, shooter.origin, dir * 1000, 4);
	shooter.attack_finished_single = time + refire;
}

void(entity shooter) func_boss_shooter_think {
	entity pl;
	float traceok = FALSE;
	if (shooter.attack_finished_single > time || shooter.cnt != shooter.owner.cnt) {
		if (shooter.enemy) {
			shooter.angles = vectoangles(ENTITY_CENTER(shooter.enemy) - shooter.origin);
			shooter.angles_y += 180; //WTF?
			shooter.angles_x += 180; //WTF?
		} else
			shooter.angles = shooter.owner.angles;

		return;
	}
	if (shooter.enemy &&
			(shooter.enemy.health < 1 || shooter.enemy.solid == SOLID_NOT || !shooter.enemy.takedamage || shooter.enemy.deadflag != DEAD_NO)) {
		shooter.enemy = NULL;
	}
	entity ple;
	if not(shooter.enemy) {
		PLAYER_FOR_EACH(pl)
		if (pl.health >= 1)
		if (pl.takedamage)
		if not(pl.flags & FL_NOTARGET)
		if (pl.deadflag == DEAD_NO) {
			ple = player_entity(pl);
			trace_line(shooter.origin, ENTITY_CENTER(ple), TRACE_MOVE_NORMAL, shooter);
			if (trace_ent == ple) {
				traceok = TRUE;
				break;
			}
		}
		shooter.enemy = pl;
	}
	if (shooter.enemy) {
		ple = player_entity(shooter.enemy);
		vector plo = ENTITY_CENTER(ple);
		if not(traceok) {
			trace_line(shooter.origin, plo, TRACE_MOVE_NORMAL, shooter);
			traceok = (trace_ent == ple);
		}
		if (traceok) {
			shooter.angles = vectoangles(plo - shooter.origin);
			shooter.angles_y += 180; //WTF?
			shooter.angles_x += 180; //WTF?
			if (shooter.owner.dmg) {
				if (shooter.message == "plasma") {
					func_boss_shooter_projectile_fire(shooter, 3000, 60, 200, 200, PROJECTILE_ELECTRO_BEAM, WEAPON_ELECTRO, EFFECT_IMPACT_PLASMA, particleeffectnum("electro_muzzleflash"), 0.6);
				} else if (shooter.message == "laser") {
					func_boss_shooter_projectile_fire(shooter, 5000, 25, 100, 100, PROJECTILE_LASER, WEAPON_LASER, EFFECT_IMPACT_LASER, particleeffectnum("lazer_muzzleflash"), 0.2);
				} else {
					func_boss_shooter_projectile_fire(shooter, 2000, 100, 1000, 200, PROJECTILE_ROCKET, WEAPON_ROCKET_LAUNCHER, EFFECT_IMPACT_ROCKET, particleeffectnum("rocketlauncher_muzzleflash"), 1);
				}
			}
		} else {
			shooter.enemy = NULL;
			shooter.angles = shooter.owner.angles;
		}
	} else {
		shooter.angles = shooter.owner.angles;
	}
}

void(entity e) func_boss_part_colorize {
	if (e.health > 0 && e.cnt == e.owner.cnt && (e.owner.state & FUNC_BOSS_STATE_TAKEDAMAGE) && !(e.spawnflags & 1)) {
		e.takedamage = DAMAGE_YES;
		e.colormod = '1 1 1' + (sin(time * 3) + 1) * '.25 .25 0' + max(0, e.lastdamage - (time - 0.5)) * '1 0 0';
	} else {
		e.takedamage = DAMAGE_NO;
		e.colormod = '0 0 0';
	}
}

void(void) func_boss_controller_think {
	entity e;
	self.nextthink = time;
	entity boss = self.enemy;
	if (!boss.state || (boss.state & FUNC_BOSS_STATE_DEAD))
		return;

	if not(self.aiment) {
		func_boss_controller_switch_target(boss.target);
	}
	if not(self.aiment) {
		return;
	}
	if (boss.speed) {
		vector d = self.aiment.origin - boss.origin;
		vector step = normalize(d) * boss.speed * frametime;
		float dl = vlen(d);
		float stepl = vlen(step);
		if (stepl >= dl) {
			setorigin(boss, self.aiment.origin);
			boss.angles = self.aiment.angles;
			boss.dmg = self.aiment.dmg;
			if not(boss.state & FUNC_BOSS_STATE_TAKEDAMAGE) {
				boss.state |= FUNC_BOSS_STATE_TAKEDAMAGE;
				if (self.aiment.target != "") {
					e = marker_Spawn(boss.netname, 0, 0, boss, '0 0 1' * boss.maxs_z, NULL, 0, boss, sprite, FALSE);
					marker_text_update(e, '1 0.5 0', '1 0.5 0', '1 0.5 0');
					marker_UpdateTeamRadar(e, RADARICON_WAYPOINT, '1 0.5 0');
					boss.max_health = 1;
					for (e = find(NULL, target, boss.targetname); e; e = find(e, target, boss.targetname)) {
						if (e.classname != "func_boss_part") continue;
						if (e.cnt != boss.cnt) continue;
						if (e.health > 1) boss.max_health += (e.health - 1);
					}
					boss.health = boss.max_health;
					marker_UpdateMaxHealth(boss.sprite, boss.health);
					marker_UpdateHealth(boss.sprite, boss.health);
				}
			}
			if (self.aiment.target != "")
				func_boss_controller_switch_target(self.aiment.target);
			else {
				self.aiment = NULL;
				func_boss_volume_explode(boss);
				sound(boss, CHAN_WEAPON, boss.noise, VOL_BASE, ATTN_MIN);
				entity oldself = self;
				self = boss;
				debris_throw('0 0 0');
				self = oldself;
				boss.state |= FUNC_BOSS_STATE_DEAD;
				boss.effects |= EFFECT_NODRAW;
				boss.solid = SOLID_NOT;
				for (e = find(NULL, target, boss.targetname); e; e = find(e, target, boss.targetname)) {
					if (e.classname == "func_boss_part" && (e.spawnflags & 1)) {
						e.effects &= ~EFFECT_NODRAW;
					}
				}
			}
		} else {
			setorigin(boss, boss.origin + step);
			float f = stepl / dl;
			boss.angles = self.aiment.angles * f + boss.angles * (1 - f);
		}
	}
	for (e = find(NULL, target, boss.targetname); e; e = find(e, target, boss.targetname)) {
		if (e.classname != "func_boss_part" && e.classname != "func_boss_shooter") continue;
		makevectors(boss.angles);
		setorigin(e, boss.origin + v_forward * e.pos1_x - v_right * e.pos1_y + v_up * e.pos1_z);
		if (e.classname == "func_boss_part") {
			e.angles = boss.angles;
			func_boss_part_colorize(e);
		}
		if (e.classname == "func_boss_shooter") {
			func_boss_shooter_think(e);
		}
	}
}

void(entity boss, entity attacker) func_boss_check_parts {
	entity e;
	if (boss.targetname != "") {
		for (e = find(NULL, target, boss.targetname); e; e = find(e, target, boss.targetname)) {
			if (e.classname != "func_boss_part") continue;
			if (e.cnt != boss.cnt) continue;
			if (e.health > 0) return;
		}
	}
	for (e = find(NULL, target, boss.targetname); e; e = find(e, target, boss.targetname)) {
		if (e.classname == "func_boss_shooter" && e.cnt == boss.cnt) {
			e.effects |= EFFECT_NODRAW;
			e.solid = SOLID_NOT;
			continue;
		}
	}
	//boss switched to next phase
	boss.cnt++;
	boss.state &= ~FUNC_BOSS_STATE_TAKEDAMAGE;
	if (boss.sprite) {
		marker_FadeOutIn(boss.sprite, 1);
		boss.sprite = NULL;
	}
	boss.dmg = FALSE;
	entity oldself = self;
	self = boss.enemy;
	func_boss_controller_switch_target(boss.target);
	self = oldself;
	for (e = find(NULL, target, boss.targetname); e; e = find(e, target, boss.targetname)) {
		if (e.classname != "func_boss_part") continue;
		if (e.cnt != boss.cnt) continue;
		if (e.health > 0) return;
	}
	//boss defeated
	if (boss.target2) {
		for (e = find(NULL, targetname, boss.target2); e; e = find(e, targetname, boss.target2)) {
			if (e.use) {
				oldself = self;
				self = e;
				entity oldactivator = activator;
				activator = attacker;
				self.use();
				activator = oldactivator;
				self = oldself;
			}
		}
	}
};

void(void) func_boss_init_delayed {
	entity e;
	e = spawn();
	self.enemy = e;
	e.enemy = self;
	e.classname = "func_boss_controller";
	e.think = func_boss_controller_think;
	e.nextthink = time;
	for (e = find(NULL, target, self.targetname); e; e = find(e, target, self.targetname)) {
		if (e.classname != "func_boss_part" && e.classname != "func_boss_shooter") continue;
		e.owner = self;
		e.netname = self.netname;
		e.pos1 = e.origin - self.origin;
	}
}

void(void) func_boss_use {
	self.state = FUNC_BOSS_STATE_ACTIVE;
	entity e;
	for (e = find(NULL, target, self.targetname); e; e = find(e, target, self.targetname)) {
		if (e.classname != "func_boss_part") continue;
		if (e.health) e.health /= plugin_monster_quant();
		if (e.health) e.health *= monster_difficulty;
	}
}

void(void) func_boss_reset {
	self.origin = self.spawnorigin;
	self.angles = '0 0 0';
	self.effects &= ~EFFECT_NODRAW;
	setorigin(self, self.spawnorigin);
	if (self.sprite) {
		marker_Kill(self.sprite);
		self.sprite = NULL;
	}
	self.state = 0;
	self.enemy.aiment = NULL;
	self.cnt = 0;
}

void(void) spawnfunc_func_boss {
	model_init(SOLID_BSP);
	monster_common_init(); // for monster_difficulty
	if (self.targetname == "") {
		entity_abort("missed targetname property");
		return;
	}
	entity_initialize(self, func_boss_init_delayed, INITPRIO_FINDTARGET);
	self.use = func_boss_use;
	if (self.speed <= 0) self.speed = 1000;
	if (self.netname == "") self.netname = "Level Boss";
	if (self.noise == "")
		self.noise = "weapons/rocket_impact.wav";

	precache_sound(self.noise);
	if (self.debris == "")
		self.debris = "models/onslaught/gen_gib1.md3 models/onslaught/gen_gib2.md3 models/onslaught/gen_gib3.md3 models/onslaught/gen_gib1.md3 models/onslaught/gen_gib2.md3 models/onslaught/gen_gib3.md3 models/onslaught/gen_gib1.md3 models/onslaught/gen_gib2.md3 models/onslaught/gen_gib3.md3";

	debris_init();
	self.spawnorigin = self.origin;
	self.reset = func_boss_reset;
	self.reset();
}

void(entity inflictor, entity attacker, float _damage, float deathtype, vector hitloc, vector force) func_boss_part_damage {
	entity boss = self.owner;
	if not(boss.state & FUNC_BOSS_STATE_TAKEDAMAGE) return;
	if not(boss.cnt == self.cnt) return;
	self.health -= _damage;
	entity e;
	boss.health = 0;
	float hp1 = FALSE;
	for (e = find(NULL, target, boss.targetname); e; e = find(e, target, boss.targetname)) {
		if (e.classname != "func_boss_part") continue;
		if (e.cnt != boss.cnt) continue;
		if (e.health >= 1) {
			if (e.health > 1) boss.health += (e.health - 1);
			hp1 = TRUE;
		}
	}
	if (hp1) boss.health += 1;
	marker_UpdateHealth(boss.sprite, boss.health);
	self.lastdamage = time;
	if (self.health <= 0) {
		self.effects |= EFFECT_NODRAW;
		self.solid = SOLID_NOT;
		self.takedamage = FALSE;
		self.event_damage = NULL;
		func_boss_volume_explode(self);
		func_boss_check_parts(self.owner, attacker);
		debris_throw('0 0 0');
		sound(self, CHAN_WEAPON, self.noise, VOL_BASE, ATTN_MIN);
	}
}

void(void) func_boss_part_init_delayed {
	entity e = find(NULL, targetname, self.target);
	if (!e || e.classname != "func_boss") {
		entity_abort("linked func_boss not found");
		return;
	}
}

void(void) func_boss_part_reset {
	self.angles = '0 0 0';
	if (self.spawnflags & 1) {
		self.solid = SOLID_NOT;
		self.effects |= EFFECT_NODRAW;
	} else {
		self.solid = SOLID_BSP;
		self.effects &= ~EFFECT_NODRAW;
	}
	self.health = self.max_health;
	self.colormod = '0 0 0';
	self.takedamage = DAMAGE_NO;
	setorigin(self, self.spawnorigin);
}

void(void) spawnfunc_func_boss_part {
	model_init(SOLID_BSP);
	self.event_damage = func_boss_part_damage;
	if (self.target == "") {
		entity_abort("missed target property");
		return;
	}
	if (self.noise == "")
		self.noise = "weapons/rocket_impact.wav";

	precache_sound(self.noise);
	if (self.debris == "")
		self.debris = "models/onslaught/gen_gib1.md3 models/onslaught/gen_gib2.md3 models/onslaught/gen_gib3.md3";

	debris_init();
	entity_initialize(self, func_boss_part_init_delayed, INITPRIO_LAST);
	self.max_health = self.health;
	self.spawnorigin = self.origin;
	self.reset = func_boss_part_reset;
	self.reset();
}

void(void) func_boss_shooter_reset {
	self.solid = SOLID_BSP;
	self.angles = '0 0 0';
	self.effects &= ~EFFECT_NODRAW;
	self.enemy = NULL;
	setorigin(self, self.spawnorigin);
}

void(void) spawnfunc_func_boss_shooter {
	model_init(SOLID_BSP);
	if (self.target == "") {
		entity_abort("missed target property");
		return;
	}
	entity_initialize(self, func_boss_part_init_delayed, INITPRIO_LAST);
	self.spawnorigin = self.origin;
	self.reset = func_boss_shooter_reset;
	self.reset();
}
