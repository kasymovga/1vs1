float sv_damageindicator_accumulate_interval;

#define damage_indicator_send damageindicator_send //compatibility with old save-files
float(entity to, float sf) damage_indicator_send {
	net_write_byte(MSG_ENTITY, NET_CSQC_DMG_INDICATOR);
	float _damage = self.dmg + 0.4;
	net_write_byte(MSG_ENTITY, NET_BOUND_TO_BYTE(_damage));
	net_write_short(MSG_ENTITY, self.origin_x);
	net_write_short(MSG_ENTITY, self.origin_y);
	net_write_short(MSG_ENTITY, self.origin_z);
	return TRUE;
}

void(void) damage_indicator_remove {
	entity e;
	float i;
	for (i = 0, e = self.owner; e && i < 7; e = e.dmg_indicator, i++)
		if (e.dmg_indicator == self) {
			e.dmg_indicator = self.dmg_indicator;
			break;
		}

	if (i == 7) //something wrong with chain
		self.owner.dmg_indicator = world;

	remove(self);
}

float(void) damage_indicator_customize {
	if (self.enemy == other)
		return TRUE;

	if (other.classname == "spectator")
		if (other.enemy == self.enemy)
			return TRUE;

	return FALSE;
}

var void(entity targ, entity attacker, float _damage, vector ignore) damage_indicator_damage_force_done_next;
void(entity targ, entity attacker, float _damage, vector ignore) damage_indicator_damage_force_done {
	damage_indicator_damage_force_done_next(targ, attacker, _damage, ignore);
	if (targ == attacker)
		return;

	if (targ.flags & FL_PROJECTILE)
		return;

	entity e;
	float i;
	for (i = 0, e = targ.dmg_indicator; e ;e = e.dmg_indicator, i++) {
		if (i > 5) // too much damage indicators for one entity
			return;

		if (e.enemy == attacker)
			break;
	}
	if not(e) {
		e = spawn();
		e.dmg_indicator = targ.dmg_indicator;
		e.think = damage_indicator_remove;
		e.owner = targ;
		e.enemy = attacker;
		e.customizeentityforclient = damage_indicator_customize;
		net_link_entity(e, FALSE, 0, damage_indicator_send);
		targ.dmg_indicator = e;
	}
	setorigin(e, targ.origin + 0.5 * (targ.maxs + targ.mins));
	e.SendFlags = 1;
	e.dmg = e.dmg + _damage;
	e.nextthink = time + sv_damageindicator_accumulate_interval;
}

void(void) damage_indicator_init {
	if not(cvar("sv_damageindicator"))
		return;

	if (rm_active)
		return;

	CVAR_CACHE(sv_damageindicator_accumulate_interval);
	damage_indicator_damage_force_done_next = plugin_chain_damage_force_done;
	plugin_chain_damage_force_done = damage_indicator_damage_force_done;
}
