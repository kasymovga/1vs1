float g_voice_flood_spv;
float g_voice_flood_spv_team;

string player_sound_voice_samples_all;
float player_voice_message_sample_not_found;
float player_voice_message_sample_fixed;
stringfield(string type) player_voice_message_sample_field {
	player_voice_message_sample_not_found = 0;
	player_voice_message_sample_fixed = 0;
	switch (type) {
#define _VOICEMSG(m) case #m: return playersound_##m;
	ALLVOICEMSGS
#undef _VOICEMSG
	}
	player_voice_message_sample_not_found = 1;
	return playersound_taunt;
}

stringfield(string type) player_sound_sample_field {
	player_voice_message_sample_not_found = 0;
	player_voice_message_sample_fixed = 0;
	switch (type) {
#define _VOICEMSG(m) case #m: return playersound_##m;
	ALLPLAYERSOUNDS
#undef _VOICEMSG
	}
	player_voice_message_sample_not_found = 1;
	return playersound_taunt;
}

void(string f) player_sound_precache {
	float fh;
	string s;
	fh = fopen(f, FILE_READ);
	if (fh < 0)
		return;

	while ((s = fgets(fh))) {
		if (tokenize_console(s) != 3)
			continue;

		sound_random_precache(argv(1), stof(argv(2)));
	}
	fclose(fh);
	if not(player_sound_voice_samples_all) {
#define _VOICEMSG(m) player_sound_voice_samples_all = strcat(player_sound_voice_samples_all, " ", #m);
		ALLVOICEMSGS
#undef _VOICEMSG
		player_sound_voice_samples_all = strzone(substring(player_sound_voice_samples_all, 1, strlen(player_sound_voice_samples_all) - 1));
	}
}

void() player_sound_clear {
#define _VOICEMSG(m) if (self.playersound_##m) { str_unzone_ifneeded(self.playersound_##m); self.playersound_##m = NULL; }
	ALLPLAYERSOUNDS
	ALLVOICEMSGS
#undef _VOICEMSG
}

void(entity to, entity from) player_sound_copy {
#define _VOICEMSG(m) str_unzone_ifneeded(to.playersound_##m); to.playersound_##m = str_zone_ifneeded(from.playersound_##m);
	ALLPLAYERSOUNDS
	ALLVOICEMSGS
#undef _VOICEMSG
}

float(string f, float first) player_sound_load {
	float fh;
	string s;
	var .string field;
	fh = fopen(f, FILE_READ);
	if (fh < 0)
		return FALSE;

	while ((s = fgets(fh))) {
		if (tokenize_console(s) != 3)
			continue;

		field = player_sound_sample_field(argv(0));
		if (player_voice_message_sample_not_found)
			field = player_voice_message_sample_field(argv(0));

		if (player_voice_message_sample_not_found)
			continue;

		if (player_voice_message_sample_fixed)
			if not(first)
				continue;

		if (self.field)
			strunzone(self.field);

		self.field = strzone(strcat(argv(1), " ", argv(2)));
	}
	fclose(fh);
	return TRUE;
}

void() player_sound_update {
	player_sound_clear();
	player_sound_load("sound/player/default.sounds", 1);
	float loaded = FALSE;
	if (player_sound_load(strcat(self.body.model, ".sounds"), 0)) loaded = TRUE;
	if (player_sound_load(strcat(self.body.model, "_", ftos(self.skinindex), ".sounds"), 0)) loaded = TRUE;
	if not(loaded) //aditional fallback attempt with skin 0
		player_sound_load(strcat(self.body.model, "_0.sounds"), 0);
}

void(string type, string msg) player_sound_voice_message {
	var .string sample;
	float ownteam;
	if (self.classname != "player")
		return;

	sample = player_voice_message_sample_field(type);
	if (player_voice_message_sample_not_found) {
		sprint(self, strcat("Invalid voice. Use one of: ", player_sound_voice_samples_all, "\n"));
		return;
	}
	ownteam = (type != "taunt" && type != "teamshot");
	float flood;
	float flood_spv;
	var .float flood_field;
	flood = 0;
	if (ownteam) {
		flood_spv = g_voice_flood_spv_team;
		flood_field = floodcontrol_voiceteam;
	} else {
		flood_spv = g_voice_flood_spv;
		flood_field = floodcontrol_voice;
	}
	if (time >= self.flood_field)
		self.flood_field = max(time, self.flood_field) + flood_spv;
	else
		flood = 1;

	if (timeout_status == 2) //when game is paused, no flood protection
		self.flood_field = flood = 0;

	if (msg != "")
		chat_say(self, ownteam, world, msg, 0);

	if (flood)
		return;

	string s = sound_random_by_str(self.sample);
	if (type == "taunt") {
		if (self.classname == "player")
			if (self.deadflag == DEAD_NO)
				anim_set((self.body.weaponentity ? self.body.weaponentity : self.body), self.anim_taunt, FALSE, TRUE, TRUE);

		if (!sv_taunt)
			return;

		FOR_EACH_REALCLIENT(msg_entity) {
			if (msg_entity.cvar_cl_voice_directional >= 1) {
				if (msg_entity == self || !self.body)
					sound_to(MSG_ONE, self, CHAN_VOICE, s, VOL_BASEVOICE, bound(ATTN_MIN, msg_entity.cvar_cl_voice_directional_taunt_attenuation, ATTN_MAX));
				else
					sound_to(MSG_ONE, self.body.body, CHAN_VOICE, s, VOL_BASEVOICE, bound(ATTN_MIN, msg_entity.cvar_cl_voice_directional_taunt_attenuation, ATTN_MAX));
			} else if (msg_entity.cvar_cl_voice_directional >= 0)
				sound_to(MSG_ONE, self, CHAN_VOICE, s, VOL_BASEVOICE, ATTN_NONE);
		}
	} else if (type == "teamshoot") {
		if (self.pusher)
			if (self.pusher.team == self.team) {
				msg_entity = self.pusher;
				if (clienttype(msg_entity) == CLIENTTYPE_REAL) {
					if (msg_entity.cvar_cl_voice_directional == 1)
						sound_to(MSG_ONE, self, CHAN_VOICE, s, VOL_BASEVOICE, ATTN_MIN);
					else if (msg_entity.cvar_cl_voice_directional >= 0)
						sound_to(MSG_ONE, self, CHAN_VOICE, s, VOL_BASEVOICE, ATTN_NONE);
				}
				msg_entity = self;
				if (clienttype(msg_entity) == CLIENTTYPE_REAL)
					sound_to(MSG_ONE, self, CHAN_VOICE, s, VOL_BASE, ATTN_NONE);
			}
	} else {
		FOR_EACH_REALCLIENT(msg_entity)
			if (!team_mode || msg_entity.team == self.team)
			{
				if (msg_entity.cvar_cl_voice_directional == 1)
					sound_to(MSG_ONE, self, CHAN_VOICE, s, VOL_BASEVOICE, ATTN_MIN);
				else if (msg_entity.cvar_cl_voice_directional >= 0)
					sound_to(MSG_ONE, self, CHAN_VOICE, s, VOL_BASEVOICE, ATTN_NONE);
			}
	}
}

void(void) player_sound_init {
	CVAR_CACHE(g_voice_flood_spv);
	CVAR_CACHE(g_voice_flood_spv_team);
	player_sound_precache("sound/player/default.sounds");
}
