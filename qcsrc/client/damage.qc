.float silent;

void Ent_DamageInfo(float isNew)
{
	float hittype;
	float issilent;
	vector force, org;

	hittype = ReadShort();

	issilent = (hittype & 0x8000);
	hittype = (hittype & 0x7FFF);

	org_x = ReadCoord();
	org_y = ReadCoord();
	org_z = ReadCoord();

	force = decompressShortVector(ReadShort());

	self.team = ReadByte();

	if not(isNew)
		return;

	// TODO spawn particle effects and sounds based on hittype

	float hitwep, secondary, bounce, headshot;
	vector org2, backoff;
	float r;

	hitwep = DEATH_WEAPONOFWEAPONDEATH(hittype);
	secondary = hittype & HITTYPE_SECONDARY;
	bounce = hittype & HITTYPE_BOUNCE;
	headshot = hittype & HITTYPE_HEADSHOT;
	r = prandom();

	traceline(org - normalize(force) * 16, org + normalize(force) * 16, MOVE_NOMONSTERS, world);
	if(trace_fraction < 1 && hitwep != WEP_NEX && hitwep != WEP_MINSTANEX)
		backoff = trace_plane_normal;
	else
		backoff = -1 * normalize(force);

	setorigin(self, org + backoff * 2); // for sound() calls

	if(DEATH_ISHG(hittype)) {
		if (!issilent)
			sound(self, CHAN_AUTO, "weapons/grenade_impact.wav", VOL_BASE, ATTN_NORM);

		hittype &~= DEATH_HITTYPEMASK;
		switch (hittype)
		{
			case HG_NORMAL:
			case HG_REMOTE:
			case HG_NAPALM:
			case HG_RAZE:
				pointparticles(particleeffectnum("RM_EXPLOSION"), self.origin, '0 0 0', 1);
				break;

			case HG_PLASMA: case HG_LASER:
				if((hittype == HG_PLASMA && (secondary || bounce)) || hittype == HG_LASER) {
					org2 = org + backoff * 6;
					pointparticles(rm_particleeffectnum_team("RM_HG_PLASMA_SHARD_EXPLODE", self.team, 2 - (hittype == HG_LASER)), org2, '0 0 0', 1);
					if(!issilent)
						sound(self, CHAN_PROJECTILE, "weapons/electro_impact.wav", VOL_BASE, ATTN_NORM);
				} else { // plasma bomb explosion
					org2 = org + backoff * 2;
					pointparticles(rm_particleeffectnum_team("RM_HG_PLASMA_EXPLODE", self.team, 2), org2, '0 0 0', 1);
					if(!issilent)
						sound(self, CHAN_PROJECTILE, "weapons/hookbomb_impact.wav", VOL_BASE, ATTN_NORM);
				}
				break;
			}
	} else switch(hitwep) {
		case WEP_LASER:
			org2 = org + backoff * 6;
			pointparticles(particleeffectnum("laser_impact"), org2, backoff * 1000, 1);
			if(!issilent)
				sound(self, CHAN_PROJECTILE, "weapons/laserimpact.wav", VOL_BASE, ATTN_NORM);
			break;
		case WEP_SHOTGUN:
		case WEP_SUPERSHOTGUN:
			org2 = org + backoff * 2;
			pointparticles(particleeffectnum("shotgun_impact"), org2, backoff * 1000, 1);
			if(!issilent)
			{
				if(r < 0.05)
					sound(self, CHAN_PROJECTILE, "weapons/ric1.wav", VOL_BASE, ATTN_NORM);
				else if(r < 0.1)
					sound(self, CHAN_PROJECTILE, "weapons/ric2.wav", VOL_BASE, ATTN_NORM);
				else if(r < 0.2)
					sound(self, CHAN_PROJECTILE, "weapons/ric3.wav", VOL_BASE, ATTN_NORM);
			}
			break;
		case WEP_UZI:
			org2 = org + backoff * 2;
			pointparticles(particleeffectnum("machinegun_impact"), org2, backoff * 1000, 1);
			if(!issilent)
				if(r < 0.05)
					sound(self, CHAN_PROJECTILE, "weapons/ric1.wav", VOL_BASE, ATTN_NORM);
				else if(r < 0.1)
					sound(self, CHAN_PROJECTILE, "weapons/ric2.wav", VOL_BASE, ATTN_NORM);
				else if(r < 0.2)
					sound(self, CHAN_PROJECTILE, "weapons/ric3.wav", VOL_BASE, ATTN_NORM);
			break;
		case WEP_GRENADE_LAUNCHER:
			org2 = org + backoff * 12;
			pointparticles(particleeffectnum("grenade_explode"), org2, '0 0 0', 1);
			if(!issilent)
				sound(self, CHAN_PROJECTILE, "weapons/grenade_impact.wav", VOL_BASE, ATTN_NORM);
			break;
		case WEP_ELECTRO:
			org2 = org + backoff * 6;
			if(secondary)
			{
				pointparticles(particleeffectnum("electro_ballexplode"), org2, '0 0 0', 1);
				if(!issilent)
					sound(self, CHAN_PROJECTILE, "weapons/electro_impact.wav", VOL_BASE, ATTN_NORM);
			}
			else
			{
				if(bounce)
				{
					// this is sent as "primary bounce" to distinguish it from secondary bounced balls
					pointparticles(particleeffectnum("electro_combo"), org2, '0 0 0', 1);
					if(!issilent)
						sound(self, CHAN_PROJECTILE, "weapons/electro_impact_combo.wav", VOL_BASE, ATTN_NORM);
				}
				else
				{
					pointparticles(particleeffectnum("electro_impact"), org2, '0 0 0', 1);
					if(!issilent)
						sound(self, CHAN_PROJECTILE, "weapons/electro_impact.wav", VOL_BASE, ATTN_NORM);
				}
			}
			break;
		case WEP_CRYLINK:
			org2 = org + backoff * 2;
			if(secondary)
			{
				pointparticles(particleeffectnum("crylink_impact"), org2, '0 0 0', 1);
				if(!issilent)
					sound(self, CHAN_PROJECTILE, "weapons/crylink_impact2.wav", VOL_BASE, ATTN_NORM);
			}
			else
			{
				pointparticles(particleeffectnum("crylink_impactbig"), org2, '0 0 0', 1);
				if(!issilent)
					sound(self, CHAN_PROJECTILE, "weapons/crylink_impact.wav", VOL_BASE, ATTN_NORM);
			}
			break;
		case WEP_NEX:
			org2 = org + backoff * 6;
			pointparticles(particleeffectnum("nex_impact"), org2, '0 0 0', 1);
			if(!issilent)
				sound(self, CHAN_PROJECTILE, "weapons/neximpact.wav", VOL_BASE, ATTN_NORM);
			break;
		case WEP_HAGAR:
			org2 = org + backoff * 6;
			pointparticles(particleeffectnum("hagar_explode"), org2, '0 0 0', 1);
			if(!issilent)
			{
				if (r<0.15)
					sound(self, CHAN_PROJECTILE, "weapons/hagexp1.wav", VOL_BASE, ATTN_NORM);
				else if (r<0.7)
					sound(self, CHAN_PROJECTILE, "weapons/hagexp2.wav", VOL_BASE, ATTN_NORM);
				else
					sound(self, CHAN_PROJECTILE, "weapons/hagexp3.wav", VOL_BASE, ATTN_NORM);
			}
			break;
		case WEP_ROCKET_LAUNCHER:
			org2 = org + backoff * 12;
			pointparticles(particleeffectnum("rocket_explode"), org2, '0 0 0', 1);
			if(!issilent)
				sound(self, CHAN_PROJECTILE, "weapons/rocket_impact.wav", VOL_BASE, ATTN_NORM);
			break;
		case WEP_PORTO:
			print("Since when does Porto send DamageInfo?\n");
			break;
		case WEP_MINSTANEX:
			org2 = org + backoff * 6;
			pointparticles(particleeffectnum("nex_impact"), org2, '0 0 0', 1);
			if(!issilent)
				sound(self, CHAN_PROJECTILE, "weapons/neximpact.wav", VOL_BASE, ATTN_NORM);
			break;
		case WEP_HOOK:
			org2 = org + backoff * 2;
			pointparticles(particleeffectnum("hookbomb_explode"), org2, '0 0 0', 1);
			if(!issilent)
				sound(self, CHAN_PROJECTILE, "weapons/hookbomb_impact.wav", VOL_BASE, ATTN_NORM);
			break;
		case WEP_HLAC:
			org2 = org + backoff * 6;
			pointparticles(particleeffectnum("laser_impact"), org2, backoff * 1000, 1);
			if(!issilent)
				sound(self, CHAN_PROJECTILE, "weapons/laserimpact.wav", VOL_BASE, ATTN_NORM);
			break;
		case WEP_CAMPINGRIFLE:
			org2 = org + backoff * 2;
			pointparticles(particleeffectnum("machinegun_impact"), org2, backoff * 1000, 1);
			if(!issilent)
			{
				if(r < 0.2)
					sound(self, CHAN_PROJECTILE, "weapons/ric1.wav", VOL_BASE, ATTN_NORM);
				else if(r < 0.4)
					sound(self, CHAN_PROJECTILE, "weapons/ric2.wav", VOL_BASE, ATTN_NORM);
				else if(r < 0.5)
					sound(self, CHAN_PROJECTILE, "weapons/ric3.wav", VOL_BASE, ATTN_NORM);
			}
			break;
		case WEP_TUBA:
			break;
		case WEP_FIREBALL:
			if(secondary)
			{
				org2 = org + backoff * 16;
				pointparticles(particleeffectnum("fireball_explode"), org2, '0 0 0', 1);
				if(!issilent)
					sound(self, CHAN_PROJECTILE, "weapons/fireball_impact2.wav", VOL_BASE, ATTN_NORM * 0.25); // long range boom
			}
			else
			{
				// firemine goes out silently
			}
			break;
		default:
			//print("Unhandled damage of weapon ", ftos(hitwep), "\n");
			break;
	}
}

