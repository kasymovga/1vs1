float g_antilag_bullets;
float g_antilag_bullets_time;
float g_ballistics_mindistance;
float g_ballistics_materialconstant;

// for railgun damage (hitting multiple enemies)
.float railgunhit;
.float railgunhitsolidbackup;
.vector railgunhitloc;
.entity railgunhittransform;

float(float mindist, float maxdist, float halflifedist, float d) bullet_exponential_falloff {
	if (halflifedist > 0)
		return pow(0.5, (bound(mindist, d, maxdist) - mindist) / halflifedist);
	else if (halflifedist < 0)
		return pow(0.5, (bound(mindist, d, maxdist) - maxdist) / halflifedist);
	else
		return 1;
}

entity bullet_railgun_projectile;
void(vector start, vector end, float bdamage, float bforce, float mindist, float maxdist, float halflifedist, float forcehalflifedist, float deathtype) bullet_railgun {
	entity oldself = self;
	vector hitloc, endpoint, dir;
	entity ent, endent;
	float endq3surfaceflags;
	float f, ffs;
	self = akimbo_owner(self);
	if (g_projectile_use_clipgroup)
		bullet_railgun_projectile.clipgroup = self.clipgroup;

	if (entity_per_player_entities)
		bullet_railgun_projectile.existsonlyfor = self;

	bullet_railgun_projectile.owner = akimbo_owner(self);
	dir = normalize(end - start);
	// go a little bit into the wall because we need to hit this wall later
	end = end + dir;
	// trace multiple times until we hit a wall, each obstacle will be made
	// non-solid so we can hit the next, while doing this we spawn effects and
	// note down which entities were hit so we can damage them later
	while (1) {
		warpzone_trace_line(start, end, FALSE, bullet_railgun_projectile);
		// if it is world we can't hurt it so stop now
		if (trace_ent == world || trace_fraction == 1)
			break;

		// make the entity non-solid so we can hit the next one
		trace_ent.railgunhit = TRUE;
		trace_ent.railgunhitloc = trace_endpos;
		trace_ent.railgunhittransform = spawn();
		trace_ent.railgunhittransform.warpzone_shift = warpzone_trace_transform.warpzone_shift;
		trace_ent.railgunhittransform.warpzone_transform = warpzone_trace_transform.warpzone_transform;
		trace_ent.railgunhitsolidbackup = trace_ent.solid;
		// stop if this is a wall
		if (trace_ent.solid == SOLID_BSP)
			break;

		// make the entity non-solid
		trace_ent.solid = SOLID_NOT;
	}
	endpoint = trace_endpos;
	endent = trace_ent;
	endq3surfaceflags = trace_dphitq3surfaceflags;
	// find all the entities the railgun hit and restore their solid state
	for (ent = findfloat(NULL, railgunhit, TRUE); ent; ent = findfloat(ent, railgunhit, TRUE)) {
		// restore their solid type
		ent.solid = ent.railgunhitsolidbackup;
	}
	// find all the entities the railgun hit and hurt them
	for (ent = findfloat(NULL, railgunhit, TRUE); ent; ent = findfloat(ent, railgunhit, TRUE)) {
		// get the details we need to call the damage function
		hitloc = ent.railgunhitloc;
		ent.railgunhitloc = '0 0 0';
		ent.railgunhitsolidbackup = SOLID_NOT;
		ent.railgunhit = FALSE;
		//for stats so that team hit will count as a miss
		bullet_from = warpzone_transform_origin(ent.railgunhittransform, start);
		bullet_to = warpzone_transform_origin(ent.railgunhittransform, end);
		remove(ent.railgunhittransform);
		ent.railgunhittransform = NULL;
		f = bullet_exponential_falloff(mindist, maxdist, halflifedist, vlen(ent.origin - bullet_from));
		ffs = bullet_exponential_falloff(mindist, maxdist, forcehalflifedist, vlen(ent.origin - bullet_from));
		// apply the damage
		if (ent.takedamage) {
			float d = bdamage * f;
			weapon_score_hits(self, ent, deathtype, 1, d);
			damage(ent, self, self, d, deathtype, hitloc, normalize(bullet_to - bullet_from) * bforce * ffs);
		}
	}
	trace_endpos = endpoint;
	trace_ent = endent;
	trace_dphitq3surfaceflags = endq3surfaceflags;
	self = oldself;
}

