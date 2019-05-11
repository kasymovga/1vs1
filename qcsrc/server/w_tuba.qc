#define TUBA_NOTE(n) strcat("weapons/tuba_note", ftos(n), ".wav")

float g_balance_tuba_animtime;
float g_balance_tuba_attenuation;
float g_balance_tuba_damage;
float g_balance_tuba_edgedamage;
float g_balance_tuba_force;
float g_balance_tuba_radius;
float g_balance_tuba_refire;
float g_balance_tuba_volume;

.float tuba_notecount;

float Tuba_GetNote(entity pl, float hittype)
{
	float note;
	float movestate;
	movestate = 5;
	if(pl.movement_x < 0) movestate -= 3;
	if(pl.movement_x > 0) movestate += 3;
	if(pl.movement_y < 0) movestate -= 1;
	if(pl.movement_y > 0) movestate += 1;
	switch(movestate)
	{
	// layout: originally I wanted
	//   eb e  e#=f
	//   B  c  d
	//   Gb G  G#
	// but then you only use forward and right key. So to make things more
	// interesting, I swapped B with e#. Har har har...
	//   eb e  B
	// f=e# c  d
	//   Gb G  G#
		case 1: note = -6; break; // Gb
		case 2: note = -5; break; // G
		case 3: note = -4; break; // G#
		case 4: note = +5; break; // e#
		case 5: note =  0; break; // c
		case 6: note = +2; break; // d
		case 7: note = +3; break; // eb
		case 8: note = +4; break; // e
		case 9: note = -1; break; // B
	}
	if(pl.BUTTON_CROUCH)
		note -= 12;
	if(pl.BUTTON_JUMP)
		note += 12;
	if(hittype & HITTYPE_SECONDARY)
		note += 7;
	
	// we support two kinds of tubas, those tuned in Eb and those tuned in C
	// kind of tuba currently is player slot number, or team number if in
	// teamplay
	// that way, holes in the range of notes are "plugged"
	if(teamplay)
	{
		if(pl.team == COLOR_TEAM2 || pl.team == COLOR_TEAM4)
			note += 3;
	}
	else
	{
		if(pl.clientcolors & 1)
			note += 3;
	}
	
	// total range of notes:
	//                       0
	//                 ***  ** ****
	//                        ***  ** ****
	//     ***  ** ****
	//            ***  ** ****
	//     ***  ********************* ****
	//     -18.........................+12
	//        ***  ********************* ****
	//     -18............................+15
	//     with jump: ... +24
	//     ... +27
	return note;
}

void W_Tuba_Attack(float hittype)
{
	vector o;
	float c;
	W_SetupShot(self, 2, "", 1);
	if(self.tuba_notecount)
	{
		self.tuba_notecount = FALSE;
		c = CHAN_WEAPON;
	}
	else
	{
		self.tuba_notecount = TRUE;
		c = CHAN_WEAPON2;
	}
	sound(self, c, TUBA_NOTE(Tuba_GetNote(self, hittype)), bound(0, VOL_BASE * g_balance_tuba_volume, 1), g_balance_tuba_attenuation);
	damage_radius(self, self, g_balance_tuba_damage, g_balance_tuba_edgedamage, g_balance_tuba_radius, world, g_balance_tuba_force, hittype | WEP_TUBA, world);

	o = gettaginfo(self.exteriorweaponentity, 0);
	pointparticles(particleeffectnum("smoke_ring"), o + v_up * 45 + v_right * -6 + v_forward * 8, v_up * 100, 1);
}

void spawnfunc_weapon_tuba (void)
{
	weapon_defaultspawnfunc(WEP_TUBA);
}

float w_tuba(float req)
{
	if (req == WR_AIM)
	{
		// bots cannot play the Tuba well yet
		// I think they should start with the recorder first
		if(vlen(self.origin - self.enemy.origin) < g_balance_tuba_radius)
		{
			if(random() > 0.5)
				self.BUTTON_ATCK = 1;
			else
				self.BUTTON_ATCK2 = 1;
		}
	}
	else if (req == WR_THINK)
	{
		if (self.BUTTON_ATCK)
		if (weapon_prepareattack(0, g_balance_tuba_refire))
		{
			W_Tuba_Attack(0);
			weapon_thinkf(WFRAME_FIRE1, g_balance_tuba_animtime, w_ready);
		}
		if (self.BUTTON_ATCK2)
		if (weapon_prepareattack(1, g_balance_tuba_refire))
		{
			W_Tuba_Attack(HITTYPE_SECONDARY);
			weapon_thinkf(WFRAME_FIRE2, g_balance_tuba_animtime, w_ready);
		}
	}
	else if (req == WR_PRECACHE)
	{
		float i;
		for(i = -18; i <= +27; ++i)
			precache_sound(TUBA_NOTE(i));
	}
	else if (req == WR_SETUP)
		weapon_setup(WEP_TUBA);
	else if (req == WR_CHECKAMMO1)
		return TRUE; // TODO use fuel?
	else if (req == WR_CHECKAMMO2)
		return TRUE; // TODO use fuel?
	else if (req == WR_SUICIDEMESSAGE)
	{
		w_deathtypestring = "hurt his own ears with the @!#%'n Tuba";
	}
	else if (req == WR_KILLMESSAGE)
	{
		w_deathtypestring = "died of #'s great playing on the @!#%'n Tuba";
	}
	else if (req == WR_CVAR_CACHE)
	{
		CACHE_CVAR(g_balance_tuba_animtime);
		CACHE_CVAR(g_balance_tuba_attenuation);
		CACHE_CVAR(g_balance_tuba_damage);
		CACHE_CVAR(g_balance_tuba_edgedamage);
		CACHE_CVAR(g_balance_tuba_force);
		CACHE_CVAR(g_balance_tuba_radius);
		CACHE_CVAR(g_balance_tuba_refire);
		CACHE_CVAR(g_balance_tuba_volume);
	}
	return TRUE;
};
