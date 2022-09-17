.float silent;

void(float isNew) effect_impact_read {
	float impacttype;
	float issilent;
	vector force, org;
	impacttype = net_read_short();
	issilent = (impacttype & 0x8000);
	impacttype = (impacttype & 0x7FFF);
	org_x = net_read_coord();
	org_y = net_read_coord();
	org_z = net_read_coord();
	force = net_decompress_vec(net_read_short());
	self.team = net_read_byte();
	if not(isNew)
		return;

	// TODO spawn particle effects and sounds based on impacttype
	vector org2, backoff;
	float r;
	r = prandom();
	traceline(org - normalize(force) * 16, org + normalize(force) * 16, TRACE_MOVE_NOMONSTERS, world);
	if (trace_fraction < 1 && impacttype != EFFECT_IMPACT_NEX)
		backoff = trace_plane_normal;
	else
		backoff = -1 * normalize(force);

	setorigin(self, org + backoff * 2); // for sound() calls
	switch (impacttype) {
	case EFFECT_IMPACT_LASER:
		org2 = org + backoff * 6;
		pointparticles(particleeffectnum("laser_impact"), org2, backoff * 1000, 1);
		if (!issilent)
			sound(self, CHAN_PROJECTILE, "weapons/laserimpact.wav", VOL_BASE, ATTN_NORM);

		break;
	case EFFECT_IMPACT_PELLET:
		org2 = org + backoff * 2;
		pointparticles(particleeffectnum("shotgun_impact"), org2, backoff * 1000, 1);
		if (!issilent) {
			if (r < 0.05)
				sound(self, CHAN_PROJECTILE, "weapons/ric1.wav", VOL_BASE, ATTN_NORM);
			else if (r < 0.1)
				sound(self, CHAN_PROJECTILE, "weapons/ric2.wav", VOL_BASE, ATTN_NORM);
			else if (r < 0.2)
				sound(self, CHAN_PROJECTILE, "weapons/ric3.wav", VOL_BASE, ATTN_NORM);
		}
		break;
	case EFFECT_IMPACT_BULLET:
		org2 = org + backoff * 2;
		pointparticles(particleeffectnum("machinegun_impact"), org2, backoff * 1000, 1);
		if (!issilent) {
			if (r < 0.05)
				sound(self, CHAN_PROJECTILE, "weapons/ric1.wav", VOL_BASE, ATTN_NORM);
			else if (r < 0.1)
				sound(self, CHAN_PROJECTILE, "weapons/ric2.wav", VOL_BASE, ATTN_NORM);
			else if (r < 0.2)
				sound(self, CHAN_PROJECTILE, "weapons/ric3.wav", VOL_BASE, ATTN_NORM);
		}
		break;
	case EFFECT_IMPACT_GRENADE:
		org2 = org + backoff * 12;
		pointparticles(particleeffectnum("grenade_explode"), org2, '0 0 0', 1);
		if (!issilent)
			sound(self, CHAN_PROJECTILE, "weapons/grenade_impact.wav", VOL_BASE, ATTN_NORM);

		break;
	case EFFECT_IMPACT_PLASMA_BALL:
		org2 = org + backoff * 6;
		pointparticles(particleeffectnum("electro_ballexplode"), org2, '0 0 0', 1);
		if (!issilent)
			sound(self, CHAN_PROJECTILE, "weapons/electro_impact.wav", VOL_BASE, ATTN_NORM);

		break;
	case EFFECT_IMPACT_PLASMA_COMBO:
		org2 = org + backoff * 6;
		// this is sent as "primary bounce" to distinguish it from secondary bounced balls
		pointparticles(particleeffectnum("electro_combo"), org2, '0 0 0', 1);
		if (!issilent)
			sound(self, CHAN_PROJECTILE, "weapons/electro_impact_combo.wav", VOL_BASE, ATTN_NORM);

		break;
	case EFFECT_IMPACT_PLASMA:
		org2 = org + backoff * 6;
		pointparticles(particleeffectnum("electro_impact"), org2, '0 0 0', 1);
		if (!issilent)
			sound(self, CHAN_PROJECTILE, "weapons/electro_impact.wav", VOL_BASE, ATTN_NORM);

		break;
	case EFFECT_IMPACT_CRYLINK:
		org2 = org + backoff * 2;
		pointparticles(particleeffectnum("crylink_impact"), org2, '0 0 0', 1);
		if (!issilent)
			sound(self, CHAN_PROJECTILE, "weapons/crylink_impact2.wav", VOL_BASE, ATTN_NORM);

		break;
	case EFFECT_IMPACT_CRYLINK_BIG:
		org2 = org + backoff * 2;
		pointparticles(particleeffectnum("crylink_impactbig"), org2, '0 0 0', 1);
		if (!issilent)
			sound(self, CHAN_PROJECTILE, "weapons/crylink_impact.wav", VOL_BASE, ATTN_NORM);

		break;
	case EFFECT_IMPACT_NEX:
		org2 = org + backoff * 6;
		pointparticles(particleeffectnum("nex_impact"), org2, '0 0 0', 1);
		if (!issilent)
			sound(self, CHAN_PROJECTILE, "weapons/neximpact.wav", VOL_BASE, ATTN_NORM);

		break;
	case EFFECT_IMPACT_HAGAR:
		org2 = org + backoff * 6;
		pointparticles(particleeffectnum("hagar_explode"), org2, '0 0 0', 1);
		if (!issilent) {
			if (r<0.15)
				sound(self, CHAN_PROJECTILE, "weapons/hagexp1.wav", VOL_BASE, ATTN_NORM);
			else if (r<0.7)
				sound(self, CHAN_PROJECTILE, "weapons/hagexp2.wav", VOL_BASE, ATTN_NORM);
			else
				sound(self, CHAN_PROJECTILE, "weapons/hagexp3.wav", VOL_BASE, ATTN_NORM);
		}
		break;
	case EFFECT_IMPACT_ROCKET:
		org2 = org + backoff * 12;
		pointparticles(particleeffectnum("rocket_explode"), org2, '0 0 0', 1);
		if (!issilent)
			sound(self, CHAN_PROJECTILE, "weapons/rocket_impact.wav", VOL_BASE, ATTN_NORM);

		break;
	case EFFECT_IMPACT_HOOKBOOMB:
		org2 = org + backoff * 2;
		pointparticles(particleeffectnum("hookbomb_explode"), org2, '0 0 0', 1);
		if (!issilent)
			sound(self, CHAN_PROJECTILE, "weapons/hookbomb_impact.wav", VOL_BASE, ATTN_NORM);

		break;
	case EFFECT_IMPACT_FIREBALL:
		org2 = org + backoff * 16;
		pointparticles(particleeffectnum("fireball_explode"), org2, '0 0 0', 1);
		if (!issilent)
			sound(self, CHAN_PROJECTILE, "weapons/fireball_impact2.wav", VOL_BASE, ATTN_NORM * 0.25); // long range boom

		break;
	case EFFECT_IMPACT_RM_GRENADE:
		org2 = org + backoff * 6;
		if (!issilent)
			sound(self, CHAN_PROJECTILE, "weapons/grenade_impact.wav", VOL_BASE, ATTN_NORM);

		pointparticles(particleeffectnum("RM_EXPLOSION"), self.origin, '0 0 0', 1);
		break;
	case EFFECT_IMPACT_RM_PLASMA_SHARD:
	case EFFECT_IMPACT_RM_LASER:
		org2 = org + backoff * 6;
		pointparticles(particles_rm_effectnum_team("RM_HG_PLASMA_SHARD_EXPLODE", self.team, 2 - (impacttype == EFFECT_IMPACT_RM_LASER)), org2, '0 0 0', 1);
		if (!issilent)
			sound(self, CHAN_PROJECTILE, "weapons/electro_impact.wav", VOL_BASE, ATTN_NORM);

		break;
	case EFFECT_IMPACT_RM_PLASMA:
		// plasma bomb explosion
		org2 = org + backoff * 2;
		pointparticles(particles_rm_effectnum_team("RM_HG_PLASMA_EXPLODE", self.team, 2), org2, '0 0 0', 1);
		if (!issilent)
			sound(self, CHAN_PROJECTILE, "weapons/hookbomb_impact.wav", VOL_BASE, ATTN_NORM);

		break;
	default:
		//print("Unhandled damage of weapon ", ftos(hitwep), "\n");
		break;
	}
}

void(void) effect_impact_precache {
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

