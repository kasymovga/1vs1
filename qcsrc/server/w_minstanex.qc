float g_balance_minstanex_animtime;
float g_balance_minstanex_refire;

.float minstanex_lasthit;

void W_MinstaNex_Attack (void)
{
	float flying;
	flying = IsFlying(self); // do this BEFORE to make the trace values from FireRailgunBullet last

	W_SetupShot (self, TRUE, 0, "weapons/minstanexfire.wav", 0);

	yoda = 0;
	damage_goodhits = 0;
	headshot = 0;
	FireRailgunBullet (w_shotorg, w_shotorg + w_shotdir * MAX_SHOT_DISTANCE, 10000, 800, 0, 0, 0, 0, WEP_MINSTANEX);

	if(yoda > 1)
		announce(self, "announcer/male/yoda.wav");

	if(headshot)
		announce(self, "announcer/male/headshot.wav");

	self.minstanex_lasthit = damage_goodhits;
	pointparticles(particleeffectnum("nex_muzzleflash"), w_shotorg, w_shotdir * 1000, 1);

	// teamcolor / hit beam effect
	if(teamplay)
	{
	    switch(self.team)
	    {
            case COLOR_TEAM1:   // Red
                if(damage_goodhits)
                    trailparticles(world, particleeffectnum("TE_TEI_G3RED_HIT"), w_shotorg, trace_endpos);
                else
                    trailparticles(world, particleeffectnum("TE_TEI_G3RED"), w_shotorg, trace_endpos);
                break;
            case COLOR_TEAM2:   // Blue
                if(damage_goodhits)
                    trailparticles(world, particleeffectnum("TE_TEI_G3BLUE_HIT"), w_shotorg, trace_endpos);
                else
                    trailparticles(world, particleeffectnum("TE_TEI_G3BLUE"), w_shotorg, trace_endpos);
                break;
            case COLOR_TEAM3:   // Yellow
                if(damage_goodhits)
                    trailparticles(world, particleeffectnum("TE_TEI_G3YELLOW_HIT"), w_shotorg, trace_endpos);
                else
                    trailparticles(world, particleeffectnum("TE_TEI_G3YELLOW"), w_shotorg, trace_endpos);
                break;
            case COLOR_TEAM4:   // Pink
                if(damage_goodhits)
                    trailparticles(world, particleeffectnum("TE_TEI_G3PINK_HIT"), w_shotorg, trace_endpos);
                else
                    trailparticles(world, particleeffectnum("TE_TEI_G3PINK"), w_shotorg, trace_endpos);
                break;
	    }
	}
	else
        trailparticles(world, particleeffectnum("TE_TEI_G3"), w_shotorg, trace_endpos);

	// flash and burn the wall
	if (trace_ent.solid == SOLID_BSP && !(trace_dphitq3surfaceflags & Q3SURFACEFLAG_NOIMPACT))
		Damage_DamageInfo(trace_endpos, 10000, 0, 0, 800 * w_shotdir, WEP_MINSTANEX, self);

	if not(self.items & IT_UNLIMITED_WEAPON_AMMO)
		self.ammo_cells = self.ammo_cells - 1;
}


float w_minstanex(float req)
{
	if (req == WR_AIM)
	{
		if (self.ammo_cells > 0 || self.items & IT_UNLIMITED_AMMO)
			self.BUTTON_ATCK = bot_aim(1000000, 0, 1, FALSE);
		else
			self.BUTTON_ATCK2 = bot_aim(g_balance_laser_primary_speed, 0, g_balance_laser_primary_lifetime, FALSE);
	}
	else if (req == WR_THINK)
	{
		if (self.BUTTON_ATCK)
		{
			if (weapon_prepareattack(0, g_balance_minstanex_refire))
			{
				W_MinstaNex_Attack();
				weapon_thinkf(WFRAME_FIRE1, g_balance_minstanex_animtime, w_ready);
			}
		}
		else if (self.BUTTON_ATCK2)
		{
			if (self.jump_interval <= time)
			if (PLAYER_REALLY_ALIVE(self))
			{
				self.jump_interval = time + 0.9 * W_WeaponRateFactor();
				W_Laser_Attack(FALSE);
			}
		}
	}
	else if (req == WR_PRECACHE)
	{
		precache_model ("models/nexflash.md3");
		precache_sound ("weapons/minstanexfire.wav");
		precache_sound ("weapons/nexwhoosh1.wav");
		precache_sound ("weapons/nexwhoosh2.wav");
		precache_sound ("weapons/nexwhoosh3.wav");
		w_laser(WR_PRECACHE);
	}
	else if (req == WR_SETUP)
	{
		weapon_setup(WEP_MINSTANEX);
		self.minstanex_lasthit = 0;
	}
	else if (req == WR_CHECKAMMO1)
	{
		return self.ammo_cells >= 1;
	}
	else if (req == WR_CHECKAMMO2)
		return TRUE;
	else if (req == WR_SUICIDEMESSAGE)
		w_deathtypestring = "did the impossible";
	else if (req == WR_KILLMESSAGE)
		w_deathtypestring = "has been vaporized by";
	else if (req == WR_RESETPLAYER)
	{
		self.minstanex_lasthit = 0;
	}
	else if (req == WR_CVAR_CACHE)
	{
		CACHE_CVAR(g_balance_minstanex_animtime);
		CACHE_CVAR(g_balance_minstanex_refire);
		w_laser(WR_CVAR_CACHE);
	}
	return TRUE;
};
