void(void) rm_init {
	rm_active = cvar("rm");
	if not(rm_active) return;
	print("RM mode active\n");
	dlc_require("rm_ui");
	dlc_require("rm_skins");
}

entity rm_findfilter(entity e, float(entity) filter) {
	for (;(e = nextent(e));)
		if (filter(e))
			return e;

	return NULL;
}


/*
void(entity targ, entity healer, float heal) rm_heal_score {
	if(targ == healer || targ.classname != "player")
		return;

	PlayerScore_Add(healer, SP_HEALING, heal);
	PlayerScore_Add(healer, SP_SCORE, heal * cvar(strcat("g_healing_score_", gametype_ID_to_Name(game))));
}
*/

.entity heal_emitter;
float(entity to, float sf) rm_effect_heal_emitter_send {
	net_write_byte(MSG_ENTITY, NET_CSQC_RM_EFFECT_HEAL_EMITTER);
	net_write_int24(MSG_ENTITY, self.origin_x);
	net_write_int24(MSG_ENTITY, self.origin_y);
	net_write_int24(MSG_ENTITY, self.origin_z);
	return TRUE;
}

float(void) rm_effect_heal_emitter_customize {
	if (other == self.owner || (team_mode && other.team == self.owner.team))
		return TRUE;

	return FALSE;
}

void(void) rm_effect_heal_emitter_think {
	if (wasfreed(self.enemy) || self.enemy.heal_emitter != self || !RM_BUFFS_PRESENT(self.owner, RM_BUFFS_MEDIC)) {
		remove(self);
		return;
	}
	self.nextthink = time;
	self.oldorigin = self.origin;
	setorigin(self, ENTITY_CENTER(self.enemy));
	if (self.origin != self.oldorigin) {
		self.SendFlags |= 1;
	}
}

void(entity e, entity own) rm_effect_heal_emitter {
	if not(RM_BUFFS_PRESENT(own, RM_BUFFS_MEDIC)) return;
	entity emitter = spawn();
	emitter.owner = own;
	emitter.enemy = e;
	e.heal_emitter = emitter;
	setorigin(emitter, ENTITY_CENTER(e));
	self.oldorigin = self.origin;
	emitter.think = rm_effect_heal_emitter_think;
	emitter.nextthink = time;
	net_link_entity(emitter, FALSE, 0, rm_effect_heal_emitter_send);
}

void(entity e) rm_effect_heal {
	entity c;
	vector o = e.origin + e.view_ofs;
	FOR_EACH_REALCLIENT(c) if(c != e && c.enemy != e) {
		if (c.classname == "player")
		if (team_is_different_teams(c, e))
		if (e.hg_stealth || player_alpha(e, c) < 0.15)
			continue;

		msg_entity = c;
		net_write_byte(MSG_ONE, SVC_TEMPENTITY);
		net_write_byte(MSG_ONE, NET_TE_CSQC_RM_EFFECT_HEAL);
		net_write_coord(MSG_ONE, o_x);
		net_write_coord(MSG_ONE, o_y);
		net_write_coord(MSG_ONE, o_z);
	}
}

.float heal_next_particle;
float(entity targ, entity inflictor, entity healer, float heal, float aheal, float hlimit, float alimit, float healtype, float pauserot, float pausearot, vector hitloc, vector force) rm_heal {
	if (targ.classname == "player") {
		if(hlimit)
			hlimit = min(g_balance_health_limit, hlimit);
		else
			hlimit = g_balance_health_limit;

		if (alimit)
			alimit = min(g_balance_armor_limit,  alimit);
		else
			alimit = g_balance_armor_limit;

		#if 0
		if(g_clanarena) {
			hlimit = min(CVAR(g_clanarena_start_health), hlimit);
			alimit = min(CVAR(g_clanarena_start_armor),  alimit);

			if(healtype != DEATH_HURTTRIGGER)
			if(!(DEATH_HGTYPE(healtype) == HG_LINKER && healtype & HITTYPE_SECONDARY)) {
				float lim = CVAR(g_clanarena_heal_limit);
				hlimit = min(hlimit, lim);
				alimit = min(alimit, lim);
			}
		}
		#endif
	}
	float silent = (healtype == DEATH_RM_ITEM);
	if (pauserot  < 0) pauserot  = g_balance_pause_health_rot;
	if (pausearot < 0) pausearot = g_balance_pause_armor_rot;
	//if (roundstate == ROUNDSTATE_OVER)
	//	heal = aheal = 0;
	//else {
		heal  = max(0, min(heal,  hlimit - targ.health));
		aheal = max(0, min(aheal, alimit - targ.armorvalue));
	//}
	targ.health += heal;
	targ.pauserothealth_finished = max(targ.pauserothealth_finished, time + pauserot);
	targ.armorvalue += aheal;
	targ.pauserotarmor_finished = max(targ.pauserotarmor_finished, time + pausearot);
	if (targ.classname == "player")
		Buffs_ConduitDamage(targ, healer, heal, aheal, healtype, TRUE);

	if (heal || aheal) {
		//float vdtype = VDMG_TYPE_HEAL;
		//if (heal >= 100 || aheal >= 100)
		//	vdtype |= VDMG_TYPE_CRIT;
		//else if (DEATH_ISWEAPON(healtype, WEP_CAMPINGRIFLE) && (healtype & HITTYPE_HEADSHOT))
		//	vdtype |= VDMG_TYPE_CRIT;

		if (healer && clienttype(healer) == CLIENTTYPE_REAL && (targ != healer))
			rm_damage_indicator(healer, hitloc, heal, aheal, RM_DAMAGE_HEAL);

		if (clienttype(targ) == CLIENTTYPE_REAL)
			rm_damage_received_indicator(targ, -0.1 - heal, -0.1 - aheal);

		//rm_heal_score(targ, healer, heal + aheal);
		if not(silent) {
			if (time > targ.heal_next_particle) {
				rm_effect_heal(targ);
				targ.heal_next_particle = time + 0.2;
			}
			if (heal) 
				sound(targ, CHAN_AUTO, "misc/mediumhealth.wav", VOL_BASE, ATTN_NORM);

			if (aheal)
				sound(targ, CHAN_AUTO, "misc/armor10.wav", VOL_BASE, ATTN_NORM);
		}
	}
	// apply push
	if (targ.damageforcescale)
	if (vlen(force)) {
		targ.velocity = targ.velocity + targ.damageforcescale * force;
		//targ.flags &= ~FL_ONGROUND;
	}
	return heal + aheal;
}

float(float bits) rm_randombit {
	if not(bits & (bits-1)) // this ONLY holds for powers of two!
		return bits;

	float n, f, b, r;
	r = random();
	b = 0;
	n = 0;
	for (f = 1; f <= bits; f *= 2) {
		if (bits & f) {
			++n;
			r *= n;
			if (r <= 1)
				b = f;
			else
				r = (r - 1) / (n - 1);
		}
	}
	return b;
}

float(float bits, float k, float error_return) rm_randombits {
	float r;
	r = 0;
	while (k > 0 && bits != r) {
		r += rm_randombit(bits - r);
		--k;
	}
	if (error_return)
		if (k > 0)
			return -1; // all

	return r;
}
