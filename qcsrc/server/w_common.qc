float g_ballistics_mindistance;
float g_ballistics_materialconstant;

void W_GiveWeapon (entity e, float wep, string name)
{
	entity oldself;

	if (!wep)
		return;

	e.weapons = e.weapons | W_WeaponBit(wep);

	oldself = self;
	self = e;

	if (other.classname == "player")
	{
		W_ShowWeaponList(other);
		sprint (other, "You got the ^2");
		sprint (other, name);
		sprint (other, "\n");
	}

	self = oldself;
}

// for railgun damage (hitting multiple enemies)
.float railgunhit;
.float railgunhitsolidbackup;
.vector railgunhitloc;
.vector railgunhitdir;

void FireRailgunBullet (vector start, vector end, float bdamage, float bforce, float mindist, float maxdist, float halflifedist, float forcehalflifedist, float deathtype)
{
	entity oldself = self;
	local vector hitloc, endpoint, dir;
	local entity ent, endent;
	local float endq3surfaceflags;
	//local entity explosion;
	float f, ffs;
	self = Akimbo_Owner(self);

	railgun_start = start;
	railgun_end = end;

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
		trace_ent.railgunhitdir = WarpZone_TransformVelocity(WarpZone_trace_transform, normalize(end - start));
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

	// spawn a temporary explosion entity for RadiusDamage calls
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

		f = ExponentialFalloff(mindist, maxdist, halflifedist, (ent.origin - start) * ent.railgunhitdir);
		ffs = ExponentialFalloff(mindist, maxdist, forcehalflifedist, (ent.origin - start) * ent.railgunhitdir);

		// apply the damage
		if (ent.takedamage) {
			float d = bdamage * f;
			Damage_RecordHits(self, ent, deathtype, 1, d);
			Damage (ent, self, self, d, deathtype, hitloc, ent.railgunhitdir * bforce * ffs);
		}
		// create a small explosion to throw gibs around (if applicable)
		//setorigin (explosion, hitloc);
		//RadiusDamage (explosion, self, 10, 0, 50, world, 300, deathtype);

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
void W_BallisticBullet_Hit (void)
{
	float f;

	f = pow(bound(0, vlen(self.velocity) / vlen(self.oldvelocity), 1), 2); // energy multiplier

	if(other.solid == SOLID_BSP)
		Damage_DamageInfo(self.origin, self.dmg * f, 0, 0, max(1, self.dmg_force) * normalize(self.velocity) * f, self.projectiledeathtype, self);

	if(other && other != self.enemy)
	{
		endzcurveparticles();

		headshot = 0;
		yoda = 0;
		damage_headshotbonus = self.dmg_edge;
		railgun_start = self.origin - 0.1 * self.velocity;
		railgun_end = self.origin + 0.1 * self.velocity;

		float d = self.dmg * f;
		Damage_RecordHits(self.owner, other, self.projectiledeathtype, 1, d);
		Damage(other, self, self.owner, d, self.projectiledeathtype, self.origin, self.dmg_force * normalize(self.velocity) * f);
		damage_headshotbonus = 0;

		if(self.dmg_edge != 0)
		{
			if(headshot)
				announce(self.owner, "announcer/male/headshot.wav");
			if(yoda)
				announce(self.owner, "announcer/male/awesome.wav");
		}
	}

	self.enemy = other; // don't hit the same player twice with the same bullet
}

.void(void) W_BallisticBullet_LeaveSolid_think_save;
.float W_BallisticBullet_LeaveSolid_nextthink_save;
.vector W_BallisticBullet_LeaveSolid_origin;
.vector W_BallisticBullet_LeaveSolid_velocity;

void W_BallisticBullet_LeaveSolid_think()
{
	setorigin(self, self.W_BallisticBullet_LeaveSolid_origin);
	self.velocity = self.W_BallisticBullet_LeaveSolid_velocity;

	self.think = self.W_BallisticBullet_LeaveSolid_think_save;
	self.nextthink = max(time, self.W_BallisticBullet_LeaveSolid_nextthink_save);
	self.W_BallisticBullet_LeaveSolid_think_save = SUB_Null;

	self.flags &~= FL_ONGROUND;

	if(self.enemy.solid == SOLID_BSP)
	{
		float f;
		f = pow(bound(0, vlen(self.velocity) / vlen(self.oldvelocity), 1), 2); // energy multiplier
		Damage_DamageInfo(self.origin, 0, 0, 0, max(1, self.dmg_force) * normalize(self.velocity) * -f, self.projectiledeathtype, self);
	}

	UpdateCSQCProjectile(self);
}

float W_BallisticBullet_LeaveSolid(entity e, vector vel, float constant)
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
		traceline(org, v, MOVE_NORMAL, self);
		if (trace_fraction > 0)
			break;

		org = org + dir;
	}
	if (trace_startsolid) {
		traceline(trace_endpos, self.origin, MOVE_NORMAL, self);
		if(trace_fraction == 1) {// 1: we never got out of solid
			return 0;
		}
	} else
		trace_endpos = org;

	self.W_BallisticBullet_LeaveSolid_origin = trace_endpos;

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

	self.W_BallisticBullet_LeaveSolid_think_save = self.think;
	self.W_BallisticBullet_LeaveSolid_nextthink_save = self.nextthink;
	self.think = W_BallisticBullet_LeaveSolid_think;
	self.nextthink = time + dt;

	vel = vel * velfactor;

	self.velocity = '0 0 0';
	self.flags |= FL_ONGROUND; // prevent moving
	self.W_BallisticBullet_LeaveSolid_velocity = vel;

	return 1;
}

