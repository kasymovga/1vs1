float g_lms_lives;
float g_lms_sphere_damage;
float g_lms_sphere_damage_distance_factor;
float g_lms_sphere_diameter_min;
float g_lms_sphere_diameter_start_indent;
float g_lms_sphere_permutation_interval;
float g_lms_sphere_permutation_damage_increment;
vector g_lms_sphere_color;
float SP_LIVES;
var .float lms_lives;
float lms_someone_died;
entity lms_sphere;
float lms_sphere_diameter_unscaled;
float lms_sphere_diameter_start;
float lms_sphere_diameter;
float lms_sphere_permutations;
vector lms_sphere_origin_start;
vector lms_sphere_origin_end;
#define LMS_ACTIVE() (!warmup_active && time >= map_starttime)

float(void) lms_progress { //1 - begin, 0 - finish
	float tl = cvar("timelimit") * 60;
	float progress = (LMS_ACTIVE() ? bound(0, (map_starttime + tl - time) / tl, 1) : 1);
	return progress;
}

void(void) lms_sphere_update {
	float progress = lms_progress();
	lms_sphere_diameter = g_lms_sphere_diameter_min + (lms_sphere_diameter_start - g_lms_sphere_diameter_min) * progress;
	setorigin(lms_sphere, lms_sphere_origin_start * progress + (1 - progress) * lms_sphere_origin_end);
	lms_sphere.scale = max(lms_sphere_diameter, g_lms_sphere_diameter_min) / lms_sphere_diameter_unscaled;
	lms_sphere.SendFlags |= 18;
}

float(entity to, float sf) lms_sphere_send {
	net_write_byte(MSG_ENTITY, NET_CSQC_LMS_SPHERE);
	sf &= 63;
	net_write_byte(MSG_ENTITY, sf);
	if (sf & 1) {
		net_write_short(MSG_ENTITY, self.modelindex);
		net_write_coord(MSG_ENTITY, lms_sphere_diameter_unscaled);
	}
	if (sf & 2)
		net_write_coord(MSG_ENTITY, self.scale);

	if (sf & 4) {
		net_write_byte(MSG_ENTITY, self.colormod_x * 255);
		net_write_byte(MSG_ENTITY, self.colormod_y * 255);
		net_write_byte(MSG_ENTITY, self.colormod_z * 255);
	}
	if (sf & 8)
		net_write_byte(MSG_ENTITY, self.alpha * 255);

	if (sf & 16) {
		net_write_coord(MSG_ENTITY, self.origin_x);
		net_write_coord(MSG_ENTITY, self.origin_y);
		net_write_coord(MSG_ENTITY, self.origin_z);
	}
	if (sf & 32) {
		net_write_coord(MSG_ENTITY, self.angles_x);
		net_write_coord(MSG_ENTITY, self.angles_y);
		net_write_coord(MSG_ENTITY, self.angles_z);
	}
	return TRUE;
}

void(void) lms_sphere_permutate {
	entity e;
	float progress = lms_progress();;
	if (progress < 0.01 || progress > 0.99) return;
	random_selection_init();
	for (e = NULL; (e = find(e, classname, "info_player_deathmatch")); ) {
		if (e.origin != lms_sphere_origin_end)
		if (lms_sphere_diameter / 2 - vlen(e.origin - lms_sphere.origin) > 50) {
			random_selection_add(e, 0, NULL, 1, 0);
		}
	}
	lms_sphere_permutations++;
	if not(random_selection_chosen_ent) return;
	vector o = random_selection_chosen_ent.origin;
	lms_sphere_origin_start = o + (lms_sphere.origin - o) * (1 / progress);
	lms_sphere_origin_end = o;
}

