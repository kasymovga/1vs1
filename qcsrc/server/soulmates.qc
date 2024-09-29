entity soulmates_controller;
float g_soulmates_players_per_gem;
float soulmates_gems_count1;
float soulmates_gems_count2;
float soulmates_gems_count3;
float soulmates_gems_count4;
.entity soulmates_gem;

vector(float t) soulmates_gem_colormod {
	switch(t) {
	case COLOR_TEAM1:
		return '1 .8 .8';
	case COLOR_TEAM2:
		return '.8 .8 1';
	case COLOR_TEAM3:
		return '1 1 .8';
	case COLOR_TEAM4:
		return '1 .8 1';
	}
	return '.2 .2 .2';
}

vector(float t) soulmates_gem_colormod2 {
	switch(t) {
	case COLOR_TEAM1:
		return '1 .4 .4';
	case COLOR_TEAM2:
		return '.4 .4 1';
	case COLOR_TEAM3:
		return '1 1 .4';
	case COLOR_TEAM4:
		return '1 .4 1';
	}
	return '.1 .1 .1';
}

float(float t) soulmates_gem_glow {
	switch(t) {
	case COLOR_TEAM1:
		return 251;
	case COLOR_TEAM2:
		return 210;
	}
	return 0;
}

entity(entity pl) soulmates_last_attached {
	entity e, last_attached = pl;
	for (;;) {
		PLAYER_FOR_EACH(e) {
			if (e != last_attached)
			if (e.movetype == MOVETYPE_FOLLOW)
			if (e.soulmates_gem)
			if (e.soulmates_gem.aiment)
			if (e.soulmates_gem.aiment.aiment == pl) {
				last_attached = e.soulmates_gem.aiment.aiment;
				break;
			}
		}
		if (last_attached == pl) break;
		pl = last_attached;
	}
	return pl;
}

entity(entity pl) soulmates_first_attached {
	entity e;
	PLAYER_FOR_EACH(e) {
		if (e != pl)
		if (e.movetype == MOVETYPE_FOLLOW)
		if (e.soulmates_gem)
		if (e.soulmates_gem.aiment)
		if (e.soulmates_gem.aiment.aiment == pl)
			return e;
	}
	return NULL;
}

void(void) soulmates_gem_touch {
	if (other.team != self.team) return;
	if (other.classname != "player") return;
	if (PLAYER_DEAD(other)) return;
	if (self.spawnshieldtime > time) return;
	RM_ELSE({
		rm_bigprint_spec(other, "You've got a Soul Gem!", "Collide with a teammate to connect!", 2);
	}, {
		print_to_spec(other, PRINT_CENTER, "You've got a Soul Gem!\nCollide with a teammate to connect!", "", "", "");
	})
	print_all(PRINT_INFO, "{1}^2 picked up a soul gem!", other.netname, "", "");
	entity e;
	CLIENT_FOR_EACH_REAL(e) if (e != other)
		print_to(e, PRINT_CENTER, "{1}^2 picked up a soul gem!", other.netname, "", "");

	other.soulmates_gem = self;
	sound_play2all("kh/capture.wav");
	self.solid = SOLID_NOT;
	self.velocity = '0 0 0';
	self.owner = other;
	setattachment(self, other.body, "");
	setorigin(self, '0 0 0');
}

void(void) soulmates_gem_think {
	self.glow_size = 256 + cos(time * 2) * 64;
	if (self.aiment) {
		setorigin(self.aiment, self.aiment.aiment.origin + '0 0 0.82' * self.aiment.aiment.size_z);
	}
	if (self.owner) {
		vector ang = '0 0 0';
		ang_y = math_mod(time * 90, 360);
		makevectors(ang);
		setorigin(self, v_forward * 64 * sin(time * 5) + 16 * (v_up + v_up * sin(0.5 * time)));
		//self.velocity = '0 0 0';
	}
	self.nextthink = time + (self.owner ? 0 : 0.1);
}

