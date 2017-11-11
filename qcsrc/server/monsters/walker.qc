#define WALKER_MIN '-70 -70 5'
#define WALKER_MAX '70 70 90'
void walker_walk();
void walker_idle();

void walker_bullet() {
    entity flash;
	w_shotdir = normalize(self.enemy.origin - w_shotorg);
	w_shotdir_x = v_forward_x;
	w_shotdir_y = v_forward_y;
    sound (self, CHAN_WEAPON, "weapons/uzi_fire.wav", VOL_BASE, ATTN_NORM);
    fireBallisticBullet(w_shotorg, w_shotdir, 0.1, 5000, 5, self.dmg_edge * 0.1, 0, self.dmg_force * 0.1, DEATH_TURRET, 0, 1, 0);
    endFireBallisticBullet();
	flash = spawn();
	setmodel(flash, "models/uziflash.md3");
	setattachment(flash, self.weaponentity, "tag_fire");
	flash.scale     = 3;
	flash.think     = W_Uzi_Flash_Go;
	flash.nextthink = time + 0.02;
	flash.frame     = 2;
	flash.angles_z  = flash.v_angle_z + random() * 180;
	flash.alpha     = 1;
	flash.effects   = EF_ADDITIVE | EF_FULLBRIGHT | EF_LOWPRECISION;
}

void walker_rocket_explode() {
    RadiusDamage (self, self.owner, self.dmg_edge, 0, self.dmg_radius, world, self.dmg_force, WEP_ROCKET_LAUNCHER, world);
    remove(self);
}

void walker_rocket_event_damage (entity inflictor, entity attacker, float damage, float deathtype, vector hitloc, vector vforce) {
    self.health = self.health - damage;
    self.velocity = self.velocity + vforce;
    if (self.health <= 0) {
        self.think = walker_rocket_explode;
		self.nextthink = time;
	}
}

void walker_rocket_touch() {
	PROJECTILE_TOUCH;
	walker_rocket_explode();
}

void walker_rocket_think() {
	if (time > self.cnt) {
		walker_rocket_explode();
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
	UpdateCSQCProjectile(self);
}

void walker_hunt() {
	self.nextthink = time;
	if (monster_check_target(walker_walk, walker_idle))
		return;

	float dofire;
	dofire = FALSE;
	if (self.attack_finished_single < time)
	{
		traceline(self.origin, self.enemy.origin, MOVE_WORLDONLY, self);
		if (trace_fraction == 1)
			dofire = TRUE;
	}
	if (dofire) {
		self.cnt = random();
		self.attack_finished_single = time + 5;
		self.count = ((self.cnt < 0.5) ? 20 : 4);
		self.bulletcounter = time;
	}
	while (self.cnt && time >= self.bulletcounter) {
		makevectors(self.angles);
		v_forward = normalize(v_forward);
		if (self.cnt < 0.5 && v_forward * normalize(self.enemy.origin - self.origin) > 0.75) {
			self.bulletcounter = self.bulletcounter + 0.1;
			//Minigun
			w_shotorg = self.origin + v_forward * 32;
			setanim(self.weaponentity, '0 12 12', TRUE, TRUE, FALSE);
			updateanim(self.weaponentity);
			walker_bullet();
		} else {
			//Rockets
			w_shotorg = self.origin + v_up * 80;
			if (mod(self.count, 2))
				w_shotorg = w_shotorg + v_right * 16;
			else
				w_shotorg = w_shotorg - v_right * 16;

			self.bulletcounter = self.bulletcounter + 0.5;
			entity missile = CSQCProjectile(FALSE, PROJECTILE_ROCKET, FALSE);
			missile.owner = self;
			missile.dmg_edge = self.dmg_edge;
			missile.dmg_radius = self.dmg_radius;
			missile.dmg_force = self.dmg_force;
			missile.classname = "walker_rocket";
			missile.takedamage = DAMAGE_YES;
			missile.damageforcescale = 1;
			missile.health = 10;
			missile.event_damage = walker_rocket_event_damage;
			missile.movetype = MOVETYPE_FLY;
			missile.enemy = self.enemy;
			PROJECTILE_MAKETRIGGER(missile);
			missile.projectiledeathtype = WEP_ROCKET_LAUNCHER;
			setorigin(missile, w_shotorg);
			missile.velocity = normalize(v_forward + v_up) * 600;
			W_SetupProjectileVelocity(missile);
			missile.angles = vectoangles(missile.velocity);
			missile.touch = walker_rocket_touch;
			missile.think = walker_rocket_think;
			missile.nextthink = time;
			missile.cnt = time + 30;
		}
		self.count = self.count - 1;
		if not(self.count)
			self.cnt = 0;
	}
	if (self.flags & FL_ONGROUND) {
		setanim(self, '5 20 25', TRUE, TRUE, FALSE);
		updateanim(self);
		vector v = monster_move_walk(400, 5, 0);
		v = vectoangles(v);
		self.angles_y = approach_angle(self.angles_y, v_y, 180 * frametime);
	} else {
		setanim(self, '95 5 25', TRUE, TRUE, FALSE);
		updateanim(self);
	}
}

void walker_walk() {
	self.nextthink = time;
	if (monster_look_for_player(2500, 500, 0, 1, 3)) {
		return;
	}
	if (monster_walk_finished(walker_idle, 100))
		return;

	setanim(self, '5 20 25', TRUE, TRUE, FALSE);
	updateanim(self);
	if (self.flags & FL_ONGROUND) {
		vector v = monster_move_walk(400, 5, 0);
		v = vectoangles(v);
		self.angles_y = approach_angle(self.angles_y, v_y, 90 * frametime);
	}
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
	setanim(self, '0 0 0', TRUE, TRUE, FALSE);
	updateanim(self);
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
}

void walker_init() {
	precache_model("models/turrets/walker_body.md3");
	precache_model("models/turrets/walker_head_minigun.md3");
	precache_sound("weapons/uzi_fire.wav");
	CSQCProjectile_Init(PROJECTILE_ROCKET);
}

void spawnfunc_walker_spawn() {
    setsize(self, WALKER_MIN, WALKER_MAX);
	monster_init(walker_init);
	monster_prepare_spawn(walker_spawn, spawnfunc_walker_spawn);
}