void(void) lms_sphere_think {
	if (map_finished) return;
	lms_sphere_update();
	self.nextthink = time + 0.1;
	if not(LMS_ACTIVE()) return;
	if (g_lms_sphere_permutation_interval)
	if (time > self.teleport_time) {
		lms_sphere_permutate();
		self.teleport_time = time + g_lms_sphere_permutation_interval;
	}
	entity e, e2;
	float f, r;
	float d;
	self.cnt = self.cnt + 1;
	if (self.cnt >= 10) {
		self.cnt = 0;
		PLAYER_FOR_EACH(e) {
			if (e.deadflag)
				continue;

			e2 = player_entity(e);
			f = vlen(e2.origin - lms_sphere.origin);
			r = lms_sphere_diameter * 0.5;
			d = 0.5 * (g_lms_sphere_damage * ((f - r) / g_lms_sphere_damage_distance_factor) + g_lms_sphere_permutation_damage_increment * lms_sphere_permutations);
			if (f > r) {
				print_to_spec(e, PRINT_CENTER, "Return to fight area immediately!", "", "", "");
				fire_add_damage(e2, NULL, d, 2, DEATH_FIRE);
				damage(e2, NULL, NULL, d, DEATH_FIRE, ENTITY_CENTER(e), '0 0 0');
			}
		}
	}
}

void(void) lms_sphere_setup {
	lms_sphere = spawn();
	setmodel(lms_sphere, "models/sphere/sphere.md3");
	lms_sphere_diameter_unscaled = lms_sphere.maxs_x - lms_sphere.mins_x;
	lms_sphere.colormod = g_lms_sphere_color;
	random_selection_init();
	entity e;
	entity spawns = findchain(classname, "info_player_deathmatch");
	vector _maxs = spawns.origin, _mins = spawns.origin;
	for (e = spawns; e; e = e.chain) {
		if (e.origin_x > _maxs_x) _maxs_x = e.origin_x;
		if (e.origin_y > _maxs_y) _maxs_y = e.origin_y;
		if (e.origin_z > _maxs_z) _maxs_z = e.origin_z;
		if (e.origin_x < _mins_x) _mins_x = e.origin_x;
		if (e.origin_y < _mins_y) _mins_y = e.origin_y;
		if (e.origin_z < _mins_z) _mins_z = e.origin_z;
		random_selection_add(e, 0, NULL, 1, 0);
	}
	lms_sphere_origin_start = (_maxs + _mins) * 0.5;
	lms_sphere_origin_end = random_selection_chosen_ent.origin;
	float max_distance = 0, f;
	for (e = spawns; e; e = e.chain) {
		f = vlen(e.origin - lms_sphere_origin_start);
		if (f > max_distance)
			max_distance = f;
	}
	lms_sphere_diameter_start = lms_sphere_diameter = (max_distance * 2) + g_lms_sphere_diameter_start_indent;
	lms_sphere_update();
	lms_sphere.think = lms_sphere_think;
	lms_sphere.nextthink = time + 0.1;
	lms_sphere.teleport_time = time + g_lms_sphere_permutation_interval;
	net_link_entity(lms_sphere, FALSE, 0, lms_sphere_send);
}

var void(entity spot) lms_player_spawn_next;
void lms_player_spawn(entity spot) {
	lms_player_spawn_next(spot);
	if not(LMS_ACTIVE())
		return;

	self.team = 666; //fake team for spectating players
	if (self.scorekeeper.lms_lives > 0)
		return;

	score_player_set(self, SP_STATUS, 1);
	self.killcount = -666; //Prevent bprint
	spectator_observer_spawn(FALSE);
	self.killcount = 0; //prevent possible score clear by join
	lms_someone_died = TRUE;
}

var float(void) lms_spectator_to_player_handle_next;
float(void) lms_spectator_to_player_handle {
	if (LMS_ACTIVE()) {
		if (g_lms_lives <= 0)
			return TRUE;

		score_player_set(self, SP_LIVES, g_lms_lives);
		self.killcount = 0; //Prevent score reset
	}
	return lms_spectator_to_player_handle_next();
}

