entity shootingrange_controller;
float shootingrange_round_start;
float shootingrange_round_active;
float SHOOTINGRANGE_ROUND_SCORE;

void(void) shootingrange_target_show {
	self.alpha = 1;
	self.solid = self.cnt;
	entity loc = world;
	random_selection_init();
	while ((loc = find(loc, targetname, self.target))) {
		random_selection_add(loc, 0, "", 1, 1);
	}
	vector from = random_selection_chosen_ent.absmin;
	vector to = random_selection_chosen_ent.absmax;
	vector v;
	v_x = from_x + random() * (to_x - from_x);
	v_y = from_y + random() * (to_y - from_y);
	v_z = from_z + random() * (to_z - from_z);
	setorigin(self, v);
}

void(void) shootingrange_target_hide {
	self.alpha = -1;
	self.solid = SOLID_NOT;
	self.nextthink = 0;
}

void(float a) shootingrange_activate {
	if (a) {
		if (shootingrange_round_active)
			return;

		shootingrange_round_active = TRUE;
	} else {
		if not(shootingrange_round_active)
			return;

		shootingrange_round_active = FALSE;
	}
	entity e = self;
	for (self = find(world, classname, "shootingrange_target"); self; self = find(self, classname, "shootingrange_target")) {
		if (shootingrange_round_active)
			shootingrange_target_show();
		else
			shootingrange_target_hide();
	}
	self = e;
	if (shootingrange_round_active)
		FOR_EACH_PLAYER(e) {
			score_player_set(e, SP_SCORE, 0);
		}
}

float shootingrange_countdown_last;
void(void) shootingrange_controller_think {
	self.nextthink = time;
	if (time < map_starttime) {
		shootingrange_activate(FALSE);
		shootingrange_round_start = map_starttime;
		return;
	} else if (map_finished)
		return;

	if (time >= shootingrange_round_start) {
		if not(shootingrange_round_active) {
			GameStatus_Set("^3Begin!", 2);
			sound_play2all("announcer/robotic/begin.wav");
			shootingrange_countdown_last = 0;
			shootingrange_activate(TRUE);
		} else if (time - shootingrange_round_start > 60) {
			GameStatus_Set("^3Round over", 5);
			sound_play2all("domination/claim.wav");
			shootingrange_activate(FALSE);
			shootingrange_round_start = time + 10;
		}
	} else {
		float countdown = ceil(shootingrange_round_start - time);
		if (countdown <= 5) {
			GameStatus_Set(strcat("^3Starting in ", ftos(countdown)), 1);
			if (countdown <= 3)
			if (shootingrange_countdown_last != countdown) {
				sound_play2all(strcat("announcer/robotic/", ftos(countdown), ".wav"));
			}
		}
		shootingrange_countdown_last = countdown;
	}
}

void(entity inflictor, entity attacker, float _damage, float deathtype, vector hitloc, vector force) shootingrange_target_damage {
	if (deathtype & HITTYPE_SPLASH)
		return;

	float s = score_player_add(attacker, SP_SCORE, 1);
	shootingrange_target_hide();
	if (shootingrange_round_active) {
		self.nextthink = time + self.delay;
		self.think = shootingrange_target_show;
	}
}

void(void) shootingrange_target_reset {
	shootingrange_target_hide();
}

void(void) spawnfunc_shootingrange_target {
	if (self.target == "") {
		print("Removing shootingrange_target without target!\n");
		remove(self);
		return;
	}
	model_setup();
	self.classname = "shootingrange_target";
	self.takedamage = DAMAGE_AIM;
	if (self.solid == SOLID_NOT)
		self.solid = SOLID_BSP;

	self.cnt = self.solid;

	if (!self.delay)
		self.delay = 1;

	self.reset = shootingrange_target_reset;
	self.event_damage = shootingrange_target_damage;
	shootingrange_target_hide();
}

void(void) spawnfunc_shootingrange_area {
	model_setup();
	self.solid = SOLID_NOT; //untouchable
	self.model = ""; //invisible
}

void(void) shootingrange_init {
	score_generic();
	SHOOTINGRANGE_ROUND_SCORE = score_register("current", SCORE_FLAG_LOWER_IS_BETTER);
	player_independent = 1;
	shootingrange_controller = spawn();
	shootingrange_controller.nextthink = time;
	shootingrange_controller.think = shootingrange_controller_think;
	precache_sound("announcer/robotic/begin.wav");
	precache_sound("announcer/robotic/3.wav");
	precache_sound("announcer/robotic/2.wav");
	precache_sound("announcer/robotic/1.wav");
	precache_sound("domination/claim.wav");
}
