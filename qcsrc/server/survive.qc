float wave_number;
float wave_not_found;
float survive_active;
float g_surv_wave_pause;
float g_surv_freeze;
float g_surv_monster_factor;
float _survive_monster_quant;
entity survive_plan_entity;
string survive_map_finished_message;
string survive_wave_prefix;

string() survive_wave_string {
	return strcat("wave", ftos(wave_number));
}

float() survive_has_alive_players {
	entity e;
	PLAYER_FOR_EACH(e)
		if (PLAYER_REALLY_ALIVE(e))
			return TRUE;

	return FALSE;
}

float() survive_has_players {
	entity e;
	CLIENT_FOR_EACH(e)
		if (e.team >= 0 || e.classname == "player")
			return TRUE;

	return FALSE;
}

var void(entity spot) survive_player_spawn_next;
void(entity spot) survive_player_spawn {
	survive_player_spawn_next(spot);
	if not(survive_active) {
		score_player_set(self, SP_STATUS, 0);
		return;
	}
	spectator_observer_spawn(FALSE);
	score_player_set(self, SP_STATUS, 1);
}

void() survive_trigger {
	if not(survive_has_players()) {
		self.nextthink = time + g_surv_wave_pause;
		return;
	}
	entity oldself = self;
	_survive_monster_quant = (1 - g_surv_monster_factor);
	survive_active = FALSE;
	CLIENT_FOR_EACH(self) {
		if (self.team >= 0) {
			if (self.classname != "player" || (g_surv_freeze && self.deadflag == DEAD_FREEZE)) {
				self.classname = "player";
				client_put();
			}
			_survive_monster_quant += g_surv_monster_factor;
		}
	}
	self = oldself;
	if (_survive_monster_quant)
		_survive_monster_quant = 1 / (_survive_monster_quant + 0.001);
	else
		_survive_monster_quant = 1;

	for (self = world; (self = find(self, targetname, survive_wave_string())); ) {
		activator = survive_plan_entity;
		if (self.use)
			self.use();
	}
	float i;
	float wave_to_max = wave_number + 10;
	for (i = wave_number; i < wave_to_max; i++)
	for (self = world; (self = find(self, targetname, strcat("waveto", ftos(i)))); ) {
		activator = survive_plan_entity;
		if (self.use)
			self.use();
	}
	for (i = 1; i <= wave_number; i++)
	for (self = world; (self = find(self, targetname, strcat("wavefrom", ftos(i)))); ) {
		activator = survive_plan_entity;
		if (self.use)
			self.use();
	}
	survive_active = TRUE;
	game_status_set("^1New wave incoming!\n^1Try to survive", 2, "", "", "");
	sound_play2all("announcer/robotic/begin.wav");
	self = oldself;
	remove(self);
	survive_plan_entity = world;
}

void() survive_plan {
	wave_number++;
	survive_plan_entity = spawn();
	survive_plan_entity.classname = "monster";
	survive_plan_entity.think = survive_trigger;
	survive_plan_entity.nextthink = time + g_surv_wave_pause;
	survive_plan_entity.team = -1; //Fake team
	if (survive_active)
		survive_wave_prefix = "^2Wave cleared!";

	survive_active = FALSE;
	entity oldself = self;
	CLIENT_FOR_EACH(self) {
		if (self.team >= 0) {
			if (self.classname != "player" || (g_surv_freeze && self.deadflag == DEAD_FREEZE)) {
				self.classname = "player";
				client_put();
			}
		}
	}
	sound_play2all("domination/claim.wav");
	self = oldself;
}

float() survive_check_next_wave {
	string wave_ind_str = ftos(wave_number + 1);
	if (find(world, targetname, strcat("wave", wave_ind_str)))
		return TRUE;

	if (find(world, targetname, strcat("waveto", wave_ind_str)))
		return TRUE;

	return FALSE;
}

