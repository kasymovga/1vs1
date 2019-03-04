#define MONSTER_IGNOREFIRE 1
#define MONSTER_IGNORESLIME 2
#define MONSTER_IGNOREDROWN 4

#define MONSTER_SPAWN_AUTORESPAWN 1
#define MONSTER_SPAWN_FREEHUNT 2
#define MONSTER_SPAWN_STAYSTILL 4
#define MONSTER_SPAWN_SHIELDED 8

float g_monster_pushfactor;

void monster_proj_explode(void) {
	self.event_damage = SUB_Null;
	self.takedamage = DAMAGE_NO;
	RadiusDamage (self, self.owner, self.dmg_edge, 0, self.dmg_radius, world, self.dmg_force, self.projectiledeathtype, other);
	remove (self);
}

void monster_proj_touch(void) {
	PROJECTILE_TOUCH;
	monster_proj_explode();
}

void monster_sound(entity m, string s, float force) {
	if (force)
		m.watersound_finished = 0;

	if (s != "")
	if (m.watersound_finished < time) {
		m.watersound_finished = time + 5;
		sound(m, CHAN_TRIGGER, s, VOL_BASE, ATTN_NORM);
	}
}

void monster_set_route() {
	float f1, f2;
	entity p;
	if (self.items & IT_JETPACK) {
		f1 = bot_ai_navigation_jetpack;
		f2 = bot_ai_navigation_jetpack_mindistance;
		bot_ai_navigation_jetpack = TRUE;
		bot_ai_navigation_jetpack_mindistance = 100;
	}
	bot_navigation_movemode = MOVE_NORMAL;
	navigation_clearroute();
	navigation_goalrating_start();
	if (self.enemy)
		navigation_routerating(self.enemy, 10000, 10000);
	else
		FOR_EACH_PLAYER(p)
			if (p.health >= 1)
			if (p.deadflag == DEAD_NO)
				navigation_routerating(p, 10000, 10000);

	navigation_goalrating_end();
	if (self.items & IT_JETPACK) {
		bot_ai_navigation_jetpack = f1;
		bot_ai_navigation_jetpack_mindistance = f2;
	}
}

vector monster_checkpoint(entity e) {
	float x_perm = e.maxs_x - e.mins_x;
	float y_perm = e.maxs_y - e.mins_y;
	float z_perm = e.maxs_z - e.mins_z;
	vector v;
	v = e.origin + e.mins;
	v_x = v_x + x_perm * random();
	v_y = v_y + y_perm * random();
	v_z = v_z + z_perm * random();
	return v;
}

float notice_sound_finished;
entity monster_look_for_player(float distance, float heardistance, float fov_factor, float attack_delay, float attack_delay_jitter) {
	entity e;
	vector v;
	vector checkpoint;
	float f;
	entity p = world;
	if not(gameover)
	FOR_EACH_PLAYER(e)
	if (e.health >= 1)
	if (e.deadflag == DEAD_NO) {
		if (teamplay) {
			if not(self.team)
				continue;

			if (self.team == e.team)
				continue;
		}
		f = vlen(e.origin - self.origin);
		if (f <= heardistance) {
			checkpoint = monster_checkpoint(e);
			traceline(self.origin + self.view_ofs, checkpoint, MOVE_NOMONSTERS, world);
			if (trace_fraction == 1) {
				p = e;
				break;
			}
		} else if (f <= distance) {
			checkpoint = monster_checkpoint(e);
			v = normalize(e.origin - self.origin);
			makevectors(self.angles);
			if (v * normalize(v_forward) >= fov_factor) {
				traceline(self.origin + self.view_ofs, checkpoint, MOVE_NOMONSTERS, world);
				if (trace_fraction == 1) {
					distance = f;
					p = e;
				}
			}
		}
	}
	if (p) {
		if (self.enemy)
		if (self.enemy.classname == "monster_walk_path" || self.enemy.classname == "path_corner")
			self.message2 = self.enemy.targetname;

		self.think = self.weapon_think;
		self.enemy = p;
		self.attack_finished_single = time + random() * attack_delay_jitter + attack_delay;
		self.think();
		if (time > notice_sound_finished) {
			monster_sound(self, self.noise1, FALSE);
			notice_sound_finished = time + 5;
		}
	}
	return p;
}

void monster_drop_item(float item_code, string _model, string _sound, string _name, .float itemfield, float itemvalue) {
	if (random(1) > 0.2)
		return;

	entity e = self;
	self = spawn();
	self.classname = "droppedweapon";
	self.itemfield = itemvalue;
	setorigin(self, e.origin);
	StartItem (_model, _sound, 15, 0, _name, item_code, 0, 0, generic_pickupevalfunc, 100);
	self = e;
}