.float dmg_edge;
.float dmg_force;
.float dmg_radius;
void(void) bullet_hit {
	float f;
	f = pow(bound(0, vlen(self.velocity) / vlen(self.oldvelocity), 1), 2); // energy multiplier
	if (other && other != self.enemy && other.takedamage) {
		effect_curveparticles_end();
		damage_headshot = 0;
		damage_yoda = 0;
		damage_headshotbonus = self.dmg_edge;
		bullet_from = self.origin - 0.1 * self.velocity;
		bullet_to = self.origin + 0.1 * self.velocity;
		float d = self.dmg * f;
		weapon_score_hits(self.owner, other, self.projectiledeathtype, 1, d);
		damage(other, self, self.owner, d, self.projectiledeathtype, self.origin, self.dmg_force * normalize(self.velocity) * f);
		damage_headshotbonus = 0;
		if (self.dmg_edge != 0) {
			if (damage_headshot)
				announce(self.owner, "announcer/male/headshot.wav", "^1Head^3Shot");

			if (damage_yoda)
				announce(self.owner, "announcer/male/awesome.wav", "^5Awesome");
		}
	}
	if (other.solid == SOLID_BSP) {
		effect_curveparticles_end();
		effect_impact(self.origin, self.dmg * f, 0, 0, max(1, self.dmg_force) * normalize(self.velocity) * f, self.species, self);
	}
	self.enemy = other; // don't hit the same player twice with the same bullet
}

void(void) bullet_leave_solid_think {
	setorigin(self, self.pos1);
	self.velocity = self.pos2;
	self.think = stdproc_remove;
	self.nextthink = max(time, self.cnt);
	self.flags &= ~FL_ONGROUND;
	if (self.enemy.solid == SOLID_BSP) {
		float f;
		f = pow(bound(0, vlen(self.velocity) / vlen(self.oldvelocity), 1), 2); // energy multiplier
		effect_impact(self.origin, 0, 0, 0, max(1, self.dmg_force) * normalize(self.velocity) * -f, self.species, self);
	}
	projectile_update(self);
}

float(entity e, vector vel, float constant) bullet_leave_solid {
	// move the entity along its velocity until it's out of solid, then let it resume
	float dt, dst, velfactor, v0, vs;
	float maxdist;
	float E0_m, Es_m;
	// E(s) = E0 - constant * s, constant = area of bullet circle * material constant / mass
	v0 = vlen(vel);
	E0_m = 0.5 * v0 * v0;
	maxdist = E0_m / constant;
	// maxdist = 0.5 * v0 * v0 / constant
	// dprint("max dist = ", ftos(maxdist), "\n");
	if (maxdist <= g_ballistics_mindistance)
		return 0;

	vector dir = normalize(vel);
	vector v = self.origin + normalize(vel) * maxdist;
	vector org = self.origin + dir;
	float i;
	for (i = 1; i < 4; i++) {
		trace_line(org, v, TRACE_MOVE_NORMAL, self);
		if (trace_fraction > 0)
			break;

		org = org + dir;
	}
	if (trace_startsolid) {
		trace_line(trace_endpos, self.origin, TRACE_MOVE_NORMAL, self);
		if (trace_fraction == 1) {// 1: we never got out of solid
			return 0;
		}
	} else
		trace_endpos = org;

	self.pos1 = trace_endpos;
	dst = vlen(trace_endpos - self.origin);
	// E(s) = E0 - constant * s, constant = area of bullet circle * material constant / mass
	Es_m = E0_m - constant * dst;
	if (Es_m <= 0) {
		// roundoff errors got us
		return 0;
	}
	vs = sqrt(2 * Es_m);
	velfactor = vs / v0;
	dt = dst / (0.5 * (v0 + vs));
	// this is not correct, but the differential equations have no analytic
	// solution - and these times are very small anyway
	//print("dt = ", ftos(dt), "\n");
	self.cnt = self.nextthink;
	self.think = bullet_leave_solid_think;
	self.nextthink = time + dt;
	vel = vel * velfactor;
	self.velocity = '0 0 0';
	self.flags |= FL_ONGROUND; // prevent moving
	self.pos2 = vel;
	return 1;
}

void(void) bullet_touch {
	if (self.think == bullet_leave_solid_think) // skip this!
		return;

	PROJECTILE_TOUCH;
	bullet_hit();
	// go through solid!
	if (!bullet_leave_solid(self, self.velocity, self.dmg_radius)) {
		remove(self);
		return;
	}
	self.projectiledeathtype |= HITTYPE_BOUNCE;
}

float bullet_hit_scan;
float bullet_projectile;
void() bullet_end {
	effect_curveparticles_end();
	if (bullet_hit_scan) {
		antilag_end();
	}
}

