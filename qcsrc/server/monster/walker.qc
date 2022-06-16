#define WALKER_MIN '-70 -70 5'
#define WALKER_MAX '70 70 90'
void walker_walk();
void walker_idle();

void walker_bullet() {
	entity flash;
	weapon_shotdir = normalize(self.enemy.origin - weapon_shotorg);
	weapon_shotdir_x = v_forward_x;
	weapon_shotdir_y = v_forward_y;
	sound (self, CHAN_WEAPON, "weapons/uzi_fire.wav", VOL_BASE, ATTN_NORM);
	bullet_begin(5000);
	bullet(weapon_shotorg, weapon_shotdir, 0.1, 5000, 5, self.dmg_edge * 0.1, 0, self.dmg_force * 0.1, DEATH_TURRET, particleeffectnum("tr_bullet"), 1, 100);
	bullet_end();
	flash = spawn();
	setmodel(flash, "models/uziflash.md3");
	setattachment(flash, self.weaponentity, "tag_fire");
	flash.scale     = 3;
	flash.think     = weapon_uzi_flash_go;
	flash.nextthink = time + 0.02;
	flash.frame     = 2;
	flash.angles_z  = flash.v_angle_z + random() * 180;
	flash.alpha     = 1;
	flash.effects   = EFFECT_ADDITIVE | EFFECT_FULLBRIGHT | EFFECT_LOWPRECISION;
}

void walker_rocket_event_damage (entity inflictor, entity attacker, float _damage, float deathtype, vector hitloc, vector vforce) {
	self.health = self.health - _damage;
	self.velocity = self.velocity + vforce;
	if (self.health <= 0) {
		self.think = projectile_explode;
		self.nextthink = time;
	}
}

void walker_rocket_think() {
	if (time > self.cnt) {
		projectile_explode();
		return;
	}
	vector v;
	if (self.enemy.health < 1)
	if (self.enemy.classname != "player")
		self.enemy = world;

	if (self.enemy) {
		v = self.enemy.origin - self.origin;
		vector a = vectoangles(v);
		float approach_speed = 60 * frametime;
		self.nextthink = time;
		self.angles_x = approach_angle(self.angles_x, a_x, approach_speed);
		self.angles_y = approach_angle(self.angles_y, a_y, approach_speed);
		self.angles_z = approach_angle(self.angles_z, a_z, approach_speed);
		makevectors(self.angles);
		self.velocity = v_forward * 600;
		self.velocity_z = -self.velocity_z;
	}
}

void walker_hunt() {
	self.nextthink = time;
	if (monster_check_target(walker_walk, walker_idle))
		return;

	float dofire;
	dofire = FALSE;
	if (self.attack_finished_single < time)
		dofire = monster_look_to(self.enemy);

	makevectors(self.angles);
	if (dofire && v_forward * (self.enemy.origin - self.origin) > 0.5) {
		self.cnt = random();
		self.attack_finished_single = time + 4;
		self.count = ((self.cnt < 0.5) ? 20 : 4);
		self.bulletcounter = time;
	}
	if (self.cnt && time >= self.bulletcounter) {
		if (self.cnt < 0.5) {
			self.bulletcounter = self.bulletcounter + 0.1;
			//Minigun
			weapon_shotorg = self.origin + v_forward * 32 + '0 0 16';
			anim_set(self.weaponentity, '0 12 12', TRUE, TRUE, FALSE);
			anim_update(self.weaponentity);
			walker_bullet();
		} else {
			//Rockets
			weapon_shotorg = self.origin + v_up * 80;
			if (math_mod(self.count, 2))
				weapon_shotorg = weapon_shotorg + v_right * 16;
			else
				weapon_shotorg = weapon_shotorg - v_right * 16;

			self.bulletcounter = self.bulletcounter + 0.5;
			entity missile = projectile(FALSE, PROJECTILE_ROCKET, FALSE, self);
			projectile_setup(missile, weapon_shotorg, WEP_ROCKET_LAUNCHER, self.dmg_edge, 0, self.dmg_radius, self.dmg_force, 0, MOVETYPE_FLY);
			missile.classname = "walker_rocket";
			missile.takedamage = DAMAGE_YES;
			missile.damageforcescale = 1;
			missile.health = 10;
			missile.event_damage = walker_rocket_event_damage;
			missile.enemy = self.enemy;
			missile.velocity = normalize(v_forward + '0 0 0.5') * 600;
			missile.touch = projectile_touch_explode;
			missile.think = walker_rocket_think;
			missile.nextthink = time;
			missile.cnt = time + 30;
			missile.angles = vectoangles(missile.velocity);
			missile.angles_x = missile.angles_x;
		}
		self.count = self.count - 1;
		if not(self.count)
			self.cnt = 0;
	}
	float onground = (self.flags & FL_ONGROUND);
	anim_set(self, (onground ? '5 20 25' : '95 5 25'), TRUE, FALSE, FALSE);
	anim_update(self);
	vector v = monster_move_walk((onground ? 400 : 100), (onground ? 25 : 5), 0);
	if (dofire || self.cnt) {
		v = vectoangles(self.enemy.origin - self.origin);
	} else
		v = vectoangles(v);

	self.angles_y = approach_angle(self.angles_y, v_y, 720 * frametime);
}

void walker_walk() {
	self.nextthink = time;
	if (monster_look_for_player(2500, 500, 0, 1, 3)) {
		return;
	}
	if (monster_walk_finished(walker_idle, 100))
		return;

	float onground = (self.flags & FL_ONGROUND);
	anim_set(self, (onground ? '5 20 25' : '95 5 25'), TRUE, FALSE, FALSE);
	anim_update(self);
	vector v = monster_move_walk((onground ? 400 : 100), (onground ? 25 : 5), 0);
	v = vectoangles(v);
	self.angles_y = approach_angle(self.angles_y, v_y, 180 * frametime);
}

void walker_remove() {
	remove(self.weaponentity);
	entity e;
	for (e = world; (e = findentity(e, owner, self));)
		if (self.classname == "walker_rocket")
			e.owner = world;
}

void walker_idle() {
	self.nextthink = time;
	if (monster_look_for_player(2500, 500, 0, 1, 3)) {
		return;
	}
	movelib_beak_simple(100 * frametime);
	anim_set(self, '0 0 0', TRUE, TRUE, FALSE);
	anim_update(self);
}

void walker_spawn() {
	monster_prepare(walker_hunt, walker_walk, walker_idle);
	setmodel(self, "models/turrets/walker_body.md3");
	self.weaponentity = spawn();
	setmodel(self.weaponentity, "models/turrets/walker_head_minigun.md3");
	setattachment(self.weaponentity, self, "tag_head");
	self.species = SPECIES_ROBOT_SOLID;
	self.solid = SOLID_BBOX;
	self.damageforcescale = 0.1;
	self.netname = "Walker Nagibator";
	self.movetype = MOVETYPE_WALK;
	self.entremove = walker_remove;
	self.takedamage = DAMAGE_AIM;
	self.weaponentity.colormod = self.colormod;
	self.ammo_rockets = 20;
	self.ammo_nails = 50;
	self.frags = 3;
	self.view_ofs = '0 0 50';
}

void walker_init() {
	precache_model("models/turrets/walker_body.md3");
	precache_model("models/turrets/walker_head_minigun.md3");
	precache_sound("weapons/uzi_fire.wav");
}

void spawnfunc_monster_walker_spawn() {
    setsize(self, WALKER_MIN, WALKER_MAX);
	monster_init(walker_init);
	monster_prepare_spawn(walker_spawn, spawnfunc_monster_walker_spawn);
}