void monster_die() {
	//self.view_ofs = self.mins_z  + (self.maxs_z - self.mins_z) * 0.25;
	Violence_GibSplash(self, 1, 1, self.enemy);
	self.solid = SOLID_NOT;
	self.alpha = -1;
	self.nextthink = time;
	if (self.spawnflags & MONSTER_SPAWN_SHIELDED) {
		entity e;
		e = world;
		while ((e = find(e, targetname, "monster_shield_destroy"))) {
			if (e.owner == self) {
				remove(e);
				break;
			}
		}
	}
	self.think = SUB_Remove;

	if (self.ammo_shells)
		monster_drop_item(IT_SHELLS, "models/items/a_shells.md3", "misc/itempickup.wav", "Shells", ammo_shells, self.ammo_shells);

	if (self.ammo_nails)
		monster_drop_item(IT_NAILS, "models/items/a_bullets.md3", "misc/itempickup.wav", "Bullets", ammo_nails, self.ammo_nails);

	if (self.ammo_rockets)
		monster_drop_item(IT_ROCKETS, "models/items/a_rockets.md3", "misc/itempickup.wav", "Rockets", ammo_rockets, self.ammo_rockets);

	if (self.ammo_cells)
		monster_drop_item(IT_CELLS, "models/items/a_cells.md3", "misc/itempickup.wav", "Cells", ammo_cells, self.ammo_cells);
}

void monster_corpse_event_damage(entity inflictor, entity attacker, float damage, float deathtype, vector hitloc, vector force) {
	if (attacker.classname != "monster")
		self.health = self.health - damage;

	self.velocity = self.velocity + force * self.damageforcescale;
	if (self.health < -200)
		monster_die();
}

void monster_die_animated() {
	anim_set(self, self.anim_die1, FALSE, TRUE, TRUE);
	self.movetype = MOVETYPE_TOSS;
	self.solid = SOLID_CORPSE;
	self.nextthink = time + 5;
	self.think = monster_die;
	self.event_damage = monster_corpse_event_damage;
}

void monster_event_damage(entity inflictor, entity attacker, float damage, float deathtype, vector hitloc, vector force) {
	if (self.spawnflags & MONSTER_SPAWN_SHIELDED) {
        entity sh = spawn();
        sh.alpha = 0.5;
        sh.scale  = (128 / vlen(self.maxs - self.mins))*2;
		setmodel(sh, "models/vhshield.md3");
        //sh.scale = 1.25;
        sh.effects = EF_LOWPRECISION;
        sh.angles = vectoangles(normalize(-force));
		sh.nextthink = time + 0.2;
		sh.think = SUB_Remove;
		setorigin(sh, hitloc + normalize(force) * sh.scale * 100);
		if (clienttype(attacker) == CLIENTTYPE_REAL)
			centerprint(attacker, "Enemy protected by shield!");

		return;
	}
	if (deathtype == DEATH_LAVA || deathtype == DEATH_FIRE) {
		if (self.flags & MONSTER_IGNOREFIRE)
			return;
	} else if (deathtype == DEATH_SLIME) {
		if (self.flags & MONSTER_IGNORESLIME)
			return;
	} else if (deathtype == DEATH_DROWN) {
		if (self.flags & MONSTER_IGNOREDROWN)
			return;
	}
	if (attacker.classname != "monster")
		self.health = self.health - damage;

	Violence_GibSplash_At(hitloc, force, 2, bound(0, damage, 200) / 16, self, attacker);
	self.velocity = self.velocity + force * self.damageforcescale;
	if (self.health < 1) {
		stopsound(self, CHAN_TRIGGER);
		monster_sound(self, self.noise2, FALSE);
		GameHook_MonsterKilled(attacker);
		entity o = self.owner;
		float quant = GameHook_MonsterQuant();
		if (o.spawnflags & 1) {
			o.nextthink = time + o.respawntime;
			o.dmg = o.dmg + quant;
		}
		o.frags = o.frags - quant;
		if (o.frags < quant)
		if (o.dmg < quant) {
			activator = attacker;
			entity oldself = self;
			self = o;
			SUB_UseTargets();
			self = oldself;
		}
		self.enemy = attacker;
		if (self.anim_die1 != '0 0 0')
			monster_die_animated();
		else
			monster_die();
	} else if (attacker.classname == "player") {
		monster_sound(self, self.noise3, FALSE);
		if (self.enemy) {
			if (self.enemy.classname == "monster_walk_path" || self.enemy.classname == "path_corner")
				self.message2 = self.enemy.targetname;
			else
				return;
		}

		self.enemy = attacker;
		self.think = self.weapon_think;
	}
}