entity bullet_trace_callback_ent;
float bullet_trace_callback_eff;
void(vector start, vector hit, vector end) bullet_trace_callback {
	if (vlen(hit - start) > 16) {
		if (bullet_trace_callback_ent.wframe) {
			bullet_trace_callback_ent.wframe = 0;
			effect_curveparticles_from_tracetoss(bullet_trace_callback_eff, warpzone_transform_origin(warpzone_trace_transform, bullet_trace_callback_ent.oldorigin), hit, bullet_trace_callback_ent.velocity);
		} else
			effect_curveparticles_from_tracetoss(bullet_trace_callback_eff, start, hit, bullet_trace_callback_ent.velocity);
	}
}

void(float pSpeed, float projectiletype, float traceeffects) bullet_begin {
	bullet_hit_scan = (g_antilag_bullets && pSpeed >= g_antilag_bullets);
	bullet_projectile = projectiletype;
	bullet_trace_callback_eff = traceeffects;
	if (bullet_hit_scan) {
		entity o = akimbo_owner(self);
		antilag_begin(o);
	}
}

void(vector start, vector start_visual, vector dir, float spread, float pSpeed, float lifetime, float _damage, float headshotbonus, float force, float impacttype, float dtype, float gravityfactor, float bulletconstant) bullet {
	entity oldself, oldself_akimbo = self;
	entity proj;
	if (bullet_hit_scan && g_antilag_bullets_time <= 0) {
		proj = spawn();
		self = akimbo_owner(self);
		proj.owner = self;
		if (g_projectile_use_clipgroup)
			proj.clipgroup = self.clipgroup;

		if (entity_per_player_entities && self) {
			if (clienttype(self) == CLIENTTYPE_NOTACLIENT)
				proj.existsonlyfor = self.existsonlyfor;
			else
				proj.existsonlyfor = self;
		}
	} else {
		proj = projectile(TRUE, bullet_projectile, TRUE, self);
		proj.classname = "bullet";
		proj.think = stdproc_remove;
		proj.nextthink = time + lifetime - g_antilag_bullets_time; // min(pLifetime, vlen(world.maxs - world.mins) / pSpeed);
		proj.touch = bullet_touch;
	}
	projectile_setup(proj, start, impacttype, dtype, _damage, headshotbonus, g_ballistics_materialconstant / bulletconstant, force, gravityfactor, (gravityfactor ? MOVETYPE_TOSS : MOVETYPE_FLY));
	proj.velocity = (dir + randomvec() * spread) * pSpeed;
	weapon_setup_projectile_velocity(proj);
	proj.oldvelocity = proj.velocity;
	oldself = self;
	if (bullet_hit_scan) {
		proj.oldorigin = start_visual;
		proj.wframe = 1;
		self = proj;
		float i;
		float hit_scan_time;
		float checks;
		float proj_remove;
		if (g_antilag_bullets_time > 0) {
			hit_scan_time = g_antilag_bullets_time;
			checks = 1;
			proj_remove = FALSE;
		} else {
			hit_scan_time = lifetime;
			checks = 100;
			proj_remove = TRUE;
		}
		for (i = 0; i < checks; i++) {
			bullet_trace_callback_ent = self;
			if (proj.gravity) {
				warpzone_trace_toss_trough_zone(self, oldself, hit_scan_time / 200, 200, NULL, (bullet_trace_callback_eff >= 0 ? bullet_trace_callback : NULL)); // life time distance
				self.velocity = warpzone_trace_toss_velocity;
			} else {
				warpzone_trace_line_trough_zone(self.origin, start + proj.velocity * hit_scan_time, FALSE, self, world, bullet_trace_callback); // life time distance
				self.velocity = warpzone_transform_velocity(warpzone_trace_transform, self.velocity);
			}
			if (trace_fraction == 1) {
				if not(proj_remove) setorigin(self, trace_endpos);
				break; // won't hit anything anytime soon
			}
			setorigin(self, trace_endpos);
			other = trace_ent;
			if (!PROJECTILE_OWNER_CHECK()) {
				if (projectile_no_impact_check()) {
					proj_remove = TRUE;
					break;
				}
				// hit the player
				bullet_hit();
			}
			// go through solid!
			if (other && other.armorvalue > 0) {
				proj_remove = TRUE;
				break;
			}
			if (!bullet_leave_solid(self, self.velocity, self.dmg_radius)) {
				proj_remove = TRUE;
				break;
			}
			bullet_leave_solid_think();
		}
		if (proj_remove)
			remove(proj);
	}
:finish
	self = oldself_akimbo;
}

void bullet_init(void) {
	CVAR_CACHE(g_ballistics_materialconstant);
	CVAR_CACHE(g_ballistics_mindistance);
	CVAR_CACHE(g_antilag_bullets);
	CVAR_CACHE(g_antilag_bullets_time);
	if not(bullet_railgun_projectile)
		bullet_railgun_projectile = spawn();
}
