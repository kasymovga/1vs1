#define NAPALM_BURN_INTERVAL 0.3

void(void) napalm_touch {
	PROJECTILE_TOUCH;
}

void(void) napalm_burn {
	entity e, o;
	float d,/* ismedic,*/ sameteam;
	vector p;
	float dtype = self.projectiledeathtype;
	float _damage = self.dmg;
	float edgedamage = self.dmg_edge;
	float dist = self.dmg_radius;
	float burntime = self.dmg_force;
	o = self.realowner;
	if (dtype != DEATH_HURTTRIGGER) {
		if (o.classname != "player" || o.team != self.team) {
			remove(self);
			return;
		}
		//ismedic = Buffs_Present(o, BUFF_MEDIC);
	}
	for (e = findradius(self.origin, dist); e; e = e.chain) if(e.takedamage == DAMAGE_AIM) {
		if (dtype != DEATH_HURTTRIGGER && e.classname == "player") {
			sameteam = !team_is_different_teams(o, e);
			if(sameteam && o != e)
				if(!cvar("g_friendlyfire"))
						continue;
		}
		p = e.origin;
		p_x += e.mins_x + random() * (e.maxs_x - e.mins_x);
		p_y += e.mins_y + random() * (e.maxs_y - e.mins_y);
		p_z += e.mins_z + random() * (e.maxs_z - e.mins_z);
		d = vlen(self.origin - p);
		if (d < dist) {
			trace_line(self.origin, p, TRACE_MOVE_NOMONSTERS, self);
			if (trace_fraction < 1)
				continue;

			d = _damage + (edgedamage - _damage) * (vlen(self.origin - p) / dist);
			fire_add_damage(e, o, d * burntime, burntime, dtype);
		}
	}
}

void(void) napalm_think {
	if (time > self.pushltime) {
		remove(self);
		return;
	}
	if (self.waterlevel > 0) {
		remove(self);
		return;
	}
	RM({
		if(self.projectiledeathtype != DEATH_HURTTRIGGER) {
			rm_effect_heal_emitter(self, self.realowner);
		}
	})
	napalm_burn();
	self.nextthink = time + NAPALM_BURN_INTERVAL;
}

entity(entity powner, vector porg, float lifetime, float lifetime_randfactor, float deathtype,
		float burnradius, float burndamage, float burnedgedamage, float burntime) napalm_spawn {
	entity proj = projectile(TRUE, PROJECTILE_HG_NAPALMSHARD, TRUE, powner);
	proj.movetype = MOVETYPE_BOUNCE;
	proj.gravity = 1;
	proj.classname = "napalm";
	proj.projectiledeathtype = deathtype;
	proj.pushltime = time + lifetime + random_2() * lifetime_randfactor;
	proj.effects = EFFECT_NODEPTHTEST;
	proj.bot_dodge = TRUE;
	proj.bot_dodgerating = burndamage + 100;
	proj.dmg_radius = burnradius;
	proj.dmg = burndamage;
	proj.dmg_edge = burnedgedamage;
	proj.dmg_force = burntime;
	//proj.csqcprojectile_extradata = burntime;
	//proj.heal_emitter_radius = burntime;
	proj.touch = napalm_touch;
	proj.think = napalm_think;
	proj.reset = stdproc_remove;
	proj.nextthink = time;
	proj.solid = SOLID_CORPSE;
	setorigin(proj, porg);
	rm_buffs_meodp_point_attach(proj, rm_buffs_meodp_death_remove_multiple);
	return proj;
}

float napalm_init_done;

void(void) napalm_init {
	if (napalm_init_done) {
		return;
	}
	projectile_init(PROJECTILE_HG_NAPALMSHARD);
	dlc_require(DLC_RM_EFFECTS);
	napalm_init_done = TRUE;
}