void(entity gem) soulmates_gem_drop {
	if not(gem.owner) return;
	setattachment(gem, NULL, "");
	setorigin(gem, gem.owner.origin + '0 0 35');
	if (self.aiment) {
		if (gem.owner.aiment == gem.aiment && gem.owner.movetype == MOVETYPE_FOLLOW) {
			gem.owner.movetype = MOVETYPE_WALK;
			gem.owner.aiment = NULL;
		}
		remove(gem.aiment);
		gem.aiment = NULL;
	}
	gem.flags &= ~FL_ONGROUND;
	gem.solid = SOLID_TRIGGER;
	gem.movetype = MOVETYPE_TOSS;
	gem.owner.soulmates_gem = NULL;
	gem.owner = NULL;
	gem.spawnshieldtime = time + 1;
}

void(entity gem) soulmates_gem_remove {
	soulmates_gem_drop(gem);
	if (gem.team == COLOR_TEAM1)
		soulmates_gems_count1--;
	else if (gem.team == COLOR_TEAM2)
		soulmates_gems_count2--;
	else if (gem.team == COLOR_TEAM3)
		soulmates_gems_count3--;
	else if (gem.team == COLOR_TEAM4)
		soulmates_gems_count4--;

	remove(gem.enemy);
	remove(gem);
}

void(entity gem) soulmates_gem_place {
	soulmates_gem_drop(gem);
	entity e;
	random_selection_init();
	for (e = NULL; (e = find(e, classname, "info_player_deathmatch")); ) {
		if (e.team == gem.team) {
			random_selection_add(e, 0, NULL, 1, 1);
		}
	}
	if not(random_selection_chosen_ent)
		for (e = NULL; (e = find(e, classname, "info_player_deathmatch")); ) {
			random_selection_add(e, 0, NULL, 1, 1);
		}
	if not(random_selection_chosen_ent) {
		soulmates_gem_remove(gem);
		return;
	}
	setorigin(gem, random_selection_chosen_ent.origin + '0 0 35');
	e = self;
	self = gem;
	entity_droptofloor();
	self = e;
	e.movetype = MOVETYPE_NONE;
}

entity(float t) soulmates_gem_create {
	entity e;
	e = spawn();
	e.classname = "soulmates_gem";
	e.target = "###item###";
	e.team = t;
	e.touch = soulmates_gem_touch;
	e.think = soulmates_gem_think;
	e.nextthink = time + random();
	e.solid = SOLID_TRIGGER;
	e.flags = FL_ITEM;
	//e.reset2 = sm_SoulGem_Reset;
	setmodel(e, "models/runematch/rune.mdl");
	setsize(e, '0 0 -35', '0 0 0');
	e.glow_size = 256;
	e.glow_color = soulmates_gem_glow(t);
	e.glow_trail = 1;
	e.enemy = spawn();
	e.enemy.enemy = e;
	e.enemy.classname = "soulmates_gem_effect";
	setmodel(e.enemy, "models/runematch/curse.mdl");
	e.dphitcontentsmask = (DPCONTENTS_SOLID | DPCONTENTS_BODY | DPCONTENTS_PLAYERCLIP);
	setattachment(e.enemy, e, "");
	e.colormod = soulmates_gem_colormod(t);
	e.enemy.colormod = soulmates_gem_colormod2(t);
	e.alpha = e.enemy.alpha = 0.8;
	e.effects = e.enemy.effects = (EFFECT_ADDITIVE | EFFECT_FULLBRIGHT | EFFECT_LOWPRECISION);
	if (t == COLOR_TEAM1)
		soulmates_gems_count1++;
	else if (t == COLOR_TEAM2)
		soulmates_gems_count2++;
	else if (t == COLOR_TEAM3)
		soulmates_gems_count3++;
	else if (t == COLOR_TEAM4)
		soulmates_gems_count4++;

	return e;
}

void(float before, float after, float t) soulmates_gems_adjust {
	if (before == after) return;
	entity gem;
	if (before < after) {
		soulmates_gem_place(soulmates_gem_create(t));
	} else {
		for (gem = NULL; (gem = find(gem, classname, "soulmates_gem")); ) {
			if (gem.team == t && !gem.owner) break;
		}
		if (gem)
			soulmates_gem_remove(gem);
	}
}