void DamageInfo_Precache()
{
	precache_sound("weapons/crylink_impact2.wav");
	precache_sound("weapons/crylink_impact.wav");
	precache_sound("weapons/electro_impact.wav");
	precache_sound("weapons/electro_impact_combo.wav");
	precache_sound("weapons/grenade_impact.wav");
	precache_sound("weapons/hagexp1.wav");
	precache_sound("weapons/hagexp2.wav");
	precache_sound("weapons/hagexp3.wav");
	precache_sound("weapons/flacexp1.wav");
	precache_sound("weapons/flacexp2.wav");
	precache_sound("weapons/flacexp3.wav");
	precache_sound("weapons/hookbomb_impact.wav");
	precache_sound("weapons/laserimpact.wav");
	precache_sound("weapons/neximpact.wav");
	precache_sound("weapons/ric1.wav");
	precache_sound("weapons/ric2.wav");
	precache_sound("weapons/ric3.wav");
	precache_sound("weapons/rocket_impact.wav");
	precache_sound("weapons/fireball_impact.wav");
	precache_sound("weapons/fireball_impact2.wav");
}

void DamageIndicator_Draw() {
	if (self.alpha <= 0)
		return;

	self.alpha -= frametime / CVAR(cl_damageindicator);
	self.origin_z += frametime * 25;
	vector o = project_3d_to_2d(self.origin);
    if(o_z < 0 || o_x < 0 || o_y < 0 || o_x > CVAR(vid_conwidth) || o_y > CVAR(vid_conheight))
        return;

	o_z = 0;
	drawstring(o, UnboundFromByte(self.cnt), '12 12 0', '1 0.5 0', self.alpha, DRAWFLAG_NORMAL);
}

void Ent_DamageIndicator(float bisnew);

void DamageIndicator_Remove() {
	entity e = spawn();
	e.origin = self.origin;
	e.cnt = self.cnt;
	e.alpha = self.alpha;
	e.draw2d = DamageIndicator_Draw;
	e.draw2dflag = 1;
	e.think = stdproc_remove;
	e.nextthink = time + self.alpha * CVAR(cl_damageindicator);
}

void Ent_DamageIndicator(float bisnew) {
	self.cnt = ReadByte();
	self.origin_x = ReadShort();
	self.origin_y = ReadShort();
	self.origin_z = ReadShort();
	if (CVAR(cl_damageindicator) > 0) {
		self.alpha = 1;
		self.draw2d = DamageIndicator_Draw;
		self.draw2dflag = 1;
		self.entremove = DamageIndicator_Remove;
	}
}
