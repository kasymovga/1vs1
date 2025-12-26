float g_score_bestweapon;
float WEAPON_SCORE;
.float actual_damage[WEAPON_COUNT_EXTRA]; //amount of damage done

void(entity attacker, float deathtype, float shots) weapon_score_fires {
	float weaponid;
	weaponid = DEATH_WEAPONOF(deathtype);
	if not(warmup_active)
	if (time >= map_starttime)
	if (WEAPON_VALID(weaponid)) {
		// Track damage done and update the stat to be sent later in g_world.qc
		float f = attacker.bullets_fired[weaponid] + shots;
		attacker.(bullets_fired[weaponid]) = f;
		attacker.maxdamage_fired = weaponid + 64 * rint(attacker.bullets_fired[weaponid]);
		entity s = attacker.scorekeeper;
		if (g_score_bestweapon)
		if (s) {
			float bestwep = s.scores[WEAPON_SCORE] & 63;
			if (weaponid == bestwep) {
				f = rint(attacker.bullets_hit[weaponid] * 100 / f) * 64 + weaponid;
				score_player_set(attacker, WEAPON_SCORE, f);
			}
		}
	}
}

void(entity cl) weapon_score_send {
	if (clienttype(cl) != CLIENTTYPE_REAL) return;
	msg_entity = cl;
	float w, fired;
	entity src;
	if (SPECTATOR_IS_SPECTATOR(cl))
		src = SPECTATOR_SPECTATEE(cl);
	else
		src = cl;

	net_write_byte(MSG_ONE, SVC_TEMPENTITY);
	net_write_byte(MSG_ONE, NET_TE_CSQC_WEAPON_SCORE);
	for (w = WEAPON_FIRST; w < WEAPON_COUNT_EXTRA; w++) {
		fired = src.bullets_fired[w];
		if not(fired) continue;
		net_write_byte(MSG_ONE, w);
		net_write_short(MSG_ONE, fired);
		net_write_short(MSG_ONE, src.bullets_hit[w]);
	}
	net_write_byte(MSG_ONE, 0);
}

void(entity attacker, entity targ, float deathtype, float hits, float _damage) weapon_score_hits {
	float weaponid;
	weaponid = DEATH_WEAPONOF(deathtype);
	if (targ.deadflag == DEAD_NO)
	if (targ.iscreature)
	if (targ != attacker)
	if (!team_teams || targ.team != attacker.team)
	if not(warmup_active)
	if (time >= map_starttime)
	if (WEAPON_VALID(weaponid)) {
		// Track damage done and update the stat to be sent later in g_world.qc
		float h = attacker.bullets_hit[weaponid] + hits;
		attacker.(bullets_hit[weaponid]) = h;
		float d = attacker.actual_damage[weaponid] + _damage;
		attacker.(actual_damage[weaponid]) = d;
		entity s = attacker.scorekeeper;
		if (g_score_bestweapon)
		if (s) {
			float bestwep = s.scores[WEAPON_SCORE] & 63;
			if (attacker.actual_damage[bestwep] <= d) {
				float f;
				f = rint(h * 100 / attacker.bullets_fired[weaponid]) * 64 + weaponid;
				score_player_set(attacker, WEAPON_SCORE, f);
			}
		}
		attacker.damage_hits = weaponid + 64 * rint(attacker.bullets_hit[weaponid]);
	}
}

var void(void) weapon_score_score_basics_end_next;
void(void) weapon_score_score_basics_end {
	WEAPON_SCORE = score_register("bestwep", 0);
	weapon_score_score_basics_end_next();
}

void(void) weapon_score_init {
	CVAR_CACHE(g_score_bestweapon);
	if (g_score_bestweapon) {
		weapon_score_score_basics_end_next = plugin_chain_score_basics_end;
		plugin_chain_score_basics_end = weapon_score_score_basics_end;
	}
}