void(void) soulmates_controller_think {
	self.nextthink = time;
	entity pl, pl2, e;
	PLAYER_FOR_EACH(pl) {
		if (pl.soulmates_gem && pl.movetype != MOVETYPE_FOLLOW) {
			PLAYER_FOR_EACH(pl2) {
				if (pl2 != pl && PLAYER_REALLY_ALIVE(pl2) && pl2.movetype != MOVETYPE_FOLLOW && pl.team == pl2.team) {
					if (math_boxes_overlap(pl.absmin - '10 10 10', pl.absmax + '10 10 10', pl2.absmin, pl2.absmax)) {
						pl2 = soulmates_last_attached(pl2);
						pl.movetype = MOVETYPE_FOLLOW;
						pl.velocity = '0 0 0';
						pl.flags |= FL_ONGROUND;
						pl.soulmates_gem.aiment = spawn();
						pl.aiment = pl.soulmates_gem.aiment;
						pl.soulmates_gem.aiment.aiment = pl2;
						setorigin(pl.soulmates_gem.aiment, pl2.origin + pl2.size_z * '0 0 0.82');
						RM_ELSE({
							PLAYER_FOR_EACH(e) if (e.team != pl2.team)
								rm_bigprint_spec(other, "^1Warning!", strcat(pl.netname, " ^7 is now ", pl2.netname, "^7's soulmate!"), 2);
						}, {
							print_all(PRINT_INFO, "{1}^7 is now {2}^7's soulmate!", pl.netname, pl2.netname, "");
						})
						print_to_spec(pl, PRINT_CENTER, "You are now {1}^7's soulmate!", pl2.netname, "", "");
						print_to_spec(pl2, PRINT_CENTER, "{1}^7 is now your soulmate!", pl.netname, "", "");
						sound_play2all("kh/capture.wav");
						goto next_player;
					}
				}
			}
		}
:next_player
	}
	if (time > self.lastshot_time) {
		self.lastshot_time = time + 1;
		float gems1 = 0, gems2 = 0, gems3 = 0, gems4 = 0;
		PLAYER_FOR_EACH(pl) {
			if (pl.team == COLOR_TEAM1)
				gems1++;
			else if (pl.team == COLOR_TEAM2)
				gems2++;
			else if (pl.team == COLOR_TEAM3)
				gems3++;
			else if (pl.team == COLOR_TEAM4)
				gems4++;
		}
		gems1 = floor(gems1 / g_soulmates_players_per_gem);
		gems2 = floor(gems2 / g_soulmates_players_per_gem);
		gems3 = floor(gems3 / g_soulmates_players_per_gem);
		gems4 = floor(gems4 / g_soulmates_players_per_gem);
		soulmates_gems_adjust(soulmates_gems_count1, gems1, COLOR_TEAM1);
		soulmates_gems_adjust(soulmates_gems_count2, gems2, COLOR_TEAM2);
		soulmates_gems_adjust(soulmates_gems_count3, gems3, COLOR_TEAM3);
		soulmates_gems_adjust(soulmates_gems_count4, gems4, COLOR_TEAM4);
	}
}

var void(float killed) soulmates_player_clear_next;
void(float killed) soulmates_player_clear {
	if (self.soulmates_gem)
		soulmates_gem_drop(self.soulmates_gem);

	entity attached = soulmates_first_attached(self);
	if (attached) {
		attached.movetype = MOVETYPE_WALK;
		attached.soulmates_gem.aiment = NULL;
	}
	soulmates_player_clear_next(killed);
}

void(void) soulmates_init {
	if not(team_mode) return;
	if not(cvar("g_soulmates")) return;
	CVAR_CACHE(g_soulmates_players_per_gem);
	precache_model("models/runematch/rune.mdl");
	precache_model("models/runematch/curse.mdl");
	precache_sound("kh/capture.wav");
	soulmates_controller = spawn();
	soulmates_controller.think = soulmates_controller_think;
	soulmates_controller.nextthink = time;
	soulmates_player_clear_next = plugin_chain_player_clear;
	plugin_chain_player_clear = soulmates_player_clear;
}
