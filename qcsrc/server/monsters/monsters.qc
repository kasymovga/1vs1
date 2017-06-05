#define MONSTER_DIE 1

entity monster_look_for_player(float distance, float fov_factor) {
	entity e;
	vector v;
	float f;
	entity p;
	FOR_EACH_PLAYER(e)
	if (e.health >= 1) {
		
		f = vlen(e.origin - self.origin);
		if (f <= distance) {
			v = normalize(e.origin - self.origin);
			makevectors(self.angles);
			if (v * normalize(v_forward) >= fov_factor) {
				traceline(self.origin, e.origin, MOVE_WORLDONLY, self);
				if (trace_fraction == 1) {
					distance = f;
					p = e;
				}
			}
		}
	}
	return p;
}

void monster_die() {
	self.solid = SOLID_NOT;
	self.alpha = -1;
	self.nextthink = time;
	self.think = SUB_Remove;
}

void monster_event_damage(entity inflictor, entity attacker, float damage, float deathtype, vector hitloc, vector force) {
	if (attacker.classname != "monster")
		self.health = self.health - damage;

	Violence_GibSplash_At(hitloc, force, 2, bound(0, damage, 200) / 16, self, attacker);
	self.velocity = self.velocity + force * self.damageforcescale;
	if (self.health < 1) {
		Violence_GibSplash(self, 1, 1, attacker);
		monster_die();
		entity o = self.owner;
		if (o.spawnflags & 1) {
			o.nextthink = time + o.respawntime;
			o.dmg = o.dmg + 1;
		}
	} else if (attacker.classname == "player") {
		self.enemy = attacker;
		self.think = self.weapon_think;
	}
}

void monster_move_walk(vector direction, float _speed, float blend_factor) {
	float dir_z_save = direction_z;
	float vel_z_save = self.velocity_z;
	movelib_move_simple(direction, _speed, blend_factor * frametime);
	direction_z = dir_z_save;
	self.velocity_z = vel_z_save;
}

vector monster_get_direction_to(entity e) {
	vector v = self.enemy.origin - self.origin;
	v_z = 0;
	return normalize(v);
}

void monster_spawn_think() {
	if (self.dmg <= 0)
		return;

	entity oldself = self;
	self = spawn();
	self.angles = oldself.angles;
	setorigin(self, oldself.origin);
	self.owner = oldself;
	self.reset = monster_die;

	oldself.weapon_think();

	self = oldself;
	self.dmg = self.dmg - 1;
	self.nextthink = time + self.respawntime;
}

void monster_prepare(void() hunt, void() walk, void() idle) {
	self.classname = "monster";
	self.weapon_think = hunt;
	self.nextthink = time;
	string t = self.owner.target;
	if (t == "")
		t = self.target;

	if (t != "")
		self.enemy = find(world, targetname, t);

	if (self.enemy)
		self.think = walk;
	else
		self.think = idle;

	self.event_damage = monster_event_damage;
}

void monster_prepare_spawn(void() spawnfunc, void() resetfunc) {
	self.weapon_think = spawnfunc;
	self.use = self.think = monster_spawn_think;
	self.nextthink = 0;
	self.dmg = max(self.cnt, 1);
	self.reset = resetfunc;
	if (self.targetname == "") {
		self.nextthink = time;
	}
}

void spawnfunc_monster_walk_path() { }
