entity nadget_scan_chain;
float g_nadgets_scan_stick_lifetime_override;
float g_nadgets_scan_radius;

void(void) nadget_scan_on_remove {
	nadget_GenericProjectile_Remove();
	entity e;
	if (nadget_scan_chain == self)
		nadget_scan_chain = self.enemy;
	else
		for (e = nadget_scan_chain; e.enemy; e = e.enemy) {
			if (e.enemy == self) {
				e.enemy = e.enemy.enemy;
				break;
			}
		}
	sound_stop(self, CHAN_PROJECTILE);
}

float(void) nadget_scan_wave_customize {
	if (team_mode) {
		if (other.team == self.team)
			return TRUE;
	} else if (other == self.owner)
		return TRUE;

	return FALSE;
}

var float(entity plr, entity targ) nadget_scan_PlayerVisibleThroughWallFor_NextLink;
float(entity plr, entity targ) nadget_scan_PlayerVisibleThroughWallFor {
	entity e;
	for (e = nadget_scan_chain; e; e = e.enemy) {
		if (team_mode) {
			if (e.team != targ.team) continue;
		} else {
			if (e.owner == plr) {
				//print(plr.netname, " cannot be visible for ", targ.netname, " because it's owner of scan\n");
				continue;
			}
			if (targ != e.owner) {
				//print(targ.netname, " cannot see ", plr.netname, " because he is not owner of scan\n");
				continue;
			}
		}
		if (vlen(e.origin - plr.origin) > g_nadgets_scan_radius) continue;
		//print(plr.netname, " visible for ", targ.netname, "\n");
		return TRUE;
	}
	return nadget_scan_PlayerVisibleThroughWallFor_NextLink(plr, targ);
}

void(void) nadget_scan_wave_think {
	if (self.scale >= self.cnt) {
		remove(self);
		return;
	}
	self.scale = approach(self.scale, self.cnt, self.speed * frametime);
	setorigin(self, self.origin);
	self.nextthink = time;
}

void(entity inflictor, entity attacker, float _damage, float deathtype, vector hitloc, vector force) nadget_scan_damage {
	if (team_mode) {
		if (attacker.team == self.team)
			return;
	} else if (attacker == self.owner)
		return;

	self.health -= _damage;
	if (self.health < 0)
		stdproc_remove();
}

void(void) nadget_scan_think {
	if (self.movetype == MOVETYPE_FOLLOW || self.movetype == MOVETYPE_NONE) {
		pointparticles(particleeffectnum("crylink_impact"), self.origin, '0 0 0', 1);
		if (time >= self.cnt) {
			entity e;
			e = spawn();
			setmodel(e, "models/ctf/shield.md3");
			setorigin(e, self.origin);
			e.alpha = 0.125;
			e.effects = EFFECT_ADDITIVE | EFFECT_FULLBRIGHT | EFFECT_LOWPRECISION | EFFECT_DOUBLESIDED | EFFECT_NODEPTHTEST;
			setmodel(e, "models/ctf/shield.md3");
			e.cnt = 1000 / e.maxs_x;
			e.customizeentityforclient = nadget_scan_wave_customize;
			e.scale = 0.001;
			e.colormod = '0 2 0';
			//e.glow_color = 0xF5;
			e.nextthink = time;
			e.think = nadget_scan_wave_think;
			e.speed = e.cnt / 2;
			e.owner = self.realowner;
			e.team = self.realowner.team;
			self.cnt = time + 0.8;
		}
	}
	nadget_GenericProjectile_Think();
}

NADGET_HOOKFUNCTION(scan, Init) {
	nadget_scan_PlayerVisibleThroughWallFor_NextLink = plugin_chain_PlayerVisibleThroughWallFor;
	plugin_chain_PlayerVisibleThroughWallFor = nadget_scan_PlayerVisibleThroughWallFor;
	CVAR_CACHE(g_nadgets_scan_stick_lifetime_override);
	CVAR_CACHE(g_nadgets_scan_radius);
	return NADGET_INIT_OK;
}

NADGET_HOOKFUNCTION(scan, Attack) {
	entity gren = nadget_GenericProjectile(NADGET_SCAN, '0 0 0', FALSE);
	gren.think = nadget_scan_think;
	gren.entremove = nadget_scan_on_remove;
	gren.enemy = nadget_scan_chain;
	nadget_scan_chain = gren;
    return NADGET_ATTACK_OK;
}
