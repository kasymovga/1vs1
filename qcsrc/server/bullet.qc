float g_antilag_bullets;
float g_ballistics_mindistance;
float g_ballistics_materialconstant;

// for railgun damage (hitting multiple enemies)
.float railgunhit;
.float railgunhitsolidbackup;
.vector railgunhitloc;
.entity railgunhittransform;

float(float mindist, float maxdist, float halflifedist, float d) bullet_exponential_falloff {
	if(halflifedist > 0)
		return pow(0.5, (bound(mindist, d, maxdist) - mindist) / halflifedist);
	else if(halflifedist < 0)
		return pow(0.5, (bound(mindist, d, maxdist) - maxdist) / halflifedist);
	else
		return 1;
}


void(vector start, vector end, float bdamage, float bforce, float mindist, float maxdist, float halflifedist, float forcehalflifedist, float deathtype) bullet_railgun {
	entity oldself = self;
	local vector hitloc, endpoint, dir;
	local entity ent, endent;
	local float endq3surfaceflags;
	//local entity explosion;
	float f, ffs;
	self = akimbo_owner(self);
	dir = normalize(end - start);

	// go a little bit into the wall because we need to hit this wall later
	end = end + dir;

	// trace multiple times until we hit a wall, each obstacle will be made
	// non-solid so we can hit the next, while doing this we spawn effects and
	// note down which entities were hit so we can damage them later
	while (1)
	{
		WarpZone_TraceLine(start, end, FALSE, self);

		// if it is world we can't hurt it so stop now
		if (trace_ent == world || trace_fraction == 1)
			break;

		// make the entity non-solid so we can hit the next one
		trace_ent.railgunhit = TRUE;
		trace_ent.railgunhitloc = end;
		trace_ent.railgunhittransform = WarpZone_trace_transform;
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
	ent = findfloat(world, railgunhit, TRUE);
	while (ent)
	{
		// restore their solid type
		ent.solid = ent.railgunhitsolidbackup;
		ent = findfloat(ent, railgunhit, TRUE);
	}

	// spawn a temporary explosion entity for damage_radius calls
	//explosion = spawn();

	// find all the entities the railgun hit and hurt them
	ent = findfloat(world, railgunhit, TRUE);
	while (ent)
	{
		// get the details we need to call the damage function
		hitloc = ent.railgunhitloc;
		ent.railgunhitloc = '0 0 0';
		ent.railgunhitsolidbackup = SOLID_NOT;
		ent.railgunhit = FALSE;

		//for stats so that team hit will count as a miss
		bullet_from = WarpZone_TransformOrigin(ent.railgunhittransform, start);
		bullet_to = WarpZone_TransformOrigin(ent.railgunhittransform, end);

		f = bullet_exponential_falloff(mindist, maxdist, halflifedist, vlen(ent.origin - bullet_from));
		ffs = bullet_exponential_falloff(mindist, maxdist, forcehalflifedist, vlen(ent.origin - bullet_from));

		// apply the damage
		if (ent.takedamage) {
			float d = bdamage * f;
			damage_record_hits(self, ent, deathtype, 1, d);
			damage(ent, self, self, d, deathtype, hitloc, normalize(bullet_to - bullet_from) * bforce * ffs);
		}
		// create a small explosion to throw gibs around (if applicable)
		//setorigin (explosion, hitloc);
		//damage_radius (explosion, self, 10, 0, 50, world, 300, deathtype);

		// advance to the next entity
		ent = findfloat(ent, railgunhit, TRUE);
	}

	// we're done with the explosion entity, remove it
	//remove(explosion);

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

	if(other.solid == SOLID_BSP)
		damage_info(self.origin, self.dmg * f, 0, 0, max(1, self.dmg_force) * normalize(self.velocity) * f, self.projectiledeathtype, self);

	if(other && other != self.enemy)
	{
		effect_curveparticles_end();

		headshot = 0;
		yoda = 0;
		damage_headshotbonus = self.dmg_edge;
		bullet_from = self.origin - 0.1 * self.velocity;
		bullet_to = self.origin + 0.1 * self.velocity;

		float d = self.dmg * f;
		damage_record_hits(self.owner, other, self.projectiledeathtype, 1, d);
		damage(other, self, self.owner, d, self.projectiledeathtype, self.origin, self.dmg_force * normalize(self.velocity) * f);
		damage_headshotbonus = 0;

		if(self.dmg_edge != 0)
		{
			if(headshot)
				announce(self.owner, "announcer/male/headshot.wav", "^1Head^3Shot");
			if(yoda)
				announce(self.owner, "announcer/male/awesome.wav", "^5Awesome");
		}
	}

	self.enemy = other; // don't hit the same player twice with the same bullet
}

.void(void) bullet_leave_solid_think_save;
.float bullet_leave_solid_nextthink_save;
.vector bullet_leave_solid_origin;
.vector bullet_leave_solid_velocity;

void bullet_leave_solid_think()
{
	setorigin(self, self.bullet_leave_solid_origin);
	self.velocity = self.bullet_leave_solid_velocity;

	self.think = self.bullet_leave_solid_think_save;
	self.nextthink = max(time, self.bullet_leave_solid_nextthink_save);
	self.bullet_leave_solid_think_save = stdproc_nothing;

	self.flags &~= FL_ONGROUND;

	if(self.enemy.solid == SOLID_BSP)
	{
		float f;
		f = pow(bound(0, vlen(self.velocity) / vlen(self.oldvelocity), 1), 2); // energy multiplier
		damage_info(self.origin, 0, 0, 0, max(1, self.dmg_force) * normalize(self.velocity) * -f, self.projectiledeathtype, self);
	}

	projectile_update(self);
}

float bullet_leave_solid(entity e, vector vel, float constant)
{
	// move the entity along its velocity until it's out of solid, then let it resume

	float dt, dst, velfactor, v0, vs;
	float maxdist;
	float E0_m, Es_m;

	// outside the world? forget it
	if(self.origin_x > world.maxs_x || self.origin_y > world.maxs_y || self.origin_z > world.maxs_z || self.origin_x < world.mins_x || self.origin_y < world.mins_y || self.origin_z < world.mins_z)
		return 0;

	// E(s) = E0 - constant * s, constant = area of bullet circle * material constant / mass
	v0 = vlen(vel);

	E0_m = 0.5 * v0 * v0;
	maxdist = E0_m / constant;
	// maxdist = 0.5 * v0 * v0 / constant
	// dprint("max dist = ", ftos(maxdist), "\n");

	if(maxdist <= g_ballistics_mindistance)
		return 0;

	vector dir = normalize(vel);
	vector v = self.origin + normalize(vel) * maxdist;
	vector org = self.origin + dir;
	float i;
	for (i = 1; i < 4; i++) {
		trace_line(org, v, MOVE_NORMAL, self);
		if (trace_fraction > 0)
			break;

		org = org + dir;
	}
	if (trace_startsolid) {
		trace_line(trace_endpos, self.origin, MOVE_NORMAL, self);
		if(trace_fraction == 1) {// 1: we never got out of solid
			return 0;
		}
	} else
		trace_endpos = org;

	self.bullet_leave_solid_origin = trace_endpos;

	dst = vlen(trace_endpos - self.origin);
	// E(s) = E0 - constant * s, constant = area of bullet circle * material constant / mass
	Es_m = E0_m - constant * dst;
	if(Es_m <= 0)
	{
		// roundoff errors got us
		return 0;
	}
	vs = sqrt(2 * Es_m);
	velfactor = vs / v0;

	dt = dst / (0.5 * (v0 + vs));
	// this is not correct, but the differential equations have no analytic
	// solution - and these times are very small anyway
	//print("dt = ", ftos(dt), "\n");

	self.bullet_leave_solid_think_save = self.think;
	self.bullet_leave_solid_nextthink_save = self.nextthink;
	self.think = bullet_leave_solid_think;
	self.nextthink = time + dt;

	vel = vel * velfactor;

	self.velocity = '0 0 0';
	self.flags |= FL_ONGROUND; // prevent moving
	self.bullet_leave_solid_velocity = vel;

	return 1;
}

void(void) bullet_touch {
	if(self.think == bullet_leave_solid_think) // skip this!
		return;

	PROJECTILE_TOUCH;
	bullet_hit();

	// go through solid!
	if(!bullet_leave_solid(self, self.velocity, self.dmg_radius)) {
		remove(self);
		return;
	}

	self.projectiledeathtype |= HITTYPE_BOUNCE;
}

float bulletHitScan;
void() bullet_end {
	effect_curveparticles_end();
	if (bulletHitScan) {
		antilag_end();
	}
}

entity bullet_trace_callback_ent;
float bullet_trace_callback_eff;
void bullet_trace_callback(vector start, vector hit, vector end)
{
	if(vlen(hit - start) > 16)
		effect_curveparticles_from_tracetoss(bullet_trace_callback_eff, bullet_trace_callback_ent.origin, hit, bullet_trace_callback_ent.velocity); //bullet_trace_callback_ent.origin changed by WarpZone_TraceToss_ThroughZone, it's needed for curve particles
}

void bullet_begin(float pSpeed) {
	bulletHitScan = (g_antilag_bullets && pSpeed >= g_antilag_bullets);
	if (bulletHitScan) {
		entity o = akimbo_owner(self);
		antilag_begin(o);
	}
}

void(vector start, vector dir, float spread, float pSpeed, float lifetime, float _damage, float headshotbonus, float force, float dtype, float tracereffects, float gravityfactor, float bulletconstant) bullet {
	entity oldself, oldself_akimbo = self;
	entity proj;
	if(bulletHitScan)
	{
		proj = spawn();
		self = akimbo_owner(self);
		proj.owner = self;
		proj.clipgroup = self.clipgroup;
	} else {
		proj = projectile(TRUE, PROJECTILE_BULLET, TRUE, self);
		proj.classname = "bullet";
		proj.think = stdproc_remove;
		proj.nextthink = time + lifetime; // min(pLifetime, vlen(world.maxs - world.mins) / pSpeed);
		proj.touch = bullet_touch;
	}
	projectile_setup(proj, start, dtype, _damage, headshotbonus, g_ballistics_materialconstant / bulletconstant, force);
	if(gravityfactor > 0) {
		proj.movetype = MOVETYPE_TOSS;
		proj.gravity = gravityfactor;
	} else
		proj.movetype = MOVETYPE_FLY;

	proj.velocity = (dir + randomvec() * spread) * pSpeed;
	weapon_setup_projectile_velocity(proj);
	proj.oldvelocity = proj.velocity;
	if(bulletHitScan)
	{
		oldself = self;
		self = proj;

		float i;
		for(i = 0; i < 100; i++)
		{
			bullet_trace_callback_ent = self;
			bullet_trace_callback_eff = tracereffects;
			if (proj.gravity) {
				WarpZone_TraceToss_ThroughZone(self, oldself, 0.125 * 0.05, 200, world, bullet_trace_callback);
				self.velocity = WarpZone_tracetoss_velocity;
			} else {
				WarpZone_TraceLine_ThroughZone(self.origin, start + proj.velocity * 1.25, FALSE, self, world, bullet_trace_callback);
				self.velocity = WarpZone_TransformVelocity(WarpZone_trace_transform, self.velocity);
			}

			if(trace_fraction == 1)
				break;
				// won't hit anything anytime soon (DP's
				// tracetoss does 200 tics of, here,
				// 0.05*0.125s, that is, 1.25 seconds

			other = trace_ent;
			setorigin(self, trace_endpos);

			if(!PROJECTILE_OWNER_CHECK())
			{
				if(projectile_no_impact_check())
					break;

				// hit the player
				bullet_hit();
			}

			// go through solid!
			if(!bullet_leave_solid(self, self.velocity, self.dmg_radius))
				break;

			bullet_leave_solid_think();
		}
		self = oldself;
		remove(proj);
		self = oldself_akimbo;
		return;
	}
	self = oldself_akimbo;
}

void bullet_init() {
	CVAR_CACHE(g_ballistics_materialconstant);
	CVAR_CACHE(g_ballistics_mindistance);
	CVAR_CACHE(g_antilag_bullets);
}
