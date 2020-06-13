float g_balance_nex_magazinecapacity;
float g_balance_nex_reloadtime;
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
.float nex_ammoclip;

.float nex_lasthit;

void weapon_nex_whoosh(vector start, vector end) {
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
		sound_to_at(MSG_ONE, pseudoprojectile, beampos, CHAN_PROJECTILE, snd, VOL_BASE * f, ATTN_NONE);
	}

	if(pseudoprojectile)
		remove(pseudoprojectile);
}

void weapon_nex_beam_particles(vector start, vector endpos, vector to) {
	weapon_nex_whoosh(start, endpos);
	WriteByte(MSG_BROADCAST, SVC_TEMPENTITY);
	WriteByte(MSG_BROADCAST, TE_CSQC_NEXGUNBEAMPARTICLE);
	
	WriteCoord(MSG_BROADCAST, start_x);
	WriteCoord(MSG_BROADCAST, start_y);
	WriteCoord(MSG_BROADCAST, start_z);
	WriteCoord(MSG_BROADCAST, endpos_x);
	WriteCoord(MSG_BROADCAST, endpos_y);
	WriteCoord(MSG_BROADCAST, endpos_z);
}

void weapon_nex_attack (void)
{
	float flying;
	flying = physics_is_flying(self); // do this BEFORE to make the trace values from bullet_railgun last

	antilag_begin(Akimbo_Owner(self));
	weapon_setup_shot (self, 5, "weapons/nexfire.wav", 1);

	yoda = 0;
	headshot = 0;
	damage_goodhits = 0;
	bullet_railgun (weapon_shotorg, weapon_shotorg + weapon_shotdir * MAX_SHOT_DISTANCE, g_balance_nex_damage, g_balance_nex_force, g_balance_nex_damagefalloff_mindist, g_balance_nex_damagefalloff_maxdist, g_balance_nex_damagefalloff_halflife, g_balance_nex_damagefalloff_forcehalflife, WEP_NEX);
	antilag_end();

	if(headshot)
		announce(Akimbo_Owner(self), "announcer/male/headshot.wav", "^1Head^3Shot");
	else if((yoda && flying) || yoda > 1)
		announce(self, "announcer/male/yoda.wav", "^5Amazing");
	else if (damage_goodhits && self.nex_lasthit && sv_announcer_extra_twohits != "") {
		if(announce(self, sv_announcer_extra_twohits, "^5Impressive"))
			damage_goodhits = 0; // only every second time
	}
	self.nex_lasthit = damage_goodhits;
	
	// flash and burn the wall
	if (trace_ent.solid == SOLID_BSP && !(trace_dphitq3surfaceflags & Q3SURFACEFLAG_NOIMPACT))
		damage_info(trace_endpos, g_balance_nex_damage, 0, 0, g_balance_nex_force * WarpZone_TransformVelocity(WarpZone_trace_transform, weapon_shotdir), WEP_NEX, self);

	//beam and muzzle flash done on client
	WarpZone_DrawEffectTriangle(weapon_shotorg, weapon_shotorg_visual, WarpZone_UnTransformOrigin(WarpZone_trace_transform, trace_endpos), weapon_nex_beam_particles);

	if not(self.items & IT_UNLIMITED_WEAPON_AMMO)
		self.ammo_cells = self.ammo_cells - g_balance_nex_ammo;

	if (g_balance_nex_magazinecapacity)
		self.nex_ammoclip -= 1;
}

void(void) weapon_nex_reloadandready {
	weapon_clip_reloadandready(g_balance_nex_magazinecapacity, ammo_cells, nex_ammoclip,
			g_balance_nex_ammo, g_balance_nex_ammo, g_balance_nex_reloadtime);
}

void(void) weapon_nex_reload {
	weapon_clip_reload(g_balance_nex_magazinecapacity, ammo_cells, nex_ammoclip, g_balance_nex_ammo,
			g_balance_nex_ammo, "weapons/campingrifle_reload.wav", g_balance_nex_reloadtime,
			weapon_nex_reloadandready);
}

float weapon_nex(float req)
{
	if (req == WR_AIM)
		self.BUTTON_ATCK = bot_aim(1000000, 0, 1, FALSE);
	else if (req == WR_THINK) {
		if (g_balance_nex_magazinecapacity && (self.nex_ammoclip < 0 || (!self.nex_ammoclip && self.BUTTON_ATCK))) { // forced reload (e.g. because interrupted)
			if(self.switchweapon == self.weapon)
			if(self.weaponentity.state == WS_READY)
				weapon_nex_reload();
		} else if (!g_balance_nex_magazinecapacity || self.nex_ammoclip > 0) {
			if (self.BUTTON_ATCK) {
				if (weapon_prepareattack(0, g_balance_nex_refire)) {
					weapon_nex_attack();
					weapon_thinkf(WFRAME_FIRE1, g_balance_nex_animtime, weapon_ready);
				}
			}
		}
		if (g_balance_nex_magazinecapacity) {
			self.ammoclip = self.nex_ammoclip;
			if (self.ammoclip <= 0) self.ammoclip = -1;
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
	else if (req == WR_CHECKAMMO1)
		return self.ammo_cells >= g_balance_nex_ammo;
	else if (req == WR_CHECKAMMO2)
		return FALSE;
	else if (req == WR_SUICIDEMESSAGE)
		weapon_deathtypestring = "did the impossible";
	else if (req == WR_KILLMESSAGE) {
		weapon_deathtypestring = "has been vaporized by";
	} else if (req == WR_RELOAD) {
		weapon_nex_reload();
	} else if (req == WR_SETUP) {
		weapon_setup(WEP_NEX);
		if (g_balance_nex_magazinecapacity) {
			weapon_clip_checkmaxbullets(g_balance_nex_magazinecapacity, ammo_cells, nex_ammoclip, g_balance_nex_ammo, g_balance_nex_ammo);
			if not(self.nex_ammoclip)
				self.nex_ammoclip = -1;
		}
	} else if (req == WR_RESETPLAYER) {
		if (g_balance_nex_magazinecapacity)
			self.nex_ammoclip = ((self.items & IT_UNLIMITED_WEAPON_AMMO) ? g_balance_nex_magazinecapacity : -1);
	} else if (req == WR_CVAR_CACHE) {
		CACHE_CVAR(g_balance_nex_magazinecapacity);
		CACHE_CVAR(g_balance_nex_reloadtime);
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
}

void(void) spawnfunc_weapon_nex {
	weapon_defaultspawnfunc(WEP_NEX);
}
