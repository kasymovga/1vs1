float g_balance_nex_ammo;
float g_balance_nex_animtime;
float g_balance_nex_damage;
float g_balance_nex_damagefalloff_forcehalflife;
float g_balance_nex_damagefalloff_halflife;
float g_balance_nex_damagefalloff_maxdist;
float g_balance_nex_damagefalloff_mindist;
float g_balance_nex_force;
float g_balance_nex_refire;
string sv_announcer_extra_twohits;

.float nex_lasthit;

void NexWhoosh(vector start, vector end) {
	entity pseudoprojectile;
	vector beampos;
	vector dir = normalize(end - start);
	string snd;
	float length = vlen(start - end);
	float f;
	FOR_EACH_REALCLIENT(msg_entity) if(msg_entity != self) if(!msg_entity.railgunhit) if not(msg_entity.classname == "spectator" && msg_entity.enemy == self) // we use realclient, so spectators can hear the whoosh too
	{
		// nearest point on the beam
		beampos = start + dir * bound(0, (msg_entity.origin - start) * dir, length);

		f = bound(0, 1 - vlen(beampos - msg_entity.origin) / 512, 1);
		if(f <= 0)
			continue;

		snd = strcat("weapons/nexwhoosh", ftos(floor(random() * 3) + 1), ".wav");

		if(!pseudoprojectile)
			pseudoprojectile = spawn(); // we need this so the sound uses the "entchannel4" volume
		soundtoat(MSG_ONE, pseudoprojectile, beampos, CHAN_PROJECTILE, snd, VOL_BASE * f, ATTN_NONE);
	}

	if(pseudoprojectile)
		remove(pseudoprojectile);
}

void DrawNexBeamParticles(vector start, vector endpos, vector to) {
	NexWhoosh(start, endpos);
	WriteByte(MSG_BROADCAST, SVC_TEMPENTITY);
	WriteByte(MSG_BROADCAST, TE_CSQC_NEXGUNBEAMPARTICLE);
	
	WriteCoord(MSG_BROADCAST, start_x);
	WriteCoord(MSG_BROADCAST, start_y);
	WriteCoord(MSG_BROADCAST, start_z);
	WriteCoord(MSG_BROADCAST, endpos_x);
	WriteCoord(MSG_BROADCAST, endpos_y);
	WriteCoord(MSG_BROADCAST, endpos_z);
}

void W_Nex_Attack (void)
{
	float flying;
	flying = IsFlying(self); // do this BEFORE to make the trace values from FireRailgunBullet last

	antilag_begin(Akimbo_Owner(self));
	W_SetupShot (self, 5, "weapons/nexfire.wav", 1);

	yoda = 0;
	damage_goodhits = 0;
	FireRailgunBullet (w_shotorg, w_shotorg + w_shotdir * MAX_SHOT_DISTANCE, g_balance_nex_damage, g_balance_nex_force, g_balance_nex_damagefalloff_mindist, g_balance_nex_damagefalloff_maxdist, g_balance_nex_damagefalloff_halflife, g_balance_nex_damagefalloff_forcehalflife, WEP_NEX);
	antilag_end();

	if((yoda && flying) || yoda > 1)
		announce(self, "announcer/male/yoda.wav");
	else if (damage_goodhits && self.nex_lasthit && sv_announcer_extra_twohits != "")
	{
		if(announce(self, sv_announcer_extra_twohits))
			damage_goodhits = 0; // only every second time
	}
	self.nex_lasthit = damage_goodhits;
	
	// flash and burn the wall
	if (trace_ent.solid == SOLID_BSP && !(trace_dphitq3surfaceflags & Q3SURFACEFLAG_NOIMPACT))
		damage_info(trace_endpos, g_balance_nex_damage, 0, 0, g_balance_nex_force * WarpZone_TransformVelocity(WarpZone_trace_transform, w_shotdir), WEP_NEX, self);

	//beam and muzzle flash done on client
	WarpZone_DrawEffectTriangle(w_shotorg, w_shotorg_visual, WarpZone_UnTransformOrigin(WarpZone_trace_transform, trace_endpos), DrawNexBeamParticles);

	if not(self.items & IT_UNLIMITED_WEAPON_AMMO)
		self.ammo_cells = self.ammo_cells - g_balance_nex_ammo;
}

void spawnfunc_weapon_nex (void); // defined in t_items.qc

float w_nex(float req)
{
	if (req == WR_AIM)
		self.BUTTON_ATCK = bot_aim(1000000, 0, 1, FALSE);
	else if (req == WR_THINK)
	{
		if (self.BUTTON_ATCK)
		{
			if (weapon_prepareattack(0, g_balance_nex_refire))
			{
				W_Nex_Attack();
				weapon_thinkf(WFRAME_FIRE1, g_balance_nex_animtime, w_ready);
			}
		}
	}
	else if (req == WR_PRECACHE)
	{
		precache_model ("models/nexflash.md3");
		precache_sound ("weapons/nexfire.wav");
		precache_sound ("weapons/nexwhoosh1.wav");
		precache_sound ("weapons/nexwhoosh2.wav");
		precache_sound ("weapons/nexwhoosh3.wav");
	}
	else if (req == WR_SETUP)
		weapon_setup(WEP_NEX);
	else if (req == WR_CHECKAMMO1)
		return self.ammo_cells >= g_balance_nex_ammo;
	else if (req == WR_CHECKAMMO2)
		return FALSE;
	else if (req == WR_SUICIDEMESSAGE)
		w_deathtypestring = "did the impossible";
	else if (req == WR_KILLMESSAGE)
		w_deathtypestring = "has been vaporized by";
	else if (req == WR_CVAR_CACHE)
	{
		CACHE_CVAR(g_balance_nex_ammo);
		CACHE_CVAR(g_balance_nex_animtime);
		CACHE_CVAR(g_balance_nex_damage);
		CACHE_CVAR(g_balance_nex_damagefalloff_forcehalflife);
		CACHE_CVAR(g_balance_nex_damagefalloff_halflife);
		CACHE_CVAR(g_balance_nex_damagefalloff_maxdist);
		CACHE_CVAR(g_balance_nex_damagefalloff_mindist);
		CACHE_CVAR(g_balance_nex_force);
		CACHE_CVAR(g_balance_nex_refire);
		CACHE_CVAR_STR(sv_announcer_extra_twohits);
		if (sv_announcer_extra_twohits != "")
			precache_sound(sv_announcer_extra_twohits);
	}
	return TRUE;
};