vector monster_get_direction() {
	if (self.goalcurrent)
		navigation_poptouchedgoals();

	vector v;
	if (self.goalcurrent) {
		//print("self.goalcurrent=", self.goalcurrent.classname, "\n");
		if (self.navigation_jetpack_goal == self.goalcurrent) {
			v = self.navigation_jetpack_point - self.origin;
			//print("Trying fly\n");
		} else
			v = self.goalcurrent.origin - self.origin;
	} else
		v = self.enemy.origin - self.origin;

	return normalize(v);
}

vector monster_move_swim(float _speed, float blend_factor) {
	vector v = '0 0 0';
	if (self.waterlevel < WATERLEVEL_SWIMMING) {
		movelib_beak_simple(blend_factor * frametime);
		self.gravity = 1;
		return v;
	}
	self.gravity = 0.01;
	v = normalize(self.enemy.origin - self.origin);
	if (self.waterlevel == WATERLEVEL_SUBMERGED) {
		v_z = v_z + 0.5 * vlen(v);
	}
	movelib_move_simple(normalize(v), _speed, blend_factor * frametime);
	return v;
}

void monster_move_fly_idle(float _speed, float blend_factor) {
	if (self.waterlevel) {
		movelib_move_simple('0 0 1', _speed, blend_factor * frametime);
		return;
	}
	if (self.velocity != '0 0 0') {
		float f = max(0,vlen(self.velocity) - _speed * frametime);
		if (f) {
			self.velocity = normalize(self.velocity) * f;
		} else
			self.velocity = '0 0 0';
	}
}

vector monster_move_walk(float _speed, float blend_factor, float rushdistance) {
	float dir_z_save;
	float vel_z_save;
	vector v;
	if (self.waterlevel == WATERLEVEL_SUBMERGED) {
		_speed *= 0.5;
		if(self.air_finished < time + 6)
			self.velocity_z += (_speed - self.velocity_z) * frametime;
	}
	if (rushdistance)
	if (self.enemy)
	if (rushdistance > vlen(self.origin - self.enemy.origin)) {
		v = normalize(self.enemy.origin - self.origin);
		dir_z_save = v_z;
		vel_z_save = self.velocity_z;
		movelib_move_simple(v, _speed, blend_factor * frametime);
		v_z = dir_z_save;
		self.velocity_z = vel_z_save;
		return v;
	}
	if (self.bot_strategytime < time) {
		self.bot_strategytime = time + 1 + random() * 1;
		monster_set_route();
	}
	v = monster_get_direction();
	v_z = 0;
	dir_z_save = v_z;
	vel_z_save = self.velocity_z;
	if not(self.flags & FL_ONGROUND)
		_speed = _speed * 0.5;

	movelib_move_simple(v, _speed, blend_factor * frametime);
	v_z = dir_z_save;
	self.velocity_z = vel_z_save;
	return v;
}

vector monster_move_fly(float _speed, float blend_factor) {
	if (self.bot_strategytime < time) {
		self.bot_strategytime = time + 1 + random() * 1;
		monster_set_route();
	}
	vector v;
	v = monster_get_direction();
	v_z = v_z + 0.5;
	movelib_move_simple(normalize(v), _speed, blend_factor * frametime);
	return v;
}

void monster_shield_restore(void) {
	self.owner.spawnflags |= MONSTER_SPAWN_SHIELDED;
}

void monster_shield_destroy(void) {
	self.owner.spawnflags &~= MONSTER_SPAWN_SHIELDED;
	if (clienttype(activator) == CLIENTTYPE_REAL) {
		monster_sound(self.owner, self.owner.noise3, TRUE);
		centerprint(activator, "Enemy shield is broken!");
	}
	self.nextthink = time + 10;
	self.think = monster_shield_restore;
}

void monster_spawn_think() {
	float quant = GameHook_MonsterQuant();
	if (teamplay)
	if not(self.team)
		return;

	if (self.dmg < quant)
		return;

	entity oldself = self;
	self = spawn();
	self.angles = oldself.angles;
	setorigin(self, oldself.origin);
	sound (self, CHAN_TRIGGER, "misc/teleport.wav", VOL_BASE, ATTN_NORM);
	pointparticles(particleeffectnum("teleport"), self.origin, '0 0 0', 1);
	self.owner = oldself;
	self.reset = monster_die;
	oldself.weapon_think();
	self.pushfactor = self.damageforcescale * g_monster_pushfactor;
	if (self.pushfactor) {
		self.touch = push_touch;
	}
	self.spawnflags = oldself.spawnflags;
	if (self.spawnflags & MONSTER_SPAWN_SHIELDED) {
		precache_model("models/vhshield.md3");
		entity shield_destroy = spawn();
		shield_destroy.owner = self;
		shield_destroy.targetname = "monster_shield_destroy";
		shield_destroy.use = monster_shield_destroy;
	}
	setsize(self, oldself.mins, oldself.maxs);
	if not(self.frags)
		self.frags = 1;

	self = oldself;
	self.dmg = self.dmg - quant;
	self.frags = self.frags + quant;
	self.nextthink = time + self.respawntime;
}