float survive_last_countdown;
float(float ignore, float ignore2) survive_winning_condition {
	if (time < map_starttime)
		return FALSE;

	//print("survive_WinningCondition()\n");
	entity e, oldself, monster;
	if (wave_not_found) {
		CLIENT_FOR_EACH(e)
			e.winning = TRUE;

		survive_map_finished_message = "^2All enemies destroyed!\n^2You successfully survived\n";
		e = find(world, targetname, "survive_success");
		if (e) {
			oldself = self;
			self = e;
			activator = world;
			other = world;
			if (self.use)
				self.use();
			self = oldself;
		}
		return TRUE;
	}
	if (survive_active)
	if not(survive_has_alive_players()) {
		survive_map_finished_message = "^1No alive players left!\n^1Nobody survived\n";
		return TRUE;
	}
	monster = find(world, classname, "monster");
	if not(monster)
	for (e = world; (e = find(e, targetname, survive_wave_string()));) {
		if (strstrofs(e.classname, "_spawn", 0) > 0)
		if (e.nextthink) {
			monster = e;
			break;
		}
	}
	float i;
	for (i = 1; !monster && i <= wave_number; i++)
	for (e = world; (e = find(e, targetname, strcat("wavefrom", ftos(i)))); ) {
		if (strstrofs(e.classname, "_spawn", 0) > 0)
		if (e.nextthink) {
			monster = e;
			break;
		}
	}
	for (i = wave_number; !monster && i >= 1; i--)
	for (e = world; (e = find(e, targetname, strcat("waveto", ftos(i)))); ) {
		if (strstrofs(e.classname, "_spawn", 0) > 0)
		if (e.nextthink) {
			monster = e;
			break;
		}
	}
	if not(monster) {
		if (survive_check_next_wave())
			survive_plan();
		else
			wave_not_found = TRUE;
	}
	if (survive_plan_entity) {
		if not(survive_has_players()) {
			game_status_set(strcat(survive_wave_prefix, "\n^2Awaiting players..."), 1, "", "", "");
			survive_plan_entity.nextthink = time + g_surv_wave_pause;
		} else {
			float countdown = ceil(survive_plan_entity.nextthink - time);
			if (countdown > 0)
			if (survive_last_countdown != countdown) {
				game_status_set(strcat(survive_wave_prefix, "\n^3New wave starts in {1} seconds"), 1, ftos(countdown), "", "");
				if (countdown <= 3)
					sound_play2all(strcat("announcer/robotic/", ftos(countdown), ".wav"));

				survive_last_countdown = countdown;
			}
		}
	}
	return FALSE;
}

void(entity attacker) survive_monster_killed {
	if (attacker.classname == "player") {
		score_player_add(attacker, SP_SCORE, self.frags);
		score_team_add_to(attacker.team, ST_SCORE, self.frags);
	}
}

float() survive_monster_quant {
	return _survive_monster_quant;
}

void(void) spawnfunc_survive_wave {
	self.use = stdproc_nothing;
}

float() survive_ice_skip_think {
	return !survive_active;
}

var void(entity unfrozer) survive_ice_unfroze_next;
void(entity unfrozer) survive_ice_unfroze {
	survive_ice_unfroze_next(unfrozer);
	score_player_set(self.owner, SP_STATUS, 0);
	if (unfrozer.classname == "player") {
		score_player_add(unfrozer, SP_SCORE, 1);
		score_player_add(unfrozer, FREEZE_SHARED_SCORE_REVIVE, 1);
	}
}

void() survive_ice_frozen_status {
	score_player_set(self, SP_STATUS, 1);
}

float(entity attacker, entity inflictor, float deathtype) survive_death_handle {
	survive_ice_frozen_status();
	return FALSE;
}

string(string s) survive_map_finish_message_mod {
	return survive_map_finished_message;
}

void survive_init_delayed() {
	if (g_surv_freeze) {
		plugin_ice_skip_think = survive_ice_skip_think;
		plugin_ice_skip_death_handle = survive_ice_skip_think;
		survive_ice_unfroze_next = plugin_chain_ice_unfroze;
		plugin_chain_ice_unfroze = survive_ice_unfroze;
		plugin_ice_frozen_status = survive_ice_frozen_status;
		ice_init();
	} else {
		plugin_player_death_handle = survive_death_handle;
	}
}

void survive_init() {
	team_teams_set_count(1);
	survive_map_finished_message = "^3No time left, game finished";
	precache_sound("domination/claim.wav");
	precache_sound("announcer/robotic/begin.wav");
	precache_sound("announcer/robotic/3.wav");
	precache_sound("announcer/robotic/2.wav");
	precache_sound("announcer/robotic/1.wav");
	CVAR_CACHE(g_surv_freeze);
	entity_initialize(world, survive_init_delayed, INITPRIO_GAMETYPE);
	_survive_monster_quant = 1;
	plugin_winning_condition = survive_winning_condition;
	plugin_map_finish_message_mod = survive_map_finish_message_mod;
	plugin_score_winning_condition_countdown = stub_score_winning_condition_countdown;
	plugin_monster_quant = survive_monster_quant;
	plugin_monster_killed = survive_monster_killed;
	survive_player_spawn_next = plugin_chain_player_spawn;
	plugin_chain_player_spawn = survive_player_spawn;
	score_basics(SCORE_FLAG_SORT_PRIO_PRIMARY, SCORE_FLAG_SORT_PRIO_PRIMARY, TRUE); // NOTE this assumes that the rogue team is team 3
	SP_STATUS = score_register("status", 0);
	if (g_surv_freeze)
		FREEZE_SHARED_SCORE_REVIVE = score_register("revs", SCORE_FLAG_SORT_PRIO_SECONDARY);

	CVAR_CACHE(g_surv_wave_pause);
	g_surv_monster_factor = bound(0, cvar("g_surv_monster_factor"), 1);
	wave_number = cvar("g_surv_wave_skip");
}