float(entity attacker, entity inflictor, float deathtype) lms_player_death_handle {
	if (LMS_ACTIVE()) {
		score_player_add(self, SP_LIVES, -1);
		if (self.scorekeeper.lms_lives <= 0)
			score_player_set(self, SP_STATUS, 1);

		g_lms_lives = min(g_lms_lives, max(0, self.scorekeeper.lms_lives));
		if (attacker)
		if (attacker.classname == "player")
		if (attacker != self)
			lms_someone_died = TRUE;
	}
	return FALSE;
}

var void(void) lms_client_connect_next;
void(void) lms_client_connect {
	score_player_set(self, SP_LIVES, g_lms_lives);
	if (LMS_ACTIVE()) {
		entity e;
		PLAYER_FOR_EACH(e) {
			if (e.classname == "player")
			if (e.scorekeeper.lms_lives < self.scorekeeper.lms_lives)
				score_player_set(self, SP_LIVES, e.scorekeeper.lms_lives);
		}
	}
	lms_client_connect_next();
}

float(float ignore, float ignore2) lms_winning_condition {
	if not(LMS_ACTIVE())
		return FALSE;

	entity e;
	float alive_players = 0;
	if not(lms_someone_died)
		return FALSE;

	PLAYER_FOR_EACH(e) {
		if (e.scorekeeper.lms_lives > 0)
			alive_players++;
	}
	if (alive_players < 2)
		return TRUE;

	return FALSE;
}

float(void) lms_forbid_spectators {
	return FALSE;
}

void(void) lms_init_delayed {
	lms_sphere_setup();
}

float(entity spot) lms_spawn_score_good {
	if not(LMS_ACTIVE()) return TRUE;
	float f = vlen(spot.origin - lms_sphere.origin);
	if (f < (lms_sphere_diameter * 0.5) - 40)
		return TRUE;

	return FALSE;
}

float(entity plr, entity item, float f) lms_havocbot_role_goalrating_items_mod {
	vector o = ENTITY_CENTER(item);
	if (vlen(o - lms_sphere.origin) > (lms_sphere_diameter / 2))
		return 0;

	return f;
}

void(void) lms_init {
	lms_player_spawn_next = plugin_chain_player_spawn;
	plugin_chain_player_spawn = lms_player_spawn;
	lms_client_connect_next = plugin_chain_client_connect;
	plugin_chain_client_connect = lms_client_connect;
	lms_spectator_to_player_handle_next = plugin_chain_spectator_to_player_handle;
	plugin_chain_spectator_to_player_handle = lms_spectator_to_player_handle;
	plugin_winning_condition = lms_winning_condition;
	plugin_forbid_specatators = lms_forbid_spectators;
	plugin_player_death_handle = lms_player_death_handle;
	plugin_spawn_score_good = lms_spawn_score_good;
	score_basics(SCORE_FLAG_SORT_PRIO_SECONDARY, SCORE_FLAG_SORT_PRIO_SECONDARY, TRUE);
	SP_STATUS = score_register("status", 0);
	SP_LIVES = score_register("lives", SCORE_FLAG_SORT_PRIO_PRIMARY | SCORE_FLAG_NOCLEAR);
	lms_lives = scores[SP_LIVES];
	plugin_havocbot_role_goalrating_items_mod = lms_havocbot_role_goalrating_items_mod;
	CVAR_CACHE(g_lms_lives);
	CVAR_CACHE(g_lms_sphere_diameter_min);
	CVAR_CACHE(g_lms_sphere_diameter_start_indent);
	CVAR_CACHE(g_lms_sphere_damage);
	CVAR_CACHE(g_lms_sphere_damage_distance_factor);
	CVAR_CACHE(g_lms_sphere_permutation_interval);
	CVAR_CACHE(g_lms_sphere_permutation_damage_increment);
	g_lms_sphere_color = stov(cvar_string("g_lms_sphere_color"));
	precache_model("models/sphere/sphere.md3");
	entity_initialize(NULL, lms_init_delayed, INITPRIO_GAMETYPE);
}

#undef LMS_ACTIVE