void monster_spawn_use() {
	if not(self.spawnflags & 1)
		self.reset();

	if (activator)
	if (GameHook_MonsterTeamSwitchable())
		self.team = activator.team;

	self.think();
}

void monster_prepare(void() hunt, void() walk, void() idle) {
	self.classname = "monster";
	self.health = self.owner.health;
	self.dmg_edge = self.owner.dmg_edge;
	self.dmg_force = self.owner.dmg_force;
	self.dmg_radius = self.owner.dmg_radius;
	self.noise1 = self.owner.noise1;
	self.noise2 = self.owner.noise2;
	self.noise3 = self.owner.noise3;
	self.iscreature = TRUE;
	self.bot_attack = TRUE;
	self.team = self.owner.team;
	self.weapon_think = hunt;
	self.nextthink = time;
	self.dphitcontentsmask = DPCONTENTS_SOLID | DPCONTENTS_MONSTERCLIP | DPCONTENTS_BOTCLIP | DPCONTENTS_BODY;
	string t = self.owner.target;
	if (t == "")
		t = self.target;

	if (t != "") {
		self.enemy = find(world, targetname, t);
		if (self.enemy.classname != "monster_walk_path" && self.enemy.classname != "path_corner")
			self.enemy = world;
	}
	if (self.enemy || self.owner.spawnflags & 2) {
		self.think = walk;
		//print("Prepare route\n");
	} else
		self.think = idle;

	self.event_damage = monster_event_damage;
	if (self.team > 0)
		self.colormod = TeamColorMod(self.team);
}

void monster_set_fly() {
	self.items = IT_JETPACK | IT_UNLIMITED_WEAPON_AMMO;
}

float monster_walk_finished(void() idle, float dist) {
	if not(self.enemy) //Free walk
		return FALSE;

	vector v = self.enemy.origin - self.origin;
	v_z = 0;
	if (vlen(v) < dist) {
		if (self.enemy.target != "")
			self.enemy = find(world, targetname, self.enemy.target);
		else
			self.enemy = world;

		if not(self.enemy) {
			self.think = idle;
			idle();
			return TRUE;
		} else
			monster_set_route();
	} else if not(self.goalcurrent) {
		if (self.bot_strategytime < time) {
			self.bot_strategytime = time + 1 + random();
			monster_set_route();
		}
	}
	return FALSE;
}

float monster_check_target(void() walk, void() guard) {
	entity e = self.enemy;
	if (e.health < 1 || e.deadflag != DEAD_NO || !e.takedamage) {
		self.enemy = world;
		if (self.message2 != "")
			self.enemy = find(world, targetname, self.message2);

		if (self.enemy || self.owner.spawnflags & 2) {
			self.think = walk;
			monster_set_route();
		} else
			self.think = guard;

		self.think();
		return TRUE;
	} else if (self.bot_strategytime < time) {
		self.bot_strategytime = time + 1 + random() * 1;
		monster_set_route();
	}
	return FALSE;
}

float monster_common_init_done;
void monster_common_init() {
	precache_sound("misc/teleport.wav");
	CACHE_CVAR(g_monster_pushfactor);
}

void monster_init(void() init_func) {
	if not(monster_common_init_done) {
		monster_common_init();
		monster_common_init_done = TRUE;
	}
	if (find(world, classname, self.classname) != self)
		return;

	init_func();
}

string monster_classname() {
	float spawn_suffix = strstrofs(self.classname, "_spawn", 0);
	if (spawn_suffix >= 0) {
		return substring(self.classname, 8, spawn_suffix - 8);
	}
	return substring(self.classname, 8, -1);
}

float monster_difficulty;

