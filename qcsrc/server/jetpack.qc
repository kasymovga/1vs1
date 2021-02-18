entity jetpack_physics;
float g_jetpack_attenuation;
float g_balance_pause_fuel_regen;

float(entity to, float sf) jetpack_physics_send {
	WriteByte(MSG_ENTITY, ENT_CLIENT_PHYSICS_JETPACK);
	WriteCoord(MSG_ENTITY, g_jetpack_acceleration_side);
	WriteCoord(MSG_ENTITY, g_jetpack_acceleration_up);
	WriteCoord(MSG_ENTITY, g_jetpack_antigravity);
	WriteCoord(MSG_ENTITY, g_jetpack_maxspeed_side);
	WriteCoord(MSG_ENTITY, g_jetpack_maxspeed_up);
	return TRUE;
}

void(float fuel_fact) jetpack_finished {
	if not(self.items & IT_UNLIMITED_WEAPON_AMMO)
		self.ammo_fuel -= g_jetpack_fuel * frametime * fuel_fact;

	self.items |= IT_USING_JETPACK;
	// jetpack also inhibits health regeneration, but only for 1 second
	self.pauseregen_finished = max(self.pauseregen_finished, time + g_balance_pause_fuel_regen);
}

float(float fvel) jetpack_velocity_mod {
	if(g_jetpack_fuel && !(self.items & IT_UNLIMITED_WEAPON_AMMO))
		return min(1, self.ammo_fuel / (g_jetpack_fuel * frametime * fvel));

	return 1;
}

float(void) jetpack_using {
	if (self.items & IT_JETPACK) {
		if (!g_jetpack_fuel || self.ammo_fuel > 0 || self.items & IT_UNLIMITED_WEAPON_AMMO)
			return TRUE;

		if not(buttons_prev & 2)
		if (self.items & IT_FUEL_REGEN)
			sprint(self, "You don't have any fuel for the ^2Jetpack\n");
	}
	return FALSE;
}

var void() jetpack_player_effects_next_link;
void() jetpack_player_effects {
	if((self.items & IT_USING_JETPACK) && !self.deadflag) {
		if not(self.modelflags & MF_ROCKET) {
			sound(self, CHAN_TRIGGER, "misc/jetpack_fly.wav", VOL_BASE, g_jetpack_attenuation);
			self.modelflags |= MF_ROCKET;
		}
		self.items &~= IT_USING_JETPACK;
	} else {
		if (self.modelflags & MF_ROCKET) {
			sound_stop(self, CHAN_TRIGGER);
			self.modelflags &~= MF_ROCKET;
		}
	}
	jetpack_player_effects_next_link();
}

float jetpack_enabled;
void(void) jetpack_enable {
	if (jetpack_enabled)
		return;

	hint_add("Press jump key while midair to activate jetpack after you picked up one.");
	jetpack_enabled = TRUE;
	jetpack_physics = spawn();
	net_link_entity(jetpack_physics, FALSE, 0, jetpack_physics_send);
	CVAR_CACHE(g_jetpack_acceleration_side);
	CVAR_CACHE(g_jetpack_acceleration_up);
	CVAR_CACHE(g_jetpack_antigravity);
	CVAR_CACHE(g_jetpack_maxspeed_side);
	CVAR_CACHE(g_jetpack_maxspeed_up);
	CVAR_CACHE(g_jetpack_fuel);
	CVAR_CACHE(g_jetpack_attenuation);
	CVAR_CACHE(g_balance_pause_fuel_regen);
	physics_player_plug = physics_jetpack;
	jetpack_player_effects_next_link = gamehook_chain_player_effects;
	gamehook_chain_player_effects = jetpack_player_effects;
}

void(void) jetpack_init {
	CVAR_CACHE(g_jetpack);
	if not(g_jetpack)
		return;

	jetpack_enable();
	player_start_items |= (IT_JETPACK | IT_FUEL_REGEN);
	player_start_ammo_fuel = max(0, cvar("g_balance_fuel_rotstable"));
}