void W_BallisticBullet_Touch (void)
{
	if(self.think == W_BallisticBullet_LeaveSolid_think) // skip this!
		return;

	PROJECTILE_TOUCH;
	W_BallisticBullet_Hit ();

	// go through solid!
	if(!W_BallisticBullet_LeaveSolid(self, self.velocity, self.dmg_radius))
	{
		remove(self);
		return;
	}

	self.projectiledeathtype |= HITTYPE_BOUNCE;
}

float fireBallisticBulletHitScan;
void endFireBallisticBullet()
{
	endzcurveparticles();
	if (fireBallisticBulletHitScan) {
		antilag_end();
	}
}

entity fireBallisticBullet_trace_callback_ent;
float fireBallisticBullet_trace_callback_eff;
void fireBallisticBullet_trace_callback(vector start, vector hit, vector end)
{
	if(vlen(trace_endpos - fireBallisticBullet_trace_callback_ent.origin) > 16)
		zcurveparticles_from_tracetoss(fireBallisticBullet_trace_callback_eff, fireBallisticBullet_trace_callback_ent.origin, trace_endpos, fireBallisticBullet_trace_callback_ent.velocity);
}

void fireBallisticBulletNoGravity_trace_callback(vector start, vector hit, vector end)
{
	endzcurveparticles();
	if(vlen(trace_endpos - fireBallisticBullet_trace_callback_ent.origin) > 16)
		trailparticles(world, fireBallisticBullet_trace_callback_eff, fireBallisticBullet_trace_callback_ent.origin, trace_endpos);
}

void beginFireBallisticBullet(float pSpeed) {
	fireBallisticBulletHitScan = (g_antilag_bullets && pSpeed >= g_antilag_bullets);
	if (fireBallisticBulletHitScan) {
		entity o = Akimbo_Owner(self);
		antilag_begin(o);
	}
}

void fireBallisticBullet(vector start, vector dir, float spread, float pSpeed, float lifetime, float damage, float headshotbonus, float force, float dtype, float tracereffects, float gravityfactor, float bulletconstant)
{
	entity oldself, oldself_akimbo = self;
	self = Akimbo_Owner(self);
	entity proj;
	if(fireBallisticBulletHitScan)
	{
		proj = spawn();
	} else {
		proj = CSQCProjectile(TRUE, PROJECTILE_BULLET, TRUE);
		proj.think = SUB_Remove;
		proj.nextthink = time + lifetime; // min(pLifetime, vlen(world.maxs - world.mins) / pSpeed);
		proj.touch = W_BallisticBullet_Touch;
	}

	proj.classname = "bullet";
	proj.owner = self;
	PROJECTILE_MAKETRIGGER(proj);
	if(gravityfactor > 0)
	{
		proj.movetype = MOVETYPE_TOSS;
		proj.gravity = gravityfactor;
	}
	else
		proj.movetype = MOVETYPE_FLY;
	proj.velocity = (dir + randomvec() * spread) * pSpeed;
	W_SetupProjectileVelocity(proj);
	proj.angles = vectoangles(proj.velocity);
	proj.dmg_radius = g_ballistics_materialconstant / bulletconstant;
	// so: bulletconstant = bullet mass / area of bullet circle
	setorigin(proj, start);
	proj.dmg = damage;
	proj.dmg_edge = headshotbonus;
	proj.dmg_force = force;
	proj.projectiledeathtype = dtype;

	proj.oldvelocity = proj.velocity;

	if(fireBallisticBulletHitScan)
	{
		oldself = self;
		self = proj;

		float i;
		for(i = 0; i < 100; i++)
		{
			fireBallisticBullet_trace_callback_ent = self;
			fireBallisticBullet_trace_callback_eff = tracereffects;
			if (proj.gravity) {
				WarpZone_TraceToss_ThroughZone(self, oldself, 0.125 * 0.05, 200, world, fireBallisticBullet_trace_callback);
				self.velocity = WarpZone_tracetoss_velocity;
			} else {
				WarpZone_TraceLine_ThroughZone(self.origin, start + proj.velocity * 1.25, FALSE, self, world, fireBallisticBulletNoGravity_trace_callback);
				self.velocity = WarpZone_TransformVelocity(WarpZone_trace_transform, self.velocity);
			}

			if(trace_fraction == 1)
				break;
				// won't hit anything anytime soon (DP's
				// tracetoss does 200 tics of, here,
				// 0.05*0.125s, that is, 1.25 seconds

			other = trace_ent;
			setorigin(self, trace_endpos);

			if(!SUB_OwnerCheck())
			{
				if(SUB_NoImpactCheck())
					break;

				// hit the player
				W_BallisticBullet_Hit ();
			}

			// go through solid!
			if(!W_BallisticBullet_LeaveSolid(self, self.velocity, self.dmg_radius))
				break;

			W_BallisticBullet_LeaveSolid_think();
		}
		self = oldself;
		remove(proj);
		self = oldself_akimbo;
		return;
	}
	self = oldself_akimbo;
}


void W_PrepareExplosionByDamage(entity attacker, void() explode)
{
	self.takedamage = DAMAGE_NO;
	self.event_damage = SUB_Null;
	self.owner = attacker;

	// do not explode NOW but in the NEXT FRAME!
	// because recursive calls to RadiusDamage are not allowed
	self.nextthink = time;
	self.think = explode;
}

void W_BallisticInit() {
	CACHE_CVAR(g_ballistics_materialconstant);
	CACHE_CVAR(g_ballistics_mindistance);
}