void monster_prepare_spawn(void() spawnfunc, void() resetfunc) {
	self.weapon_think = spawnfunc;
	self.think = monster_spawn_think;
	self.use = monster_spawn_use;
	self.nextthink = 0;
	self.dmg = max(self.cnt, 1);
	self.frags = 0;
	self.reset = resetfunc;
	self.dmg_edge = cvar(strcat("g_monster_", monster_classname(), "_damage")) * monster_difficulty;
	self.dmg_force = cvar(strcat("g_monster_", monster_classname(), "_force"));
	self.health = cvar(strcat("g_monster_", monster_classname(), "_health")) * monster_difficulty;
	self.dmg_radius = cvar(strcat("g_monster_", monster_classname(), "_radius"));
	if (!self.respawntime)
		self.respawntime = 1;

	if (teamplay)
	if not(self.team)
		self.team = -1;

	if (self.targetname == "") {
		self.nextthink = time;
	}
	if (self.noise1 != "")
		precache_sound(self.noise1);

	if (self.noise2 != "")
		precache_sound(self.noise2);

	if (self.noise3 != "")
		precache_sound(self.noise3);
}

void spawnfunc_monster_walk_path() {
#if 0
	setmodel(self, "models/ebomb.mdl");
	self.scale = 4;
	self.solid = SOLID_NOT;
#endif
}

void monsters_init() {
	float g_monster_difficulty;
	if (g_campaign)
		g_monster_difficulty = g_campaign_skill;
	else
		g_monster_difficulty = cvar("g_monster_difficulty");

	monster_difficulty = 0.5 + bound(0, g_monster_difficulty, 3) * 0.25;
	string monster_list = cvar_string("g_monsters_spawn");
	string head, tail;
	tail = monster_list;
	float n, i;
	string monster_name;
	string monster_func;
	string _monster_classname;
	float monster_count;
	entity monster;
	entity oldself;
	while (tail != "") {
		head = car(tail);
		tail = cdr(tail);
		n = strstrofs(head, ":", 0);
		if (n > 0) {
			monster_name = substring(head, 0, n);
			monster_count = stof(substring(head, n + 1, -1));
		} else {
			monster_name = head;
			monster_count = 1;
		}

		_monster_classname = strzone(strcat("monster_", monster_name, "_spawn"));
		monster_func = strcat("spawnfunc_monster_", monster_name, "_spawn");
		if (isfunction(monster_func)) {
			for (i = 0; i < monster_count; i++) {
				monster = spawn();
				monster.classname = _monster_classname;
				monster.cnt = 1;
				monster.respawntime = 10;
				monster.spawnflags = 3;
				oldself = self;
				self = monster;
				callfunction(monster_func);
				if not(MoveToRandomMapLocation(monster, DPCONTENTS_SOLID | DPCONTENTS_CORPSE | DPCONTENTS_PLAYERCLIP, DPCONTENTS_SLIME | DPCONTENTS_LAVA | DPCONTENTS_SKY | DPCONTENTS_BODY | DPCONTENTS_DONOTENTER, Q3SURFACEFLAG_SKY, 10, 1024, 256)) {
					print("Cant find place for ", monster_name, "\n");
					SUB_Remove();
				}
				self = oldself;
			}
		} else
			print("Function ", monster_func, " not found\n");
	}
	precache_model("models/items/a_bullets.md3");
	precache_model("models/items/a_shells.md3");
	precache_model("models/items/a_rockets.md3");
	precache_model("models/items/a_cells.md3");
	precache_sound("misc/itempickup.wav");
}

void monster_group_reset() {
}

void monster_group_counter_remove() {
	self.owner.enemy = world;
	entity e;
	while ((e = find(e, target2, self.targetname))) {
		e.target2 = "";
	}
	strunzone(self.targetname);
	remove(self);
}

void monster_group_counter_use() {
	self.cnt = self.cnt - 1;
	if (self.cnt <= 0) {
		SUB_UseTargets();
		self.use = world.use;
		self.think = monster_group_counter_remove;
		self.nextthink = time;
	}
}

void monster_group_use() {
	if (self.enemy)
		return;

	entity e = world;
	entity group = spawn();
	group.targetname = strzone(strcat("_monster_group", ftos(self.cnt)));
	while ((e = find(e, targetname, self.target))) {
		e.target2 = group.targetname;
	}
	group.use = monster_group_counter_use;
	group.target = self.target2;
	group.owner = self;
	group.reset = monster_group_counter_remove;
	group.cnt = 0;
	self.enemy = group;
	entity oldself = self;
	while ((e = find(e, targetname, oldself.target))) {
		group.cnt = group.cnt + 1;
		self = e;
		self.use();
	}
	if (group.cnt <= 0) {
		self = group;
		monster_group_counter_remove();
	}
	self = oldself;
}

float monster_groups;
void spawnfunc_monster_group() {
	self.reset = monster_group_reset;
	self.use = monster_group_use;
	monster_groups++;
	self.cnt = monster_groups;
}
