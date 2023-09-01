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

float(entity pl, float hittype) weapon_tuba_note {
	float note = 0;
	float movestate;
	movestate = 5;
	if (pl.movement_x < 0) movestate -= 3;
	if (pl.movement_x > 0) movestate += 3;
	if (pl.movement_y < 0) movestate -= 1;
	if (pl.movement_y > 0) movestate += 1;
	switch (movestate) {
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
	if (pl.BUTTON_CROUCH)
		note -= 12;

	if (pl.BUTTON_JUMP)
		note += 12;

	if (hittype & HITTYPE_SECONDARY)
		note += 7;
	
	// we support two kinds of tubas, those tuned in Eb and those tuned in C
	// kind of tuba currently is player slot number, or team number if in
	// teamplay
	// that way, holes in the range of notes are "plugged"
	if (team_mode) {
		if (pl.team == COLOR_TEAM2 || pl.team == COLOR_TEAM4)
			note += 3;
	} else {
		if (pl.clientcolors & 1)
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

void(float hittype) weapon_tuba_attack {
	vector o;
	float c;
	weapon_setup_shot(self, 2, "", 1);
	if (self.tuba_notecount) {
		self.tuba_notecount = FALSE;
		c = CHAN_WEAPON;
	} else {
		self.tuba_notecount = TRUE;
		c = CHAN_WEAPON2;
	}
	sound(self, c, TUBA_NOTE(weapon_tuba_note(self, hittype)), bound(0, VOL_BASE * g_balance_tuba_volume, 1), g_balance_tuba_attenuation);
	damage_radius(self, self, g_balance_tuba_damage, g_balance_tuba_edgedamage, g_balance_tuba_radius, world, g_balance_tuba_force, 0, hittype | WEAPON_TUBA | HITTYPE_NOTEAMDAMAGE, world);
	o = gettaginfo(self.exteriorweaponentity, 0);
	pointparticles(particleeffectnum("smoke_ring"), o + v_up * 45 + v_right * -6 + v_forward * 8, v_up * 100, 1);
}

void(void) spawnfunc_weapon_tuba {
	weapon_defaultspawnfunc(WEAPON_TUBA);
}

float(float req) weapon_tuba {
	if (req == WEAPON_REQUEST_AIM) {
		// bots cannot play the Tuba well yet
		// I think they should start with the recorder first
		if (vlen(self.origin - self.enemy.origin) < g_balance_tuba_radius) {
			if (random() > 0.5)
				self.BUTTON_ATCK = 1;
			else
				self.BUTTON_ATCK2 = 1;
		}
	} else if (req == WEAPON_REQUEST_THINK) {
		if (self.BUTTON_ATCK)
		if (weapon_prepareattack(0, g_balance_tuba_refire)) {
			weapon_tuba_attack(0);
			weapon_thinkf(WEAPON_FRAME_FIRE1, g_balance_tuba_animtime, weapon_ready);
		}
		if (self.BUTTON_ATCK2)
		if (weapon_prepareattack(1, g_balance_tuba_refire)) {
			weapon_tuba_attack(HITTYPE_SECONDARY);
			weapon_thinkf(WEAPON_FRAME_FIRE2, g_balance_tuba_animtime, weapon_ready);
		}
	} else if (req == WEAPON_REQUEST_PRECACHE) {
		float i;
		for (i = -18; i <= +27; ++i)
			precache_sound(TUBA_NOTE(i));
	} else if (req == WEAPON_REQUEST_SETUP) {
	} else if (req == WEAPON_REQUEST_SUICIDEMESSAGE) {
		weapon_deathtypestring = "hurt his own ears with the @!#%'n Tuba";
	} else if (req == WEAPON_REQUEST_KILLMESSAGE) {
		weapon_deathtypestring = "died of #'s great playing on the @!#%'n Tuba";
	} else if (req == WEAPON_REQUEST_CVAR_CACHE) {
		CVAR_CACHE(g_balance_tuba_animtime);
		CVAR_CACHE(g_balance_tuba_attenuation);
		CVAR_CACHE(g_balance_tuba_damage);
		CVAR_CACHE(g_balance_tuba_edgedamage);
		CVAR_CACHE(g_balance_tuba_force);
		CVAR_CACHE(g_balance_tuba_radius);
		CVAR_CACHE(g_balance_tuba_refire);
		CVAR_CACHE(g_balance_tuba_volume);
	}
	return TRUE;
}
